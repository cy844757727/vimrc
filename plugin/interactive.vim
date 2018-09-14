"
"
"
if exists('loaded_INTERACTIVEVim')
  finish
endif
let loaded_INTERACTIVEVim = 1

" 标记组定义
hi DBGSignHl  ctermbg=38  ctermfg=231
sign define DBGSignDef text=➤  texthl=DBGSignHl

let s:newSignId = 100
let s:cmdWinId = -1
let s:sourceWinId = -1
let s:dbgSign = []
let s:action = 0
let s:jobBusy = 0

command! -nargs=+ -complete=file Async :call job_start("<args>", {'in_io': 'null', 'out_io': 'null', 'err_io': 'null'})

function s:DbgInitial(cmd)
    if s:jobBusy == 1
        return
    else
        let s:jobBusy = 1
    endif
    SWorkSpace
    wall
    silent tabonly
    silent only
    let s:sourceWinId = win_getid()
    bo 15new .dbglog
    let s:dbgWinId = win_getid()
    set buftype=nofile
    set filetype=dbg
"    set bufhidden=wipe
    let l:time = system('date')[:-2]
    call setline(1, ['', '', '===== Debuging time: ' . l:time . ' =====', '( ' . a:cmd . ' )'])
    normal G$
    let s:dbgJob = job_start(a:cmd, {'mode': 'raw', 'callback': 'Interactive_DbgMsgHandle'})
    let s:dbgChannel = job_getchannel(s:dbgJob)
endfunction

function! Interactive_DbgMsgHandle(channel, msg)
    call win_gotoid(s:dbgWinId)
    call append(line('$'), split(a:msg, '\n\+'))
    normal G$
    if s:action == 1
        call s:DbgJumpLine(a:msg)
        call win_gotoid(s:dbgWinId)
    endif
endfunction

function s:DbgSendMsg(msg)
    let s:action = a:msg =~ '^\([rcnsu]\|run\|continue\|next\|step\|until\)$\|^\(j\|jump\) ' ? 1 : 0
    try
        call ch_sendraw(s:dbgChannel, a:msg . "\n")
    catch
        call win_gotoid(s:dbgWinId)
        bdelete
        let s:jobBusy = 0
        if !empty(s:dbgSign)
            exec 'sign unplace ' . s:dbgSign[1] . ' file=' . s:dbgSign[0]
        endif
        let s:dbgSign = []
        LWorkSpace
    endtry
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
        return
    endif
    if !empty(s:dbgSign)
        exec 'sign unplace ' . s:dbgSign[1] . ' file=' . s:dbgSign[0]
    endif
    let [l:file, l:line] = [expand('%'), line('.')]
    let l:signPlace = execute('sign place')
    while !empty(matchlist(l:signPlace, '    \S\+=\d\+' . '  id=' . s:newSignId . '  '))
        let s:newSignId += 1
    endwhile
    exec 'sign place ' . s:newSignId . ' line=' . l:line . ' name=DBGSignDef' . ' file=' . l:file
    let s:dbgSign = [l:file, s:newSignId]
endfunction

"========================================================================================================
"========================================================================================================
function s:ShellInitial(cmd)
    let l:nrOfNerd = bufwinnr('NERD_tree')
    let l:nrOfTag = bufwinnr('TagBar')
    NERDTreeClose
    TagbarClose
    bo 15new .shelllog
    set filetype=shell
    set buftype=nofile
    let s:shellWinId = win_getid()
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
    call win_gotoid(s:cmdWinId)
    call setline(1, ['', '( ' . a:cmd . ' )', '>> '])
    normal G$
    let s:jobBusy = 1
    let s:shellJob = job_start(a:cmd, {'mode': 'raw', 'callback': 'Interactive_ShellMsgHandle'})
    let s:shellChannel = job_getchannel(s:shellJob)
endfunction

function! Interactive_ShellMsgHandle(channel, msg)
    call win_gotoid(s:shellWinId)
    if getline('$') =~ '^>> $'
        normal Gdd
    endif
    call append(line('$'), split(a:msg, '\n'))
    if getline('$') !~ '^>>'
        call append('$', ['>> '])
    endif
    normal G$
endfunction

function s:ShellSendMsg(msg)
    try
        call ch_sendraw(s:shellChannel, a:msg . "\n")
    catch
        call win_gotoid(s:shellWinId)
        bdelete
        let s:jobBusy = 0
    endtry
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

function! INTERACTIVE_SendMsg(msg, type)
    if a:type == 'dbg'
        call s:DbgSendMsg(a:msg)
    elseif a:type == 'shell'
        cal s:ShellSendMsg(a:msg)
    endif
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
        call s:DbgInitial(l:cmd)
    elseif a:type == 'shell'
        call s:ShellInitial(a:cmd == '' ? 'bash' : a:cmd)
    endif
endfunction

command -nargs=* -complete=file SDebug :call INTERACTIVE_Start(<q-args>, 'dbg')
command -nargs=* -complete=file Dbg :call INTERACTIVE_Start(<q-args>, 'dbg')
command -nargs=* -complete=file SShell :call INTERACTIVE_Start(<q-args>, 'shell')

