""""""""""""""""""""""""""""""""""""""""""""""
" File: async.vim
" Author: Cy <844757727@qq.com>
" Description: Asynchronous job & embedded terminal manager
"              run & debug script language
" Last Modified: 2019年01月18日 星期五 15时04分00秒
""""""""""""""""""""""""""""""""""""""""""""""


if exists('g:loaded_Async') || v:version < 800
  finish
endif
let g:loaded_Async = 1


command -nargs=* -complete=customlist,Async_CompleteTerm TTerm :call async#TermToggle('toggle', <q-args>)
command -nargs=* -complete=customlist,Async_CompleteTerm Term :call async#TermToggle('on', <q-args>)
command -nargs=+ -complete=customlist,Async_CompleteTerm HTerm :call async#TermToggle('off', <q-args>)
command -nargs=+ -bang -complete=customlist,Async_CompleteAsync Async :call async#JobRun('<bang>', <q-args>, {}, {})
command -nargs=+ -bang -complete=customlist,Async_CompleteAsync Asyncrun :call async#JobRunOut('<bang>', <q-args>, {})
command -bang SAsync :call async#JobStop('<bang>')
command -nargs=+ -complete=file SGdb :call async#GdbStart(<q-args>, BMBPSign#SignRecord('break', 'tbreak'))


function! Async_CompleteTerm(L, C, P)
    let l:ex = split(a:C[:a:P])

    for l:item in l:ex[1:]
        if executable(l:item)
            return getcompletion(a:L.'*', 'file')
        endif
    endfor

    let l:default = filter(copy(g:async_terminalType), "v:val =~ '^".a:L."'")
    return  (!empty(l:default) ? l:default + ['|'] : []) + getcompletion(a:L.'*', 'shellcmd')
endfunction


function! Async_CompleteAsync(L, C, P)
    let l:num = len(split(a:C[:a:P], '\v\s+'))
    return getcompletion(a:L.'*', l:num == 1 || (l:num == 2 && a:L != '') ? 'shellcmd' : 'file' )
endfunction

