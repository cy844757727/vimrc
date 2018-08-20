"
if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1
let b:ale_enabled = 0

setlocal nonu
setlocal statusline=[commit\ info]%=\ \ \ \ \ %-10.(%l:%c%V%)\ %4P\ 
setlocal foldmethod=marker
setlocal foldmarker=diff\ --git\ a/,enddiff\ --git
setlocal foldtext=Git_MyCommitFoldInfo()

nnoremap <buffer> <silent> <Space> :silent! normal za<Cr>
nnoremap <buffer> <C-w> :call GIT_CloseTab()<Cr>
nnoremap <buffer> <S-t> :call GIT_CloseTab()<Cr>
nnoremap <buffer> <f5>  :call GIT_Refresh()<Cr>
nnoremap <buffer> d :call <SID>FileDiff()<Cr>
nnoremap <buffer> \co :call <SID>CheckOutFile()<Cr>
nnoremap <buffer> ? :call <SID>HelpDoc()<Cr>

"augroup Git_commit
"	autocmd!
"augroup END

if exists('*Git_MyCommitFoldInfo')
    finish
endif

function! Git_MyCommitFoldInfo()
    let l:i = v:foldstart + 2
    let l:str = getline(l:i)
    while l:str !~ '^--- '
        let l:i += 1
        let l:str = getline(l:i)
    endwhile
    let l:str = l:str == '--- /dev/null' ? 'New' : strpart(l:str, 6)
    let l:str1 = getline(l:i + 1)
    let l:str1 = l:str1 == '+++ /dev/null' ? 'Delete' : strpart(l:str1, 6)
    let l:str .= l:str == l:str1 ? '    ' : '  ' . l:str1 . '    '
    let l:num = printf('%-5d', v:foldend - v:foldstart + 1)
    return '▶ Lines: ' . l:num . '  File: ' . l:str
endfunction

function <SID>FileDiff()
    let l:file = getline('.')
    if l:file =~ '^diff --git '
    	let l:file = matchstr(l:file, '\( a/\)\zs\S\+')
        let l:hash = split(getline(1))
        exec '!git difftool -y ' . l:hash[3] . ' ' . l:hash[1] . ' -- ' . l:file
    endif
endfunction

function <SID>CheckOutFile()
    let l:file = getline('.')
    if l:file =~ '^diff --git '
    	let l:file = matchstr(l:file, '\( a/\)\zs\S\+')
        let l:hash = split(getline(1))[1]
        let l:msg = system("git checkout " . l:hash . ' -- ' . l:file)
        if l:msg =~ '^error:\|^fatal:'
            echo l:msg
        else
            3wincmd w
            silent edit!
            call setline(1, GIT_FormatStatus())
            2wincmd w
        endif
    endif
endfunction

function <SID>HelpDoc()
    let l:help = [
                \ '* Git commit quick help',
                \ '====================================',
                \ '    <spcae>: code fold | unfold',
                \ '    <C-w>:   close tabpage',
                \ '    <S-t>:   close tabpage',
                \ '    <f5>:    refresh tabpage',
                \ '    d:       diff file',
                \ '    \co:     checkout file'
                \ ]
    echo join(l:help, "\n")
endfunction
