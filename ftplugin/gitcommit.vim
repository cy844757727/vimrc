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
setlocal foldcolumn=0
setlocal foldlevel=0
setlocal foldmethod=marker
setlocal foldmarker={[(<{,}>)]}
setlocal foldminlines=1
setlocal foldtext=Git_MyCommitFoldInfo()
setlocal statusline=%2(\ %)\ Commit%=%2(\ %)

nnoremap <buffer> <silent> <Space> :silent! normal za<CR>
nnoremap <buffer> <silent> d :call <SID>FileDiff()<CR>
nnoremap <buffer> <silent> e :call <SID>EditFile()<CR>
nnoremap <buffer> <silent> \co :call <SID>CheckOutFile()<CR>
nnoremap <buffer> <silent> m :call git#MainMenu()<CR>
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
    let l:line = getline(v:foldstart)
    let l:mode = getline(v:foldstart + 1)
    let l:file = matchstr(l:line, '\(diff --\w* \(a/\)\?\)\zs\S*')

    if l:mode =~ 'index '
        let l:mode = getline(v:foldstart + 2)
    endif

    let l:cc = l:line =~ ' --cc \| --combined ' ? ' .' : '  '

    if l:mode =~ '^--- '
        let l:file = l:cc.'● '.l:file
    elseif l:mode =~ 'new file mode'
        let l:file = l:cc.' '.l:file
    elseif l:mode =~ 'deleted file mode'
        let l:file = l:cc.' '.l:file
    elseif l:mode =~ 'old mode '
        let l:file = '   '.l:file
    elseif l:mode =~ 'rename from'
        let l:file = '   '.l:file.'   '.matchstr(l:line, '\( b/\)\zs\S*')
    elseif l:mode =~ 'copy from '
        let l:file = '   '.l:file.'   '.matchstr(l:line, '\( b/\)\zs\S*')
    elseif l:mode =~ 'Binary files '
        let l:file = '   '.l:file
    else
        let l:file  = '    '.l:line
    endif

    return ' '.printf('%-5d', v:foldend - v:foldstart + 1).l:file.'  '
endfunction

function <SID>FileDiff()
    let l:file = getline('.')
    if l:file =~ '^diff --git '
    	let l:file = matchstr(l:file, '\( a/\)\zs\S\+')
        let l:hash = split(getline(1))
        exec '!git difftool -y ' . l:hash[3] . ' ' . l:hash[1] . ' -- ' . l:file
    endif
endfunction

function <SID>EditFile()
    let l:file = getline('.')
    if l:file =~ '^diff --\w* '
    	let l:file = matchstr(l:file, '\(diff --\w* \(a/\)\?\)\zs\S\+')
        let l:winId = win_findbuf(bufnr(l:file))
        if l:winId != []
            call win_gotoid(l:winId[0])
        elseif filereadable(l:file)
            exec '-tabedit ' . l:file
        endif
    endif
endfunction

function <SID>CheckOutFile()
    let l:file = getline('.')
    if l:file =~ '^diff --git ' && input('Confirm checkout file from specified commit(yes/no): ') == 'yes'
    	let l:file = matchstr(l:file, '\( a/\)\zs\S\+')
        let l:hash = split(getline(1))[1]
        let l:msg = system("git checkout " . l:hash . ' -- ' . l:file)
        if l:msg =~ 'error:\|fatal:'
            echo l:msg
        else
            wincmd w
            silent edit!
            call setline(1, git#FormatStatus())
            wincmd W
        endif
    endif
endfunction

function <SID>HelpDoc()
    echo
                \ "Git commit quick help !?\n" .
                \ "==================================================\n" .
                \ "    <spcae>: code fold | unfold    (za)\n" .
                \ "    m:       git menu\n" .
                \ "    d:       diff file             (git difftool -y)\n" .
                \ "    e:       edit file\n" .
                \ "    \\co:     checkout file         (git checkout hash --)\n" .
                \ "    1234:    jump to 1234 wimdow"
endfunction

