"
if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1
let b:ale_enabled = 0

setlocal nonu
setlocal statusline=[commit\ info]%=\ \ \ \ \ %-10.(%l:%c%V%)\ %4P\ 
setlocal foldmethod=marker
setlocal foldmarker=diff\ --git\ a/,enddiff\ --git
setlocal foldtext=Git_MyCommitFoldInfo()

nnoremap <buffer> <silent> <Space> :silent! normal za<Cr>
nnoremap <buffer> <C-w> :call GIT_CloseTab()<Cr>
nnoremap <buffer> <S-t> :call GIT_CloseTab()<Cr>
nnoremap <buffer> <f5>  :call GIT_Refresh(0)<Cr>
nnoremap <buffer> d :call <SID>FileDiff()<Cr>
nnoremap <buffer> \co :call <SID>CheckOutFile()<Cr>

augroup Git_commit
	autocmd!
	autocmd BufWritePost <buffer> call delete('.Git_commit')
augroup END

if !exists('*Git_MyCommitFoldInfo')
    function! Git_MyCommitFoldInfo()
        let l:i = v:foldstart + 2
        let l:str = getline(l:i)
        while l:str !~ '^--- '
            let l:i += 1
            let l:str = getline(l:i)
        endwhile
        if l:str =~ '/dev/null'
            let l:str = 'New'
        else
            let l:str = strpart(l:str, 6)
        endif
"        let l:str = l:str =～ '/dev/null' ? 'New' : strpart(l:str, 6)
        let l:str1 = getline(l:i + 1)
        if l:str1 =~ '/dev/null'
            let l:str1 = 'Delete'
        else
            let l:str1 = strpart(l:str1, 6)
        endif
"        let l:str1 = l:str1 =～ '/dev/null' ? 'Delete' : strpart(l:str1, 6)
        if l:str != l:str1
        	let l:str .= '  ' . l:str1
        endif
        let l:num = printf('%-5d', v:foldend - v:foldstart + 1)
        return '▶ Lines: ' . l:num . ' File: ' . l:str . '  '
    endfunction
endif

if !exists('*<SID>FileDiff')
    function <SID>FileDiff()
        let l:file = getline('.')
        if l:file =~ '^diff --git '
        	let l:file = strpart(split(l:file)[-1], 2)
        	let l:hash = split(getline(1))
        	exec '!git difftool -y ' . l:hash[3] . ' ' . l:hash[1] . ' -- ' . l:file
        endif
    endfunction
endif

if !exists('*<SID>CheckOutFile')
    function <SID>CheckOutFile()
        let l:file = getline('.')
        if l:file =~ '^diff --git '
            let l:file = strpart(split(l:file)[-1], 2)
            let l:hash = split(getline(1))[1]
            let l:msg = system("git checkout " . l:hash . ' -- ' . l:file)
            3wincmd w
            silent edit!
            call setline(1, GIT_FormatStatus())
            2wincmd w
        endif
    endfunction
endif

