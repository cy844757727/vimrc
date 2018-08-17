"
"
"
if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1

nnoremap <buffer> <C-w> :call GIT_CloseTab()<Cr>
nnoremap <buffer> <S-t> :call GIT_CloseTab()<Cr>
nnoremap <buffer> <f5>  :call GIT_Refresh()<Cr>
setlocal nonu
setlocal nowrap
setlocal statusline=[log]%=\ \ \ \ \ %-10.(%l:%c%V%)\ %4P\ 

if !exists('*s:RefreshCommit')
function s:RefreshCommit()
    let l:hash = matchstr(getline('.'), ' [a-z0-9]\{7} ')
    if !empty(l:hash)
        wincmd w
        silent edit!
        silent call setline(1, GIT_FormatCommit(l:hash))
        set filetype=gitcommit
        wincmd W
    endif
endfunction
endif

autocmd! CursorMoved <buffer> call s:RefreshCommit()
"autocmd! TabEnter <buffer> call s:RefreshCommit()

