"
"
if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1

nnoremap <buffer> <C-w> :call GIT_CloseTab()<Cr>
nnoremap <buffer> <S-t> :call GIT_CloseTab()<Cr>
nnoremap <buffer> <f5>  :call GIT_Refresh()<Cr>
nnoremap <buffer> <silent> d :call <SID>FileDiff()<Cr>
nnoremap <buffer> <silent> r :call <SID>CancelStaged()<Cr>
nnoremap <buffer> <silent> a :call <SID>AddFile()<Cr>
nnoremap <buffer> <silent> \co :call <SID>CheckOutFile()<Cr>
setlocal nonu
setlocal statusline=[file\ status]%=\ \ \ \ \ %-10.(%l:%c%V%)\ %4P\ 

if !exists('*<SID>Refresh')
    function s:Refresh(lin)
        call delete('.Git_status')
        silent edit!
        call setline(1, GIT_FormatStatus())
        call cursor(a:lin, 1)
    endfunction
endif

if !exists('*<SID>FileDiff')
    function <SID>FileDiff()
        let l:str = split(getline('.'))
        if len(l:str) != 2
            return
        endif
        let [l:flag, l:file] = split(system("git status -s -- " . l:str[1]))
        if l:flag =~ 'M'
            let l:curL = line('.')
            let l:lin = search('^尚未暂存以备提交的变更\|^Changes not staged for commit', 'n')
            if l:lin != 0 && l:curL > l:lin
                exec '!git difftool -y ' . l:file
                return
            endif
            let l:lin = search('^要提交的变更\|Changes to be committed', 'n')
            if l:lin != 0 && l:curL > l:lin && l:flag !~ 'A'
                exec '!git difftool -y --cached -- ' . l:file
                return
            endif
        endif
    endfunction
endif

if !exists('*<SID>CancelStaged')
    function <SID>CancelStaged()
        let l:str = split(getline('.'))
        if len(l:str) != 2
            return
        endif
        let l:lin = search('^尚未暂存以备提交的变更\|Changes not staged for commit', 'n')
        let l:curL = line('.')
        if l:lin == 0 || l:curL < l:lin
            call system("git reset HEAD -- " . l:str[1])
            call s:Refresh(l:curL)
        endif
    endfunction
endif

if !exists('*<SID>AddFile')
    function <SID>AddFile()
        let l:curL = line('.')
        let l:lin = search('^未跟踪的文件\|^Untracked files', 'n')
        if l:lin != 0 && l:curL > l:lin
            call system('git add -- ' . getline('.'))
        else
            let l:lin = search('^尚未暂存以备提交的变更\|Changes not staged for commit', 'n')
            if l:lin != 0 && l:curL > l:lin
                let l:str = split(getline('.'))
                if len(l:str) != 2
                    return
                endif
                call system('git add -- ' . l:str[1])
            else
                return
            endif
        endif
        call s:Refresh(l:curL)
    endfunction
endif

if !exists('*<SID>CheckOutFile')
function <SID>CheckOutFile()
    let l:str = split(getline('.'))
    if len(l:str) != 2
        return
    endif
    let l:curL = line('.')
    call system('git checkout HEAD -- ' . l:str[1])
    call s:Refresh(l:curL)
endfunction
endif

