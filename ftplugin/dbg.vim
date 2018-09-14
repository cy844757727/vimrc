" ===============================
if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1

nnoremap <buffer> a GA
inoremap <buffer> <CR> <Esc>:call <SID>ScreenInput()<CR>A
"inoremap <buffer> <Tab> <C-n>
"inoremap <buffer> <Tab> <C-r>=<SID>GdbCmdComplete()<CR>
nnoremap <buffer> e :call INTERACTIVE__Stop()<CR>

"    setlocal complete=s~/.vim/misc/shell.cmd
nnoremap <buffer> b :call <SID>SendMsg('break ' . input('Enter a line number to insert breakpoint: '))<CR>
nnoremap <buffer> r :call <SID>SendMsg('run')<CR>
nnoremap <buffer> c :call <SID>SendMsg('continue')<CR>
nnoremap <buffer> n :call <SID>SendMsg('next')<CR>
nnoremap <buffer> s :call <SID>SendMsg('step')<CR>
nnoremap <buffer> u :call <SID>SendMsg('until')<CR>
nnoremap <buffer> q :call <SID>SendMsg('quit')<CR>
nnoremap <buffer> i :call <SID>SendMsg(input("Enter the message to be sent: "))<CR>
nnoremap <buffer> p :call <SID>SendMsg('print ' . input("Input the name of the variable to be printed: "))<CR>
nnoremap <buffer> j :call <SID>SendMsg('jump ' . input("Enter a line number to jump: "))<CR>
nnoremap <buffer> <CR> :call <SID>SendMsg('')<CR>

"setlocal complete+=w,b,u

if exists("*<SID>ScreenInput")
    finish
endif

function <SID>ScreenInput()
    let l:str = matchstr(getline('$'), '^\((gdb)\s*\)\zs\S*.*\S\+')
    if !empty(l:str)
        call setline('$', ['', '$> ' . l:str])
        call INTERACTIVE_SendMsg(l:str, 'dbg')
    else
        call append('$', '(gdb) ')
    endif
    normal G$
endfunction

function <SID>SendMsg(msg)
    call setline('$', ['', '$> ' . a:msg])
    call INTERACTIVE_SendMsg(a:msg, 'dbg')
    normal G$
endfunction

