""""""""""""""""""""""""""""""""""""""""""""""""""""
" Name: git plugin : tabpage manager
" Author: CY <844757727@qq.com>
""""""""""""""""""""""""""""""""""""""""""""""""""""
if exists('g:loaded_A_GIT_Manager') || !executable('git')
    finish
endif
let g:loaded_A_GIT_Manager = 1


function! git#Diff(arg) abort
    if isdirectory('.git')
        exe '!git difftool -y '.(empty(a:arg) ? expand('%') : a:arg)
    elseif !empty(a:arg)
        exe '!vim -d '.a:arg.' '.expand('%')
    endif
endfunction


function! git#FormatLog()
    let l:log = systemlist("git log --oneline --graph --branches --pretty=format:'^%h^  %an^ ﲊ %ar^%d  %s'")
    let [l:lenGraph, l:lenAuthor, l:lenTime] = [0, 0, 0]

    for l:str in l:log
        let l:list = split(l:str, '\^')
        if len(l:list) > 1
            let l:lenGraph = max([strdisplaywidth(l:list[0]), l:lenGraph])
            let l:lenAuthor = max([strdisplaywidth(l:list[2]), l:lenAuthor])
            let l:lenTime = max([strdisplaywidth(l:list[3]), l:lenTime])
        endif
    endfor

    for l:i in range(len(l:log))
        let l:list = split(l:log[l:i], '\^')
        if len(l:list) > 1
            let l:list[0] .= repeat(' ', l:lenGraph - strdisplaywidth(l:list[0]))
            let l:list[2] .= repeat(' ', l:lenAuthor - strdisplaywidth(l:list[2]))
            let l:list[3] .= repeat(' ', l:lenTime - strdisplaywidth(l:list[3]))
            let l:log[l:i] = join(l:list, ' ')
        endif
    endfor

    return l:log
endfunction


function! git#FormatBranch()
    let l:content = ['Local:', ''] + map(systemlist('git branch -v'), "'    '.v:val")
    let l:remote = map(systemlist('git remote -v'), "'    '.v:val")
    let l:tag = map(systemlist('git tag|sort -nr'), "'    '.v:val")
    let l:stash = map(systemlist('git stash list'), "'    '.v:val")

    if !empty(l:remote)
        let l:content += ['', 'Remote:', ''] + l:remote
    endif

    if !empty(l:tag)
        let l:content += ['', 'Tag:', ''] + l:tag
    endif

    if !empty(l:stash)
        let l:content += ['', 'Stash:', ''] + l:stash
    endif

    return l:content
endfunction


