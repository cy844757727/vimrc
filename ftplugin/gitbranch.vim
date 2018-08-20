"
"
if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1

setlocal nonu
setlocal tabstop=1
setlocal nowrap
setlocal statusline=[Branch\ status]%=\ \ \ \ \ %-10.(%l:%c%V%)\ %4P\ 

nnoremap <buffer> <C-w> :call GIT_CloseTab()<Cr>
nnoremap <buffer> <S-t> :call GIT_CloseTab()<Cr>
nnoremap <buffer> <f5>  :call GIT_Refresh()<Cr>
nnoremap <buffer> <space> :echo getline('.')<Cr>
nnoremap <buffer> <silent> c :call <SID>CheckOutBranch()<Cr>
nnoremap <buffer> <silent> a :call <SID>AddRemote()<Cr>
nnoremap <buffer> b :call <SID>NewBranch()<Cr>
nnoremap <buffer> n :call <SID>NewBranch(1)<Cr>
nnoremap <buffer> <silent> \d :call <SID>DeleteItem()<Cr>
nnoremap <buffer> ? :call <SID>HelpDoc()<Cr>

"augroup Git_branch
"	autocmd!
"augroup END

if exists('*<SID>CheckOutBranch')
    finish
endif

function <SID>Refresh(lin, arg)
    if a:arg == 0
        silent edit!
        call setline(1, GIT_FormatBranch())
    else
        call GIT_Refresh()
        4wincmd w
    endif
    call cursor(a:lin, 1)
endfunction

function <SID>CheckOutBranch()
    call system('git stash')
    let l:str = split(matchstr(getline('.'), '^\s\+.*$'))
    if len(l:str) !=0 && l:str[0] != '*' && line('.') < search('^[^L]\w*:', 'n')
        let l:msg = system("git checkout " . l:str[0])
        if l:msg =~ '^error:\|^fatal:'
            echo l:msg
        else
            for l:item in systemlist('git stash list')
                if l:item =~ ' ' . l:str[0] . ':'
                    let l:id = matchstr(l:item, '^[^:]\+')
                    call system('git stash apply ' . l:id . ' && git stash drop ' . l:id)
                    break
                endif
            endfor
            call <SID>Refresh(line('.'), 1)
        endif
    endif
endfunction

function <SID>AddRemote()
	let l:name = input('Enter a name(Default origin)： ', 'origin')
	let l:addr = input('Enter remote URL: ')
	if empty(l:addr)
		echo "    Abort"
    else
        let l:msg = system('git remote add ' . l:name . ' ' . l:addr)
        if l:msg =~ '^error:\|^fatal:'
            echo l:msg
        else
            call <SID>Refresh(line('.'), 0)
        endif
    endif
endfunction

function <SID>NewBranch(...)
    let l:op = a:0 > 0 ? ' checkout -b ' : ' branch '
    let l:name = input('Enter new branch name: ')
    if l:name == ''
        echo '    Abort!'
        return
    endif
    let l:msg = system('git' . l:op . l:name)
    if l:msg =~ '^error:\|^fatal:'
        echo "\n" . l:msg
    else
        call <SID>Refresh(line('.'), a:0 > 0 ? 1 : 0 )
    endif
endfunction

function <SID>DeleteItem()
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
            let l:msg = system('git branch -d ' . l:str[0])
        endif
        if l:msg =~ '^error:\|^fatal:'
            echo l:msg
        elseif l:msg != 'none'
            call <SID>Refresh(l:curL, 0)
        endif
    endif
endfunction


function <SID>HelpDoc()
    let l:help = [
                \ '* Git branch quick help',
                \ '============================',
                \ '    <C-w>:   close tabpage',
                \ '    <S-t>:   close tabpage',
                \ '    <f5>:    refresh tabpage',
                \ '    <space>: echo',
                \ '    c:       checkout branch',
                \ '    a:       add remote branch',
                \ '    b:       new branch',
                \ '    n:       new branch & checkout branch',
                \ '    \d:      delete current item'
                \ ]
    echo join(l:help, "\n")
endfunction

