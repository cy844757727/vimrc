"
"
"
"
"
command! -nargs=+ -complete=custom,GIT_CompleteCommand Git :echo system('git ' . "<args>")
command! -nargs=* -complete=file Gadd :call GIT_Add_Rm_Mv("<args>", 0)
command! -nargs=+ -complete=file Grm :call GIT_Add_Rm_Mv("<args>", 1)
command! -nargs=+ -complete=file Gmv :call GIT_Add_Rm_Mv("<args>", 2)
command! -nargs=* Gstatus :echo system('git status ' . '<args>')
command! -nargs=* Glog :echo system("git log --oneline --graph --pretty=format:\"%h - 👦%an 📆%ar  💬%s\" " . '<args>')
command! -nargs=* Greflog :echo system('git reflog ' . '<args>')
command! -nargs=* -complete=file Gmergetool :!git mergetool <args>
command! -nargs=* -complete=file Gdifftool :!git difftool <args>
command! -nargs=* -complete=custom,GIT_CompleteBranch Gbranch :call GIT_Branch_Remote_Tag("<args>", 0)
command! -nargs=* Gremote :call GIT_Branch_Remote_Tag("<args>", 1)
command! -nargs=* Gtag :call GIT_Branch_Remote_Tag("<args>", 2)
command! -nargs=+ Gcommit :echo system('git commit ' . "<args>")|call GIT_Refresh()
command! -nargs=+ -complete=file Greset :echo system('git reset ' . '<args>')|call GIT_Refresh()
command! -nargs=+ -complete=file Gcheckout :echo system('git checkout ' . '<args>')[:-2]|call GIT_Refresh()
command! -nargs=* -complete=custom,GIT_CompleteBranch Gmerge :echo system('git merge ' . '<args>')[:-2]
command! -nargs=* Gpush :echo 'Waiting...' | echo system('git push ' . '<args>')[:-2]
command! -nargs=* Gpull :echo system('git pull ' . '<args>')[:-2]|call GIT_Refresh()
command! -nargs=* Gfetch :echo system('git fetch ' . '<args>')[:-2]|call GIT_Refresh()
command! -nargs=* -complete=file Gdiff :echo system('git diff ' . 'args>')
command! GTab :call GIT_TabPage()
command! GClose :call GIT_CloseTab()

augroup Git_manager
	autocmd!
	autocmd BufRead,BufNewFile .Git_log    set filetype=gitlog|set buftype=nofile
	autocmd BufRead,BufNewFile .Git_commit set filetype=gitcommit|set buftype=nofile
	autocmd BufRead,BufNewFile .Git_status set filetype=gitstatus|set buftype=nofile
	autocmd BufRead,BufNewFile .Git_branch set filetype=gitbranch|set buftype=nofile
augroup END

" For merge complete
function! GIT_CompleteBranch(A, L, P)
    return system("git branch|grep '^[^*]'|sed -n 's/^ \\+//p'")
endfunction

function! GIT_CompleteCommand(A, L, P)
    return system("git help|sed -n 's/^  \\+\\(\\w\\+\\) \\+.*/\\1/p'")
endfunction

function! GIT_Add_Rm_Mv(arg, flag)
    let l:op = a:flag == 0 ? ' add ' :
                \ a:flag == 1 ? ' rm ' : ' mv '
    let l:arg = a:arg == '' ? '.' : a:arg
    let l:msg = system('git' . l:op . l:arg)[:-2]
    if l:msg =~ '^error:\|^fatal:'
        echo l:msg
    elseif bufwinnr('.Git_status') != -1
        3wincmd w
        silent edit!
        call setline(1, GIT_FormatStatus())
        echo l:msg
    endif
endfunction

function! GIT_Branch_Remote_Tag(arg, flag)
    let l:op = a:flag == 0 ? ' branch ' :
                \ a:flag == 1 ? ' remote ' : ' tag '
    let l:msg = system('git' . l:op . a:arg)[:-2]
    if a:arg == '' || l:msg =~ '^error:\|^fatal:'
        echo l:msg
    elseif bufwinnr('.Git_branch') != -1
        4wincmd w
        silent edit!
        call setline(1, GIT_FormatBranch())
        echo l:msg
    endif
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
    let l:tag = systemlist('git tag')
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
    return l:local + l:remote + l:tag + l:stash
endfunction

function! GIT_FormatCommit(hash)
	let l:format = 'commit %H ... %p%n' .
            \ 'Author:  %an  <%ae>%n' .
            \ 'Date:    %ad%n' .
            \ 'Commit:  %cn  <%ce>%n' .
            \ 'Date:    %cd%n%n' .
            \ '         %s'
    let l:commit = systemlist("git show --pretty='" . l:format . "' " . a:hash . "|sed '12,$s/^\\(diff --git .*\\)/enddiff --git\\n\\1/'")
    if len(l:commit) > 12
        let l:commit += ['enddiff --git', '@@ ================= @@']
    endif
    return l:commit
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
    if !bufexists('.Git_log')
        let l:col = float2nr(0.4 * &columns)
        let l:lin = float2nr(0.4 * &lines)
        silent tabnew .Git_commit
        exec 'silent ' . l:col . 'vnew .Git_status'
        call setline(1, GIT_FormatStatus())
        exec 'silent belowright ' . l:lin . 'new .Git_branch'
        call setline(1, GIT_FormatBranch())
        1wincmd w
        silent new .Git_log
        exec '2resize ' . l:lin
        call setline(1, GIT_FormatLog())
    else
        call win_gotoid(win_findbuf(bufnr('.Git_status'))[0])
        call GIT_Refresh(1)
    endif
endfunction

function! GIT_Toggle()
    if bufwinnr('.Git_log') != -1
        call GIT_CloseTab()
    else
        call GIT_TabPage()
    endif
endfunction

function! GIT_Refresh(...)
    if bufwinnr('.Git_log') != -1
        let l:winnr = winnr()
        let l:pos = getpos('.')
    	if a:0 > 0
        	let l:col = float2nr(0.4 * &columns)
        	let l:lin = float2nr(0.4 * &lines)
        	exec '2resize ' . l:lin
        	exec 'vert 3resize ' . l:col
        	exec '4resize ' . l:lin
        endif
        4wincmd w
        silent edit!
        call setline(1, GIT_FormatBranch())
        wincmd W
        silent edit!
        call setline(1, GIT_FormatStatus())
        1wincmd w
        silent edit!
        call setline(1, GIT_FormatLog())
        exec l:winnr . 'wincmd w'
        call setpos('.', l:pos)
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
endfunction

