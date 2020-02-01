""""""""""""""""""""""""""""""""""""""""""""""""""""
" Author: CY <844757727@qq.com>
" Description: git plugin : tabpage manager(log)
""""""""""""""""""""""""""""""""""""""""""""""""""""
if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1
let b:curL = -1

setlocal buftype=nofile
setlocal statusline=%2(\ %)\ Log%=%2(\ %)
let b:statuslineBase = '%2( %) Log%=%2( %)'

nnoremap <buffer> <silent> <space> :echo matchstr(getline('.'), ' .*$')<CR>
nnoremap <buffer> <silent> t :call <SID>TagCommit()<CR>
nnoremap <buffer> <silent> c :call <SID>RefreshCommitA()<CR>
nnoremap <buffer> <silent> C :call <SID>RefreshCommitA(1)<CR>
nnoremap <buffer> <silent> \rs :call <SID>Reset_Revert_Commit(1)<CR>
nnoremap <buffer> <silent> \rv :call <SID>Reset_Revert_Commit()<CR>
nnoremap <buffer> <silent> \co :call <SID>CheckOutNewBranck()<CR>
nnoremap <buffer> <silent> m :call git#Menu(1)<CR>
nnoremap <buffer> <silent> M :call git#Menu(0)<CR>
nnoremap <buffer> <silent> ? :call <SID>HelpDoc()<CR>
nnoremap <buffer> <silent> 1 :1wincmd w<CR>
nnoremap <buffer> <silent> 2 :2wincmd w<CR>
nnoremap <buffer> <silent> 3 :3wincmd w<CR>
nnoremap <buffer> <silent> 4 :4wincmd w<CR>


if exists('*<SID>Reset_Revert_Commit')
    finish
endif

command -nargs=? -complete=file -buffer Log :call s:LogTarget(<q-args>)

augroup Git_log
augroup END

function <SID>RefreshCommitA(...)
    call s:RefreshCommit()

    if a:0 > 0
        autocmd Git_log CursorMoved <buffer> call s:RefreshCommit()
    elseif exists('#Git_log#CursorMoved#<buffer>')
        autocmd! Git_log CursorMoved <buffer>
    endif
endfunction

function s:LogTarget(target)
    if empty(a:target) || filereadable(a:target)
        silent edit!
        setlocal modifiable
        call setline(1, git#FormatLog(a:target))
        let l:list = split(b:statuslineBase, '%=')
        let &l:statusline = l:list[0] . ' -- ' . a:target . '%=' . l:list[1]
        setlocal nomodifiable
    endif
endfunction

function s:RefreshCommit()
    let l:hash = matchstr(getline('.'), '\w\{7}')

    if !empty(l:hash)
        wincmd w
        setlocal noreadonly modifiable
        silent edit!
        call setline(1, git#FormatCommit(l:hash))
        set filetype=gitcommit
        setlocal foldminlines=1
        setlocal nobuflisted readonly nomodifiable
        normal zj
        wincmd W
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

    if !empty(l:hash)
        let l:tag = input('[option] [-a] [-m Note] Tag ('.l:hash.'): ')
        if l:tag =~# '\S'
            call s:MsgHandle(system('git tag '.l:tag.' '.l:hash))
        endif
    endif
endfunction

function <SID>Reset_Revert_Commit(...)
    let l:hash = matchstr(getline('.'), '\w\{7}')

    if l:hash == '' || input('Are you sure to reset/revert commit(yes/no): ') != 'yes'
        redraw!
        return
    endif

    redraw!
    call s:MsgHandle(system('git '.(a:0 == 0 ? 'revert ' : 'reset --hard ').l:hash))
endfunction

function <SID>CheckOutNewBranck()
    let l:hash = matchstr(getline('.'), '\w\{7}')
    if l:hash != ''
        let l:name = input('Enter new branch name(start from '.l:hash.'): ')
        if l:name =~# '\S'
            call s:MsgHandle(system('git stash && git checkout -b '.l:name.' '.l:hash))
        endif
    endif
endfunction

function <SID>HelpDoc()
    echo
                \ "Git log quick help !?\n".
                \ "==================================================\n".
                \ "    t:       tag commit            (git tag)\n".
                \ "    \\rs:     reset commit          (git reset --hard)\n".
                \ "    \\rv:     revert commit         (git revert)\n".
                \ "    \\co:     checkout new branch   (git checkout -b)\n".
                \ "    1234:    jump to 1234 wimdow"
endfunction

