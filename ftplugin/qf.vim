"
"
"

if exists("b:did_ftplugin_")
    finish
endif
let b:did_ftplugin_ = 1
setlocal winfixheight nowrap

nnoremap <silent> <buffer> t :call <SID>Open('tabedit')<CR>
nnoremap <silent> <buffer> T :call <SID>Open('tabedit', 'big')<CR>
nnoremap <silent> <buffer> s :call <SID>Open('bel split')<CR>
nnoremap <silent> <buffer> S :call <SID>Open('bel split', 'big')<CR>
nnoremap <silent> <buffer> v :call <SID>Open('bel vsplit')<CR>
nnoremap <silent> <buffer> V :call <SID>Open('bel vsplit', 'big')<CR>
nnoremap <silent> <buffer> e :call <SID>Open('edit')<CR>
nnoremap <silent> <buffer> E :call <SID>Open('edit', 'big')<CR>
nnoremap <silent> <buffer> <C-w>_ :call <SID>MaxMin()<CR>

function! <SID>MaxMin()
    if winheight(0) == get(g:, 'BottomWinHeight', 15)
        resize
    else
        exe 'resize '.get(g:, 'BottomWinHeight', 15)
    endif
endfunction

function! <SID>Open(way, ...)
    let l:match = split(matchstr(getline('.'), '\v^[^|]+\|[^|]*\|'), '\v[ |]+')

    if empty(l:match) || !filereadable(l:match[0])
        return
    endif
    
    cclose

    if a:0 == 0 && exists('*misc#EditFile')
        call misc#EditFile(l:match[0], a:way)
    elseif l:file !~? expand('%') || a:way !=# 'edit'
        exe a:way.' '.l:match[0]
    endif

    call cursor(l:match[1], get(l:match, 3, 1))
    normal zz
endfunction


