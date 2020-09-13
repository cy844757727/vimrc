""""""""""""""""""""""""""""""""""""""""""""""""""""
" Author: CY <844757727@qq.com>
" Description: git plugin : tabpage manager(status)
""""""""""""""""""""""""""""""""""""""""""""""""""""
if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1
let b:curL = -1

setlocal buftype=nofile shiftwidth=1

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
vnoremap <buffer> <silent> \co :call <SID>CheckOutFile(2)<CR>
nnoremap <buffer> <silent> m   :call git#Menu(1)<CR>
nnoremap <buffer> <silent> M   :call git#Menu(0)<CR>
nnoremap <buffer> <silent> ?   :call <SID>HelpDoc()<CR>
nnoremap <buffer> <silent> 1   :1wincmd w<CR>
nnoremap <buffer> <silent> 2   :2wincmd w<CR>
nnoremap <buffer> <silent> 3   :3wincmd w<CR>
nnoremap <buffer> <silent> 4   :4wincmd w<CR>

nnoremap <buffer> <silent> <C-j> :call search('^\w\+:$', 'W')<CR>
nnoremap <buffer> <silent> <C-k> :call search('^\w\+:$', 'bW')<CR>

augroup Git_status
	autocmd!
	autocmd CursorMoved <buffer> call s:cursorJump()
augroup END

if exists('*<SID>FileDiff')
    finish
endif


function s:GetLineInfo(...)
    let l:line = getline('.')
    if l:line !~# '^\s\+\S'
        return ['', '']
    endif

    let l:lin = search('^\w\+:$', 'bn')
    if l:lin == 0
        return ['', '']
    endif

    if a:0 != 0 && a:1 == 2
        let l:rslt = [getline(l:lin)[0]]
        for l:line in getline("'<", "'>")
            if l:line =~# '^\s\+\S'
                call add(l:rslt, split(l:line))
            endif
        endfor
        return l:rslt
    endif
    return [getline(l:lin)[0]] + split(l:line)
endfunction


function <SID>EditFile()
    let l:file = s:GetLineInfo()[-1]
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
    let l:lineInfo = s:GetLineInfo()

    if l:lineInfo[1] ==# 'M'
        exec (g:GIT_diffguitool ? 'Async! git difftool -g -y ' : '!git difftool -y ') .
                    \ (l:lineInfo[0] ==# 'S' ? ' --cached -- ' : ' -- ') . l:lineInfo[-1]
    endif
endfunction


function <SID>CancelStaged(...)
    let l:lineInfo = s:GetLineInfo()

    if a:0 != 0 || l:lineInfo[0] ==# 'S'
        call git#MsgHandle(system('git reset HEAD' . (a:0 == 0 ? ' -- '.l:lineInfo[-1] : '')), 'status')
    endif
endfunction


function <SID>AddFile(...)
    let l:lineInfo = s:GetLineInfo()

    if a:0 == 0
        let l:cmd = ' -- ' . l:lineInfo[-1]
    elseif l:lineInfo[0] != 'U'
        let l:cmd = ' -u'
    else
        let l:cmd = ' .'
    endif
    call git#MsgHandle(system('git add' . l:cmd), 'status')
"    if a:0 != 0 || l:lineInfo[0] =~# '[WU]'
"        call git#MsgHandle(system('git add' . (a:0 == 0 ? ' -- '.l:lineInfo[-1] : ' .')), 'status')
"    endif
endfunction


function <SID>CheckOutFile(...) range
    if a:0 != 0 && a:1 == 2
        let l:lineInfo = s:GetLineInfo(2)
    else
        let l:lineInfo = s:GetLineInfo()
    endif

    if l:lineInfo[0] =~# '[SW]' && input('Confirm discarding changes in working directory(yes/no): ') ==# 'yes'
        redraw!
        if a:0 != 0 && a:1 == 2
            let l:msg = ''
            for l:file in l:lineInfo[1:]
                let l:msg .= system('git checkout -- ' . l:file[-1])
            endfor
            call git#MsgHandle(l:msg, 'status')
        else
            call git#MsgHandle(system('git checkout -- ' . l:lineInfo[-1]), 'status')
        endif
    else
        redraw!
    endif
endfunction


function! <SID>DeleteItem(...)
    let l:lineInfo = s:GetLineInfo()
    if empty(l:lineInfo[0])
        return
    endif

    if l:lineInfo[0] ==# 'U'
        let l:ans = input('Confirm the file deletion (YES) or ignore file (yes): ')
        redraw!
        if l:ans ==# 'YES'
            call git#MsgHandle(system('rm '.l:lineInfo[-1]), 'status')
        elseif l:ans ==# 'yes'
            call writefile([l:lineInfo[-1]], '.gitignore', 'a')
            call git#Refresh('status')
        endif
    elseif input('Cancel file tracking(yes): ') ==# 'yes'
        redraw!
        call git#MsgHandle(system('git rm --cached -- ' . l:lineInfo[-1]), 'status')
    else
        redraw!
    endif

endfunction


function <SID>FileLog()
    let l:lineInfo = s:GetLineInfo()

    if l:lineInfo[0] =~# '[SW]'
        call git#Refresh('log', {'filelog': l:lineInfo[-1]})
        1wincmd w
    endif
endfunction


function s:cursorJump()
    let l:lin = line('.')

    if b:curL == l:lin
        return
    endif

    let l:end = line('$')
    let l:op = b:curL > l:lin ? 'k' : 'j'
    while line('.') != l:end && getline('.') !~ '^\s\+\S'
        exec 'normal ' . l:op
        if line('.') == 1
            let l:op = 'j'
        endif
    endwhile

    let b:curL = line('.')
endfunction


let s:quickui_doc = [
            \ '    <space>:     echo',
            \ '    d:           diff file                  (git difftool)',
            \ '    r:           reset file staging         (git reset HEAD --)',
            \ '    R:           reset all staged file      (git reset HEAD)',
            \ '    a:           add file                   (git add)',
            \ '    A:           add all file               (git add .)',
            \ '    e:           edit file                  (new tabpage)',
            \ '    \l:          file log                   (git rm)',
            \ '    \d:          delete file                (git rm)',
            \ '    \D:          delete file                (git rm -f)',
            \ '    \co:         checkout file              (git checkout --)',
            \ '    1234:        jump to 1234 window'
            \ ]
let s:quickui_opt = {'title': 'Map: status', 'w': 80, 'h': len(s:quickui_doc)}

function <SID>HelpDoc()
    if exists('g:quickui#style#border')
        call quickui#textbox#open(s:quickui_doc, s:quickui_opt)
    else
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
    endif
endfunction

