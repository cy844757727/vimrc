""""""""""""""""""""""""""""""""""""""""""""""""""""
" Author: CY <844757727@qq.com>
" Description: git plugin : tabpage manager(status)
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

nnoremap <buffer> <space> :echo getline('.')<CR>
nnoremap <buffer> <silent> d :call <SID>FileDiff()<CR>
nnoremap <buffer> <silent> r :call <SID>CancelStaged()<CR>
nnoremap <buffer> <silent> R :call <SID>CancelStaged(1)<CR>
nnoremap <buffer> <silent> a :call <SID>AddFile()<CR>
nnoremap <buffer> <silent> A :call <SID>AddFile(1)<CR>
nnoremap <buffer> <silent> e :call <SID>EditFile()<CR>
nnoremap <buffer> <silent> \d :call <SID>DeleteItem()<CR>
nnoremap <buffer> <silent> \D :call <SID>DeleteItem(1)<CR>
nnoremap <buffer> <silent> \co :call <SID>CheckOutFile()<CR>
nnoremap <buffer> <silent> m :call git#MainMenu()<CR>
nnoremap <buffer> <silent> ? :call <SID>HelpDoc()<CR>
nnoremap <buffer> <silent> 1 :1wincmd w<CR>
nnoremap <buffer> <silent> 2 :2wincmd w<CR>
nnoremap <buffer> <silent> 3 :3wincmd w<CR>
nnoremap <buffer> <silent> 4 :4wincmd w<CR>

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
    call setline(1, git#FormatStatus())
    call setpos('.', l:pos)
endfunction

function s:MsgHandle(msg)
    if a:msg =~ 'error:\|fatal'
        echo a:msg
    elseif a:msg != 'none'
        call s:Refresh()
    endif
endfunction

function <SID>EditFile()
    let l:file = split(matchstr(getline('.'), '^\s\+.*$'))
    if len(l:file) == 1
        let l:file = l:file[0]
    elseif len(l:file) == 2
        let l:file = l:file[1]
    else
        return
    endif
    let l:winId = win_findbuf(bufnr(l:file))
    if l:winId != []
        call win_gotoid(l:winId[0])
    elseif filereadable(l:file)
        exec '-tabedit ' . l:file
    endif
endfunction

function <SID>FileDiff()
    let l:file = split(matchstr(getline('.'), '^\s\+.*$'))
    if len(l:file) == 2
        let l:sign = split(system("git status -s -- " . l:file[1]))[0]
        if l:sign =~ 'M'
            let l:lin = search('^尚未暂存以备提交的变更\|^Changes not staged for commit', 'n')
            let l:flag = (l:lin == 0) || (line('.') < l:lin) ? ' -y --cached ' : ' -y '
            exec '!git difftool' . l:flag . l:file[1]
        endif
    endif
endfunction

function <SID>CancelStaged(...)
	let l:msg = 'none'
    if a:0 > 0
        let l:msg = system('git reset HEAD')
    else
        let l:file = split(matchstr(getline('.'), '^\s\+.*$'))
        let l:lin = search('^尚未暂存以备提交的变更\|Changes not staged for commit', 'n')
        if len(l:file) == 2 && (l:lin == 0 || line('.') < l:lin)
            let l:msg = system("git reset HEAD -- " . l:file[1])
        endif
    endif
    call s:MsgHandle(l:msg)
endfunction

function <SID>AddFile(...)
	let l:msg = 'none'
    if a:0 > 0
        let l:msg = system('git add .')
    else
    	let l:file = split(matchstr(getline('.'), '^\s\+.*$'))
    	if len(l:file) == 1
            let l:msg = system('git add -- ' . l:file[0])
        elseif len(l:file) == 2
            let l:lin = search('^尚未暂存以备提交的变更\|Changes not staged for commit', 'n')
            if l:lin != 0 && line('.') > l:lin
                let l:msg = system('git add -- ' . l:file[1])
            endif
        endif
    endif
    call s:MsgHandle(l:msg)
endfunction

function <SID>CheckOutFile()
    let l:file = split(matchstr(getline('.'), '^\s\+.*$'))
    if len(l:file) == 2
        call s:MsgHandle(system('git checkout HEAD -- ' . l:file[1]))
    endif
endfunction

function! <SID>DeleteItem(...)
    let l:file = split(matchstr(getline('.'), '^\s\+.*$'))
    let l:msg = 'none'
    if input('Confirm the deletion(yes/no): ') != 'yes'
        return
    elseif len(l:file) == 1
        let l:msg = system('rm ' . l:file[0])
    else
        let l:pre = a:0 > 0 ? '-f ' : ''
        let l:linN = search('^尚未暂存以备提交的变更\|^Changes not staged for commit', 'n')
        if l:linN != 0 && line('.') > l:linN
            let l:msg = system('git rm ' . l:pre . '-- ' . l:file[-1])
        else
            let l:msg = system('git rm ' . l:pre . '--cached -- ' . l:file[-1])
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
                \ "    m:       git menu\n" .
                \ "    d:       diff file              (git difftool)\n" .
                \ "    r:       reset file staging     (git reset HEAD --)\n" .
                \ "    R:       reset all staged file  (git reset HEAD)\n" .
                \ "    a:       add file               (git add)\n" .
                \ "    A:       add all file           (git add .)\n" .
                \ "    e:       edit file              (new tabpage)\n" .
                \ "    \\d:      delete file            (git rm)\n" .
                \ "    \\D:      delete file            (git rm -f)\n" .
                \ "    \\co:     checkout file          (git checkout HEAD --)\n" .
                \ "    1234:    jump to 1234 window"
endfunction

