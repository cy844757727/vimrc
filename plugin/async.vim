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


command -nargs=* -complete=customlist,Term_completeFun TTerm :call async#TermToggle('toggle', <q-args>)
command -nargs=* -complete=customlist,Term_completeFun Term :call async#TermToggle('on', <q-args>)
command -nargs=+ -complete=customlist,Term_completeFun HTerm :call async#TermToggle('off', <q-args>)
command -nargs=+ -bang -complete=customlist,Async_completeFun Async :call async#JobRun('<bang>', <q-args>, {}, {})
command -nargs=+ -bang -complete=customlist,Async_completeFun Asyncrun :call async#JobRunOut('<bang>', <q-args>, {})
command -bang SAsync :call async#JobStop('<bang>')
command -nargs=+ -complete=file SGdb :call async#GdbStart(<q-args>, BMBPSign#SignRecord('break', 'tbreak'))


function! Term_completeFun(L, C, P)
    let l:ex = split(strpart(a:C, 0, a:P))

    for l:item in l:ex[1:]
        if executable(l:item)
            return map(getcompletion(a:L.'*', 'file'), 'fnameescape(v:val)')
        endif
    endfor

    let l:default = filter(copy(g:Async_TerminalType), "v:val =~ '^".a:L."'")
    return  (!empty(l:default) ? l:default + ['|'] : []) + getcompletion(a:L.'*', 'shellcmd')
endfunction


function! Async_completeFun(L, C, P)
    let l:num = len(split(strpart(a:C, 0, a:P), '\v\s+'))

    if l:num == 1 || (l:num == 2 && a:L != '')
        return getcompletion(a:L.'*', 'shellcmd')
    endif

    return map(getcompletion(a:L.'*', 'file'), 'fnameescape(v:val)')
endfunction

