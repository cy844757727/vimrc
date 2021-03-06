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

nnoremap <buffer> <Space>      :echo getline('.')<CR>
nnoremap <buffer> <silent> d   :call <SID>FileDiff()<CR>
nnoremap <buffer> <silent> D   :call <SID>FileDiff(1)<CR>
nnoremap <buffer> <silent> \d  :call <SID>DelFile()<CR>
nnoremap <buffer> <silent> \l  :call <SID>FileLog()<CR>
nnoremap <buffer> <silent> \L  :call <SID>FileLog(1)<CR>
nnoremap <buffer> <silent> e   :call <SID>EditFile()<CR>
nnoremap <buffer> <silent> \rs :call <SID>ResetFile()<CR>
nnoremap <buffer> <silent> \RS :call <SID>ResetFile()<CR>
nnoremap <buffer> <silent> \co :call <SID>CheckOutFile()<CR>
nnoremap <buffer> <silent> \CO :call <SID>CheckOutFile(1)<CR>
vnoremap <buffer> <silent> \co :call <SID>CheckOutFile(2)<CR>
vnoremap <buffer> <silent> \CO :call <SID>CheckOutFile(3)<CR>
nnoremap <buffer> <silent> m   :call git#Menu(1)<CR>
nnoremap <buffer> <silent> M   :call git#Menu(0)<CR>
nnoremap <buffer> <silent> ?   :call <SID>HelpDoc()<CR>
nnoremap <buffer> <silent> 1   :1wincmd w<CR>
nnoremap <buffer> <silent> 2   :2wincmd w<CR>
nnoremap <buffer> <silent> 3   :3wincmd w<CR>
nnoremap <buffer> <silent> 4   :4wincmd w<CR>

nnoremap <buffer> <silent> <C-right>    :call <SID>SwitchCommit('next')<CR>
nnoremap <buffer> <silent> <C-left>     :call <SID>SwitchCommit('previous')<CR>

"augroup Git_commit
"	autocmd!
"augroup END

if exists('*Git_MyCommitFoldInfo')
    finish
endif

function s:GetLineInfo(...)
    let l:line = getline('.')
    if l:line !~# '^>    '
        return ['', '', '']
    endif

    let l:dict = git#GetConfig(['parent', 'commit'])
    if empty(l:dict['parent'])
        return ['', '', '']
    endif

    if a:0 != 0 && a:1 == 2
        let l:rslt = [l:dict.commit, l:dict.parent]
        for l:line in getline("'<", "'>")
            if l:line =~# '^>'
                call add(l:rslt, split(l:line)[1:])
            endif
        endfor
        return l:rslt
    endif
    return [l:dict.commit, l:dict.parent] + split(l:line)[1:]
endfunction


function <SID>FileDiff(...)
    let l:fileInfo = s:GetLineInfo()

    if l:fileInfo[2] =~# '[AMD]'
        let l:parent = ''
        if a:0 == 0
            let l:parents = l:fileInfo[1]
            let l:parent = l:parents[0]
            if len(l:parents) > 1
                let l:parent = l:parents[input('Select parent commit(0:'.l:parents[0].'  1:'.l:parents[1].'): ')]
            endif
        endif

        exec (g:GIT_diffguitool ? 'Async! git difftool -g -y ' : '!git difftool -y ') .
                    \ l:parent . ' ' . l:fileInfo[0] . ' -- ' . l:fileInfo[-1]
    endif
endfunction


function <SID>EditFile()
    let l:file = s:GetLineInfo()[-1]

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
    let l:file = s:GetLineInfo()[-1]

    if filereadable(l:file) && input('Confirm remove file from repository(yes/no): ') == 'yes'
        call git#MsgHandle(system('git rm --cached -- ' . l:file), 'status')
    endif
endfunction


