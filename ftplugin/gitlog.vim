"
"
"
if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1
let b:curL = -1

setlocal nonu
setlocal nowrap
setlocal statusline=[log]%=\ \ \ \ \ %-10.(%l:%c%V%)\ %4P\ 

nnoremap <buffer> <C-w> :call GIT_CloseTab()<Cr>
nnoremap <buffer> <S-t> :call GIT_CloseTab()<Cr>
nnoremap <buffer> <f5>  :call GIT_Refresh()<Cr>
nnoremap <buffer> <space> :echo matchstr(getline('.'), '💬.*$')<Cr>
nnoremap <buffer> <silent> \rs :call <SID>Reset_Revert_Commit(1)<Cr>
nnoremap <buffer> <silent> \rv :call <SID>Reset_Revert_Commit()<Cr>
nnoremap <buffer> <silent> \co :call <SID>CheckOutNewBranck()<Cr>
nnoremap <buffer> ?     :call <SID>HelpDoc()<Cr>

augroup Git_log
	autocmd!
	autocmd CursorMoved <buffer> call s:RefreshCommit()
augroup END

if exists('*<SID>Reset_Revert_Commit')
    finish
endif

function s:RefreshCommit()
    if line('.') != b:curL
        let b:curL = line('.')
        let l:hash = matchstr(getline('.'), '\w\{7}')
        if l:hash != ''
            wincmd w
            silent edit!
            call setline(1, GIT_FormatCommit(l:hash))
            filetype detect
            wincmd W
        endif
    endif
endfunction

function <SID>Reset_Revert_Commit(...)
    let l:hash = matchstr(getline('.'), '\w\{7}')
    if l:hash != ''
        let l:op = a:0 > 0 ? ' reset --hard ' : ' revert '
        let l:msg = system('git' . l:op . l:hash)
        if l:msg =~ '^error:\|^fatal:'
            echo l:msg
        else
            call GIT_Refresh()
        endif
    endif
endfunction

function <SID>CheckOutNewBranck()
    let l:hash = matchstr(getline('.'), '\w\{7}')
    if l:hash != ''
        let l:name = input('Enter new branch name(start from ' . l:hash . '): ')
        if l:name != ''
            let l:msg = system('git checkout -b ' . l:name . ' ' . l:hash)
            if l:msg =~ '^error:\|^fatal:'
                echo l:msg
            else
                call GIT_Refresh()
            endif
        else
            echo '    Abort'
        endif
    endif
endfunction

function <SID>HelpDoc()
    let l:help = [
                \ '* Git log quick help *',
                \ '=============================',
                \ '    <C-w>:   close tabpage',
                \ '    <S-t>:   close tabpage',
                \ '    <f5>:    refresh tabpage',
                \ '    <space>: echo',
                \ '    \rs:     reset commit (carefull)',
                \ '    \rv:     revert commit',
                \ '    \co:     checkout new branch'
                \ ]
    echo join(l:help, "\n")
endfunction

