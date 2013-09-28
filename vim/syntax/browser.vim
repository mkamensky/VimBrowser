" File Name: browser.vim
" Maintainer: Moshe Kaminsky
" Last Modified: Sun 20 Mar 2005 11:15:00 AM IST
" Description: syntax for a browser buffer. part of the browser plugin
" Version: 1.0
"

if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

SynMarkDef Link display oneline contains=TOP,Cite keepend
SynMarkDef FollowedLink display oneline contains=TOP keepend
SynMarkDef Form matchgroup=browserInputBoundary oneline display keepend
SynMarkDef Image oneline display keepend
SynMarkDef Bold display contains=TOP keepend
SynMarkDef Underline display contains=TOP keepend
SynMarkDef Italic display contains=TOP keepend
SynMarkDef Teletype display contains=TOP keepend
SynMarkDef Strong display contains=TOP keepend
SynMarkDef Em display contains=TOP keepend
SynMarkDef Code display contains=TOP keepend
SynMarkDef Kbd display contains=TOP keepend
SynMarkDef Samp display contains=TOP keepend
SynMarkDef Var display contains=TOP keepend
SynMarkDef Cite display contains=TOP keepend
SynMarkDef Definition display contains=TOP keepend
SynMarkDef Header1 contains=TOP keepend display skipnl skipwhite
SynMarkDef Header2 contains=TOP keepend display skipnl skipwhite
SynMarkDef Header3 contains=TOP keepend display skipnl skipwhite
SynMarkDef Header4 contains=TOP keepend display skipnl skipwhite
SynMarkDef Header5 contains=TOP keepend display skipnl skipwhite
SynMarkDef Header6 contains=TOP keepend display skipnl skipwhite

syntax region browserPre matchgroup=browserIgnore start=/\~>$/ end=/^<\~\s*$/ 
      \contains=TOP keepend

" The head
syntax region browserHead matchgroup=browserHeadTitle 
      \start=/^Document header:.*{{{$/ end=/^}}}$/ 
      \contains=browserHeadField keepend
syntax region browserHeadField matchgroup=browserHeadKey 
      \start=/^  [^:]*:/ end=/$/ oneline display contained

" Forms
syntax region browserTextField matchgroup=browserTFstart 
      \start=+\]>+ end=+$+ oneline display
syntax match browserRadioSelected /(\*)/hs=s+1,he=e-1 display
syntax region browserTextArea matchgroup=browserTABorder 
      \start=/^ *--- Click to edit the text area ----* {{{$/ 
      \end=/^ *}}} --*$/ keepend

if exists('g:browser_syntax_sync')
  if g:browser_syntax_sync > 0
    execute 'syntax sync minlines=' . g:browser_syntax_sync
  else
    syntax sync fromstart
  endif
else
  syntax sync minlines=20
endif

if version >= 508 || !exists("did_c_syn_inits")
  if version < 508
    let did_c_syn_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif

  SynMarkLink Header1 SpellBad
  SynMarkLink Header2 SpellCap
  SynMarkLink Header3 SpellRare
  SynMarkLink Header4 SpellLocal
  SynMarkLink Header5 DiffAdd
  SynMarkLink Header6 DiffChange
  HiLink browserHeaderUL PreProc
  HiLink browserIgnore Ignore
  HiLink browserPre Identifier
  HiLink browserHeadTitle Title
  HiLink browserHeadKey Type
  HiLink browserHeadField Constant
  HiLink browserTextField DiffAdd
  HiLink browserTFstart Folded
  HiLink browserTAborder Folded
  HiLink browserTextArea Repeat
  HiLink browserRadioSelected Label
  HiLink browserInputBoundary Delimiter

  SynMarkLink Link Underlined
  SynMarkLink FollowedLink LineNr
  SynMarkLink Form Label
  SynMarkLink Image Special
  SynMarkHighlight Bold term=bold cterm=bold gui=bold
  SynMarkHighlight Underline term=underline cterm=underline gui=underline
  SynMarkHighlight Italic term=italic cterm=italic gui=italic
  SynMarkLink Teletype Special
  SynMarkHighlight Strong term=standout cterm=standout gui=standout
  SynMarkHighlight Em term=bold,italic cterm=bold,italic gui=bold,italic
  SynMarkLink Code Identifier
  SynMarkLink Kbd Operator
  SynMarkHighlight Samp term=inverse cterm=inverse gui=inverse
  SynMarkLink Var Repeat
  SynMarkLink Definition Define
  SynMarkLink Cite Constant

  delcommand HiLink
endif


let b:current_syntax = 'browser'

