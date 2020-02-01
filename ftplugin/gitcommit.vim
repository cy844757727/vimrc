""""""""""""""""""""""""""""""""""""""""""""""""""""
" Author: CY <844757727@qq.com>
" Description: git plugin : tabpage manager(commit)
""""""""""""""""""""""""""""""""""""""""""""""""""""
if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1
let b:ale_enabled = 0

setlocal buftype=nofile
setlocal foldminlines=1
setlocal statusline=%2(\ %)\ Commit%=%2(\ %)
let b:statuslineBase = '%2( %) Commit%=%2( %)'

nnoremap <buffer> <silent> <Space> :silent! normal za<CR>
nnoremap <buffer> <silent> d :call <SID>FileDiff()<CR>
nnoremap <buffer> <silent> D :call <SID>FileDiff(1)<CR>
nnoremap <buffer> <silent> \d :call <SID>DelFile()<CR>
nnoremap <buffer> <silent> \l :call <SID>FileLog()<CR>
nnoremap <buffer> <silent> e :call <SID>EditFile()<CR>
nnoremap <buffer> <silent> \co :call <SID>CheckOutFile()<CR>
nnoremap <buffer> <silent> \CO :call <SID>CheckOutFile(1)<CR>
nnoremap <buffer> <silent> m :call git#Menu(1)<CR>
nnoremap <buffer> <silent> M :call git#Menu(0)<CR>
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

function s:GetCurLinInfo()
    let l:line = getline('.')
    if l:line !~# '^>    '
        return ['', '', '']
    endif

    let l:lin = search('^commit ', 'bn')
    if l:lin == 0
        return ['', '', '']
    endif

    let l:hash = split(getline(l:lin))
    return [l:hash[1], l:hash[3]] + split(l:line)[1:]
endfunction


function <SID>FileDiff(...)
    let l:fileInfo = s:GetCurLinInfo()

    if l:fileInfo[2] ==# 'M'
        exec (exists('g:Git_GuiDiffTool') ? 'Async! ' : '!') .
                    \ 'git difftool -y ' . (a:0 == 0 ? l:fileInfo[1] : '') .
                    \ ' ' . l:fileInfo[0] . ' -- ' . l:fileInfo[-1]
    endif
endfunction


function <SID>EditFile()
    let l:file = s:GetCurLinInfo()[-1]

    if filereadable(l:file)
        if exists('*misc#EditFile')
            call misc#EditFile(l:file, '-tabedit')
        else
            let l:winId = win_findbuf(bufnr(l:file))
            if l:winId != []
                call win_gotoid(l:winId[0])
            elseif filereadable(l:file)
                exec '-tabedit ' . l:file
            endif
        endif
    endif
endfunction


function <SID>DelFile()
    let l:file = s:GetCurLinInfo()[-1]

    if filereadable(l:file) && input('Confirm remove file from repository(yes/no): ') == 'yes'
        let l:msg = system('git rm --cached -- ' . l:file)
        if l:msg =~ 'error:\|fatal:'
            echo l:msg
        else
            wincmd w
            silent edit!
            setlocal modifiable
            call setline(1, git#FormatStatus())
            setlocal nomodifiable
            wincmd W
        endif
    endif
endfunction


function <SID>CheckOutFile(...)
    let l:fileInfo = s:GetCurLinInfo()

    if !empty(l:fileInfo[0]) && input('Confirm checkout file from specified commit(yes/no): ') == 'yes'
        let l:msg = system('git checkout ' . (a:0 == 0 ? l:fileInfo[0] : l:fileInfo[1]) . ' -- ' . l:fileInfo[-1])
        if l:msg =~ 'error:\|fatal:'
            echo l:msg
        else
            wincmd w
            silent edit!
            setlocal modifiable
            call setline(1, git#FormatStatus())
            setlocal nomodifiable
            wincmd W
        endif
    endif
endfunction


function <SID>FileLog()
    let l:file = s:GetCurLinInfo()[-1]

    if !empty(l:file)
        wincmd W
        silent edit!
        setlocal modifiable
        call setline(1, git#FormatLog(l:file))
        let l:list = split(b:statuslineBase, '%=')
        let &l:statusline = l:list[0] . ' -- ' . l:file . '%=' . l:list[1]
        let b:target = l:file
        setlocal nomodifiable
    endif
endfunction


function <SID>HelpDoc()
    echo
                \ "Git commit quick help !?\n" .
                \ "==================================================\n" .
                \ "    <spcae>: code fold | unfold    (za)\n" .
                \ "    d:       diff file             (git difftool -y)\n" .
                \ "    D:       diff file             (git difftool -y, workspace)\n" .
                \ "    \\l:      file log             (git log --oneline -- file)\n" .
                \ "    \\d:      del file             (git rm --cached )\n" .
                \ "    e:       edit file\n" .
                \ "    \\co:     checkout file         (git checkout hash --)\n" .
                \ "    \\CO:     checkout file         (git checkout prehash --)\n" .
                \ "    1234:    jump to 1234 wimdow"
endfunction

