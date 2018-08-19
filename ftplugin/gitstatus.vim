"
"
"
"
if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1

setlocal nonu
setlocal statusline=[file\ status]%=\ \ \ \ \ %-10.(%l:%c%V%)\ %4P\ 

nnoremap <buffer> <C-w> :call GIT_CloseTab()<Cr>
nnoremap <buffer> <S-t> :call GIT_CloseTab()<Cr>
nnoremap <buffer> <f5>  :call GIT_Refresh()<Cr>
nnoremap <buffer> <space> :echo getline('.')<Cr>
nnoremap <buffer> <silent> d :call <SID>FileDiff()<Cr>
nnoremap <buffer> <silent> r :call <SID>CancelStaged()<Cr>
nnoremap <buffer> <silent> R :call <SID>CancelStaged(1)<Cr>
nnoremap <buffer> <silent> a :call <SID>AddFile()<Cr>
nnoremap <buffer> <silent> A :call <SID>AddFile(1)<Cr>
nnoremap <buffer> <silent> \co :call <SID>CheckOutFile()<Cr>
nnoremap <buffer> <silent> ? :call <SID>HelpDoc()<Cr>

augroup Git_status
	autocmd!
	autocmd BufWritePost <buffer> call delete('.Git_status')
augroup END

if exists('*<SID>Refresh')
    finish
endif

function <SID>Refresh(lin)
    silent edit!
    call setline(1, GIT_FormatStatus())
    call cursor(a:lin, 1)
    set filetype=gitstatue
endfunction

function <SID>FileDiff()
    let l:str = split(getline('.'))
    if len(l:str) == 2
        let [l:sign, l:file] = split(system("git status -s -- " . l:str[1]))
        if l:sign =~ 'M' "&& l:sign !～ 'A'
            let l:lin = search('^尚未暂存以备提交的变更\|^Changes not staged for commit', 'n')
            if l:lin == 0 || line('.') < l:lin
                let l:flag = ' -y --cached '
            else
                let l:flag = ' -y '
            endif
            exec '!git difftool' . l:flag . l:file
        endif
    endif
endfunction

function <SID>CancelStaged(...)
    if a:0 > 0
        let l:msg = system('git reset HEAD')
    else
        let l:str = split(getline('.'))
        let l:lin = search('^尚未暂存以备提交的变更\|Changes not staged for commit', 'n')
        if len(l:str) == 2 && (l:lin == 0 || line('.') < l:lin)
            let l:msg = system("git reset HEAD -- " . l:str[1])
        endif
    endif
    if !exists('l:msg')
        return
    elseif l:msg =~ '^error:\|^fatal'
        echo l:msg
    else
        call <SID>Refresh(line('.'))
    endif
endfunction

function <SID>AddFile(...)
    if a:0 > 0
        let l:msg = system('git add .')
    else
        let l:curL = line('.')
        let l:lin = search('^未跟踪的文件\|^Untracked files', 'n')
        if l:lin != 0 && l:curL > l:lin
            let l:msg = system('git add -- ' . getline('.'))
        else
            let l:lin = search('^尚未暂存以备提交的变更\|Changes not staged for commit', 'n')
            let l:str = split(getline('.'))
            if l:lin != 0 && l:curL > l:lin && len(l:str) == 2
                let l:msg = system('git add -- ' . l:str[1])
            endif
        endif
    endif
    if !exists('l:msg')
        return
    elseif l:msg =~ '^error:\|^fatal'
        echo l:msg
    else
        call <SID>Refresh(line('.'))
    endif
endfunction

function <SID>CheckOutFile()
    let l:str = split(getline('.'))
    if len(l:str) == 2
        let l:msg = system('git checkout HEAD -- ' . l:str[1])
        if l:msg =~ '^error:'
            echo l:msg
        else
            call <SID>Refresh(line('.'))
        endif
    endif
endfunction

function <SID>HelpDoc()
    let l:help = [
                \ '* Git Status quick help *',
                \ '===========================================',
                \ '    <C-w>: close tabpage',
                \ '    <S-t>: close tabpage',
                \ '    <f5>:  refresh tabpage',
                \ '    <space>: echo',
                \ '    d:     diff file (difftool: vimdiff)',
                \ '    r:     reset file staging (git reset)',
                \ '    R:     reset all file staging',
                \ '    a:     add file (git add)',
                \ '    A:     add all file',
                \ '    \co:   checkout file (git checkout)'
                \ ]
    echo join(l:help, "\n")
endfunction
