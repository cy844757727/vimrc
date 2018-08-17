"
"
"
"
"
command! -nargs=+ -complete=custom,GIT_CompleteCommand Git :echo system('git ' . "<args>")[:-2]
command! -nargs=+ -complete=file Gadd :echo system('git add ' . '<args>')[:-2]|call GIT_Refresh()
command! -nargs=* Gstatus :echo system('git status ' . '<args>')[:-2]
command! -nargs=* Glog :echo system("git log --oneline --graph --pretty=format:\"%h - 👦%an 📆%ar  💬%s\" " . '<args>')
command! -nargs=* Greflog :echo system('git reflog ' . '<args>')[:-2]
command! -nargs=+ Gcommit :echo system('git commit ' . "<args>")[:-2]|call GIT_Refresh()
command! -nargs=+ -complete=file Greset :echo system('git reset ' . '<args>')[:-2]|call GIT_Refresh()
command! -nargs=* -complete=custom,GIT_CompleteBranch Gbranch :echo system('git branch ' . '<args>')[:-2]
command! -nargs=+ -complete=file Gcheckout :echo system('git checkout ' . '<args>')[:-2]|call GIT_Refresh()
command! -nargs=* -complete=file Gtag :echo system('git tag ' . '<args>')[:-2]|call GIT_Refresh()
command! -nargs=* -complete=custom,GIT_CompleteBranch Gmerge :echo system('git merge ' . '<args>')[:-2]
command! -nargs=* Gmergetool :!git mergetool <args>
command! -nargs=* Gpush :echo system('git push ' . '<args>')[:-2]
command! -nargs=* Gpull :echo system('git pull ' . '<args>')[:-2]|call GIT_Refresh()
command! -nargs=* Gfetch :echo system('git fetch ' . '<args>')[:-2]|call GIT_Refresh()
command! -nargs=* Gremote :echo system('git remote ' . '<args>')[:-2]|call GIT_Refresh()
command! -nargs=* -complete=file Gdiff :echo system('git diff ' . '<args>')[:-2]
command! -nargs=+ -complete=file Grm :echo system('git rm ' . '<args>')[:-2]|call GIT_Refresh()
command! -nargs=+ -complete=file Gmv :echo system('git mv ' . '<args>')[:-2]|call GIT_Refresh()
command! -nargs=* -complete=file Gdifftool :!git difftool <args>
command! GTab :call GIT_TabPage()
command! GClose :call GIT_CloseTab()

" For merge complete
function! GIT_CompleteBranch(A, L, P)
    return system("git branch|grep '^[^*]'|sed -n 's/^ \\+//p'")
endfunction

function! GIT_CompleteCommand(A, L, P)
    return system("git help|sed -n 's/^  \\+\\(\\w\\+\\) \\+.*/\\1/p'")
endfunction

function! GIT_FormatLog()
    let l:log = systemlist("git log --oneline --graph --pretty=format:\"^%h^👦%an^📆%ar^💬%s\"")
    let l:lenGraph = 0
    let l:lenAuthor = 0
    let l:lenTime = 0
    for l:str in l:log
        let l:list = split(l:str, '\^')
        if len(l:list) == 1
            continue
        endif
        let l:lenGraph = max([strwidth(l:list[0]), l:lenGraph])
        let l:lenAuthor = max([strwidth(l:list[2]), l:lenAuthor])
        let l:lenTime = max([strwidth(l:list[3]), l:lenTime])
    endfor
    for l:i in range(len(l:log))
        let l:list = split(l:log[l:i], '\^')
        if len(l:list) == 1
            continue
        endif
        let l:list[0] .= repeat(' ', l:lenGraph - strwidth(l:list[0]))
        let l:list[2] .= repeat(' ', l:lenAuthor - strwidth(l:list[2]))
        let l:list[3] .= repeat(' ', l:lenTime - strwidth(l:list[3]))
        let l:log[l:i] = join(l:list, ' ')
    endfor
    return l:log
endfunction

function! GIT_FormatBranch()
    let l:local = systemlist('git branch -v')
    let l:remote = systemlist('git remote -v')
    let l:tag = systemlist('git tag -v')
    call map(l:local, "'    ' . v:val")
    call map(l:remote, "'    ' . v:val")
    call map(l:tag, "'    ' . v:val")
    return ['Local:', ''] + l:local + ['', 'Remote:', ''] + l:remote + ['', 'Tag:', ''] + l:tag
endfunction

let s:format = join([
            \ 'commit %H ... %p',
            \ 'Author:  %an  <%ae>',
            \ 'Date:    %ad',
            \ 'Commit:  %cn  <%ce>',
            \ 'Date:    %cd%n',
            \ '         %s'],
            \ '%n')

function! GIT_FormatCommit(hash)
    let l:commit = systemlist("git show --pretty='" . s:format . "' " . a:hash . "|sed '12,$s/^\\(diff --git .*\\)/enddiff --git\\n\\1/'")
"    let l:commit = systemlist("git show --pretty='" . s:format . "' " . a:hash)
"    let l:i =len(l:commit) - 1
"    while l:i >= 12
"        if l:commit[l:i] =~ '^diff --git '
"            call insert(l:commit, 'enddiff --git', l:i)
"            let l:i -= 4
"        endif
"        let l:i -= 1
"    endwhile
    return l:commit
endfunction

function! GIT_FormatStatus()
    let l:status = systemlist('git status')
    let l:i = len(l:status) - 1
    while l:i >= 0
        if l:status[l:i] =~ '^\s*（'
            call remove(l:status, l:i)
        elseif l:status[l:i] =~ '^\s\+'
            let l:list = split(l:status[l:i])
            let l:status[l:i] = '    ' . l:list[0] . repeat(' ', 10 - strwidth(l:list[0])) . join(l:list[1:])
        endif
        let l:i -= 1
    endwhile
    return l:status
endfunction

function! GIT_TabPage()
    if !bufexists('.Git_log')
        let l:col = float2nr(0.4 * &columns)
        let l:lin = float2nr(0.4 * &lines)
        tabnew
        call setline(1, GIT_FormatLog())
        set filetype=gitlog
        silent file .Git_log
        exec l:col . 'vnew'
        call setline(1, GIT_FormatStatus())
        set filetype=gitstatus
        silent file .Git_status
        wincmd W
        exec 'belowright ' . l:lin . 'new'
        call setline(1, GIT_FormatCommit(''))
        set filetype=gitcommit
        silent file .Git_commit
        wincmd w
        exec 'belowright ' . l:lin . 'new'
        call setline(1, GIT_FormatBranch())
        set filetype=.gitbranch
        silent file .Git_branch
    else
        call win_gotoid(win_findbuf(bufnr('.Git_status'))[0])
        call GIT_Refresh()
    endif
endfunction

function! GIT_Refresh()
    if bufwinnr('.Git_log') != -1
        4wincmd w
        call delete('.Git_branch')
        silent edit!
        call setline(1, GIT_FormatBranch())
        wincmd W
        call delete('.Git_status')
        silent edit!
        call setline(1, GIT_FormatStatus())
        1wincmd w
        call delete('.Git_log')
        silent edit!
        call setline(1, GIT_FormatLog())
    endif
endfunction

function! GIT_CloseTab()
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
    if filereadable('.Git_commit')
        call delete('.Git_commit')
    endif
    if filereadable('.Git_log')
        call delete('.Git_log')
    endif
    if filereadable('.Git_status')
        call delete('.Git_sattus')
    endif
    if filereadable('.Git_branch')
        call delete('.Git_branch')
    endif
endfunction

