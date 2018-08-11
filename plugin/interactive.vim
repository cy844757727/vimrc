"
"
"
if exists('loaded_INTERACTIVEVim')
  finish
endif
let loaded_INTERACTIVEVim = 1

sign define DBGSignDef text=➤  texthl=DBGSignHl

let s:newSignId = 100
let s:cmdWinId = -1
let s:sourceWinId = -1
let s:job = -1
let s:channel = -1
let s:dbgSign = []
let s:action = 0
let s:taskType = ''
let s:jobBusy = 0

function s:StartTask(cmd, type)
    if s:jobBusy == 1
        return
    endif
    let s:taskType = a:type
    if a:type == 'dbg'
        call s:DbgInitial(a:cmd)
    else
        call s:DefaultInitial(a:cmd)
    endif
    normal G$
    let s:jobBusy = 1
    let s:job = job_start(a:cmd, {'mode': 'raw', 'callback': 'Interactive_MsgHandle'})
    let s:channel = job_getchannel(s:job)
endfunction

function s:DbgInitial(cmd)
    SWorkSpace
    wall
    silent tabonly
    silent only
    let s:sourceWinId = win_getid()
    bo 15new .dbglog
    let s:cmdWinId = win_getid()
    set filetype=dbg
"    badd ~/.vim/misc/gdb.cmd
    let l:time = system('date')[:-2]
    call append(line('$'), ['', '', '===== Debuging time: ' . l:time . ' =====', '( ' . a:cmd . ' )'])
    write
endfunction

function s:DefaultInitial(cmd)
    let l:nrOfNerd = bufwinnr('NERD_tree')
    let l:nrOfTag = bufwinnr('TagBar')
    NERDTreeClose
    TagbarClose
    bo 15new .shelllog
    let s:cmdWinId = win_getid()
    set filetype=shell
    if l:nrOfNerd != -1
        if l:nrOfTag !=-1
            NERDTree
            TagbarOpen
        else
            NERDTree
        endif
    elseif l:nrOfTag != -1
        let g:tagbar_vertical=0
        let g:tagbar_left=1
        TagbarOpen
        let g:tagbar_vertical=19
        let g:tagbar_left=0
    endif
"    badd ~/.vim/misc/shell.cmd
    call win_gotoid(s:cmdWinId)
    if s:taskType == 'bash'
        call append(line('$'), ['', '( ' . a:cmd . ' )', '>> '])
        write
    endif
endfunction

function s:SendMsg(msg, action)
    let @z = ''
    let s:action = a:action
    try
        call ch_sendraw(s:channel, a:msg . "\n")
    catch
        call win_gotoid(s:cmdWinId)
        write
        bdelete
        let s:jobBusy = 0
        if s:taskType == 'dbg'
            if !empty(s:dbgSign)
                exec 'sign unplace ' . s:dbgSign[1] . ' file=' . s:dbgSign[0]
            endif
            let s:dbgSign = []
"            bdelete ~/.vim/misc/gdb.cmd
            LWorkSpace
"        elseif s:taskType == 'bash'
"            bdelete ~/.vim/misc/shell.cmd
        endif
    endtry
endfunction

function! Interactive_MsgHandle(channel, msg)
    let @Z = a:msg
    call win_gotoid(s:cmdWinId)
    if getline(line('$')) =~ '^>>\|(gdb)'
        normal Gdd
    endif
    if s:taskType == 'dbg'
        call append(line('$'), split(a:msg, '\n\+'))
    elseif s:taskType == 'bash'
        call append(line('$'), split(a:msg, '\n') + ['>> '])
    else
        call append(line('$'), split(a:msg, '\n'))
    endif
    normal G$
    write
    if s:action == 1
        call s:DbgJumpLine(a:msg)
    endif
endfunction

function s:DbgJumpLine(msg)
    call win_gotoid(s:sourceWinId)
    let l:str = split(matchstr(a:msg, '[^ \n]\+:\d\+'), ':')
    let l:line = matchstr(a:msg, '^\d\+')
    if !empty(l:str)
        if filereadable(l:str[0])
            exec 'edit ' . l:str[0]
            call cursor(l:str[1], 1)
        else
            return
        endif
    elseif !empty(l:line)
        call cursor(l:line, 1)
    else
        call win_gotoid(s:cmdWinId)
        return
    endif
    if !empty(s:dbgSign)
        exec 'sign unplace ' . s:dbgSign[1] . ' file=' . s:dbgSign[0]
    endif
    let l:file = expand('%') | let l:line = line('.')
    let l:tmp = @z
    redir @z
    silent sign place
    redir END
    while !empty(matchlist(@z, '    \S\+=\d\+' . '  id=' . s:newSignId . '  '))
        let s:newSignId += 1
    endwhile
    exec 'sign place ' . s:newSignId . ' line=' . l:line . ' name=DBGSignDef' . ' file=' . l:file
    let @z = l:tmp
    let s:dbgSign = [l:file, s:newSignId]
    call win_gotoid(s:cmdWinId)
endfunction
" ==========================================================
" ==========================================================
" ==========================================================
function! INTERACTIVE__Stop()
    if s:taskType == 'dbg'
        let l:msg = 'quit'
    elseif s:taskType == 'bash'
        let l:msg = 'exit'
    else
        let l:msg = 'exit'
    endif
    call s:SendMsg(l:msg, 0)
    let l:timer = timer_start(100, function(INTERACTIVE_SendMsg('', 0)))
"    call s:SendMsg(l:msg, 0)
endfunction

function! INTERACTIVE_SendMsg(msg, action)
    call s:SendMsg(a:msg, a:action)
endfunction

function! INTERACTIVE_Start(cmd, type)
    if a:type == 'dbg'
        if a:cmd == ''
            let l:target = system("sed -n 's/^EXEF\\s*:=\\s*//p' Makefile")[:-2]
            if l:target =~ '\S\+'
                let l:cmd = 'gdb -q -x .breakpoint ' . l:target
            endif
        else
            if a:cmd =~ '^\s*gdb\s\+'
                let l:cmd = a:cmd
            else
                let l:cmd = 'gdb -q -x .breakpoint ' . a:cmd
            endif
        endif
    elseif a:type == 'bash' && a:cmd == ''
        let l:cmd = 'bash'
    else
        let l:cmd = a:cmd
    endif
    call s:StartTask(l:cmd, a:type)
endfunction

command -nargs=* -complete=file SDebug :call INTERACTIVE_Start(<q-args>, 'dbg')
command -nargs=* -complete=file SShell :call INTERACTIVE_Start(<q-args>, 'bash')

