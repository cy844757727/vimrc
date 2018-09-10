""""""""""""""""""""""""""""""""""""""""""""""""""""
" Name: git plugin : tabpage manager
" Author: CY <844757727@qq.com>
""""""""""""""""""""""""""""""""""""""""""""""""""""
if exists('loaded_GIT_Manager')
  finish
endif
let loaded_GIT_Manager = 1

command! -nargs=+ -complete=customlist,GIT_Complete Git :echo system('git ' . "<args>")
command! Ginit :echo system('git init')[:-2]
command! -nargs=* -complete=customlist,GIT_Complete Gadd :call GIT_Add_Rm_Mv("<args>", 0)
command! -nargs=+ -complete=customlist,GIT_Complete Grm :call GIT_Add_Rm_Mv("<args>", 1)
command! -nargs=+ -complete=customlist,GIT_Complete Gmv :call GIT_Add_Rm_Mv("<args>", 2)
command! -nargs=* -complete=customlist,GIT_Complete Gstatus :echo system('git status ' . "<args>")[:-2]
command! -nargs=* -complete=customlist,GIT_Complete Glog :echo system("git log --oneline --graph --pretty=format:\"%h - 👦%an 📆%ar  💬%s\" " . '<args>')[:-2]
command! -nargs=* Greflog :echo system('git reflog ' . "<args>")[:-2]
command! -nargs=* -complete=customlist,GIT_Complete Gmergetool :!git mergetool <args>
command! -nargs=* -complete=customlist,GIT_Complete Gdifftool :!git difftool <args>
command! -nargs=* -complete=custom,GIT_CompleteBranch Gbranch :call GIT_Branch_Remote_Tag("<args>", 0)
command! -nargs=* -complete=customlist,GIT_Complete Gremote :call GIT_Branch_Remote_Tag("<args>", 1)
command! -nargs=* -complete=custom,GIT_CompleteBranch Gtag :call GIT_Branch_Remote_Tag("<args>", 2)
command! -nargs=+ -complete=customlist,GIT_Complete Gcommit :call GIT_Commit_Reset_Revert_CheckOut_Merge("<args>", 0)
command! -nargs=+ -complete=customlist,GIT_Complete Greset :call GIT_Commit_Reset_Revert_CheckOut_Merge("<args>", 1)
command! -nargs=+ Grevert :call GIT_Commit_Reset_Revert_CheckOut_Merge("<args>", 2)
command! -nargs=+ -complete=customlist,GIT_Complete Gcheckout :call GIT_Commit_Reset_Revert_CheckOut_Merge("<args>", 3)
command! -nargs=+ -complete=custom,GIT_CompleteBranch Gmerge :call GIT_Commit_Reset_Revert_CheckOut_Merge("<args>", 4)
command! -nargs=* Gpush :call GIT_Push_Pull_Fetch("<args>", 0)
command! -nargs=* Gpull :call GIT_Push_Pull_Fetch("<args>", 1)
command! -nargs=* Gfetch :call GIT_Push_Pull_Fetch("<args>", 2)
command! -nargs=* -complete=customlist,GIT_Complete Gdiff :call GIT_Diff(<f-args>)
command! GTab :call GIT_TabPage()
command! GClose :call GIT_CloseTab()

augroup Git_manager
	autocmd!
	autocmd BufWinEnter .Git_log    set filetype=gitlog|set nobuflisted
	autocmd BufWinEnter .Git_commit set filetype=gitcommit|set nobuflisted
	autocmd BufWinEnter .Git_status set filetype=gitstatus|set nobuflisted
	autocmd BufWinEnter .Git_branch set filetype=gitbranch|set nobuflisted
augroup END

" windows ID
let s:idLog = -1
let s:idCommit = -1
let s:idStatus = -1
let s:idBranch = -1
"let g:GIT_CurrentBranch = ''

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
        let l:D = matchstr(a:L, '^.*/')
        let l:L = matchstr(a:L, '[^/]*$')
        let l:list = map(systemlist('ls -1F ' . l:D . "|grep '^" . l:L . "'"), "'" . l:D . "' . v:val")
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

