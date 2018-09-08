""""""""""""""""""""""""""""""""""""""""""""""""""""
" Name: git plugin : tabpage manager(commit)
" Author: CY <844757727@qq.com>
""""""""""""""""""""""""""""""""""""""""""""""""""""
if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1
let b:ale_enabled = 0

setlocal nonu
setlocal buftype=nofile
setlocal foldmethod=marker
setlocal foldmarker={[(<{,}>)]}
setlocal foldtext=Git_MyCommitFoldInfo()
setlocal statusline=\ [2-Commit]%=\ \ \ \ \ %-5l\ %4P\ 

nnoremap <buffer> <silent> <Space> :silent! normal za<CR>
nnoremap <buffer> <silent> d :call <SID>FileDiff()<CR>
nnoremap <buffer> <silent> \co :call <SID>CheckOutFile()<CR>
nnoremap <buffer> <silent> m :call GIT_MainMenu()<CR>
nnoremap <buffer> <silent> ? :call <SID>HelpDoc()<CR>
nnoremap <buffer> <silent> 1 :1wincmd w<CR>
nnoremap <buffer> <silent> 2 :2wincmd w<CR>
nnoremap <buffer> <silent> 3 :3wincmd w<CR>
nnoremap <buffer> <silent> 4 :4wincmd w<CR>

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
                \ 'text': 'Switch file (x) permission',
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
    echo
                \ "Git commit quick help !?\n" .
                \ "==================================================\n" .
                \ "    <spcae>: code fold | unfold (za)\n" .
                \ "    m:       git menu\n" .
                \ "    d:       diff file\n" .
                \ "    \\co:     checkout file\n" .
                \ "    1234:    jump to 1234 wimdo"
endfunction

