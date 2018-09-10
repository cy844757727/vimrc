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

nnoremap <buffer> <silent> t :call <SID>TagCommit()<CR>
nnoremap <buffer> <silent> \rs :call <SID>Reset_Revert_Commit(1)<CR>
nnoremap <buffer> <silent> \rv :call <SID>Reset_Revert_Commit()<CR>
nnoremap <buffer> <silent> \co :call <SID>CheckOutNewBranck()<CR>
nnoremap <buffer> <silent> m :call GIT_MainMenu()<CR>
nnoremap <buffer> <silent> ? :call <SID>HelpDoc()<CR>
nnoremap <buffer> <silent> 1 :1wincmd w<CR>
nnoremap <buffer> <silent> 2 :2wincmd w<CR>
nnoremap <buffer> <silent> 3 :3wincmd w<CR>
nnoremap <buffer> <silent> 4 :4wincmd w<CR>

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

function s:MsgHandle(msg)
    if a:msg =~ 'error:\|fatal:'
        echo a:msg
    else
        call GIT_Refresh()
    endif
endfunction

function <SID>TagCommit()
    let l:hash = matchstr(getline('.'), '\w\{7}')
    if l:hash != ''
        let l:tag = input('Input a tag: ')
        if l:tag != ''
            let l:note = input('Enter a note: ')
            let l:tag = l:note == '' ? l:tag . ' ' : '-a ' . l:tag . " -m '"  . l:note . "' "
            let l:msg = system('git tag ' . l:tag . l:hash)
            call s:MsgHandle(l:msg)
        endif
    endif
endfunction

function <SID>Reset_Revert_Commit(...)
    let l:hash = matchstr(getline('.'), '\w\{7}')
    if l:hash == ''
        return
    elseif a:0 == 0
        let l:op = 'revert '
    elseif input('Are you sure to reset commit which will cover workspace yes/no(no): ') == 'yes'
        let l:op = 'reset --hard '
    else
        redraw!
        return
    endif
    let l:msg = system('git ' . l:op . l:hash)
    call s:MsgHandle(l:msg)
endfunction

function <SID>CheckOutNewBranck()
    let l:hash = matchstr(getline('.'), '\w\{7}')
    if l:hash != ''
        let l:name = input('Enter new branch name(start from ' . l:hash . '): ')
        if l:name != ''
            let l:msg = system('git checkout -b ' . l:name . ' ' . l:hash)
            call s:MsgHandle(l:msg)
        else
            echo '    Abort'
        endif
    endif
endfunction

function <SID>HelpDoc()
    echo
                \ "Git log quick help !?\n" .
                \ "==================================================\n" .
                \ "    m:       git menu\n" .
                \ "    t:       tag commit\n" .
                \ "    \\rs:     reset commit (carefull)\n" .
                \ "    \\rv:     revert commit\n" .
                \ "    \\co:     checkout new branch\n" .
                \ "    1234:    jump to 1234 wimdow"
endfunction

