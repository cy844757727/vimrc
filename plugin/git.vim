""""""""""""""""""""""""""""""""""""""""""""""""""""
" Author: CY <844757727@qq.com>
" Description: git plugin : tabpage manager
""""""""""""""""""""""""""""""""""""""""""""""""""""
if exists('g:loaded_GIT_Manager') || !executable('git')
  finish
endif
let g:loaded_GIT_Manager = 1

command! -nargs=+ -complete=customlist,GIT_CompleteGit Git :echo system('git ' . "<args>")
command! -nargs=* -complete=customlist,GIT_CompleteGit Gdiff :call git#Diff(<q-args>)
command! GitManager :call git#Toggle()


augroup Git_manager
	autocmd!
	autocmd BufWinEnter .Git_log    set filetype=gitlog|set nobuflisted
	autocmd BufWinEnter .Git_commit set filetype=gitcommit|set nobuflisted
	autocmd BufWinEnter .Git_status set filetype=gitstatus|set nobuflisted
	autocmd BufWinEnter .Git_branch set filetype=gitbranch|set nobuflisted
augroup END


function! GIT_CompleteGit(L, C, P)
    let l:ex = split(strpart(a:C, 0, a:P))

    if l:ex[0] == 'Git'
        let l:ex[0] = 'git'
    else
        let l:ex[0] = strpart(l:ex[0], 1)
        let l:ex = ['git'] + l:ex
    endif

    if !isdirectory('.git') || (index(l:ex, '--') != -1 && a:L !~ '--')
        let l:list = map(getcompletion(a:L.'*', 'file'), 'fnameescape(v:val)')
    elseif a:L =~ '^-' && len(filter(copy(l:ex), "v:val !~ '^-'")) < 3
        let l:list = systemlist('git help '.(l:ex[1] =~ '^-' ? 'git' : l:ex[1])."|sed -n '".
                    \ 's/^ \+\(-\{1,2\}\w[-a-zA-Z]*\).*/\1/p'."'|grep -e '".a:L."'")
    elseif len(l:ex) == 1 || (len(l:ex) == 2 && a:L != '')
        let l:list = systemlist("man git|sed -n '".'s/^ \+git-\([-a-zA-Z]*\).*/\1/p'."'|grep -e '".a:L."'")
    elseif l:ex[1] !~ '^-' && ((len(l:ex) == 2 && a:L == '') || (len(l:ex) == 3 && a:L != ''))
        let l:list = systemlist('man git '.l:ex[1]."|sed -n '".
                    \ '7,30s/^ \+git'.l:ex[1].' \(\w[-a-z]\+\) [-<\[].*/\1/p'."'|grep -e '".a:L."'")
    else
        return []
    endif

    return l:list
endfunction

