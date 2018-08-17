"
if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1

nnoremap <buffer> <silent> <Space> :silent! normal za<Cr>
nnoremap <buffer> <C-w> :call GIT_CloseTab()<Cr>
nnoremap <buffer> <S-t> :call GIT_CloseTab()<Cr>
nnoremap <buffer> d :call <SID>FileDiff()<Cr>
nnoremap <buffer> \co :call <SID>CheckOutFile()<Cr>
let b:ale_enabled = 0
setlocal nonu
setlocal statusline=[commit\ info]%=\ \ \ \ \ %-10.(%l:%c%V%)\ %4P\ 
setlocal foldnestmax=1
setlocal foldmethod=marker
setlocal foldmarker=diff\ --git\ ,enddiff\ --git
setlocal foldtext=MyCommitFoldInfo()

if !exists('*MyCommitFoldInfo')
    function MyCommitFoldInfo()
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
        let l:str1 = getline(l:i + 1)
        if l:str1 =~ '/dev/null'
            let l:str1 = 'Delete'
        else
            let l:str1 = strpart(l:str1, 6)
        endif
        if l:str != l:str1
                let l:str .= '  ' . l:str1
        endif
        let l:num = printf('%-5d', v:foldend - v:foldstart + 1)
        return '▶ Lines: ' . l:num . ' File: ' . l:str . '  '
    endfunction
endif

if !exists('*<SID>FileDiff')
    function <SID>FileDiff()
        let l:file = strpart(split(getline('.'))[-1], 2)
        let l:hash = split(getline(1))
        exec '!git difftool -y ' . l:hash[3] . ' ' . l:hash[1] . ' -- ' . l:file
    endfunction
endif

if !exists('*<SID>CheckOutFile')
    function <SID>CheckOutFile()
        let l:file = getline('.')
        if l:file =~ '^diff --git '
            let l:file = strpart(split(l:file)[-1], 2)
            let l:hash = split(getline(1))[1]
            let l:msg = system("git checkout " . l:hash . ' -- ' . l:file)[:-2]
            3wincmd w
            silent edit!
            call setline(1, GIT_FormatStatus())
            2wincmd w
            echo l:msg
        endif
    endfunction
endif

