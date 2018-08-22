"
"
"
"
if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1

setlocal nonu
setlocal statusline=\ \ 3-File\ status%=\ \ \ \ \ %-10.(%l:%c%V%)\ %4P\ 

nnoremap <buffer> <C-w> :call GIT_CloseTab()<Cr>
nnoremap <buffer> <S-t> :call GIT_CloseTab()<Cr>
nnoremap <buffer> <f5>  :call GIT_Refresh()<Cr>
nnoremap <buffer> <space> :echo getline('.')<Cr>
nnoremap <buffer> <silent> d :call <SID>FileDiff()<Cr>
nnoremap <buffer> <silent> r :call <SID>CancelStaged()<Cr>
nnoremap <buffer> <silent> R :call <SID>CancelStaged(1)<Cr>
nnoremap <buffer> <silent> a :call <SID>AddFile()<Cr>
nnoremap <buffer> <silent> A :call <SID>AddFile(1)<Cr>
nnoremap <buffer> <silent> \co :call <SID>CheckOutFile()<Cr>
nnoremap <buffer> <silent> m :call GIT_Menu()<Cr>
nnoremap <buffer> <silent> ? :call <SID>HelpDoc()<Cr>
nnoremap <buffer> <silent> 1 :1wincmd w<Cr>
nnoremap <buffer> <silent> 2 :2wincmd w<Cr>
nnoremap <buffer> <silent> 3 :3wincmd w<Cr>
nnoremap <buffer> <silent> 4 :4wincmd w<Cr>

"augroup Git_status
"	autocmd!
"augroup END

if exists('*<SID>FileDiff')
    finish
endif

function <SID>Refresh()
    let l:pos = getpos('.')
    silent edit!
    call setline(1, GIT_FormatStatus())
    call setpos('.', l:pos)
endfunction

function <SID>FileDiff()
    let l:str = split(getline('.'))
    if len(l:str) == 2
        let [l:sign, l:file] = split(system("git status -s -- " . l:str[1]))
        if l:sign =~ 'M' "&& l:sign !～ 'A'
            let l:lin = search('^尚未暂存以备提交的变更\|^Changes not staged for commit', 'n')
            let l:flag = (l:lin == 0) || (line('.') < l:lin) ? ' -y --cached ' : ' -y '
            exec '!git difftool' . l:flag . l:file
        endif
    endif
endfunction

function <SID>CancelStaged(...)
	let l:msg = 'none'
    if a:0 > 0
        let l:msg = system('git reset HEAD')
    else
        let l:str = split(matchstr(getline('.'), '^\s\+.*$'))
        let l:lin = search('^尚未暂存以备提交的变更\|Changes not staged for commit', 'n')
        if len(l:str) == 2 && (l:lin == 0 || line('.') < l:lin)
            let l:msg = system("git reset HEAD -- " . l:str[1])
        endif
    endif
    if l:msg =~ 'error:\|fatal'
        echo l:msg
    elseif l:msg != 'none'
        call <SID>Refresh()
    endif
endfunction

function <SID>AddFile(...)
	let l:msg = 'none'
    if a:0 > 0
        let l:msg = system('git add .')
    else
    	let l:str = split(matchstr(getline('.'), '^\s\+.*$'))
    	if len(l:str) == 1
            let l:msg = system('git add -- ' . l:str[0])
        elseif len(l:str) == 2
            let l:lin = search('^尚未暂存以备提交的变更\|Changes not staged for commit', 'n')
            if l:lin != 0 && line('.') > l:lin
                let l:msg = system('git add -- ' . l:str[1])
            endif
        endif
    endif
    if l:msg =~ 'error:\|fatal'
        echo l:msg
    elseif l:msg != 'none'
        call <SID>Refresh()
    endif
endfunction

function <SID>CheckOutFile()
    let l:str = split(getline('.'))
    if len(l:str) == 2
        let l:msg = system('git checkout HEAD -- ' . l:str[1])
        if l:msg =~ 'error:\|fatal:'
            echo l:msg
        else
            call <SID>Refresh()
        endif
    endif
endfunction

function <SID>Commit()
    let l:m = input('Input message(git commit -m): ')
    if l:m == ''
        echo '   Abort!'
    else
        let l:msg = system("git commit -m '" . l:m . "'")
        if l:msg =~ 'error:\|fatal:'
            echo l:msg
        else
            call GIT_Refresh()
        endif
    endif
endfunction

function <SID>HelpDoc()
    let l:help = [
                \ 'Git Status quick help !?',
                \ '==================================================',
                \ '    <C-w>:   close tabpage',
                \ '    <S-t>:   close tabpage',
                \ '    <f5>:    refresh tabpage',
                \ '    <space>: echo',
                \ '    m:       git menu',
                \ '    d:       diff file (difftool: vimdiff)',
                \ '    r:       reset file staging (git reset)',
                \ '    R:       reset all file staging',
                \ '    a:       add file (git add)',
                \ '    A:       add all file',
                \ '    \co:     checkout file (git checkout)',
                \ '    1234:    jump to 1234 wimdow'
                \ ]
    echo join(l:help, "\n")
endfunction
