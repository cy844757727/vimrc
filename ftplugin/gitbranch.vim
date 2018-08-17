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
setlocal tabstop=1
setlocal statusline=[branch\ status]%=\ \ \ \ \ %-10.(%l:%c%V%)\ %4P\ 

