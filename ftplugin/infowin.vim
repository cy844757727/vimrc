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

setlocal nonu nowrap buftype=nofile nobuflisted foldcolumn=0 foldmethod=indent

nnoremap <silent> <buffer> <CR> :call <SID>Open('edit', 'keep')<CR>
nnoremap <silent> <buffer> <2-leftmouse> :call <SID>Open('edit', 'keep')<CR>
nnoremap <silent> <buffer> t :call <SID>Open('tabedit')<CR>
nnoremap <silent> <buffer> T :call <SID>Open('tabedit', 'big')<CR>
nnoremap <silent> <buffer> s :call <SID>Open('bel split')<CR>
nnoremap <silent> <buffer> S :call <SID>Open('bel split', 'big')<CR>
nnoremap <silent> <buffer> v :call <SID>Open('bel vsplit')<CR>
nnoremap <silent> <buffer> V :call <SID>Open('bel vsplit', 'big')<CR>
nnoremap <silent> <buffer> e :call <SID>Open('edit')<CR>
nnoremap <silent> <buffer> E :call <SID>Open('edit', 'big')<CR>
nnoremap <silent> <buffer> <C-j> :call search('^\S')\|normal zt<CR>
nnoremap <silent> <buffer> <C-k> :call search('^\S', 'b')\|normal zt<CR>
nnoremap <silent> <buffer> <C-w>_ :call <SID>MaxMin()<CR>

function! <SID>MaxMin()
    exe 'resize '.(winheight(0) != get(g:, 'BottomWinHeight', 15) ?
                \ get(g:, 'BottomWinHeight', 15) : '')
endfunction

function! <SID>Open(way, ...) abort
    try
        let [l:file, l:lin] = s:GetLine()
    catch
        return
    endtry

    exe get(a:000, 0, '') !=# 'keep' ? 'quit' : 'wincmd W'

    if a:0 == 0 && exists('*misc#EditFile')
        call misc#EditFile(l:file, a:way)
    elseif l:file !~? expand('%') || a:way !=# 'edit'
        exe a:way.' '.l:file
    endif

    call cursor(l:lin, 1)
    normal zz
endfunction


function s:GetLine() abort
    let l:line = getline('.')
    let l:indent = strdisplaywidth(matchstr(l:line, '\v^\s*'))
    let l:lin = matchstr(l:line, '\v^\s+\zs\d+\ze:')

    if l:indent == 0 || empty(l:lin)
        return []
    endif

    let l:nr = line('.') - 1
    while l:nr > 0
        let l:line = getline(l:nr)
        if strdisplaywidth(matchstr(l:line, '\v^\s*')) < l:indent
            let l:file = l:line
            break
        endif
        let l:nr -= 1
    endwhile

    return [b:infoWin.path.'/'.l:file, l:lin]
endfunction

