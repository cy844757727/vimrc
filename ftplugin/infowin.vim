""""""""""""""""""""""""""""""""""""""""""""""""""""
" Name:   
" Author: CY <844757727@qq.com>
""""""""""""""""""""""""""""""""""""""""""""""""""""
"
"
if exists('b:did_ftplugin_')
    finish
endif
let b:did_ftplugin_ = 1

setlocal nonu nowrap buftype=nofile nobuflisted foldcolumn=0 foldmethod=indent

nnoremap <silent> <buffer> <CR> :call <SID>Open('edit', 'keep')<CR>
nnoremap <silent> <buffer> <2-leftmouse> :call <SID>Open('edit', 'keep')<CR>
nnoremap <silent> <buffer> t :call <SID>Open('tabedit', 'default')<CR>
nnoremap <silent> <buffer> T :call <SID>Open('tabedit', 'force')<CR>
nnoremap <silent> <buffer> s :call <SID>Open('bel split', 'default')<CR>
nnoremap <silent> <buffer> S :call <SID>Open('bel split', 'force')<CR>
nnoremap <silent> <buffer> v :call <SID>Open('bel vsplit', 'default')<CR>
nnoremap <silent> <buffer> V :call <SID>Open('bel vsplit', 'force')<CR>
nnoremap <silent> <buffer> e :call <SID>Open('edit', 'default')<CR>
nnoremap <silent> <buffer> E :call <SID>Open('edit', 'force')<CR>
nnoremap <silent> <buffer> p :call <SID>Preview('noauto')<CR>
nnoremap <silent> <buffer> P :call <SID>Preview('auto')<CR>
nnoremap <silent> <buffer> <C-j> :call search('^\S')\|normal zt<CR>
nnoremap <silent> <buffer> <C-k> :call search('^\S', 'b')\|normal zt<CR>
nnoremap <silent> <buffer> <C-w>_ :call <SID>MaxMin()<CR>

" Determine auto preview
let s:auto = 0

augroup InfoWin_
    autocmd!
    autocmd BufWinLeave <buffer> call s:PreviewClose()
    autocmd CursorMoved <buffer> if s:auto|call s:PreviewAuto()|endif
augroup END

function! <SID>MaxMin()
    exe 'resize '.(winheight(0) != get(g:, 'BottomWinHeight', 15) ?
                \ get(g:, 'BottomWinHeight', 15) : '')
endfunction


function! <SID>Open(way, mode) abort
    let [l:file, l:lin, l:col] = b:infoWin.getline()

    if !filereadable(l:file)
        return
    endif

    exe a:mode =~# 'keep' ? 'wincmd W' : 'quit'

    if a:mode =~# 'default' && exists('*misc#EditFile')
        call misc#EditFile(l:file, a:way.' +'.l:lin)
    else
        exe bufnr(l:file) == bufnr('%') && a:way =~# 'edit' ?
                    \ 'normal '.l:lin.'ggzz' :
                    \ a:way.' +'.l:lin.' '.l:file
    endif

    if l:col > 1
        exe 'normal 0'.(l:col-1).'l'
    endif
endfunction


let s:currentLine = 0
function <SID>Preview(flag)
    let [l:file, l:lin, l:col] = b:infoWin.getline()

    if !filereadable(l:file)
        return
    endif

    let l:cur = winnr()
    if l:cur != winnr('$') && getwinvar(l:cur + 1, 'infoWinPreview', 0)
        if line('.') == s:currentLine && xor(s:auto, a:flag !=# 'auto')
            exe (l:cur+1).'close'
            return
        endif

        wincmd w
        exe l:file =~# bufname('%') ? 'normal '.l:lin.'ggzz' :
                    \ 'edit +'.l:lin.' '.l:file
    else
        exe 'belowright vsplit +'.l:lin.' '.l:file
        let w:infoWinPreview = 1
        let w:buftype = 1
        setlocal statusline=\ 﩮%f%m%r%h%w%<%=%{misc#StatuslineExtra()}%3(%)%4P\ 
    endif

    if l:col > 1
        exe 'normal 0'.(l:col-1).'l'
    endif

    wincmd W
    let s:currentLine = line('.')
    let s:auto = a:flag ==# 'auto' ? 1 : 0
endfunction


function s:PreviewAuto()
    let l:cur = winnr()
    if line('.') == s:currentLine || l:cur == winnr('$') ||
                \ !getwinvar(l:cur + 1, 'infoWinPreview', 0)
        return
    endif

    let [l:file, l:lin, l:col] = b:infoWin.getline()

    if !filereadable(l:file)
        return
    endif
    
    let s:currentLine = line('.')
    wincmd w
    exe l:file =~# bufname('%') ? 'normal '.l:lin.'ggzz' :
                \ 'edit +'.l:lin.' '.l:file

    if l:col > 1
        exe 'normal 0'.(l:col-1).'l'
    endif

    wincmd W
endfunction


function s:PreviewClose()
    let s:auto = 0
    let l:i = winnr('$')

    while l:i > 0
        if getwinvar(l:i, 'infoWinPreview', 0)
            exe l:i.'close'
            return
        endif

        let l:i -= 1
    endwhile
endfunction

