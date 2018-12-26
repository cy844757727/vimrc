""""""""""""""""""""""""""""""""""""""""""""""""""""
" Author: CY <844757727@qq.com>
" Description: git plugin : tabpage manager(log)
""""""""""""""""""""""""""""""""""""""""""""""""""""
if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1
let b:curL = -1

setlocal nonu
setlocal nowrap
setlocal buftype=nofile
setlocal foldcolumn=0
setlocal statusline=%2(\ %)\ Log%=%2(\ %)

nnoremap <buffer> <silent> t :call <SID>TagCommit()<CR>
nnoremap <buffer> <silent> \rs :call <SID>Reset_Revert_Commit(1)<CR>
nnoremap <buffer> <silent> \rv :call <SID>Reset_Revert_Commit()<CR>
nnoremap <buffer> <silent> \co :call <SID>CheckOutNewBranck()<CR>
nnoremap <buffer> <silent> m :call git#MainMenu()<CR>
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
            setlocal noreadonly modifiable
            silent edit!
            call setline(1, git#FormatCommit(l:hash))
            set filetype=gitcommit
            set nobuflisted
            setlocal foldminlines=1
            normal zj
            setlocal readonly nomodifiable
            wincmd W
        endif
    endif
endfunction

function s:MsgHandle(msg)
    if a:msg =~ 'error:\|fatal:'
        echo a:msg
    else
        call git#Refresh()
    endif
endfunction

function <SID>TagCommit()
    let l:hash = matchstr(getline('.'), '\w\{7}')
    if l:hash != ''
        let l:tag = input('Input a tag: ')
        if l:tag != ''
            let l:note = input('Enter a note: ')
            let l:tag = l:note == '' ? l:tag . ' ' : '-a ' . l:tag . " -m '"  . l:note . "' "
            call s:MsgHandle(system('git tag ' . l:tag . l:hash))
        endif
    endif
endfunction

function <SID>Reset_Revert_Commit(...)
    let l:hash = matchstr(getline('.'), '\w\{7}')
    if l:hash == '' || input('Are you sure to reset/revert commit(yes/no): ') != 'yes'
        redraw!
        return
    elseif a:0 == 0
        let l:op = 'revert '
    else
        let l:op = 'reset --hard '
    endif
    redraw!
    call s:MsgHandle(system('git ' . l:op . l:hash))
endfunction

function <SID>CheckOutNewBranck()
    let l:hash = matchstr(getline('.'), '\w\{7}')
    if l:hash != ''
        let l:name = input('Enter new branch name(start from ' . l:hash . '): ')
        if l:name != ''
            call s:MsgHandle(system('git stash && git checkout -b ' . l:name . ' ' . l:hash))
        endif
    endif
endfunction

function <SID>HelpDoc()
    echo
                \ "Git log quick help !?\n" .
                \ "==================================================\n" .
                \ "    m:       git menu\n" .
                \ "    t:       tag commit            (git tag)\n" .
                \ "    \\rs:     reset commit          (git reset --hard)\n" .
                \ "    \\rv:     revert commit         (git revert)\n" .
                \ "    \\co:     checkout new branch   (git checkout -b)\n" .
                \ "    1234:    jump to 1234 wimdow"
endfunction

