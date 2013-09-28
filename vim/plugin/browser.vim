" File Name: browser.vim
" Maintainer: Moshe Kaminsky <kaminsky@math.huji.ac.il>
" Last Modified: Sun 20 Mar 2005 10:07:52 AM IST
" Description: web browser plugin for vim
" Version: 1.1
" GetLatestVimScripts: 1128 1 synmark.vim
"

" don't run twice or when 'compatible' is set
if exists('g:browser_plugin_version') || &compatible
  finish
endif
let g:browser_plugin_version = 1.1

let g:browser_install_dir = expand('<sfile>:p:h:h')

let g:browser_sidebar = 0

"""""""""""""" commands """""""""""""""""""
" long commands. The short versions from version 0.1 are in browser_short.vim

command! -bang -nargs=+ BrowserCommand call BrowserDefCmd(<q-args>, <q-bang>)

function! BrowserDefCmd(args, bang)
  let cmd = substitute(a:args, '^.*\<\(\S\+\)$', '\1', '')
  let args = a:args
  if strlen(a:bang)
    let cmd = cmd . '<bang>'
    let args = '-bang ' . args
  endif
  execute 'command! ' . args . ' call BrowserInit() | ' . cmd . ' <args>'
endfunction

" opening
BrowserCommand! -bar -nargs=* -complete=custom,s:CompleteBrowse Browse
BrowserCommand! -bar -nargs=* -complete=custom,s:CompleteBrowse BrowserSplit

" history
command! -bang -bar -nargs=? BrowserHistory 
      \if strlen(<q-bang>) | 
      \  BrowserSideBar BrowserHistory <args> | 
      \else | 
      \  Browse history://<args> | 
      \endif

" bookmarks
BrowserCommand! -bar -nargs=1 -complete=custom,s:CompleteBkmkFile 
      \BrowserAddrBook
BrowserCommand -bar -nargs=? -complete=custom,s:CompleteBkmkFile 
      \BrowserListBookmarks
command! -bang -bar -nargs=? -complete=custom,s:CompleteBkmkFile 
      \BrowserBookmarksPage if strlen(<q-bang>) | 
      \BrowserSideBar BrowserBookmarksPage <args> | 
      \else | Browse :<args>: | endif

" other
command! -bar -nargs=+ -complete=command BrowserSideBar 
      \let g:browser_sidebar = matchstr(<q-args>, '^\S*') | 
      \<args> | let g:browser_sidebar = 0


"""" init the browser """"
let g:browser_plugin_load = 'main.vim'
function! BrowserInit()
  if &verbose > 0 || ( exists('g:browser_verbosity_level') && 
                      \g:browser_verbosity_level > 1 )
    echomsg 'Initializing browser plugin...'
  endif
  let load = g:browser_plugin_load
  while strlen(load)
    let cur = substitute(load, ',.*', '', '')
    let load = substitute(load, '^[^,]\+,\?', '', '')
    if &verbose > 0
      echomsg '  ' . cur
    endif
    exec 'source ' . g:browser_install_dir . '/browser/plugin/' . cur
  endwhile
endfunction

command -bar BrowserInit call BrowserInit()

"""" completion """"
function! s:CompleteBkmkFile(...)
  call BrowserInit()
  return BrowserCompleteBkmkFile(a:1, a:2, a:3)
endfunction

function! s:CompleteBrowse(Arg, CmdLine, Pos)
  call BrowserInit()
  return BrowserCompleteBrowse(a:Arg, a:CmdLine, a:Pos)
endfunction