function! git#FormatCommit(hash)
    return systemlist(
                \ "git show --pretty='".
                \ 'commit %H ... %p%n'.
                \ 'Author:  %an  <%ae>%n'.
                \ 'Date:    %ad%n'.
                \ 'Commit:  %cn  <%ce>%n'.
                \ 'Date:    %cd%n'.
                \ '%D%n%n'.
                \ '         %s'.
                \ "' ".a:hash.
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
    setlocal nonu nospell nowrap foldcolumn=0

    exe 'silent belowright '.l:col.'vnew .Git_status'
    setlocal noreadonly modifiable
    call setline(1, git#FormatStatus())
    call search('^\(\s\+\)\zs\S')
    setlocal readonly nomodifiable
    setlocal winfixwidth nospell nonu foldcolumn=0

    exe 'silent belowright '.l:lin.'new .Git_branch'
    setlocal noreadonly modifiable
    call setline(1, git#FormatBranch())
    call search('^\([ *]\+\)\zs\w')
    setlocal readonly nomodifiable
    setlocal winfixheight nospell nonu nowrap foldcolumn=0

    1wincmd w
    exe 'silent belowright '.l:lin.'new .Git_commit'
    setlocal noreadonly modifiable
    call setline(1, git#FormatCommit('HEAD'))
    setlocal readonly nomodifiable
    setlocal winfixheight nospell nonu foldcolumn=0
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
            exe win_id2tabwin(win_findbuf(bufnr('Git_log'))[0])[0].'tabnext'
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

        exe l:winnr.'wincmd w'
        let t:tab_lable = ' Git-Manager'
        let t:git_tabpageManager = 1
    endif
endfunction


let s:menuUI1 =  "** Git Menu:\n".
            \ "==================================================\n".
            \ "    (i)nitialize      <git init>\n".
            \ "    (g)c              <git gc>\n".
            \ "    (a)dd all files   <git add.>\n".
            \ "    (r)eset all files <git reset -q HEAD>\n".
            \ "    (c)ommit          <git commit -m>\n".
            \ "    a(m)end           <git commit --amend -m>\n".
            \ "    (p)ush            <git push>\n".
            \ "    (f)etch           <git fetch>\n".
            \ "    (P)ull            <git pull>\n"

let s:menuTip1 = {
            \ 'g': 'Compressing...',
            \ 'p': 'Pushing...',
            \ 'P': 'Pulling...',
            \ 'f': 'Fetching...'
            \ }

let s:menuCmd1 = {
            \ 'i': 'git init -a',
            \ 'a': 'git add .',
            \ 'r': 'git reset -q HEAD',
            \ 'g': 'git gc',
            \ 'p': 'git push',
            \ 'P': 'git pull',
            \ 'f': 'git fetch'
            \ }

let s:menuUI2 =  "** Git Menu:\n" .
            \ "==================================================\n".
            \ "    (a)dd remote           <git remote add>\n".
            \ "    (t)ag                  <git tag>\n".
            \ "    (c)heckout new branch  <git checkout -q -b>\n".
            \ "    (m)erge branch         <git merge>\n".
            \ "    (r)ebase branch        <git rebash>\n".
            \ "    (d)iff tool            <git difftool -y>\n".
            \ "    (M)erge tool           <git mergetool -y>\n" 

let s:sep = repeat('=', 50)
let s:menuTip2 = {
            \ 'a': "** Add remote repository\n".s:sep,
            \ 't': "** Attach a tag\n".s:sep,
            \ 'c': "** Create and switch a new branch\n".s:sep,
            \ 'm': "** merge the specified branch to current\n".s:sep,
            \ 'r': "** rebase the specified branch to current\n".s:sep
            \ }

let s:menuInput2 = {
            \ 'a': ['[option] Name & URL: ', 'origin '],
            \ 't': ['[option] [-a] [-m Note] Tag [commit]: '],
            \ 'c': ['NewBranch [startpoint]: '],
            \ 'm': ['[option] Branch: ', '', 'custom,git#CompleteBranch'],
            \ 'r': ['[option] Branch: ', '', 'custom,git#CompleteBranch']
            \ }

let s:menuCmd2 = {
            \ 'a': 'git remote add ',
            \ 't': 'git tag ',
            \ 'c': 'git stash && git checkout -q -b ',
            \ 'm': 'git merge ',
            \ 'r': 'git rebase '
            \ }


function! git#Menu(sel)
    let l:msg = ''
    echo a:sel ? s:menuUI1 : s:menuUI2
    let l:char = nr2char(getchar())
    redraw!

    if a:sel
        if has_key(s:menuCmd1, l:char)
            echo get(s:menuTip1, l:char, ' ')
            let l:msg = system(s:menuCmd1[l:char])[:-2]
        elseif l:char ==# 'c'
            let l:str = input('Input a message(-m): ')
            if l:str =~# '\S'
                let l:msg = system("git commit -m '".l:str."'")[:-2]
            endif
        elseif l:char ==# 'm'
            let l:str = input('Input a message(--amend -m): ', system('git log --pretty=format:%s -1'))
            if l:str =~# '\S'
                let l:msg = system("git commit --amend -m '".l:str."'")[:-2]
            endif
        else
            return
        endif
    else
        if has_key(s:menuCmd2, l:char)
            echo get(s:menuTip2, l:char, ' ')
            let l:str = function('input', s:menuInput2[l:char])()

            if l:str =~# '\S'
                let l:msg = system(s:menuCmd2[l:char].l:str)[:-2]
            endif
        elseif l:char ==# 'd'
            :!git difftool -y
        elseif l:char ==# 'M'
            :!git mergetool -y
        else
            return
        endif
    endif

    if l:msg !~ '\verror:|fatal:'
        call git#Refresh()
    endif

    redraw
    echo l:msg
endfunction


function! git#CompleteBranch(L, C, P)
    if a:L =~ '^-'
        return system("git help merge|sed -n 's/ \\+\\(-[-a-zA-Z]*\\).*/\\1/p'")
    endif

    return system("git branch|grep '^[^*]'|sed -n 's/^ \\+//p'")
endfunction


