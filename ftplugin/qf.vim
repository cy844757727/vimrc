"
"
"

if exists("b:did_ftplugin_")
    finish
endif
let b:did_ftplugin_ = 1
setlocal winfixheight nowrap

nnoremap <silent> <buffer> t :call <SID>Open('tabedit', 'default')<CR>
nnoremap <silent> <buffer> T :call <SID>Open('tabedit', 'big')<CR>
nnoremap <silent> <buffer> s :call <SID>Open('bel split', 'default')<CR>
nnoremap <silent> <buffer> S :call <SID>Open('bel split', 'big')<CR>
nnoremap <silent> <buffer> v :call <SID>Open('bel vsplit', 'default')<CR>
nnoremap <silent> <buffer> V :call <SID>Open('bel vsplit', 'big')<CR>
nnoremap <silent> <buffer> e :call <SID>Open('edit', 'default')<CR>
nnoremap <silent> <buffer> E :call <SID>Open('edit', 'big')<CR>

function! s:MaxMin()
    let l:height = get(g:, 'BottomWinHeight', 15)
    exe 'resize '.(winheight(0) != l:height ? l:height : '')
endfunction

let b:WinResize = function('s:MaxMin')

function! <SID>Open(way, mode) abort
    let l:match = split(matchstr(getline('.'), '\v^[^|]+\|[^|]*\|'), '\v[ |]+')

    if empty(l:match) || !filereadable(l:match[0])
        return
    endif
    
    cclose

    if a:mode ==# 'default' && exists('*misc#EditFile')
        call misc#EditFile(l:match[0], a:way)
    elseif bufnr(l:match[0]) != bufnr('%') || a:way !=# 'edit'
        exe a:way.' '.l:match[0]
    endif

    call cursor(l:match[1], get(l:match, 3, 1))
    normal zz
endfunction


