"
"
"

sign define DBGCurrent text=⏩ texthl=NormalSign
let s:newSignId = 0

" 
function! dbg#start(file, cmd, args, prompt, re)
    exe 'tabe ' . a:file
    let t:re = a:re
    let t:prompt = a:prompt
    let t:srcWinId = win_getid()
    let t:tempMsg = ''
    belowright 15split
    let t:dbgWinId = win_getid()
    let t:dbgBufnr = term_start(a:cmd, {
                \ 'term_rows': 15,
                \ 'out_cb': 'DBGMsgHandle',
                \ 'exit_cb': 'DBGExitHandle',
                \ 'term_kill': 'q',
                \ 'term_finish': 'close', 
                \ 'norestore': 1,
                \ 'curwin': 1
                \ })

    if !empty(a:args)
        call term_sendkeys(t:dbgBufnr, a:args . "\n")
    endif
endfunction

" 
function! DBGMsgHandle(handle, msg)
    if a:msg =~ t:prompt
        let t:match = matchlist(t:tempMsg . a:msg, t:re)
        let t:tempMsg = ''

        if !empty(t:match) && filereadable(t:match[1])
            call win_gotoid(t:srcWinId)
            exe 'edit ' . t:match[1]
            call cursor(t:match[2], 1)
            call s:setSign(expand('%'), t:match[2])
            call win_gotoid(t:dbgWinId)
        endif
    else
        let t:tempMsg .= a:msg
    endif
endfunction

" 
function! s:setSign(file, line)
    let l:signPlace = execute('sign place file=' . a:file)

    if exists('t:sign') && !empty(t:sign)
        exe 'sign unplace ' . t:sign.id . ' file=' . t:sign.file
    endif

    " Ensure id uniqueness
    let s:newSignId += 1
    while !empty(matchlist(l:signPlace, '    \S\+=\d\+' . '  id=' . s:newSignId . '  '))
        let s:newSignId += 1
    endwhile

    exe 'sign place ' . s:newSignId . ' line=' . a:line . ' name=DBGCurrent' . ' file=' . a:file
    let t:sign = {'id': s:newSignId, 'file': a:file}
endfunction

" 
function! DBGExitHandle(...)
    if exists('t:sign') && !empty(t:sign)
        exe 'sign unplace ' . t:sign.id . ' file=' . t:sign.file
        unlet t:sign
    endif

    if exists('t:dbgWinId')
        try
            tabclose
        catch
            call win_gotoid(t:srcWinId)
            unlet t:start
            unlet t:re
            unlet t:prompt
            unlet t:tempMsg
            unlet t:srcWinId
            unlet t:dbgWinId
            unlet t:dbgBufnr
            unlet t:match
        endtry
    endif
endfunction