function! GIT_Add_Rm_Mv(arg, flag)
    let l:op = a:flag == 0 ? 'add ' :
                \ a:flag == 1 ? 'rm ' : 'mv '
    let l:arg = a:arg == '' ? '.' :
                \ a:arg == '%' ? expand('%') : a:arg
    let l:msg = system('git ' . l:op . l:arg)[:-2]
    if l:msg =~ '^error:\|^fatal:' && bufwinnr('.Git_status') != -1
        3wincmd w
        silent edit!
        call setline(1, GIT_FormatStatus())
    endif
    echo l:msg
endfunction

function! GIT_Branch_Remote_Tag(arg, flag)
    let l:op = a:flag == 0 ? 'branch ' :
                \ a:flag == 1 ? 'remote ' : 'tag '
    let l:msg = system('git ' . l:op . a:arg)[:-2]
    if l:msg !~ 'error:\|fatal:' && bufwinnr('.Git_branch') != -1
        4wincmd w
        silent edit!
        call setline(1, GIT_FormatBranch())
    endif
    echo l:msg
endfunction

function! GIT_Commit_Reset_Revert_CheckOut_Merge(arg, flag)
    let l:op = a:flag == 0 ? 'commit ' :
                \ a:flag == 1 ? 'reset ' :
                \ a:flag == 2 ? 'revert ' :
                \ a:flag == 3 ? 'checkout ' : 'merge '
    let l:msg = system('git ' . l:op . a:arg)[:-2]
    if l:msg !~ 'error:\|fatal:' && bufwinnr('.Git_log') != -1
        call GIT_Refresh()
    endif
    echo l:msg
endfunction

function! GIT_Push_Pull_Fetch(arg, flag)
    let l:op = a:flag == 0 ? 'push ' :
                \ a:flag == 1 ? 'pull ' : 'fetch '
    echo '    Waiting...'
    let l:msg = system('git ' . l:op . a:arg)[:-2]
    if l:msg !~ 'error:\|fatal:' && bufwinnr('.Git_log') != -1
        call GIT_Refresh()
    endif
    echo l:msg
endfunction

function! GIT_Diff(...)
    if a:0 == 0
        exec '!git difftool -y HEAD -- ' . expand('%')
    elseif a:0 == 1
        exec '!git difftool -y HEAD -- ' . a:1
    else
        exec '!git difftool -y ' . join(a:000, ' ')
    endif
endfunction

function! GIT_FormatLog()
    let l:log = systemlist("git log --oneline --graph --branches --pretty=format:\"^%h^👦%an^📆%ar^%d💬%s\"")
    let l:lenGraph = 0
    let l:lenAuthor = 0
    let l:lenTime = 0
    for l:str in l:log
        let l:list = split(l:str, '\^')
        if len(l:list) > 1
            let l:lenGraph = max([strwidth(l:list[0]), l:lenGraph])
            let l:lenAuthor = max([strwidth(l:list[2]), l:lenAuthor])
            let l:lenTime = max([strwidth(l:list[3]), l:lenTime])
        endif
    endfor
    for l:i in range(len(l:log))
        let l:list = split(l:log[l:i], '\^')
        if len(l:list) > 1
            let l:list[0] .= repeat(' ', l:lenGraph - strwidth(l:list[0]))
            let l:list[2] .= repeat(' ', l:lenAuthor - strwidth(l:list[2]))
            let l:list[3] .= repeat(' ', l:lenTime - strwidth(l:list[3]))
            let l:log[l:i] = join(l:list, ' ')
        endif
    endfor
    return l:log
endfunction

function! GIT_FormatBranch()
    let l:local = systemlist('git branch -v')
    let l:remote = systemlist('git remote -v')
    let l:tag = systemlist('git tag|sort -nr')
    let l:stash = systemlist('git stash list')
    call map(l:local, "'    ' . v:val")
    let l:local = ['Local:', ''] + l:local
    if !empty(l:remote)
        call map(l:remote, "'    ' . v:val")
        let l:remote = ['', 'Remote:', ''] + l:remote
    endif
    if !empty(l:tag)
        call map(l:tag, "'    ' . v:val")
        let l:tag = ['', 'Tag:', ''] + l:tag
    endif
    if !empty(l:stash)
        call map(l:stash, "'    ' . v:val")
        let l:stash = ['', 'Stash:', '' ] + l:stash
    endif
    return l:local + l:remote + l:stash + l:tag
endfunction

