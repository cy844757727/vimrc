""""""""""""""""""""""""""""""""""""""""""""""""""""
" Name: git plugin : tabpage manager(status)
" Author: CY <844757727@qq.com>
""""""""""""""""""""""""""""""""""""""""""""""""""""
if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1
let b:curL = -1
let b:currentDir = substitute(getcwd(), '^/\w*/\w*', '~', '')

setlocal nonu
setlocal buftype=nofile
setlocal statusline=\ [3-Status]\ \ %{b:currentDir}%=\ \ \ \ \ %-5l\ %4P\ 

nnoremap <buffer> <f5>  :call GIT_Refresh()<Cr>
nnoremap <buffer> <space> :echo getline('.')<Cr>
nnoremap <buffer> <silent> d :call <SID>FileDiff()<Cr>
nnoremap <buffer> <silent> r :call <SID>CancelStaged()<Cr>
nnoremap <buffer> <silent> R :call <SID>CancelStaged(1)<Cr>
nnoremap <buffer> <silent> a :call <SID>AddFile()<Cr>
nnoremap <buffer> <silent> A :call <SID>AddFile(1)<Cr>
nnoremap <buffer> <silent> \d :call <SID>DeleteItem()<Cr>
nnoremap <buffer> <silent> \D :call <SID>DeleteItem(1)<Cr>
nnoremap <buffer> <silent> \co :call <SID>CheckOutFile()<Cr>
nnoremap <buffer> <silent> m :call GIT_Menu()<Cr>
nnoremap <buffer> <silent> ? :call <SID>HelpDoc()<Cr>
nnoremap <buffer> <silent> 1 :1wincmd w<Cr>
nnoremap <buffer> <silent> 2 :2wincmd w<Cr>
nnoremap <buffer> <silent> 3 :3wincmd w<Cr>
nnoremap <buffer> <silent> 4 :4wincmd w<Cr>

augroup Git_status
	autocmd!
	autocmd CursorMoved <buffer> call s:cursorJump()
augroup END

if exists('*<SID>FileDiff')
    finish
endif

function s:Refresh()
    let l:pos = getpos('.')
    silent edit!
    call setline(1, GIT_FormatStatus())
    call setpos('.', l:pos)
endfunction

function s:MsgHandle(msg)
    if a:msg =~ 'error:\|fatal'
        echo a:msg
    elseif a:msg != 'none'
        call s:Refresh()
    endif
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
    call s:MsgHandle(l:msg)
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
    call s:MsgHandle(l:msg)
endfunction

function <SID>CheckOutFile()
    let l:str = split(getline('.'))
    if len(l:str) == 2
        let l:msg = system('git checkout HEAD -- ' . l:str[1])
        call s:MsgHandle(l:msg)
    endif
endfunction

function! <SID>DeleteItem(...)
    let l:str = split(matchstr(getline('.'), '^\s\+.*$'))
    if len(l:str) == 0
        return
    elseif len(l:str) == 1
        let l:msg = system('rm ' . l:str[0])
    else
        let l:pre = a:0 > 0 ? '-f ' : ''
        let l:linN = search('^尚未暂存以备提交的变更\|^Changes not staged for commit', 'n')
        if l:linN != 0 && line('.') > l:linN
            let l:msg = system('git rm ' . l:pre . '-- ' . l:str[-1])
        else
            let l:msg = system('git rm ' . l:pre . '--cached -- ' . l:str[-1])
        endif
    endif
    call s:MsgHandle(l:msg)
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
    echo
                \ "Git Status quick help !?\n" .
                \ "==================================================\n" .
                \ "    <space>: echo\n" .
                \ "    <f5>:    refresh tabpage\n" .
                \ "    m:       git menu\n" .
                \ "    d:       diff file (difftool: vimdiff)\n" .
                \ "    r:       reset file staging (git reset)\n" .
                \ "    R:       reset all file staging\n" .
                \ "    a:       add file (git add)\n" .
                \ "    A:       add all file\n" .
                \ "    \\d:      delete file\n" .
                \ "    \\D:      delete file (force)\n" .
                \ "    \\co:     checkout file (git checkout)\n" .
                \ "    1234:    jump to 1234 window"
endfunction
