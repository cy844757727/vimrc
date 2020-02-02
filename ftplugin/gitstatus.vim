""""""""""""""""""""""""""""""""""""""""""""""""""""
" Author: CY <844757727@qq.com>
" Description: git plugin : tabpage manager(status)
""""""""""""""""""""""""""""""""""""""""""""""""""""
if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1
let b:curL = -1

setlocal buftype=nofile foldmethod=indent foldminlines=1 shiftwidth=1
setlocal statusline=%2(\ %)ﰧ\ Status%=%2(\ %)

nnoremap <buffer> <space>      :echo getline('.')<CR>
nnoremap <buffer> <silent> d   :call <SID>FileDiff()<CR>
nnoremap <buffer> <silent> r   :call <SID>CancelStaged()<CR>
nnoremap <buffer> <silent> R   :call <SID>CancelStaged(1)<CR>
nnoremap <buffer> <silent> a   :call <SID>AddFile()<CR>
nnoremap <buffer> <silent> A   :call <SID>AddFile(1)<CR>
nnoremap <buffer> <silent> e   :call <SID>EditFile()<CR>
nnoremap <buffer> <silent> \d  :call <SID>DeleteItem()<CR>
nnoremap <buffer> <silent> \l  :call <SID>FileLog()<CR>
nnoremap <buffer> <silent> \D  :call <SID>DeleteItem(1)<CR>
nnoremap <buffer> <silent> \co :call <SID>CheckOutFile()<CR>
nnoremap <buffer> <silent> m   :call git#Menu(1)<CR>
nnoremap <buffer> <silent> M   :call git#Menu(0)<CR>
nnoremap <buffer> <silent> ?   :call <SID>HelpDoc()<CR>
nnoremap <buffer> <silent> 1   :1wincmd w<CR>
nnoremap <buffer> <silent> 2   :2wincmd w<CR>
nnoremap <buffer> <silent> 3   :3wincmd w<CR>
nnoremap <buffer> <silent> 4   :4wincmd w<CR>

augroup Git_status
	autocmd!
	autocmd CursorMoved <buffer> call s:cursorJump()
augroup END

if exists('*<SID>FileDiff')
    finish
endif


function s:GetCurLinInfo()
    let l:line = getline('.')
    if l:line !~# '^\s\+\S'
        return ['', '']
    endif

    let l:lin = search('^\w\+:$', 'bn')
    if l:lin == 0
        return ['', '']
    endif

    return [getline(l:lin)[0]] + split(l:line)
endfunction


function <SID>EditFile()
    let l:file = s:GetCurLinInfo()[-1]
    if !filereadable(l:file)
        return
    endif

    if exists('*misc#EditFile')
        call misc#EditFile(l:file, '-tabedit')
    else
        let l:winId = win_findbuf(bufnr(l:file))
        if l:winId != []
            call win_gotoid(l:winId[0])
        else
            exec '-tabedit ' . l:file
        endif
    endif
endfunction


function <SID>FileDiff()
    let l:fileInfo = s:GetCurLinInfo()

    if l:fileInfo[1] ==# 'M'
        exec (exists('g:Git_GuiDiffTool') ? 'Async! ' : '!') .
                    \ 'git difftool -y ' .
                    \ (l:fileInfo[0] ==# 'S' ? ' --cached ' : ' ') .
                    \ l:fileInfo[-1]
    endif
endfunction


function <SID>CancelStaged(...)
	let l:msg = 'NONE'
    if a:0 > 0
        let l:msg = system('git reset HEAD')
    else
        let l:fileInfo = s:GetCurLinInfo()

        if l:fileInfo[0] ==# 'S'
            let l:msg = system("git reset HEAD -- " . l:fileInfo[-1])
        endif
    endif
    call git#MsgHandle(l:msg, 'status')
endfunction


function <SID>AddFile(...)
	let l:msg = 'NONE'
    if a:0 > 0
        let l:msg = system('git add .')
    else
        let l:fileInfo = s:GetCurLinInfo()

        if l:fileInfo[0] =~# '[WU]'
            let l:msg = system('git add -- ' . l:fileInfo[-1])
        endif
    endif
    call git#MsgHandle(l:msg, 'status')
endfunction


function <SID>CheckOutFile()
    let l:fileInfo = s:GetCurLinInfo()

    if l:fileInfo[0] =~# '[SW]'
        if input('Confirm discarding changes in working directory(yes/no): ') == 'yes'
            call git#MsgHandle(system('git checkout -- ' . l:fileInfo[-1]), 'status')
        endif
        redraw!
    endif
endfunction


function! <SID>DeleteItem(...)
    let l:fileInfo = s:GetCurLinInfo()
    if empty(l:fileInfo[0])
        return
    endif

    if input('Confirm the deletion(yes/no): ') != 'yes'
        redraw!
        return
    endif

    call git#MsgHandle(system((l:fileInfo[0] ==# 'U' ? 'rm ' : 'git rm --cached -- ') . l:fileInfo[-1]), 'status')
endfunction


function <SID>FileLog()
    let l:fileInfo = s:GetCurLinInfo()

    if l:fileInfo[0] =~# '[SW]'
        call git#Refresh('log', l:fileInfo[-1])
        1wincmd w
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
    echo
                \ "Git Status quick help !?\n" .
                \ "==================================================\n" .
                \ "    <space>: echo\n" .
                \ "    d:       diff file              (git difftool)\n" .
                \ "    r:       reset file staging     (git reset HEAD --)\n" .
                \ "    R:       reset all staged file  (git reset HEAD)\n" .
                \ "    a:       add file               (git add)\n" .
                \ "    A:       add all file           (git add .)\n" .
                \ "    e:       edit file              (new tabpage)\n" .
                \ "    \\l:      file log               (git rm)\n" .
                \ "    \\d:      delete file            (git rm)\n" .
                \ "    \\D:      delete file            (git rm -f)\n" .
                \ "    \\co:     checkout file          (git checkout --)\n" .
                \ "    1234:    jump to 1234 window"
endfunction