function <SID>ResetFile(...)
    let l:fileInfo = s:GetLineInfo()

    if a:0 == 1
        let l:parents = l:fileInfo[1]
        let l:parent = l:parents[0]
        if len(l:parents) > 1
            let l:parent = l:parents[input('Select parent commit(0:'.l:parents[0].'  1:'.l:parents[1].'): ')]
        endif
    endif

    if !empty(l:fileInfo[0]) && input('Confirm reset --mixed file from specified commit(yes/no): ') == 'yes'
        call git#MsgHandle(system('git reset --mixed  ' . (a:0 == 0 ? l:fileInfo[0] : l:parent) . ' -- ' . l:fileInfo[-1]), 'status')
    endif
endfunction

function <SID>CheckOutFile(...) range
    if a:0 != 0 && a:1 >= 2
        let l:fileInfo = s:GetLineInfo(2)
    else
        let l:fileInfo = s:GetLineInfo()
    endif

    if a:0 != 0 && (a:1 == 1 || a:1 == 3)
        let l:parents = l:fileInfo[1]
        let l:parent = l:parents[0]
        if len(l:parents) > 1
            let l:parent = l:parents[input('Select parent commit(0:'.l:parents[0].'  1:'.l:parents[1].'): ')]
        endif
    endif

    if !empty(l:fileInfo[0]) && input('Confirm checkout file from specified commit(yes/no): ') == 'yes'
        if a:0 != 0 && a:1 >= 2
            let l:msg = ''
            for l:file in l:fileInfo[2:]
                let l:msg .= system('git checkout ' . (a:1 == 2 ? l:fileInfo[0] : l:parent) . ' -- ' . l:file[-1])
            endfor
            call git#MsgHandle(l:msg, 'status')
        else
            call git#MsgHandle(system('git checkout ' . (a:0 == 0 ? l:fileInfo[0] : l:parent) . ' -- ' . l:fileInfo[-1]), 'status')
        endif
    endif
endfunction


function <SID>FileLog(...)
    if a:0 == 0
        let l:file = s:GetLineInfo()[-1]
    elseif a:1 == 1
        let l:file = ['W', '', input('Enter fielname(git log --oneline): ', '' , 'file')]
        if !filereadable(l:file)
            echo 'Err: file non-exists !!!'
            return
        endif
    else
        return
    endif

    if !empty(l:file)
        call git#Refresh('log', {'filelog': l:file})
        1wincmd w
    endif
endfunction

function <SID>SwitchCommit(lr)
    let l:dict = git#GetConfig(['commit', 'log'])
    let [l:commit, l:log] = [l:dict['commit'], l:dict['log']]
    let l:pos = index(l:log, l:commit)
    if l:commit ==# 'HEAD' || l:pos == -1
        let l:pos = 0
        let l:commit = l:log[0]
    endif

    let l:pos = l:pos + (a:lr ==# 'next' ? 1 : -1)
    if l:pos < 0 || l:pos >= len(l:log)
        return
    endif

    call git#Refresh('commit', {'commit': l:log[l:pos]})
   1wincmd w
   call search('\<'.l:log[l:pos].'\>', a:lr ==# 'next' ? '' : 'b')
   2wincmd w
endfunction


let s:quickui_doc = [
            \ '    <space>:    code fold | unfold      (za)',
            \ '    <C-left>:   child commit',
            \ '    <C-right>:  parent commit',
            \ '    e:          edit file',
            \ '    d:          diff file               (git difftool -y)',
            \ '    D:          diff file               (git difftool -y, workspace)',
            \ '    \l:         file log                (git log --oneline -- file)',
            \ '    \L:         file log                (git log --oneline -- [input{}])',
            \ '    \d:         del file                (git rm --cached)',
            \ '    \rs:        reset file              (git reset --mixed hash --)',
            \ '    \RS:        reset file              (git reset --mixed prehash --)',
            \ '    \co:        checkout file           (git checkout hash --)',
            \ '    \CO:        checkout file           (git checkout prehash --)',
            \ '    1234:       jump to 1234 window'
            \ ]
let s:quickui_opt = {'title': 'Map: commit', 'w': 80, 'h': len(s:quickui_doc)}

function <SID>HelpDoc()
    if exists('g:quickui#style#border')
        call quickui#textbox#open(s:quickui_doc, s:quickui_opt)
    else
        echo join(s:quickui_doc, "\n")
    endif
endfunction

