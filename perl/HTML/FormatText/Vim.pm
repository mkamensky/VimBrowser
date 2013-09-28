# File Name: Vim.pm
# Maintainer: Moshe Kaminsky <kaminsky@math.huji.ac.il>
# Last Update: September 17, 2004
###########################################################

package HTML::FormatText::Vim;
# for some reason, 'use base' doesn't fail when the base cannot be loaded, so
# we 'use' it explicilty
use HTML::FormatText;
use base qw(HTML::FormatText);
use Data::Dumper;
use URI;
use Vim;
use Encode;

use warnings;
use integer;

BEGIN {
    our $VERSION = 0.3;
}

# translation from attribute names (as in the perl modules and the vim 
# variables) to html tag names. This also determines the possible values.  
# Therefore, changes here should be reflected in browser.pod, and in the syntax 
# file
our %Markup = qw(
    bold       b
    italic     i 
    teletype   tt
    strong     strong
    em         em
    code       code
    kbd        kbd
    samp       samp
    var        var
);

sub configure {
    my ($self, $args) = @_;
    $self->{$_} = delete $args->{$_} foreach qw(base forms encoding);
    $self->{'line'} = 0;
    $self->{'formcount'} = 0;
    $self->{$_} = delete $args->{$_} 
        foreach grep { /_(start|end)/o } keys %$args;
    $self->SUPER::configure($args);
}

sub nl {
    my $self = shift;
    $self->{'line'}++;
    $self->SUPER::nl(@_);
    1;
}

sub br_start {
    shift->nl(@_);
    1;
}

sub a_start {
    my $self = shift;
    my $node = $_[0];
    $self->{'lasttext'} = '';
    if ($node->attr('href')) {
        $self->{'href'} = URI->new_abs($node->attr('href'), $self->{'base'});
    };
    if ($node->attr('name')) {
        # got a fragment, update the fragments list
        $self->{'fragment'}{$node->attr('name')} = $self->{'line'};
    }
    $self->SUPER::a_start(@_);
}

# we keep count of the current 'line'. The curret column is in 'curpos'. This 
# way we generate the list of links per line.
sub a_end {
    my $self = shift;
    my $node = $_[0];
    my $text = delete $self->{'lasttext'};
    #$self->{'hspace'} = 1;
    if (exists $self->{'href'}) {
        $self->out("<<$text>>");
        push @{$self->{'links'}[$self->{'line'}]}, {
            target => $self->{'href'}->as_string,
            text => $text,
            from => $self->{'prepos'} + 2,
            to => $self->{'curpos'} - 3,
        };
        delete $self->{'href'};
    } else {
        $self->out($text);
    }
    $self->SUPER::a_end(@_);
}

# forms
sub form_start {
    my $self = shift;
    $self->{'form'} = $self->{'forms'}[$self->{'formcount'}++];
    1;
}

sub form_end {
    shift->vspace(1);
    1;
}

# TODO: need to sort this out
sub label_start {
    shift->{'hspace'} = 1;
    1;
}

