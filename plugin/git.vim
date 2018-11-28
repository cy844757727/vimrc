""""""""""""""""""""""""""""""""""""""""""""""""""""
" Author: CY <844757727@qq.com>
" Description: git plugin : tabpage manager
""""""""""""""""""""""""""""""""""""""""""""""""""""
if exists('g:loaded_GIT_Manager') || !executable('git')
  finish
endif
let g:loaded_GIT_Manager = 1

command! -nargs=+ -complete=customlist,GIT_Complete Git :echo system('git ' . "<args>")
command! Ginit :echo system('git init')[:-2]
command! -nargs=* -complete=customlist,GIT_Complete Gadd :call git#Add_Rm_Mv("<args>", 0)
command! -nargs=+ -complete=customlist,GIT_Complete Grm :call git#Add_Rm_Mv("<args>", 1)
command! -nargs=+ -complete=customlist,GIT_Complete Gmv :call git#Add_Rm_Mv("<args>", 2)
command! -nargs=* -complete=customlist,GIT_Complete Gstatus :echo system('git status ' . "<args>")[:-2]
command! -nargs=* -complete=customlist,GIT_Complete Glog :echo system("git log --oneline --graph --pretty=format:\"%h - 👦%an 📆%ar  💬%s\" " . '<args>')[:-2]
command! -nargs=* Greflog :echo system('git reflog ' . "<args>")[:-2]
command! -nargs=* -complete=customlist,GIT_Complete Gmergetool :!git mergetool <args>
command! -nargs=* -complete=customlist,GIT_Complete Gdifftool :!git difftool <args>
command! -nargs=* -complete=custom,GIT_CompleteBranch Gbranch :call git#Branch_Remote_Tag("<args>", 0)
command! -nargs=* -complete=customlist,GIT_Complete Gremote :call git#Branch_Remote_Tag("<args>", 1)
command! -nargs=* -complete=custom,GIT_CompleteBranch Gtag :call git#Branch_Remote_Tag("<args>", 2)
command! -nargs=+ -complete=customlist,GIT_Complete Gcommit :call git#Commit_Reset_Revert_CheckOut_Merge("<args>", 0)
command! -nargs=+ -complete=customlist,GIT_Complete Greset :call git#Commit_Reset_Revert_CheckOut_Merge("<args>", 1)
command! -nargs=+ Grevert :call git#Commit_Reset_Revert_CheckOut_Merge("<args>", 2)
command! -nargs=+ -complete=customlist,GIT_Complete Gcheckout :call git#Commit_Reset_Revert_CheckOut_Merge("<args>", 3)
command! -nargs=+ -complete=custom,GIT_CompleteBranch Gmerge :call git#Commit_Reset_Revert_CheckOut_Merge("<args>", 4)
command! -nargs=* Gpush :call GIT#Push_Pull_Fetch("<args>", 0)
command! -nargs=* Gpull :call GIT#Push_Pull_Fetch("<args>", 1)
command! -nargs=* Gfetch :call GIT#Push_Pull_Fetch("<args>", 2)
command! -nargs=* -complete=customlist,GIT_Complete Gdiff :call git#Diff(<f-args>)
command! GitTogglePage :call git#Toggle()

augroup Git_manager
	autocmd!
	autocmd BufWinEnter .Git_log    set filetype=gitlog|set nobuflisted
	autocmd BufWinEnter .Git_commit set filetype=gitcommit|set nobuflisted
	autocmd BufWinEnter .Git_status set filetype=gitstatus|set nobuflisted
	autocmd BufWinEnter .Git_branch set filetype=gitbranch|set nobuflisted
augroup END

" For merge complete
function! GIT_CompleteBranch(L, C, P)
    if a:L =~ '^-'
        return system("git help merge|sed -n 's/ \\+\\(-[-a-zA-Z]*\\).*/\\1/p'")
    else
        return system("git branch|grep '^[^*]'|sed -n 's/^ \\+//p'")
    endif
endfunction

function! GIT_Complete(L, C, P)
    let l:cmd = split(strpart(a:C, 0, a:P))
    if l:cmd[0] == 'Git' && (len(l:cmd) == 1 || (len(l:cmd) == 2 && a:L != ''))
        let l:list = systemlist("man git|sed -n 's/^ \\+git-\\([-a-zA-Z]*\\).*/\\1/p'|grep '^" . a:L . "'")
    elseif a:C =~ ' -- '
        let l:list = split(glob(a:L . '*'))
    elseif a:L =~ '^-' && l:cmd[0] == 'Git'
        let l:list = systemlist("git help " . l:cmd[1] .
                    \ "|sed -n 's/^ \\+\\(-\\{1,2\\}\\w[-a-zA-Z]*\\).*/\\1/p'|grep '^" . a:L . "'")
    elseif a:L =~ '^-'
        let l:list = systemlist("git help " . strpart(l:cmd[0], 1) .
                    \ "|sed -n 's/^ \\+\\(-\\{1,2\\}\\w[-a-zA-Z]*\\).*/\\1/p'|grep '^" . a:L . "'")
    else
        if a:L != ''
            call remove(l:cmd, -1)
        endif
        if l:cmd[0] == 'Git' && len(l:cmd) == 2
            let l:str = 'g' . strpart(l:cmd[0], 1) . ' ' .l:cmd[1]
        elseif len(l:cmd) == 1
            let l:str = 'git ' . strpart(l:cmd[0], 1)
        else
            return []
        endif
        let l:list = systemlist("man " . l:str .
                    \ "|sed -n '7,30s/^ \\+" . l:str . " \\(\\w[-a-z]\\+\\) [-<\\[].*/\\1/p'|grep '^" . a:L . "'")
    endif
    return l:list
endfunction

