""""""""""""""""""""""""""""""""""""""""""""""""""""
" Name: git plugin : tabpage manager(branch)
" Author: CY <844757727@qq.com>
""""""""""""""""""""""""""""""""""""""""""""""""""""
if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1
let b:curL = 1

setlocal nonu
setlocal nowrap
setlocal buftype=nofile
setlocal tabstop=1
setlocal statusline=\ [4-Branch]%=\ \ \ \ \ %-5l\ %4P\ 

nnoremap <buffer> <f5>  :call GIT_Refresh()<Cr>
nnoremap <buffer> <space> :echo getline('.')<Cr>
nnoremap <buffer> <silent> c :call <SID>CheckOutBranch()<Cr>
nnoremap <buffer> <silent> a :call <SID>AddRemote()<Cr>
nnoremap <buffer> <silent> b :call <SID>NewBranch()<Cr>
nnoremap <buffer> <silent> n :call <SID>NewBranch(1)<Cr>
nnoremap <buffer> <silent> \d :call <SID>DeleteItem()<Cr>
nnoremap <buffer> <silent> \D :call <SID>DeleteItem(1)<Cr>
nnoremap <buffer> <silent> m :call GIT_Menu()<Cr>
nnoremap <buffer> <silent> ? :call <SID>HelpDoc()<Cr>
nnoremap <buffer> <silent> 1 :1wincmd w<Cr>
nnoremap <buffer> <silent> 2 :2wincmd w<Cr>
nnoremap <buffer> <silent> 3 :3wincmd w<Cr>
nnoremap <buffer> <silent> 4 :4wincmd w<Cr>

augroup Git_branch
	autocmd!
	autocmd CursorMoved <buffer> call s:cursorJump()
augroup END

if exists('*<SID>CheckOutBranch')
    finish
endif

function <SID>Refresh(arg)
    if a:arg == 0
        let l:pos = getpos('.')
        silent edit!
        call setline(1, GIT_FormatBranch())
        call setpos('.', l:pos)
    else
        call GIT_Refresh()
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
            call <SID>Refresh(1)
        endif
    endif
endfunction

function <SID>AddRemote()
	let l:name = input('Enter a name(Default origin)： ', 'origin')
	let l:addr = input('Enter remote URL: ')
	if empty(l:addr)
		echo "    Abort!"
    else
        let l:msg = system('git remote add ' . l:name . ' ' . l:addr)
        if l:msg =~ 'error:\|fatal:'
            echo l:msg
        else
            call <SID>Refresh(0)
        endif
    endif
endfunction

function <SID>NewBranch(...)
    let l:name = input('Enter new branch name: ')
    if l:name == ''
        echo '    Abort!'
        return
    endif
    if a:0 > 0
        call system('git stash')
        let l:msg = system('git checkout -b ' . l:name)
    else
        let l:msg = system('git branch ' . l:name)
    endif
    if l:msg =~ 'error:\|fatal:'
        echo "\n" . l:msg
    else
        call <SID>Refresh(a:0 > 0 ? 1 : 0 )
    endif
endfunction

function <SID>DeleteItem(...)
    let l:msg = 'none'
    let l:curL = line('.')
    let l:str = split(matchstr(getline('.'), '^\s\+.*$'))
    if len(l:str) == 0
        return
    elseif len(l:str) == 1
        let l:msg = system('git tag -d ' . l:str[0])
    else
        let l:linS = search('^Stash:', 'n')
        let l:linR = search('^Remote:', 'n')
        if l:linS != 0 && l:curL > l:linS
            let l:msg = system('git stash drop ' . strpart(l:str[0], 0, len(l:str[0])-1))
        elseif l:linR != 0 && l:curL > l:linR
            let l:msg = system('git remote remove ' . l:str[0])
        elseif l:str[0] != '*'
            if a:0 == 0
                let l:msg = system('git branch -d ' . l:str[0])
            else
                let l:msg = system('git branch -D ' . l:str[0]) 
            endif
        endif
    endif
    if l:msg =~ 'error:\|fatal:'
        echo l:msg
    elseif l:msg != 'none'
        call <SID>Refresh(0)
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
    endif
endfunction


function <SID>HelpDoc()
    let l:help = [
                \ 'Git branch quick help !?',
                \ '==================================================',
                \ '    <space>: echo',
                \ '    <f5>:    refresh tabpage',
                \ '    m:       git menu',
                \ '    c:       checkout branch',
                \ '    a:       add remote branch',
                \ '    b:       new branch',
                \ '    n:       new branch & checkout branch',
                \ '    \d:      delete current item',
                \ '    1234:    jump to 1234 wimdow'
                \ ]
    echo join(l:help, "\n")
endfunction

