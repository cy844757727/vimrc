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

setlocal foldcolumn=0 foldmethod=indent foldminlines=0
setlocal nonu nowrap buftype=nofile nobuflisted shiftwidth=1

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

let s:auto = 0
let t:infowin_winid = win_getid(winnr()-1)

augroup InfoWin_
    autocmd!
    autocmd BufWinLeave <buffer> call s:PreviewClose()
    autocmd BufWinEnter <buffer> let t:infowin_winid = win_getid(winnr()-1)
    autocmd CursorMoved <buffer> if s:auto|call s:PreviewAuto()|endif
augroup END


function! <SID>MaxMin()
    let l:height = get(g:, 'BottomWinHeight', 15)
    exe 'resize '.(winheight(0) != l:height ? l:height : '')
endfunction


function! <SID>Open(way, mode) abort
    let [l:file, l:lin, l:col] = b:infoWin.getline()

    if !filereadable(l:file)
        return
    endif

    if a:mode !=# 'keep'
        hide
    endif

    if !win_gotoid(get(t:, 'infowin_winid', -1))
        wincmd W
    endif

    let l:ex = l:lin.'gg'.(l:col > 1 ? '0'.(l:col-1).'l' : '').'zz'

    if a:mode =~# 'default' && exists('*misc#EditFile')
        call misc#EditFile(l:file, a:way.' +normal\ '.l:ex)
    else
        exe bufnr(l:file) == bufnr('%') && a:way =~# 'edit' ?
                    \ 'normal '.l:ex : a:way.' +normal\ '.l:ex.' '.l:file
    endif
endfunction


" Recording for auto preview or open/close window
let s:currentLine = 0
" Preview window statusline
let s:statusline = ' 﩮%f%m%r%h%w%<%=%{misc#StatuslineExtra()}%3(%)%4P '

function <SID>Preview(flag)
    let [l:file, l:lin, l:col] = b:infoWin.getline()

    if !filereadable(l:file)
        return
    endif

    let l:cur = winnr()
    let l:ex = l:lin.'gg'.(l:col > 1 ? '0'.(l:col-1).'l' : '').'zz'

    if l:cur != winnr('$') && getwinvar(l:cur + 1, 'infoWinPreview', 0)
        if line('.') == s:currentLine && xor(s:auto, a:flag !=# 'auto')
            exe (l:cur+1).'close'
            return
        endif

        wincmd w

        if bufnr(l:file) == bufnr('%')
            exe 'normal '.l:ex
        else
            exe 'update|edit +'.'normal\ '.l:ex.' '.l:file
            let &l:statusline = s:statusline
        endif
    else
        exe 'belowright vsplit +normal\ '.l:ex.' '.l:file
        let [w:infoWinPreview, w:buftype] = [1, 1]
        let &l:statusline = s:statusline
    endif

    redraw | wincmd W
    let [s:currentLine, s:auto] = [line('.'), a:flag ==# 'auto' ? 1 : 0]
endfunction


function s:PreviewAuto()
    let l:cur = winnr()
    if line('.') == s:currentLine || !getwinvar(l:cur + 1, 'infoWinPreview', 0)
        return
    endif

    let s:currentLine = line('.')
    let [l:file, l:lin, l:col] = b:infoWin.getline()

    if !filereadable(l:file)
        return
    endif

    wincmd w
    let l:ex = l:lin.'gg'.(l:col > 1 ? '0'.(l:col-1).'l' : '').'zz'

    if bufnr(l:file) == bufnr('%')
        exe 'normal '.l:ex
    else
        " Auto preview: add 'filetype detect' to avoid no syntax highlight
        " when editing a new file which is not in buffer list
        exe 'update|edit +'.(bufexists(l:file) ?  '' : 'filetype\ detect|').'normal\ '.l:ex.' '.l:file
        let &l:statusline = s:statusline
    endif

    redraw | wincmd W
endfunction


function s:PreviewClose()
    let [s:auto, l:i] = [0, winnr('$')]

    while l:i > 0
        if getwinvar(l:i, 'infoWinPreview', 0)
            exe l:i.'close'
            return
        endif

        let l:i -= 1
    endwhile
endfunction

