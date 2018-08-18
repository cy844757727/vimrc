"
"
"
if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1

setlocal nonu
setlocal nowrap
setlocal statusline=[log]%=\ \ \ \ \ %-10.(%l:%c%V%)\ %4P\ 

nnoremap <buffer> <C-w> :call GIT_CloseTab()<Cr>
nnoremap <buffer> <S-t> :call GIT_CloseTab()<Cr>
nnoremap <buffer> <f5>  :call GIT_Refresh(0)<Cr>

augroup Git_log
	autocmd!
	autocmd CursorMoved <buffer> call s:RefreshCommit()
	autocmd BufWritePost <buffer> call delete('.Git_log')
augroup END

if !exists('*s:RefreshCommit')
    function s:RefreshCommit()
        let l:hash = split(getline('.'))
        if len(l:hash) > 1
            wincmd w
            silent edit!
            silent call setline(1, GIT_FormatCommit(l:hash[1]))
            set filetype=gitcommit
            wincmd W
        endif
    endfunction
endif

