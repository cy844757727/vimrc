""""""""""""""""""""""""""""""""""""""""""""""""""""
" Name: git plugin : tabpage manager
" Author: CY <844757727@qq.com>
""""""""""""""""""""""""""""""""""""""""""""""""""""
if exists('g:loaded_A_GIT_Manager') || !executable('git')
    finish
endif
let g:loaded_A_GIT_Manager = 1


function! git#Diff(...)
    if isdirectory('.git')
        let l:ex = '!git difftool -y '

        if a:0 == 0
            exe l:ex.expand('%')
        elseif a:0 == 1
            exe l:ex.a:1
        else
            exe l:ex.join(a:000, ' ')
        endif
    elseif a:0 > 0
        exe '!vim -d '.a:1.' '.get(a:000, 1, expand('%'))
    endif
endfunction


function! git#FormatLog()
    let l:log = systemlist("git log --oneline --graph --branches --pretty=format:'^%h^  %an^ ﲊ %ar^%d  %s'")
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


function! git#FormatBranch()
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
        let l:stash = ['', 'Stash:', ''] + l:stash
    endif
    return l:local + l:remote + l:stash + l:tag
endfunction


function! git#FormatCommit(hash)
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


function! git#FormatStatus()
    let l:status = filter(systemlist('git status'), "v:val !~ '^\\s*[（(]'")

    for l:i in range(len(l:status))
        if l:status[l:i] =~ '\v^\s+'
            let l:list = split(l:status[l:i])
            let l:status[l:i] = printf('    %-10S  %s', l:list[0], join(l:list[1:]))
        endif
    endfor

    if l:status[-1] !~ '\S'
        call remove(l:status, -1)
    endif

    return l:status
endfunction


function! s:TabPage()
    let l:col = float2nr(0.4 * &columns)
    let l:lin = float2nr(0.4 * &lines)
    silent $tabnew .Git_log
    setlocal noreadonly modifiable
    call setline(1, git#FormatLog())
    setlocal readonly nomodifiable
    exe 'silent belowright ' . l:col . 'vnew .Git_status'
    setlocal noreadonly modifiable
    call setline(1, git#FormatStatus())
    call search('^\(\s\+\)\zs\S')
    setlocal readonly nomodifiable
    exe 'silent belowright ' . l:lin . 'new .Git_branch'
    setlocal noreadonly modifiable
    call setline(1, git#FormatBranch())
    call search('^\([ *]\+\)\zs\w')
    setlocal readonly nomodifiable
    1wincmd w
    exe 'silent belowright ' . l:lin . 'new .Git_commit'
    setlocal noreadonly modifiable
    call setline(1, git#FormatCommit('HEAD'))
    setlocal readonly nomodifiable
    normal zj
    3wincmd w
    let t:tab_lable = ' Git-Manager'
    let t:git_tabpageManager = 1
endfunction


function! git#Toggle()
    if exists('t:git_tabpageManager')
        let l:gitTab = tabpagenr()
        try
            exe s:TabPrevious . 'tabnext'
        catch 'E121'
            1tabnext
        catch 'E16'
            $tabnext
        endtry
        exe l:gitTab . 'tabclose'
    else
        let s:TabPrevious = tabpagenr()
        try
            exe win_id2tabwin(win_findbuf(bufnr('Git_log'))[0])[0] . 'tabnext'
            call git#Refresh()
        catch
            call s:TabPage()
        endtry
    endif
endfunction


function! git#Refresh()
    if bufwinnr('.Git_log') != -1
        let l:winnr = winnr()
        4wincmd w
        setlocal noreadonly modifiable
        let l:pos = getpos('.')
        silent edit!
        call setline(1, git#FormatBranch())
        call setpos('.', l:pos)
        setlocal readonly nomodifiable
        wincmd W
        setlocal noreadonly modifiable
        let l:pos = getpos('.')
        silent edit!
        call setline(1, git#FormatStatus())
        call setpos('.', l:pos)
        setlocal readonly nomodifiable
        1wincmd w
        setlocal noreadonly modifiable
        let l:pos = getpos('.')
        silent edit!
        call setline(1, git#FormatLog())
        call setpos('.', l:pos)
        setlocal readonly nomodifiable
        exe l:winnr . 'wincmd w'
        let t:tab_lable = ' Git-Manager'
        let t:git_tabpageManager = 1
    endif
endfunction


function! git#MainMenu()
    echo
                \ "** Git Menu:\n".
                \ "==================================================\n".
                \ "    (i)nitialize      <git init>\n".
                \ "    (a)dd all files   <git add.>\n".
                \ "    (r)eset all files <git reset -q HEAD>\n".
                \ "    (c)ommit          <git commit -m>\n".
                \ "    a(m)end           <git commit --amend -m>\n".
                \ "    (p)ush            <git push>\n".
                \ "    (f)etch           <git fetch>\n".
                \ "    (P)ull            <git pull>\n".
                \ "    (t)ool operation\n".
                \ "    (o)ther operation\n".
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
        call git#Refresh()
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
                \ "    (g)c                   <git gc>\n".
                \ "    (r)ebase branch        <git rebash>\n"
                \ "!?:"
    let l:msg = ''
    let l:char = nr2char(getchar())
    redraw!
    if l:char == 'a'
        echo "** Add remote repository\n" .
                    \ '============================================================'
        let l:str = input('[option] Name & URL：', 'origin ')
        if l:str != ''
            let l:msg = system('git remote add ' . l:str)
        endif
    elseif l:char == 't'
        echo "** Attach a tag\n" .
                    \ '======================================================='
        let l:str = input('[-a -m Note] Tag: ')
        if l:str != ''
            let l:msg = system('git tag ' . l:str)
        endif
    elseif l:char == 'c'
        echo "** Create and switch a new branch\n" .
                    \ '======================================'
        let l:name = input('Branch: ')
        if l:name != ''
            let l:msg = system('git stash && git checkout -q -b ' . l:name)
        endif
    elseif l:char == 'm'
        echo "** merge the specified branch to current\n" .
                    \ '============================================'
        let l:branch = input('Branch: ', '', 'custom,git#CompleteBranch')
        if l:branch != ''
            let l:msg = system('git merge ' . l:branch)
        endif
    elseif l:char ==# 'g'
        let l:msg = system('git gc')
    elseif l:char == 'r'
        echo "** rebase the specified branch to current\n" .
                    \ '============================================'
        let l:branch = input('Branch: ', '', 'custom,git#CompleteBranch')
        if l:branch != ''
            let l:msg = system('git rebase ' . l:branch)
        endif
    endif
    return l:msg
endfunction


function! git#CompleteBranch(L, C, P)
    if a:L =~ '^-'
        return system("git help merge|sed -n 's/ \\+\\(-[-a-zA-Z]*\\).*/\\1/p'")
    else
        return system("git branch|grep '^[^*]'|sed -n 's/^ \\+//p'")
    endif
endfunction

function! git#ClearTab()
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

