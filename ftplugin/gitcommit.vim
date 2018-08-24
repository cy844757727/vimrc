"
if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1
let b:ale_enabled = 0

setlocal nonu
setlocal statusline=\ [2-Commit]%=\ \ \ \ \ %-5l\ %4P\ 
setlocal foldmethod=marker
setlocal foldmarker={[(<{,}>)]}
setlocal foldtext=Git_MyCommitFoldInfo()

nnoremap <buffer> <silent> <Space> :silent! normal za<Cr>
nnoremap <buffer> <C-w> :call GIT_CloseTab()<Cr>
nnoremap <buffer> <S-t> :call GIT_CloseTab()<Cr>
nnoremap <buffer> <f5>  :call GIT_Refresh()<Cr>
nnoremap <buffer> <silent> d :call <SID>FileDiff()<Cr>
nnoremap <buffer> <silent> \co :call <SID>CheckOutFile()<Cr>
nnoremap <buffer> <silent> m :call GIT_Menu()<Cr>
nnoremap <buffer> <silent> ? :call <SID>HelpDoc()<Cr>
nnoremap <buffer> <silent> 1 :1wincmd w<Cr>
nnoremap <buffer> <silent> 2 :2wincmd w<Cr>
nnoremap <buffer> <silent> 3 :3wincmd w<Cr>
nnoremap <buffer> <silent> 4 :4wincmd w<Cr>

"augroup Git_commit
"	autocmd!
"augroup END

if exists('*Git_MyCommitFoldInfo')
    finish
endif

function! Git_MyCommitFoldInfo()
    let l:i = v:foldstart + 2
    let l:str = getline(l:i)
    if l:str !~ '^--- '
        let l:str = getline(l:i + 1)
        let l:strN = getline(l:i + 2)
    else
        let l:strN = getline(l:i + 1)
    endif
    let l:str = l:str == '--- /dev/null' ? 'New' : strpart(l:str, 6)
    let l:strN = l:strN == '+++ /dev/null' ? 'Delete' : strpart(l:strN, 6)
    let l:str .= l:str == l:strN ? '    ' : '  ' . l:strN . '    '
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
        if l:msg =~ 'error:\|fatal:'
            echo l:msg
        else
            wincmd w
            silent edit!
            call setline(1, GIT_FormatStatus())
            wincmd W
        endif
    endif
endfunction

function <SID>HelpDoc()
    let l:help = [
                \ 'Git commit quick help !?',
                \ '==================================================',
                \ '    <spcae>: code fold | unfold',
                \ '    <C-w>:   close tabpage',
                \ '    <S-t>:   close tabpage',
                \ '    <f5>:    refresh tabpage',
                \ '    m:       git menu',
                \ '    d:       diff file',
                \ '    \co:     checkout file',
                \ '    1234:    jump to 1234 wimdow'
                \ ]
    echo join(l:help, "\n")
endfunction
