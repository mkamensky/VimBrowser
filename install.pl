#!/usr/bin/env perl
# File Name: install.pl
# Maintainer: Moshe Kaminsky <kaminsky@math.huji.ac.il>
# Original Date: Fri 19 Nov 2004 09:46:34 PM IST
# Last modified: Sat 20 Nov 2004 08:46:50 AM IST
#
# $Header$
#
# $Log$
#
###########################################################

use warnings;
use integer;

BEGIN {
    our $VERSION = 0.0;

    # try using color
    eval {
        require Term::ANSIColor;
        import Term::ANSIColor;
    };
    sub AUTOLOAD {
        return shift if $AUTOLOAD eq 'main::colored';
        return '' if $AUTOLOAD eq 'main::color';
        die "Calling undefined sub: $AUTOLOAD";
    }
    
    $SIG{__DIE__} = sub { die colored($_[0], 'red')};

    # analyze command line
    use Getopt::Long qw(:config gnu_getopt);
    use Pod::Usage;

    our $opt_help;
    our $opt_man;
    our $opt_version;
    GetOptions('help', 'version', 'man');
    pod2usage(1) if $opt_help;
    pod2usage(-verbose => 2) if $opt_man;
    print "$0 version $VERSION\n" and exit if $opt_version;
}

sub chkInst {
    if ( $Deps eq 'install' ) {
        return 1;
    } elsif ( $Deps eq 'ask' ) {
        my $ans = ask("\n@_", [qw(yes no)], 'yes');
        return $ans =~ /^y/i;
    } else {
        report "...bailing out!\n";
        return 0
    }
}

sub chkModule {
    my $module = shift;
    my $ver = shift || '';
    report "Checking for $module" . ($ver ? " >= $ver" : '') . ' ...';
    eval "use $module $ver";
    if ( $@ ) {
        report "missing or too old";
        my $inst = chkInst("Would you like to install it from CPAN?");
        if ( $inst ) {
            report "...installing from CPAN\n";
            require CPAN;
            croak("Failed to install $module")
                unless CPAN::Shell->expand('Module', $module)->install;
        } else {
            croak 'dependencies not met';
        }
    } else {
        report "Looks fine\n";
    }
}

sub deps {
    chkModule('URI');
    chkModule('HTML::Form', 1.038);
    chkModule('LWP');

    # check for synmark
    report "Checking for the synmark plugin...";
    my $tmp = new File::Temp UNLINK => 0;
    close $tmp;
    system("$Vim -N -c 'redir! > $tmp' -c 'echo g:synmark_version' -c 'q'") == 0
        or croak "Failed to run vim!";
    open my $fh, "$tmp" or die;
    my @lines = <$fh>;
    undef $fh;
    unlink "$tmp";
    if ( $lines[-1] =~ /^E15/ ) {
        report "None found";
        my $inst = chkInst("Would you like to install it from the vim site?");
        if ( $inst ) {
            report "...installing from vim.sf.net\n";
            require LWP::Simple;
            report "Downloading...\n";
            getstore(
                'http://vim.sf.net/scripts/download_script.php?src_id=3624', 
                'synmark.tar.gz');
            report "Unpacking...\n";
            eval 'require Archive::Tar';
            if ( $@ ) {
                report 
                    "  Archive::Tar not available, trying external commands\n";
                my $cmd = sprintf($Extract, 'synmark.tar.gz');
                my @out = `$Extract`;
                croak "Failed to extract
                


    


__DATA__

# start of POD

=head1 NAME

skeleton - 

=head1 SYNOPSIS

B<skeleton> B<--help>|B<--man>|B<--version>

=head1 OPTIONS

=over 4

=item B<--help>

Give a short usage message and exit with status 1

=item B<--man>

Give the full description and exit with status 1

=item B<--version>

Print a line with the program name and exit with status 0

=back

=head1 ARGUMENTS

=head1 DESCRIPTION

=head1 FILES

=head1 SEE ALSO

=head1 TODO

=head1 AUTHOR

Moshe Kaminsky <kaminsky@math.huji.ac.il> - Copyright (c) 2004

=head1 LICENSE

This program is free software. You may copy or 
redistribute it under the same terms as Perl itself.

=cut
