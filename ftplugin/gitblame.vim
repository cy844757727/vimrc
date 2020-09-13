
if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1
let b:curL = -1

setlocal buftype=nofile

augroup GIt_blame
    autocmd!
    autocmd BufEnter <buffer> call s:exit_tab()
augroup END


function s:exit_tab()
    if exists('b:target_winid') && !win_id2win(b:target_winid)
        unlet b:target_winid
        let l:pagenr = tabpagenr()
        tabprevious
        exe l:pagenr.'tabclose'
    endif
endfunction

