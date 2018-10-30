""""""""""""""""""""""""""""""""""""""""""""""""""""
" Author: CY <844757727@qq.com>
" Description: git plugin : tabpage manager(branch)
""""""""""""""""""""""""""""""""""""""""""""""""""""
if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1
let b:curL = -1

setlocal nonu
setlocal nowrap
setlocal buftype=nofile
setlocal tabstop=1
setlocal statusline=\ [4-Branch]%=\ \ \ \ \ %-5l\ %4P\ 

nnoremap <buffer> <space> :echo getline('.')<CR>
nnoremap <buffer> <silent> a :call <SID>ApplyStash()<CR>
nnoremap <buffer> <silent> c :call <SID>CheckOutBranch()<CR>
nnoremap <buffer> <silent> \d :call <SID>DeleteItem()<CR>
nnoremap <buffer> <silent> \D :call <SID>DeleteItem(1)<CR>
nnoremap <buffer> <silent> \m :call <SID>Merge_Rebase_Branch()<CR>
nnoremap <buffer> <silent> \r :call <SID>Merge_Rebase_Branch(1)<CR>
nnoremap <buffer> <silent> \R :call <SID>Merge_Rebase_Branch(2)<CR>
nnoremap <buffer> <silent> m :call git#MainMenu()<CR>
nnoremap <buffer> <silent> ? :call <SID>HelpDoc()<CR>
nnoremap <buffer> <silent> 1 :1wincmd w<CR>
nnoremap <buffer> <silent> 2 :2wincmd w<CR>
nnoremap <buffer> <silent> 3 :3wincmd w<CR>
nnoremap <buffer> <silent> 4 :4wincmd w<CR>

augroup Git_branch
	autocmd!
	autocmd CursorMoved <buffer> call s:cursorJump()
augroup END

if exists('*<SID>CheckOutBranch')
    finish
endif

function s:Refresh(arg)
    if a:arg == 0
        let l:pos = getpos('.')
        silent edit!
        call setline(1, git#FormatBranch())
        call setpos('.', l:pos)
    else
        call git#Refresh()
    endif
endfunction

function s:RefreshStatus()
    wincmd W
    let l:pos = getpos('.')
    silent edit!
    call setline(1, git#FormatStatus())
    call setpos('.', l:pos)
    wincmd w
endfunction

function <SID>ApplyStash()
    let l:curL = line('.')
    let l:linT = search('^Tag:', 'n')
    let l:linS = search('^Stash:', 'n')
    let l:str = matchstr(getline('.'), '^\(\s\+\)\zs\S.*$')
    if l:linS != 0 && l:curL > l:linS && (l:linT == 0 || l:curL < l:linT) && l:str != ''
        let l:msg = system('git stash apply ' . split(l:str, ':')[0])
        if l:msg =~ 'error:\|fatal:'
            echo l:msg
        else
            call s:RefreshStatus()
        endif
    endif
endfunction
        
function <SID>CheckOutBranch()
    let l:str = split(matchstr(getline('.'), '^\s\+.*$'))
    let l:lin = search('^[^Ll]\w\+:', 'n')
    if len(l:str) > 0 && l:str[0] != '*' && (l:lin == 0 || l:lin > line('.'))
        call system('git stash')
        let l:msg = system("git checkout " . l:str[0])
        if l:msg =~ 'error:\|fatal:'
            echo l:msg
        else
            for l:item in systemlist('git stash list')
                if l:item =~ ' ' . l:str[0] . ':'
                    let l:id = matchstr(l:item, '^[^:]\+')
                    call system('git stash apply ' . l:id . ' && git stash drop ' . l:id)
                    break
                endif
            endfor
            call s:Refresh(1)
        endif
    endif
endfunction

function s:Region(lin)
    let l:linT = search('^Tag:', 'n')
    let l:linS = search('^Stash:', 'n')
    let l:linR = search('^Remote:', 'n')
    if (l:linT != 0) && (a:lin > l:linT)
        let l:area = 'tag'
    elseif (l:linS != 0) && (a:lin > l:linS)
        let l:area = 'stash'
    elseif (l:linR != 0) && (a:lin > l:linR)
        let l:area = 'remote'
    else
        let l:area = 'local'
    endif
    return l:area
endfunction

function <SID>DeleteItem(...)
    let l:curL = line('.')
    let l:str = split(matchstr(getline('.'), '^\s\+.*$'))
    let l:linT = search('^Tag:', 'n')
    let l:linS = search('^Stash:', 'n')
    let l:linR = search('^Remote:', 'n')
    if (len(l:str) == 0) || (input('Confirm the deletion(yes/no): ') != 'yes')
        return
    elseif l:linT != 0 && l:curL > l:linT
        let l:msg = system('git tag -d ' . l:str[0])
        let l:rA = 1
    elseif l:linS != 0 && l:curL > l:linS
        let l:msg = system('git stash drop ' . strpart(l:str[0], 0, len(l:str[0])-1))
    elseif l:linR != 0 && l:curL > l:linR
        let l:msg = system('git remote remove ' . l:str[0])
    elseif l:str[0] != '*'
        let l:flag = a:0 == 0 ? '-d ' : '-D '
        let l:msg = system('git branch ' . l:flag . l:str[0])
        let l:rA = 1
    else
        let l:msg = 'none'
    endif
    if l:msg =~ 'error:\|fatal:'
        echo l:msg
    elseif l:msg != 'none'
        call s:Refresh(exists('l:rA'))
    endif
endfunction

function <SID>Merge_Rebase_Branch(...)
    let l:str = matchstr(getline('.'), '^\s\+\w\+')
    let l:lin = search('^[^Ll]\w\+:', 'n')
    if l:str != '' && (l:lin == 0 || l:lin > line('.'))
        let l:op = a:0 == 0 ? 'merge ' . l:str : 
                    \ a:1 == 1 ? 'rebase ' . l:str : 'rebase --continue '
        let l:msg = system('git ' . l:op)
        if l:msg =~ 'error:\|fatal:'
            echo l:msg
        else
            echo l:msg
            call git#Refresh()
        endif
    endif
endfunction

function s:cursorJump()
    if b:curL != line('.')
        let l:end = line('$')
        let l:op = b:curL - line('.') == 1 ? 'k' : 'j'
        while line('.') != l:end && getline('.') !~ '^\s\+\S'
            exec 'normal ' . l:op
            if line('.') == 1
                let l:op = 'j'
            endif
        endwhile
        let b:curL = line('.')
        let l:lin = search('^Tag:', 'n')
        if l:lin != 0 && b:curL > l:lin
            let l:msg = systemlist('git show ' . getline('.') . "|sed '/^diff --\\w/s/$/ {[(<{1/'")
            2wincmd w
            silent edit!
            call setline(1, l:msg)
            set filetype=gitcommit
            set nobuflisted
            4wincmd w
        endif
    endif
endfunction

function <SID>HelpDoc()
    echo
                \ "Git branch quick help !?\n" .
                \ "==================================================\n" .
                \ "    <space>: echo\n" .
                \ "    m:       git menu\n" .
                \ "    a:       apply stash                (git stash apply)\n" .
                \ "    c:       checkout branch            (git checkout)\n" .
                \ "    \\d:      delete current item\n" .
                \ "    \\D:      delete (force)\n" .
                \ "    \\m:      merge to current branch    (git merge)\n" .
                \ "    \\r:      rebase to current branch   (git rebase)\n" .
                \ "    \\R:      rebase continue            (git rebase --continue)\n" .
                \ "    1234:    jump to 1234 window"
endfunction

