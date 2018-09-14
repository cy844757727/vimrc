" ===============================
if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1

nnoremap <buffer> a GA
inoremap <buffer> <CR> <Esc>:call <SID>ScreenInput()<CR>A
"inoremap <buffer> <up> <Esc>:call <SID>GetHistory('previous')<CR>A
"inoremap <buffer> <down> <Esc>:call <SID>GetHistory('next')<CR>A
"inoremap <buffer> <Tab> <C-n>
"inoremap <buffer> <Tab> <C-r>=<SID>GdbCmdComplete()<CR>
nnoremap <buffer> e :call INTERACTIVE__Stop()<CR>

setlocal complete=s~/.vim/misc/gdb.cmd
nnoremap <buffer> i :call <SID>SendMsg(input("Input a cmd to execute: ", '', 'file'))<CR>
nnoremap <buffer> q :call <SID>SendMsg('exit')<CR>

setlocal complete+=w,b,u

if exists("*<SID>ScreenInput")
    finish
endif

function <SID>ScreenInput()
    let l:str = matchstr(getline('$'), '^\(>>\s*\)\zs\S*.*\S\+')
    if !empty(l:str)
        call setline(line('$'), ['', '$> ' . l:str, '>> '])
        call INTERACTIVE_SendMsg(l:str, 'shell')
    else
        call append(line('$'), '>> ')
    endif
    normal G$
endfunction

function <SID>SendMsg(msg)
    if getline('$') =~ '^>>'
        call setline('$', ['', '$> ' . a:msg, '>> '])
    else
        call append('$', ['', '$> ' . a:msg, '>> '])
    endif
    call INTERACTIVE_SendMsg(a:msg, 'shell')
    normal G$
endfunction

"function <SID>GdbCmdComplete()
"    let l:ind = 5 
"    let l:str = getline(line('$'))
"    let l:len = len(l:str)
"    while l:str[l:ind] !~ '\w' && l:ind <= l:len
"        let l:ind += 1
"    endwhile
"    call complete(l:ind + 1, s:cmdlist)
"    return ''
"endfunction

