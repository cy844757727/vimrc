""""""""""""""""""""""""""""""""""""""""""""""""""""
" Name: git plugin : tabpage manager(log)
" Author: CY <844757727@qq.com>
""""""""""""""""""""""""""""""""""""""""""""""""""""
if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1
let b:curL = -1


setlocal nonu
setlocal nowrap
setlocal buftype=nofile
setlocal statusline=\ [1-Log]%=\ \ \ \ \ %-5l\ %4P\ 

nnoremap <buffer> <f5>  :call GIT_Refresh()<Cr>
nnoremap <buffer> <space> :echo matchstr(getline('.'), '💬.*$')<Cr>
nnoremap <buffer> <silent> t :call <SID>TagCommit()<Cr>
nnoremap <buffer> <silent> \rs :call <SID>Reset_Revert_Commit(1)<Cr>
nnoremap <buffer> <silent> \rv :call <SID>Reset_Revert_Commit()<Cr>
nnoremap <buffer> <silent> \co :call <SID>CheckOutNewBranck()<Cr>
nnoremap <buffer> <silent> m :call GIT_Menu()<Cr>
nnoremap <buffer> <silent> ? :call <SID>HelpDoc()<Cr>
nnoremap <buffer> <silent> 1 :1wincmd w<Cr>
nnoremap <buffer> <silent> 2 :2wincmd w<Cr>
nnoremap <buffer> <silent> 3 :3wincmd w<Cr>
nnoremap <buffer> <silent> 4 :4wincmd w<Cr>


augroup Git_log
	autocmd!
	autocmd CursorMoved <buffer> call s:RefreshCommit()
    autocmd BufLeave <buffer> let b:curL = -1
augroup END

if exists('*<SID>Reset_Revert_Commit')
    finish
endif

function s:RefreshCommit()
    if line('.') != b:curL
        let l:end = line('$')
        let l:op = b:curL - line('.') == 1 ? 'k' : 'j'
        while line('.') != l:end && getline('.') !~ '\d'
            exec 'normal ' . l:op
            if line('.') == 1
                let l:op = 'j'
            endif
        endwhile
        let b:curL = line('.')
        let l:hash = matchstr(getline('.'), '\w\{7}')
        if l:hash != ''
            wincmd w
            silent edit!
            call setline(1, GIT_FormatCommit(l:hash))
            set filetype=gitcommit
            set nobuflisted
            normal zj
            wincmd W
        endif
    endif
endfunction

function <SID>TagCommit()
    let l:hash = matchstr(getline('.'), '\w\{7}')
    if l:hash != ''
        let l:tag = input('Input a tag: ')
        if l:tag != ''
            let l:note = input('Enter a note: ')
            let l:tag = l:note == '' ? l:tag : ' -a ' . l:tag . " -m '"  . l:note . "'"
            let l:msg = system('git tag' . l:tag . ' ' . l:hash)
        endif
        if l:msg =~ 'error:\|fatal:'
            echo l:msg
        else
            call GIT_Refresh()
        endif
    endif
endfunction

function <SID>Reset_Revert_Commit(...)
    let l:hash = matchstr(getline('.'), '\w\{7}')
    if l:hash != ''
        let l:op = a:0 > 0 ? ' reset --hard ' : ' revert '
        let l:msg = system('git' . l:op . l:hash)
        if l:msg =~ 'error:\|fatal:'
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
            if l:msg =~ 'error:\|fatal:'
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
                \ 'Git log quick help !?',
                \ '==================================================',
                \ '    <space>: echo',
                \ '    <f5>:    refresh tabpage',
                \ '    m:       git menu',
                \ '    t:       tag commit',
                \ '    \rs:     reset commit (carefull)',
                \ '    \rv:     revert commit',
                \ '    \co:     checkout new branch',
                \ '    1234:    jump to 1234 wimdow'
                \ ]
    echo join(l:help, "\n")
endfunction

