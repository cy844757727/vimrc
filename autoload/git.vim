""""""""""""""""""""""""""""""""""""""""""""""""""""
" Name: git plugin : tabpage manager
" Author: CY <844757727@qq.com>
""""""""""""""""""""""""""""""""""""""""""""""""""""
if exists('g:loaded_A_GIT_Manager') || !executable('git')
    finish
endif
let g:loaded_A_GIT_Manager = 1
let s:default = {'filelog': '', 'commit': 'HEAD', 'reftype': 'hash', 'log': ['HEAD']}
let s:config = copy(s:default)


function! git#Diff(arg) abort
    if isdirectory('.git')
        exe (exists('g:Git_GuiDiffTool') ? 'Async! ' : '!') .
                    \ 'git difftool -y '.(empty(a:arg) ? expand('%') : a:arg)
    elseif !empty(a:arg)
        exe '!vim -d '.a:arg.' '.expand('%')
    endif
endfunction

" 
"
"
function! s:FormatLog()
    let s:config['log'] = map(systemlist('git log --oneline '.s:config['filelog']), "v:val[:6]")
    let l:log = systemlist("git log --oneline --graph --branches --pretty=format:'^%h^  %an^ ﲊ %ar^%d  %s' " . s:config['filelog'])
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

"
"
"
function! s:FormatBranch()
    let l:content = ['Local:', ''] + map(systemlist('git branch -vv'), "'    '.v:val")
    let l:remote = map(systemlist('git remote -v'), "'    '.v:val")
    let l:tag = map(systemlist('git tag|sort -nr'), "'    '.v:val")
    let l:stash = map(systemlist('git stash list'), "'    '.v:val")

    if !empty(l:remote)
        let l:content += ['', 'Remote:', ''] + l:remote
    endif

    if !empty(l:stash)
        let l:content += ['', 'Stash:', ''] + l:stash
    endif

    if !empty(l:tag)
        let l:content += ['', 'Tag:', ''] + l:tag
    endif

    return l:content
endfunction

"
"
"
function! s:FormatCommit()
    if s:config['reftype'] ==# 'tag'
        let l:extra = ''
    else
        let l:extra = '--pretty="commit %H ... %p%n'.
                    \ 'Author:  %an  <%ae>%n'.
                    \ 'Date:    %ad%n'.
                    \ '%D%n%n'.
                    \ '         %s" '
    endif

    return systemlist('git show --raw '.l:extra.s:config['commit'].' | sed "s/^:.*\.\.\.\s*/>    /"')
endfunction

"
"
"
function! s:FormatStatus()
    let l:status = systemlist('git status -bs')
    if len(l:status) < 2
        return l:status
    endif

    let l:staged = ['', 'Staged:', '']
    let l:workspace = ['', 'WorkSpace:', '']
    let l:untracked = ['', 'Untracked:', '']

    for l:item in l:status[1:]
        if l:item[0] =~# '[MADRCU]'
            let l:staged += ['    '.l:item[0].'  '.l:item[3:]]
        endif

        if l:item[1] =~# '[MADRCU]'
            let l:workspace += ['    '.l:item[1].'  '.l:item[3:]]
        endif

        if l:item[0:1] ==# '??'
            let l:untracked += ['    '.l:item[3:]]
        endif
    endfor

    return [l:status[0]] +
                \ (len(l:staged)    > 3 ? l:staged    : []) +
                \ (len(l:workspace) > 3 ? l:workspace : []) +
                \ (len(l:untracked) > 3 ? l:untracked : [])
endfunction

