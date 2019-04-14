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
nnoremap <silent> <buffer> t :call <SID>Open('tabedit')<CR>
nnoremap <silent> <buffer> T :call <SID>Open('tabedit', 'big')<CR>
nnoremap <silent> <buffer> s :call <SID>Open('bel split')<CR>
nnoremap <silent> <buffer> S :call <SID>Open('bel split', 'big')<CR>
nnoremap <silent> <buffer> v :call <SID>Open('bel vsplit')<CR>
nnoremap <silent> <buffer> V :call <SID>Open('bel vsplit', 'big')<CR>
nnoremap <silent> <buffer> e :call <SID>Open('edit')<CR>
nnoremap <silent> <buffer> E :call <SID>Open('edit', 'big')<CR>
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


function! <SID>Open(way, ...) abort
    try
        let [l:file, l:lin] = s:GetLine()
    catch
        return
    endtry

    exe get(a:000, 0, '') !=# 'keep' ? 'quit' : 'wincmd W'

    if a:0 == 0 && exists('*misc#EditFile')
        call misc#EditFile(l:file, a:way.' +'.l:lin)
    elseif l:file !~? expand('%') || a:way !=# 'edit'
        exe a:way.' +'.l:lin.' '.l:file
    endif

    normal zz
endfunction


function s:GetLine() abort
    let l:line = getline('.')
    let l:indent = strdisplaywidth(matchstr(l:line, '\v^\s*'))
    let l:lin = matchstr(l:line, '\v^\s+\zs\d+\ze:')

    if l:indent == 0 || empty(l:lin)
        return [-1, -1]
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


let s:currentLine = 0
function <SID>Preview(flag)
    let s:auto = a:flag ==# 'auto' ? 1 : 0
    let [l:file, l:lin] = s:GetLine()

    if l:file == -1
        return
    endif
    
    let l:cur = winnr()
    if l:cur != winnr('$') && getwinvar(l:cur + 1, 'infoWinPreview', 0)
        if line('.') == s:currentLine
            exe (l:cur+1).'close'
            return
        endif

        wincmd w
        exe l:file =~# bufname('%') ? 'normal '.l:lin.'ggzz' :
                    \ 'edit +'.l:lin.' '.l:file
    else
        exe 'belowright vsplit +'.l:lin.' '.l:file
        let w:infoWinPreview = 1
    endif

    wincmd W
    let s:currentLine = line('.')
endfunction


function s:PreviewAuto()
    let l:cur = winnr()
    if line('.') == s:currentLine || l:cur == winnr('$') ||
                \ !getwinvar(l:cur + 1, 'infoWinPreview', 0)
        return
    endif

    let [l:file, l:lin] = s:GetLine()
    let s:currentLine = line('.')

    if l:file == -1
        return
    endif
    
    wincmd w
    exe l:file =~# bufname('%') ? 'normal '.l:lin.'ggzz' :
                \ 'edit +'.l:lin.' '.l:file
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

