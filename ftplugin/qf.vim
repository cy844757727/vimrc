"
"
"

if exists("b:did_ftplugin_")
    finish
endif
let b:did_ftplugin_ = 1

nnoremap <buffer> t :call <SID>Open('tabedit')<CR>
nnoremap <buffer> T :call <SID>Open('tabedit', 'big')<CR>
nnoremap <buffer> s :call <SID>Open('split')<CR>
nnoremap <buffer> S :call <SID>Open('split', 'big')<CR>
nnoremap <buffer> v :call <SID>Open('vsplit')<CR>
nnoremap <buffer> V :call <SID>Open('vsplit', 'big')<CR>
nnoremap <buffer> e :call <SID>Open('edit')<CR>
nnoremap <buffer> E :call <SID>Open('edit', 'big')<CR>


function! <SID>Open(way, ...)
    let l:match = split(matchstr(getline('.'), '\v^[^|]+\|[^|]*\|'), '\v[ |]+')

    if empty(l:match) || !filereadable(l:match[0])
        return
    endif
    
    cclose

    if a:0 > 0 && exists('*misc#EditFile')
        call misc#EditFile(l:match[0], a:way)
    else
        exe a:way.' '.l:match[0]
    endif

    call cursor(l:match[1], get(l:match, 3, 1))
    normal zz
endfunction