sub input_start {
    my ($self, $node) = @_;
    my $type = $node->attr('type');
    my $form = $self->{'form'};
    my $input = $form->find_input($node->attr('name'), $type);
    # Vim::debug("Parsing input of type $type - " . $node->attr('name'));
    my ($line, $from, $to, $update, $target, $getVal, $setVal);
    if ( not $type or $type eq 'text' ) {
        $self->out( ']> ' );
        $line = $self->{'line'};
        $from = $self->{'curpos'} - 1;
        $to =  $self->{'rm'};
        $getVal = sub {
            my $text = shift->getLine($line);
            my $res = substr($text, $from, $to-$from+1);
            $res =~ s/^\s*//o;
            $res =~ s/\s*$//o;
            $res
        };
        $setVal = sub {
            my $page = shift;
            my $text = $page->getLine($line);
            substr($text, $from, $to-$from+1) = shift;
            $page->setLine($line, $text);
        };
        $update = sub {
            $input->value(&$getVal(shift));
        };
        $self->vspace(1);
    } elsif ( $type eq 'submit' or $type eq 'image' ) { 
      # or $type eq 'reset' ) {
        my $value = $node->attr('value') || 'Submit'; #  || "\u$type";
        $self->out( "<<$value>>" );
        $line = $self->{'line'};
        $to = $self->{'curpos'}-3;
        $from = $self->{'prepos'}+2;
        $setVal = $getVal = $update = sub { 1 };
        $target = sub {
            my $obj = shift;
            map { &{$_->{'update'}}($obj) } @{$form->{'vimdata'}};
            my $req = $input->click($form, 1, 1);
        };
    } elsif ( $type eq 'radio' ) {
        $self->out( '(' . ($node->attr('checked') ? '*' : ' ') . ')' );
        $from = $to = $self->{'curpos'} - 2;
        $line = $self->{'line'};
        my $value = $node->attr('value');
        $getVal = sub {
            substr(shift->getLine($line), $from, 1)
        };
        $setVal = sub {
            my $page = shift;
            my $text = $page->getLine($line);
            substr($text, $from, 1) = shift;
            $page->setLine($line, $text);
        };
        $update = sub {
            $input->value($value) if &$getVal(shift) eq '*';
        };
    } elsif ( $type eq 'checkbox' ) {
        $self->out( '[' . ($node->attr('checked') ? 'X' : ' ') . ']' );
        $from = $to = $self->{'curpos'} - 2;
        $line = $self->{'line'};
        my $value = $node->attr('value');
        $getVal = sub {
            substr(shift->getLine($line), $from, 1)
        };
        $setVal = sub {
            my $page = shift;
            my $text = $page->getLine($line);
            substr($text, $from, 1) = shift;
            $page->setLine($line, $text);
        };
        $update = sub {
            $input->value(&$getVal(shift) eq 'X' ? $value : undef);
        };
    } elsif ( $type eq 'password' ) {
        my $size = $node->attr('size') || 6;
        $self->out( '[' . '_' x $size . ']' );
        $to = $self->{'curpos'} - 2;
        $from = $to - $size + 1;
        $line = $self->{'line'};
        # getval will return whether this is set or not
        $getVal = sub { $input->value ? 1 : 0 };
        $setVal = sub {
            my $page = shift;
            my $value = shift;
            $input->value($value);
            my $text = $page->getLine($line);
            substr($text, $from, $size) = ($value ? '#' : '_') x $size;
            $page->setLine($line, $text);
        };
        $update = sub { 1 };
    
    } else {
        return
    }
    my $inDesc = {
        form => $form,
        input => $input,
        from => $from,
        to => $to,
        update => $update,
        target => $target,
        getval => $getVal,
        setval => $setVal,
    };
    push @{$self->{'links'}[$line]}, $inDesc;
    push @{$form->{'vimdata'}}, $inDesc;
    1;
}

sub select_start {
    my ( $self, $node ) = @_;
    my $form = $self->{'form'};
    my $name = $node->attr('name');
    my $input = $form->find_input($name, 'option');
    my @values = map { decode($self->{'encoding'}, $_) } $input->value_names;
    my $len = 0;
    my @lens = map { length(encode_utf8 $_) } @values;
    map { $len = $_ if $_ > $len } @lens;
    $self->out("[$values[0]" . ( ' ' x ($len - $lens[0])) . ']');
    my $line = $self->{'line'};
    my $to = $self->{'curpos'} - 2;
    my $from = $self->{'prepos'} + 1;
    my ($update, $getVal, $setVal);
    $getVal = sub {
        my $text = shift->getLine($line);
        my $res = substr($text, $from, $len);
        $res =~ s/^\s*//o;
        $res =~ s/\s*$//o;
        $res
    };
    $setVal = sub {
        my $page = shift;
        my $text = $page->getLine($line);
        substr($text, $from, $len) = sprintf("%-${len}s", shift);
        $page->setLine($line, $text);
    };
    $update = sub {
        $input->value(decode_utf8(&$getVal(shift)));
    };
    my $inDesc = {
        form => $form,
        input => $input,
        from => $from,
        to => $to,
        update => $update,
        target => undef,
        getval => $getVal,
        setval => $setVal,
    };
    push @{$self->{'links'}[$line]}, $inDesc;
    push @{$form->{'vimdata'}}, $inDesc;
    1;
}

