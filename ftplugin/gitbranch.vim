"
"
if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1

setlocal nonu
setlocal tabstop=1
setlocal nowrap
setlocal statusline=[branch\ status]%=\ \ \ \ \ %-10.(%l:%c%V%)\ %4P\ 

nnoremap <buffer> <C-w> :call GIT_CloseTab()<Cr>
nnoremap <buffer> <S-t> :call GIT_CloseTab()<Cr>
nnoremap <buffer> <f5>  :call GIT_Refresh()<Cr>
nnoremap <buffer> <space> :echo getline('.')<Cr>
nnoremap <buffer> <silent> c :call <SID>CheckOutBranch()<Cr>
nnoremap <buffer> <silent> a :call <SID>AddRemote()<Cr>
nnoremap <buffer> b :call <SID>NewBranch()<Cr>
nnoremap <buffer> n :call <SID>NewBranch(1)<Cr>
nnoremap <buffer> ? :call <SID>HelpDOc()<Cr>

augroup Git_branch
	autocmd!
	autocmd BufWritePost <buffer> call delete('.Git_branch')
augroup END

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
    let l:str = split(getline('.'))
    let l:lin = search('^Remote:', 'n')
    if len(l:str) > 2 && l:str[0] != '*' && line('.') < l:lin
        let l:msg = system("git checkout " . l:str[0])
        if l:msg =~ '^error:'
            echo l:msg
        else
            call <SID>Refresh(line('.'), 1)
        endif
    endif
endfunction

function <SID>AddRemote()
	let l:name = input('Enter a name(Default origin)： ')
	if empty(l:name)
		let l:name = 'origin'
	endif
	let l:addr = input('Enter remote URL: ')
	if empty(l:addr)
		echo "    Abort"
    else
        let l:msg = system("git remote add " . l:name . ' ' . l:addr)
        if l:msg =~ '^error:'
            echo l:msg
        else
            call <SID>Refresh(line('.'), 0)
        endif
    endif
endfunction

function <SID>NewBranch(...)
    let l:name = input('Enter new branch name: ')
    if a:0 > 0
        let l:msg = system('git checkout -b ' . l:name)
    else
        let l:msg = system('git branch ' . l:name)
    endif
    if l:msg =~ '^error:'
        echo "\n" . l:msg
    elseif a:0 > 0
        call <SID>Refresh(line('.'), 1)
    else
        call <SID>Refresh(line('.'), 0 )
    endif
endfunction

function <SID>HelpDOc()
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
                \ '    n:       new branch & checkout branch'
                \ ]
    echo join(l:help, "\n")
endfunction

