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
    if !isdirectory('.git')
        return split(glob(a:L.'*'))
    endif

    let l:cmd = split(strpart(a:C, 0, a:P))
    if a:L =~ '^-' && len(l:cmd) < 4
        let l:op = l:cmd[1] =~ '^-' ? 'git' : l:cmd[1]
        let l:list = systemlist("git help " . l:op .
                    \ "|sed -n 's/^ \\+\\(-\\{1,2\\}\\w[-a-zA-Z]*\\).*/\\1/p'|grep '^" . a:L . "'")
    elseif len(l:cmd) == 1 || (len(l:cmd) == 2 && a:L != '')
        let l:list = systemlist("man git|sed -n 's/^ \\+git-\\([-a-zA-Z]*\\).*/\\1/p'|grep '^" . a:L . "'")
    elseif index(l:cmd, '--') != -1
        let l:list = split(glob(a:L . '*'))
    else
        if a:L != ''
            call remove(l:cmd, -1)
        endif
        if l:cmd[0] == 'Git' && len(l:cmd) == 2
            let l:str = 'git ' .l:cmd[1]
        else
            return []
        endif
        let l:list = systemlist("man " . l:str .
                    \ "|sed -n '7,30s/^ \\+" . l:str . " \\(\\w[-a-z]\\+\\) [-<\\[].*/\\1/p'|grep '^" . a:L . "'")
    endif
    return l:list
endfunction

