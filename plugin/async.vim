""""""""""""""""""""""""""""""""""""""""""""""
" File: async.vim
" Author: Cy <844757727@qq.com>
" Description: Asynchronous job & embedded terminal manager
"              script language run and debug
" Last Modified: 2019年01月06日 星期日 16时59分49秒
""""""""""""""""""""""""""""""""""""""""""""""

if exists('g:loaded_Async') || v:version < 800
  finish
endif
let g:loaded_Async = 1


command -nargs=* -complete=shellcmd TTerm :call async#TermToggle('toggle', <f-args>)
command -nargs=+ -complete=shellcmd Term :call async#TermToggle('on', <f-args>)
command -nargs=+ -complete=shellcmd HTerm :call async#TermToggle('off', <f-args>)
command -nargs=+ -bang -complete=shellcmd Async :call async#JobRun(<q-args>, '<bang>')
command -bang SAsync :call async#JobStop('<bang>')
command -nargs=+ -complete=file SGdb :call async#GdbStart(<q-args>, BMBPSign#SignRecord('break', 'tbreak'))