my @line = qw(= - ^ + " .);

sub header_end {
    my ($self, $level, $node) = @_;
    $self->vspace(0);
    $self->out($line[$level-1] x ($self->{maxpos} - $self->{lm}));
    $self->vspace(1);
    1;
}

for my $markup ( keys %Markup ) {
    my $start = $Markup{$markup} . '_start';
    my $end = $Markup{$markup} . '_end';
    *$start = sub {
        my $self = shift;
        unless ( exists $self->{"${markup}_start"} ) {
            Vim::debug(
                "Format for $markup not defined, calling SUPER::$start(@_)");
            eval '$self->SUPER::' . $start . '(@_)';
            return 1;
        }
        if (exists $self->{'href'}) {
            $self->{'lasttext'} .= $self->{"${markup}_start"};
        } else {
            $self->out($self->{"${markup}_start"});
        }
        1;
    };
    *$end = sub {
        my $self = shift;
        unless ( exists $self->{"${markup}_end"} ) {
            Vim::debug(
                "Format for $markup not defined, calling SUPER::$end(@_)");
            eval '$self->SUPER::' . $end . '(@_)';
            return 1;
        }
        if (exists $self->{'href'}) {
            $self->{'lasttext'} .= $self->{"${markup}_end"};
        } else {
            $self->out($self->{"${markup}_end"});
        }
        1;
    }
}

sub cite_start {
    my $self = shift;
    $self->textflow('`');
    1;
}


sub cite_end {
    my $self = shift;
    $self->textflow("'");
    1;
}

sub center_start {
    my $self = shift;
    $self->{'oldlm'} = $self->{'lm'};
    $self->{'oldrm'} = $self->{'rm'};
    my $width = $self->{'rm'} - $self->{'lm'};
    $self->{'lm'} += $width / 4;
    $self->{'rm'} -= $width / 4;
    $self->SUPER::center_start(@_);
}

sub center_end {
    my $self = shift;
    $self->{'lm'} = $self->{'oldlm'};
    $self->{'rm'} = $self->{'oldrm'};
    $self->vspace(1);
    $self->SUPER::center_end(@_);
}

sub div_end {
    my $self = shift;
    $self->vspace(1);
    $self->SUPER::div_end(@_);
}

# tables - need serious improvement (TODO)

sub tr_start {
    my $self = shift;
    $self->{'rowstart'} = 1;
    1;
}

sub tr_end { shift->nl; 1; }

sub td_start {
    my $self = shift;
    if ( $self->{'rowstart'} ) {
        $self->{'rowstart'} = 0;
    } else {
        $self->out(' ');
    }
    1;
}

sub td_end { 1; }

sub th_start {
    my $self = shift;
    if ( $self->{'rowstart'} ) {
        $self->{'rowstart'} = 0;
    } else {
        $self->out(' ');
    }
    $self->b_start(@_);
}

sub th_end { shift->b_end(@_) }

sub img_start {
    my($self,$node) = @_;
    my $alt = $node->attr('alt');
    $self->textflow( defined($alt) ? $alt : "[IMAGE]" );
    1;
}

sub pre_start {
    my $self = shift;
    $self->out('~>');
    $self->adjust_lm(2);
    $self->adjust_rm(-2);
    $self->SUPER::pre_start(@_);
}

sub pre_end {
    my $self = shift;
    $self->nl;
    $self->out('<~');
    $self->adjust_lm(-2);
    $self->adjust_rm(2);
    $self->SUPER::pre_end(@_);
}


sub pre_out {
    my $self = shift;
    my @lines = split /^/, shift;
    foreach ( @lines ) {
        my $nl = chomp;
        $_ = encode_utf8 $_;
        $self->SUPER::pre_out($_);
        if ( $nl ) {
            $self->nl;
        } else {
            $self->{'prepos'} = $self->{'curpos'};
            $self->{'curpos'} = length($_) + 2;
        }
    }
    1;
}

# this is mouse copied from HTML::FormatText, with the following changes:
# - the tr is removed.
sub out {
    my $self = shift;
    my $text = encode_utf8 shift;

    if ($text =~ /^\s*$/) {
        $self->{hspace} = 1;
        return;
    }

    if (defined $self->{vspace}) {
        if ($self->{out}) {
            $self->nl while $self->{vspace}-- >= 0;
        }
        $self->goto_lm;
        $self->{vspace} = undef;
        $self->{hspace} = 0;
    }

    if ($self->{hspace}) {
        if ($self->{'curpos'} + length($text) > $self->{rm}) {
            # word will not fit on line; do a line break
            $self->nl;
            $self->goto_lm;
        } else {
            # word fits on line; use a space
            $self->collect(' ');
            ++$self->{'curpos'};
        }
        $self->{hspace} = 0;
    }

    $self->collect($text);
    $self->{'prepos'} = $self->{'curpos'};
    my $pos = $self->{'curpos'} += length $text;
    Vim::debug("Added $text, curpos is " . $self->{'curpos'}, 2);
    $self->{maxpos} = $pos if $self->{maxpos} < $pos;
    $self->{'out'}++;
}

sub textflow {
    my $self = shift;
    if (exists $self->{'href'} or exists $self->{'selecttext'}) {
        $self->{'lasttext'} .= "@_";
    } else {
        $self->SUPER::textflow(@_);
    }
    1;
}

1;

__DATA__

# start of POD

=head1 NAME

HTML::FormatText::Vim - format html for displaying using the vim browser

=head1 DESCRIPTION

This module is part of the vim(1) B<browser> plugin. It is used to format 
html before displaying it in a vim buffer. I don't think it's very useful by 
itself.

=head1 SEE ALSO

L<HTML::Formatter>, L<HTML::FormatText>

The documentation of the plugin is available in the file F<browser.pod> in 
the plugins distribution.

=head1 AUTHOR

Moshe Kaminsky <kaminsky@math.huji.ac.il> - Copyright (c) 2004

=head1 LICENSE

This program is free software. You may copy or 
redistribute it under the same terms as Perl itself.

=cut