"
"
"
function! s:TabPage()
    let l:col = float2nr(0.4 * &columns)
    let l:lin = float2nr(0.4 * &lines)

    silent $tabnew .Git_log
    setlocal noreadonly modifiable
    call setline(1, s:FormatLog())
    setlocal readonly nomodifiable
    setlocal nonu nospell nowrap foldcolumn=0 " local to window
    let &l:statusline = '%2( %) Log'.(empty(s:config['filelog']) ?
                \ '' : ' -- '.s:config['filelog']).'%=%2( %)'

    exe 'silent belowright '.l:col.'vnew .Git_status'
    setlocal noreadonly modifiable
    call setline(1, s:FormatStatus())
    setlocal readonly nomodifiable
    setlocal winfixwidth nospell nonu foldcolumn=0
    setlocal statusline=%2(\ %)ﰧ\ Status%=%2(\ %)
    call search('^\s')

    exe 'silent belowright '.l:lin.'new .Git_branch'
    setlocal noreadonly modifiable
    call setline(1, s:FormatBranch())
    setlocal readonly nomodifiable
    setlocal winfixheight nospell nonu nowrap foldcolumn=0
    setlocal statusline=%2(\ %)\ Branch%=%2(\ %)
    call search('^\s')

    1wincmd w
    exe 'silent belowright '.l:lin.'new .Git_commit'
    setlocal noreadonly modifiable
    call setline(1, s:FormatCommit())
    setlocal readonly nomodifiable
    setlocal winfixheight nospell nonu foldcolumn=0
    setlocal statusline=%2(\ %)\ Commit%=%2(\ %)
    call search(empty(s:config['filelog']) ? '^>' :
                \ substitute(s:config['filelog'], '/', '\\/', 'g'))

    3wincmd w
    let t:tab_lable = ' Git-Manager'
    let t:git_tabpageManager = 1
endfunction


"function git#BlameFile(file)
"    let l:list = system('git blame '.a:file)
"    silent! $tabnew .Git_blame
"    call setline(1, l:list)
"    setlocal readonly nomodifiable
"    setlocal nonu nospell nowrap foldcolumn=0 signcolumn=no
"    silent! exec 'vsplit '.a:file
"endfunction


function! git#Toggle()
    if exists('t:git_tabpageManager')
        tabclose
    else
        try
            exe win_id2tabwin(win_findbuf(bufnr('.Git_log'))[0])[0].'tabnext'
            let t:git_tabpageManager = 1
            call git#Refresh('all')
        catch
            let s:config = copy(s:default)
            call s:TabPage()
        endtry
    endif
endfunction


function git#Refresh(target, ...)
    let l:dict = a:0 == 0 ? {} : a:1
    if !exists('t:git_tabpageManager') || type(l:dict) != type({})
        return
    endif

    let l:winnr = winnr()
    call extend(s:config, l:dict)

    if a:target ==# 'all' || a:target ==# 'log'
        1wincmd w
        let l:pos = getpos('.')
        setlocal noreadonly modifiable
        silent edit!
        call setline(1, s:FormatLog())
        setlocal readonly nomodifiable
        call setpos('.', l:pos)
        let &l:statusline = '%2( %) Log'.(empty(s:config['filelog']) ?
                    \ '' : ' -- '.s:config['filelog']).'%=%2( %)'
    endif

    if a:target ==# 'all' || a:target ==# 'commit'
        2wincmd w
        setlocal noreadonly modifiable
        silent edit!
        call setline(1, s:FormatCommit())
        setlocal nobuflisted readonly nomodifiable
        set filetype=gitcommit
        call search(empty(s:config['filelog']) ? '^>' :
                    \ substitute(s:config['filelog'], '/', '\\/', 'g'))
    endif

    if a:target ==# 'all' || a:target ==# 'status'
        3wincmd w
        let l:pos = getpos('.')
        setlocal noreadonly modifiable
        silent edit!
        call setline(1, s:FormatStatus())
        setlocal readonly nomodifiable
        call setpos('.', l:pos)
    endif

    if a:target ==# 'all' || a:target ==# 'branch'
        4wincmd w
        let l:pos = getpos('.')
        setlocal noreadonly modifiable
        silent edit!
        call setline(1, s:FormatBranch())
        setlocal readonly nomodifiable
        call setpos('.', l:pos)
    endif

    exec l:winnr . 'wincmd w'
    let t:tab_lable = ' Git-Manager'
endfunction


function! git#MsgHandle(msg, target)
    if a:msg =~ 'error:\|fatal'
        echo a:msg
        return 1
    endif

    call git#Refresh(a:target)
    return 0
endfunction

