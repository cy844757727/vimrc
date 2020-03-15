""""""""""""""""""""""""""""""""""""""""""""""""""""
" Author: CY <844757727@qq.com>
" Description: git plugin : tabpage manager(log)
""""""""""""""""""""""""""""""""""""""""""""""""""""
if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1
let s:curL = 0

setlocal buftype=nofile

nnoremap <buffer> <space>      :echo matchstr(getline('.'), ' .*$')<CR>
nnoremap <buffer> <silent> t   :call <SID>TagCommit()<CR>
nnoremap <buffer> <silent> c   :call <SID>RefreshCommitA()<CR>
nnoremap <buffer> <silent> C   :call <SID>RefreshCommitA(1)<CR>
nnoremap <buffer> <silent> \l  :Log<CR>
nnoremap <buffer> <silent> \rs :call <SID>Reset('soft')<CR>
nnoremap <buffer> <silent> \Rs :call <SID>Reset('mixed')<CR>
nnoremap <buffer> <silent> \RS :call <SID>Reset('hard')<CR>
nnoremap <buffer> <silent> \rv :call <SID>Revert()<CR>
nnoremap <buffer> <silent> \co :call <SID>CheckOutNewBranck()<CR>
nnoremap <buffer> <silent> m   :call git#Menu(1)<CR>
nnoremap <buffer> <silent> M   :call git#Menu(0)<CR>
nnoremap <buffer> <silent> ?   :call <SID>HelpDoc()<CR>
nnoremap <buffer> <silent> 1   :1wincmd w<CR>
nnoremap <buffer> <silent> 2   :2wincmd w<CR>
nnoremap <buffer> <silent> 3   :3wincmd w<CR>
nnoremap <buffer> <silent> 4   :4wincmd w<CR>


if exists('*<SID>Reset')
    finish
endif

command -nargs=? -complete=file -buffer Log :call s:LogTarget(<q-args>)

augroup Git_log
augroup END


function <SID>RefreshCommitA(...)
    call s:RefreshCommit()

    if a:0 > 0
        autocmd Git_log CursorMoved <buffer> call s:CursorMoved()
    elseif exists('#Git_log#CursorMoved#<buffer>')
        autocmd! Git_log CursorMoved <buffer>
    endif
endfunction


function s:CursorMoved()
    let l:lin = line('.')

    if l:lin == s:curL
        return
    endif

    call s:RefreshCommit()
    let s:curL = l:lin
endfunction


function s:LogTarget(target)
    if empty(a:target) || filereadable(a:target)
        call git#Refresh('log', {'filelog': a:target})
    endif
endfunction


function s:RefreshCommit()
    let l:hash = matchstr(getline('.'), '\w\{7}')

    if !empty(l:hash)
        call git#Refresh('commit', {'commit': l:hash, 'reftype': 'hash'})
        1wincmd w
    endif
endfunction


function <SID>TagCommit()
    let l:hash = matchstr(getline('.'), '\w\{7}')

    if !empty(l:hash)
        let l:tag = input('[option] [-a] [-m Note] Tag ('.l:hash.'): ')
        if l:tag =~# '\S'
            call git#MsgHandle(system('git tag '.l:tag.' '.l:hash), 'all')
        endif
    endif
endfunction


function <SID>Reset(opt)
    let l:hash = matchstr(getline('.'), '\w\{7}')


    if l:hash == '' || input('Are you sure to reset --'.a:opt.' '.l:hash.' (yes/no): ') != 'yes'
        redraw!
        return
    endif

    redraw!
    call git#MsgHandle(system('git reset --'.a:opt.' '.l:hash), 'all')
endfunction


function <SID>Revert(...)
    let l:hash = matchstr(getline('.'), '\w\{7}')

    if l:hash == '' || input('Are you sure to revert '.l:hash.' (yes/no): ') != 'yes'
        redraw!
        return
    endif

    redraw!
    call git#MsgHandle(system('git revert '.l:hash), 'all')
endfunction


function <SID>CheckOutNewBranck()
    let l:hash = matchstr(getline('.'), '\w\{7}')
    if l:hash != ''
        let l:name = input('Enter new branch name(start from '.l:hash.'): ')
        if l:name =~# '\S'
            call git#MsgHandle(system('git stash && git checkout -b '.l:name.' '.l:hash), 'all')
        endif
    endif
endfunction

let s:quickui_doc = [
            \ '    t:           tag commit                 (git tag)',
            \ '    c:           update commit detail       (git show)',
            \ '    C:           update auto                (git show)',
            \ '    \l:          log all                    (git log)',
            \ '    \rs:         reset commit               (git reset --soft)',
            \ '    \Rs:         reset commit               (git reset --mixed)',
            \ '    \RS:         reset commit               (git reset --hard)',
            \ '    \rv:         revert commit              (git revert)',
            \ '    \co:         checkout new branch        (git checkout -b)',
            \ '    1234:        jump to 1234 window'
            \ ]
let s:quickui_opt = {'title': 'Map: log', 'w': 80, 'h': len(s:quickui_doc)}

function <SID>HelpDoc()
    if exists('g:quickui#style#border')
        call quickui#textbox#open(s:quickui_doc, s:quickui_opt)
    else
        echo
                    \ "Git log quick help !?\n".
                    \ "==================================================\n".
                    \ "    t:       tag commit            (git tag)\n".
                    \ "    \\rs:     reset commit          (git reset --soft)\n".
                    \ "    \\Rs:     reset commit          (git reset --mixed)\n".
                    \ "    \\RS:     reset commit          (git reset --hard)\n".
                    \ "    \\rv:     revert commit         (git revert)\n".
                    \ "    \\co:     checkout new branch   (git checkout -b)\n".
                    \ "    1234:    jump to 1234 wimdow"
    endif
endfunction