function! GIT_FormatCommit(hash)
    return systemlist(
                \ "git show --pretty='" .
                \ 'commit %H ... %p%n' .
                \ 'Author:  %an  <%ae>%n' .
                \ 'Date:    %ad%n' .
                \ 'Commit:  %cn  <%ce>%n' .
                \ 'Date:    %cd%n' .
                \ '%D%n%n' .
                \ '         %s' .
                \ "' " . a:hash .
                \ "|sed '/^diff --\\w/s/$/ {[(<{1/'"
                \ )
endfunction

function! GIT_FormatStatus()
    let l:status = systemlist('git status')
    let l:i = len(l:status) - 1
    while l:i >= 0
        if l:status[l:i] =~ '^\s*[（(]'
            call remove(l:status, l:i)
        elseif l:status[l:i] =~ '^\s\+'
            let l:list = split(l:status[l:i])
            let l:status[l:i] = '    ' . l:list[0] . repeat(' ', 10 - strwidth(l:list[0])) . ' ' . join(l:list[1:])
        endif
        let l:i -= 1
    endwhile
    return l:status
endfunction

function! GIT_TabPage()
        let l:col = float2nr(0.4 * &columns)
        let l:lin = float2nr(0.4 * &lines)
        silent $tabnew .Git_commit
        let s:idCommit = win_getid()
        exec 'silent belowright ' . l:col . 'vnew .Git_status'
        let s:idStatus = win_getid()
        call setline(1, GIT_FormatStatus())
        call search('^\(\s\+\)\zs\S')
        exec 'silent belowright ' . l:lin . 'new .Git_branch'
        let s:idBranch = win_getid()
        call setline(1, GIT_FormatBranch())
        call search('^\([ *]\+\)\zs\w')
        1wincmd w
        silent aboveleft new .Git_log
        exec '2resize ' . l:lin
        let s:idLog = win_getid()
        call setline(1, GIT_FormatLog())
"        let g:GIT_CurrentBranch = split(system("git branch|grep '*'"))[1]
endfunction

let s:TabPrevious = 1
function! GIT_Toggle()
    if expand('%') =~ '^.Git_\(log\|commit\|status\|branch\)$'
        tabclose
        try
            exec s:TabPrevious . 'tabnext'
        catch
            $tabnext
        endtry
    else
        let s:TabPrevious = tabpagenr()
        let l:list = win_id2tabwin(s:idLog)
        if l:list != [0, 0]
            exec l:list[0] . 'tabnext'
            call GIT_Refresh()
        " apply to load session file
        elseif s:idLog == -1 && win_findbuf(bufnr('Git_log')) != []
            call win_gotoid(win_findbuf(bufnr('Git_log'))[0])
            let s:idLog = win_getid()
            call GIT_Refresh()
        else
            call GIT_TabPage()
        endif
    endif
endfunction

function! GIT_Refresh(...)
    if bufwinnr('.Git_log') != -1
        let l:winnr = winnr()
    	if a:0 > 0
        	let l:col = float2nr(0.4 * &columns)
        	let l:lin = float2nr(0.4 * &lines)
        	exec '2resize ' . l:lin
        	exec 'vert 3resize ' . l:col
        	exec '4resize ' . l:lin
        endif
        4wincmd w
        let l:pos = getpos('.')
        silent edit!
        call setline(1, GIT_FormatBranch())
        call setpos('.', l:pos)
        wincmd W
        let l:pos = getpos('.')
        silent edit!
        call setline(1, GIT_FormatStatus())
        call setpos('.', l:pos)
        1wincmd w
        let l:pos = getpos('.')
        silent edit!
        call setline(1, GIT_FormatLog())
        call setpos('.', l:pos)
        exec l:winnr . 'wincmd w'
"        let g:GIT_CurrentBranch = split(system("git branch|grep '*'"))[1]
    endif
endfunction

