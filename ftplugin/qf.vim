"
"
"

if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1

nnoremap <buffer> t :call <SID>Open('tabedit')<CR>
nnoremap <buffer> s :call <SID>Open('split')<CR>
nnoremap <buffer> v :call <SID>Open('vsplit')<CR>
nnoremap <buffer> e :call <SID>Open('edit')<CR>

"nnoremap <buffer> <C-j> :call search('^[^|]')<CR>
"nnoremap <buffer> <C-k> :call search('^[^|]', 'b')<CR>

function! <SID>Open(way)
    let l:match = matchlist(getline('.'), '^\([^|]\+\)|\([^|]*\)|')
    let l:lin = matchstr(l:match, '|\zs\d\+')
    let l:col = matchstr(l:match, '\(col \)\zs\d\+')

    if empty(l:col)
        let l:col = 1
    endif

    if empty(l:match) || !filereadable(l:match[1])
        return
    endif

    cclose
    exe a:way . ' ' . l:match[1]
    call cursor(l:lin, l:col)
    normal zz
endfunction
