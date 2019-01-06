"
"
"

if exists("b:did_ftplugin_")
    finish
endif
let b:did_ftplugin_ = 1

nnoremap <buffer> t :call <SID>Open('tabedit')<CR>
nnoremap <buffer> T :call <SID>Open('-tabedit')<CR>
nnoremap <buffer> s :call <SID>Open('split')<CR>
nnoremap <buffer> S :call <SID>Open('belowright split')<CR>
nnoremap <buffer> v :call <SID>Open('vsplit')<CR>
nnoremap <buffer> V :call <SID>Open('aboveleft vsplit')<CR>
nnoremap <buffer> e :call <SID>Open('edit')<CR>

" | need backslash here in case for command splitting
nnoremap <buffer> <C-j> :call search('^[^\|]')<CR>
nnoremap <buffer> <C-k> :call search('^[^\|]', 'b')<CR>

function! <SID>Open(way)
    let l:match = split(matchstr(getline('.'), '^[^|]\+|[^|]*|'), '[ |]\+')

    if empty(l:match) || !filereadable(l:match[0])
        return
    endif
    
    cclose
    exe a:way . ' ' . l:match[0]
    call cursor(l:match[1], get(l:match, 3, 1))
    normal zz
endfunction