function git#GetConfig(list)
    let l:dict = {}

    for l:key in a:list
        let l:dict[l:key] = get(s:config, l:key, -1)
    endfor

    return l:dict
endfunction


let s:menuUI1 = "** Git Menu:\n".
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

let s:menu1 = {
            \ 'i': {'cmd': 'git init'},
            \ 'a': {'cmd': 'git add .'},
            \ 'r': {'cmd': 'git reset -q HEAD'},
            \ 'g': {'cmd': 'git gc', 'tip': 'Compressing...'},
            \ 'p': {'cmd': 'git push', 'tip': 'Pushing...'},
            \ 'P': {'cmd': 'git pull', 'tip': 'Pulling...'},
            \ 'f': {'cmd': 'git fetch', 'tip': 'Fetching...'}
            \ }

let s:menuUI2 = "** Git Menu:\n".
            \ "==================================================\n".
            \ "    (a)dd remote           <git remote add>\n".
            \ "    (t)ag                  <git tag>\n".
            \ "    (c)heckout new branch  <git checkout -q -b>\n".
            \ "    (m)erge branch         <git merge>\n".
            \ "    (r)ebase branch        <git rebash>\n".
            \ "    (d)iff tool            <git difftool -y>\n".
            \ "    (M)erge tool           <git mergetool -y>\n"

let s:sep = repeat('=', 50)
let s:menu2 = {'a': {
            \ 'cmd': 'git remote add ',
            \ 'tip': "** Add remote repository\n".s:sep,
            \ 'input': ['[option] Name & URL: ', 'origin ']
            \ }, 't': {
            \ 'cmd': 'git tag ',
            \ 'tip': "** Attach a tag\n".s:sep,
            \ 'input': ['[option] [-a] [-m Note] Tag [commit]: ']
            \ }, 'c': {
            \ 'cmd': 'git stash -q && git checkout -q -b ',
            \ 'tip': "** Create and switch a new branch\n".s:sep,
            \ 'input': ['NewBranch [startpoint]: '],
            \ }, 'm': {
            \ 'cmd': 'git merge ',
            \ 'tip': "** merge the specified branch to current\n".s:sep,
            \ 'input': ['[option] Branch: ', '', 'custom,git#CompleteBranch']
            \ }, 'r': {
            \ 'cmd': 'git rebase ',
            \ 'tip': "** rebase the specified branch to current\n".s:sep,
            \ 'input': ['[option] branch: ', '', 'custom,git#completebranch']
            \ }}


function! git#Menu(menu)
    let l:menu = a:menu ? s:menu1 : s:menu2
    echo a:menu ? s:menuUI1 : s:menuUI2
    let l:char = nr2char(getchar())
    redraw!

    if has_key(l:menu, l:char)
        let l:item = l:menu[l:char]
        echo get(l:item, 'tip', '')

        let l:str = ''
        if has_key(l:item, 'input')
            let l:str = call('input', l:item['input'])

            if l:str !~# '\S'
                return
            endif
        endif

        let l:msg = system(l:item['cmd'].l:str)[:-2]
    elseif a:menu
        " Special cases for menu1
        if l:char ==# 'c'
            let l:str = input('Input a message(-m): ')
            if l:str =~# '\S'
                let l:msg = system("git commit -m '".l:str."'")[:-2]
            endif
        elseif l:char ==# 'm'
            let l:str = input('Input a message(--amend -m): ', system('git log --pretty=format:%s -1'))
            if l:str =~# '\S'
                let l:msg = system("git commit --amend -m '".l:str."'")[:-2]
            endif
        endif
    else
        " Special cases for menu2
        if l:char ==# 'd'
            :!git difftool -y
        elseif l:char ==# 'M'
            :!git mergetool -y
        endif
    endif

    if exists('l:msg') && !git#MsgHandle(l:msg, 'all')
        echo l:msg
    endif
endfunction


function! git#CompleteBranch(L, C, P)
    if a:L =~ '^-'
        return system("git help merge|sed -n 's/ \\+\\(-[-a-zA-Z]*\\).*/\\1/p'")
    endif

    return system("git branch|grep '^[^*]'|sed -n 's/^ \\+//p'")
endfunction


