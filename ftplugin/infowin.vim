""""""""""""""""""""""""""""""""""""""""""""""""""""
" Name:   
" Author: CY <844757727@qq.com>
""""""""""""""""""""""""""""""""""""""""""""""""""""
"
":
if exists("b:did_ftplugin_")
    finish
endif
let b:did_ftplugin_ = 1

nnoremap <silent> <buffer> <CR> :call <SID>Open('edit', 'keep')<CR>
nnoremap <silent> <buffer> <2-leftmouse> :call <SID>Open('edit', 'keep')<CR>
nnoremap <silent> <buffer> t :call <SID>Open('tabedit')<CR>
nnoremap <silent> <buffer> T :call <SID>Open('tabedit', 'big')<CR>
nnoremap <silent> <buffer> s :call <SID>Open('split')<CR>
nnoremap <silent> <buffer> S :call <SID>Open('split', 'big')<CR>
nnoremap <silent> <buffer> v :call <SID>Open('vsplit')<CR>
nnoremap <silent> <buffer> V :call <SID>Open('vsplit', 'big')<CR>
nnoremap <silent> <buffer> e :call <SID>Open('edit')<CR>
nnoremap <silent> <buffer> E :call <SID>Open('edit', 'big')<CR>
nnoremap <silent> <buffer> <C-j> :call search('^\S')\|normal zt<CR>
nnoremap <silent> <buffer> <C-k> :call search('^\S', 'b')\|normal zt<CR>


function! <SID>Open(way, ...)
    try
        let [l:file, l:lin] = s:GetLine()
    catch
        return
    endtry

    if get(a:000, 0, '') !=# 'keep'
        quit
    else
        wincmd W
    endif

    if a:0 == 0 && exists('*misc#EditFile')
        call misc#EditFile(l:file, a:way)
    else
        exe a:way.' '.l:file
    endif

    call cursor(l:lin, 1)
    normal zz
endfunction


function s:GetLine()
    let l:line = getline('.')
    let l:indent = strdisplaywidth(matchstr(l:line, '\v^\s*'))
    if l:indent == 0
        return []
    endif

    let l:nr = line('.') - 1
    let l:lin = matchstr(l:line, '\v\d+\ze:')
    while l:nr > 0
        let l:line = getline(l:nr)
        if strdisplaywidth(matchstr(l:line, '\v^\s*')) < l:indent
            let l:file = l:line
            break
        endif
        let l:nr -= 1
    endwhile

    return [b:path.'/'.l:file, l:lin]
endfunction

