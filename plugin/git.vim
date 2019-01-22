""""""""""""""""""""""""""""""""""""""""""""""""""""
" Author: CY <844757727@qq.com>
" Description: git plugin : tabpage manager
""""""""""""""""""""""""""""""""""""""""""""""""""""
if exists('g:loaded_GIT_Manager') || !executable('git')
  finish
endif
let g:loaded_GIT_Manager = 1

command! -nargs=+ -complete=customlist,GIT_Complete Git :echo system('git ' . "<args>")
command! -nargs=* -complete=customlist,GIT_Complete Gdiff :call git#Diff(<f-args>)


augroup Git_manager
	autocmd!
	autocmd BufWinEnter .Git_log    set filetype=gitlog|set nobuflisted
	autocmd BufWinEnter .Git_commit set filetype=gitcommit|set nobuflisted
	autocmd BufWinEnter .Git_status set filetype=gitstatus|set nobuflisted
	autocmd BufWinEnter .Git_branch set filetype=gitbranch|set nobuflisted
augroup END


function! GIT_Complete(L, C, P)
    let l:cmd = split(strpart(a:C, 0, a:P))

    if l:cmd[0] == 'Git'
        let l:cmd[0] = 'git'
    else
        let l:cmd[0] = strpart(l:cmd[0], 1)
        let l:cmd = ['git'] + l:cmd
    endif

    if !isdirectory('.git') || index(l:cmd, '--') != -1
        let l:list = map(getcompletion(a:L.'*', 'file'), 'fnameescape(v:val)')
    elseif a:L =~ '^-' && len(filter(copy(l:cmd), "v:val !~ '^-'")) < 3
        let l:list = systemlist('git help '.(l:cmd[1] =~ '^-' ? 'git' : l:cmd[1])."|sed -n '".
                    \ 's/^ \+\(-\{1,2\}\w[-a-zA-Z]*\).*/\1/p'."'|grep '".a:L."'")
    elseif len(l:cmd) == 1 || (len(l:cmd) == 2 && a:L != '')
        let l:list = systemlist("man git|sed -n '".'s/^ \+git-\([-a-zA-Z]*\).*/\1/p'."'|grep '".a:L."'")
    elseif l:cmd[1] !~ '^-' && ((len(l:cmd) == 2 && a:L == '') || (len(l:cmd) == 3 && a:L != ''))
        let l:list = systemlist('man git '.l:cmd[1]."|sed -n '".
                    \ '7,30s/^ \+git'.l:cmd[1].' \(\w[-a-z]\+\) [-<\[].*/\1/p'."'|grep '".a:L."'")
    else
        return []
    endif

    return l:list
endfunction

