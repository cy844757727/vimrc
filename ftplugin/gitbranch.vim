""""""""""""""""""""""""""""""""""""""""""""""""""""
" Author: CY <844757727@qq.com>
" Description: git plugin : tabpage manager(branch)
""""""""""""""""""""""""""""""""""""""""""""""""""""
if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1
let b:curL = -1

setlocal buftype=nofile
setlocal tabstop=1
setlocal statusline=%2(\ %)\ Branch%=%2(\ %)

nnoremap <buffer> <space>      :echo getline('.')<CR>
nnoremap <buffer> <silent> a   :call <SID>ApplyStash()<CR>
nnoremap <buffer> <silent> c   :call <SID>CheckOutBranch()<CR>
nnoremap <buffer> <silent> \d  :call <SID>DeleteItem()<CR>
nnoremap <buffer> <silent> \D  :call <SID>DeleteItem(1)<CR>
nnoremap <buffer> <silent> \m  :call <SID>Merge_Rebase_Branch(1)<CR>
nnoremap <buffer> <silent> \M  :call <SID>Merge_Rebase_Branch(3)<CR>
nnoremap <buffer> <silent> \r  :call <SID>Merge_Rebase_Branch(2)<CR>
nnoremap <buffer> <silent> \R  :call <SID>Merge_Rebase_Branch(4)<CR>
nnoremap <buffer> <silent> \co :call <SID>CheckOutNewBranch()<CR>
nnoremap <buffer> <silent> m   :call git#Menu(1)<CR>
nnoremap <buffer> <silent> M   :call git#Menu(0)<CR>
nnoremap <buffer> <silent> ?   :call <SID>HelpDoc()<CR>
nnoremap <buffer> <silent> 1   :1wincmd w<CR>
nnoremap <buffer> <silent> 2   :2wincmd w<CR>
nnoremap <buffer> <silent> 3   :3wincmd w<CR>
nnoremap <buffer> <silent> 4   :4wincmd w<CR>

augroup Git_branch
	autocmd!
	autocmd CursorMoved <buffer> call s:cursorJump()
augroup END

if exists('*<SID>CheckOutBranch')
    finish
endif


function s:GetCurLinInfo()
    let l:line = getline('.')
    if l:line !~# '^\s\+\S'
        return ['', '']
    endif
    
    let l:lin = search('^\w\+:$', 'bn')
    if l:lin == 0
        return ['', '']
    endif

    return [getline(l:lin)[0]] + split(l:line)
endfunction


function <SID>ApplyStash()
    let l:lineInfo = s:GetCurLinInfo()

    if l:lineInfo[0] ==# 'S'
        call git#MsgHandle(system('git stash apply ' . l:lineInfo[1][:-2]), 'status')
    endif
endfunction


function <SID>CheckOutBranch()
    let l:lineInfo = s:GetCurLinInfo()

    if l:lineInfo[0] ==# 'L' && l:lineInfo[1] !=# '*'
        let l:msg = system('git stash && git checkout ' . l:lineInfo[1])
        if l:msg =~ 'error:\|fatal:'
            echo l:msg
        else
            let l:stash = systemlist("git stash list|grep ' WIP on " . l:lineInfo[1] . ": '")
            if !empty(l:stash)
                let l:id = matchstr(l:stash[0], '^[^:]\+')
                call system('git stash apply ' . l:id . ' && git stash drop ' . l:id)
            endif
            call git#Refresh('all')
        endif
    endif
endfunction


function <SID>CheckOutNewBranch()
    let l:lineInfo = s:GetCurLinInfo()

    if l:lineInfo[0] =~# '[LT]'
        if l:lineInfo[1] ==# '*'
            call remove(l:lineInfo, 1)
        endif

        let l:name = input('Enter new branch name(start from ' . l:lineInfo[1] . '): ')
        if l:name != ''
            call git#MsgHandle(system('git stash && git checkout -b ' . l:name . ' ' . l:lineInfo[1]), 'all')
        endif
    endif
endfunction


function <SID>DeleteItem(...)
    let l:lineInfo = s:GetCurLinInfo()

    if empty(l:lineInfo[0]) || (input('Confirm the deletion(yes/no): ') != 'yes')
        redraw!
        return
    endif
    redraw!


    if l:lineInfo[0] ==# 'T'
        let l:msg = system('git tag -d '.l:lineInfo[1])
    elseif l:lineInfo[0] ==# 'S'
        let l:msg = system('git stash drop '.l:lineInfo[1][:-2])
        let l:self = 1
    elseif l:lineInfo[0] ==# 'R'
        let l:msg = system('git remote remove '.l:lineInfo[1])
    elseif l:lineInfo[0] ==# 'L' && l:lineInfo[1] !=# '*' && l:lineInfo[1] != 'master'
        let l:msg = system('git branch '.(a:0 == 0 ? '-d ' : '-D ').l:lineInfo[1])
    else
        return
    endif

    call git#MsgHandle(l:msg, exists('l:self') ? 'branch' : 'all')
endfunction


function <SID>Merge_Rebase_Branch(flag)
    let l:lineInfo = s:GetCurLinInfo()

    if l:lineInfo[0] ==# 'L' && l:lineInfo[1] !=# '*'
        let l:op = (a:flag % 2 ? 'merge ' : 'rebase ').(a:flag > 2 ? '--continue' : l:lineInfo[1])
        call git#MsgHandle(system('git ' . l:op), 'all')
    endif
endfunction


function s:cursorJump()
    let l:lin = line('.')

    if b:curL == l:lin
        return
    endif

    let l:end = line('$')
    let l:op = b:curL > l:lin ? 'k' : 'j'
    while line('.') != l:end && getline('.') !~ '^\s\+\S'
        exec 'normal ' . l:op
        if line('.') == 1
            let l:op = 'j'
        endif
    endwhile

    let l:lineInfo = s:GetCurLinInfo()
    if l:lineInfo[0] ==# 'T'
        2wincmd w
        setlocal noreadonly modifiable
        silent edit!
        call setline(1, systemlist('git show --raw ' . l:lineInfo[-1] . '|sed "s/^:.*\.\.\.\s*/>    /"'))
        set filetype=gitcommit
        setlocal nobuflisted readonly nomodifiable
        4wincmd w
    endif

    let b:curL = line('.')
endfunction


function <SID>HelpDoc()
    echo
                \ "Git branch quick help !?\n" .
                \ "==================================================\n" .
                \ "    <space>: echo\n" .
                \ "    a:       apply stash                (git stash apply)\n" .
                \ "    c:       checkout branch            (git checkout)\n" .
                \ "    \\d:      delete current item\n" .
                \ "    \\D:      delete (force)\n" .
                \ "    \\m:      merge to current branch    (git merge)\n" .
                \ "    \\M:      merge to current branch    (git merge --continue)\n" .
                \ "    \\r:      rebase to current branch   (git rebase)\n" .
                \ "    \\R:      rebase continue            (git rebase --continue)\n" .
                \ "    1234:    jump to 1234 window"
endfunction