function! GIT_MainMenu()
    echo 
                \ "** Git Menu:\n" .
                \ "==================================================\n" .
                \ "    (i)nitialize      <git init>\n" .
                \ "    (a)dd all files   <git add .>\n" .
                \ "    (r)eset all files <git reset -q HEAD>\n" .
                \ "    (c)ommit          <git commit -m>\n" .
                \ "    a(m)end           <git commit --amend -m>\n" .
                \ "    (p)ush            <git push>\n" .
                \ "    (f)etch           <git fetch>\n" .
                \ "    (P)ull            <git pull>\n" .
                \ "    (t)ool operation\n" .
                \ "    (o)ther operation\n" .
                \ "!?:"
    let l:msg = ''
    let l:char = nr2char(getchar())
    redraw!
    if l:char == 'i'
        let l:msg = system('git init -q')
    elseif l:char == 'a'
        let l:msg = system('git add .')[:-2]
    elseif l:char == 'r'
        let l:msg = system('git reset -q HEAD')[:-2]
    elseif l:char == 'c'
        let l:str = input('Input a message(-m): ')
        if l:str != ''
            let l:msg = system("git commit -m '" . l:str . "'")[:-2]
        endif
    elseif l:char == 'm'
        let l:str = input("Input a message(--amend -m): ", system('git log --pretty=format:%s -1'))
        if l:str != ''
            let l:msg = system("git commit --amend -m '" . l:str . "'")
        endif
    elseif l:char ==# 'p'
        echo ' Pushing...'
        let l:msg = system('git push')[:-2]
    elseif l:char == 'f'
        echo ' Fetching...'
        let l:msg = system('git fetch')[:-2]
    elseif l:char ==# 'P'
        echo ' Pulling...'
        let l:msg = system('git pull')[:-2]
    elseif l:char == 't'
        let l:msg = s:ToolMenu()
    elseif l:char == 'o'
        let l:msg = s:SubMenu()
    else
        return
    endif
    if l:msg !~ 'error:\|fatal:'
        call GIT_Refresh()
    endif
    redraw!
    echo l:msg
endfunction

function! s:ToolMenu()
    echo 
                \ "** Git tool menu\n" .
                \ "=================================================\n" .
                \ "    (d)iff tool           <git difftool>\n" .
                \ "    (m)erge tool          <git mergetool>\n" .
                \ "!?:"
    let l:msg = ''
    let l:char = nr2char(getchar())
    if l:char == 'd'
        :!git difftool -y
    elseif l:char == 'm'
        :!git mergetool -y
    endif
    return l:msg
endfunction

function! s:SubMenu()
    echo
                \ "** Git subMenu:\n" .
                \ "==================================================\n" .
                \ "    (a)dd remote           <git remote add>\n" .
                \ "    (t)ag HEAD             <git tag>\n" .
                \ "    (c)heckout new branch  <git checkout -q -b>\n" .
                \ "    (m)erge branch         <git merge>\n" .
                \ "    (r)ebase branch        <git rebash>\n"
                \ "!?:"
    let l:msg = ''
    let l:char = nr2char(getchar())
    redraw!
    if l:char == 'a'
        echo "** Add remote repository (Use own option, remain URL empty)\n" .
                    \ '============================================================'
        let l:name = input('Name (Default origin)： ', 'origin')
        if l:name != ''
            let l:addr = input('URL: ')
            let l:msg = system('git remote add ' . l:name . ' ' . l:addr)
        endif
    elseif l:char == 't'
        echo "** Attach a tag (Use own option, remain Note empty)\n" .
                    \ '======================================================='
        let l:tag = input('Tag: ')
        if l:tag != ''
            let l:note = input('Note: ')
            let l:tag = l:note == '' ? l:tag : '-a ' . l:tag . " -m '" . l:note . "'"
            let l:msg = system('git tag ' . l:tag)
        endif
    elseif l:char == 'c'
        echo "** Create and switch a new branch\n" .
                    \ '======================================'
        let l:name = input('Branch: ')
        if l:name != ''
            call system('git stash')
            let l:msg = system('git checkout -q -b ' . l:name)
        endif
    elseif l:char == 'm'
        echo "** merge the specified branch to current\n" .
                    \ '============================================'
        let l:branch = input('Branch: ', '', 'custom,GIT_CompleteBranch')
        if l:branch != ''
            let l:msg = system('git merge ' . l:branch)
        endif
    elseif l:char == 'r'
        echo "** rebase the specified branch to current\n" .
                    \ '============================================'
        let l:branch = input('Branch: ', '', 'custom,GIT_CompleteBranch')
        if l:branch != ''
            let l:msg = system('git rebase ' . l:branch)
        endif
    endif
    return l:msg
endfunction

function! GIT_ClearTab()
    if bufexists('.Git_commit')
        bw! .Git_commit
    endif
    if bufexists('.Git_status')
        bw! .Git_status
    endif
    if bufexists('.Git_log')
        bw! .Git_log
    endif
    if bufexists('.Git_branch')
        bw! .Git_branch
    endif
endfunction

