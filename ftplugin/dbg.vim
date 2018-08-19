" ===============================
if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1

nnoremap <buffer> a GA
inoremap <buffer> <CR> <Esc>:call <SID>ScreenInput()<CR>A
inoremap <buffer> <up> <Esc>:call <SID>GetHistory('previous')<CR>A
inoremap <buffer> <down> <Esc>:call <SID>GetHistory('next')<CR>A
"inoremap <buffer> <Tab> <C-n>
inoremap <buffer> <Tab> <C-r>=<SID>GdbCmdComplete()<CR>
nnoremap <buffer> e :call INTERACTIVE__Stop()<CR>

if &filetype == 'shell'
    let b:prompt = '>>'
    setlocal complete=s~/.vim/misc/gdb.cmd
"    let s:cmdlist = readfile('~/.vim/misc/shell.cmd')
    nnoremap <buffer> i :call <SID>SendMsg(input("Input a cmd to execute: ", '', 'file'), 0)<CR>
    nnoremap <buffer> q :call <SID>SendMsg('exit', 0)<CR>
elseif &filetype == 'dbg'
    setlocal complete=s~/.vim/misc/shell.cmd
    let b:prompt = '(gdb)'
"    let s:cmdlist = readfile('~/.vim/misc/gdb.cmd')
    nnoremap <buffer> b :call <SID>SendMsg('break ' . input('Enter a line number to insert breakpoint: '), 1)<CR>
    nnoremap <buffer> r :call <SID>SendMsg('run', 1)<CR>
    nnoremap <buffer> c :call <SID>SendMsg('continue', 1)<CR>
    nnoremap <buffer> n :call <SID>SendMsg('next', 1)<CR>
    nnoremap <buffer> s :call <SID>SendMsg('step', 1)<CR>
    nnoremap <buffer> u :call <SID>SendMsg('until', 1)<CR>
    nnoremap <buffer> q :call <SID>SendMsg('quit', 0)<CR>
    nnoremap <buffer> i :call <SID>SendMsg(input("Enter the message to be sent: "), 0)<CR>
    nnoremap <buffer> p :call <SID>SendMsg('print ' . input("Input the name of the variable to be printed: "), 0)<CR>
    nnoremap <buffer> j :call <SID>SendMsg('jump ' . input("Enter a line number to jump: "), 1)<CR>
    nnoremap <buffer> <CR> :call <SID>SendMsg('', 1)<CR>
endif

setlocal complete+=w,b,u
let b:logFile = '.' . &filetype . 'log'
if filereadable(b:logFile)
    let b:history = split(system("sed -n 's/^\$>\\s*\\(\\S\\+.*\\S\\+\\)\\s*$/\\1/p' " . b:logFile . "|uniq"), '\n\+')
else
    let b:history =[]
endif
let b:searchPos = len(b:history)

if exists("*<SID>ScreenInput")
    finish
endif

function <SID>ScreenInput()
    let l:str = matchstr(getline('$'), '^\(' . b:prompt . '\s*\)\zs\S*.*\S\+')
    if !empty(l:str)
        let b:history += [l:str]
        let b:searchPos = len(b:history)
        call setline(line('$'), ['', '$> ' . l:str, b:prompt . ' '])
        if &filetype == 'gdb'
            call INTERACTIVE_SendMsg(l:str, 1)
        else
            call INTERACTIVE_SendMsg(l:str, 0)
        endif
    else
        call append(line('$'), b:prompt . ' ')
    endif
    normal G$
endfunction

function <SID>SendMsg(msg, action)
    let l:end = line('$')
    if getline(l:end) =~ '^' . b:prompt
        call setline(l:end, ['', '$> ' . a:msg, b:prompt . ' '])
    else
        call append(l:end, ['', '$> ' . a:msg, b:prompt . ' '])
    endif
    let b:history += [a:msg]
    let b:searchPos = len(b:history)
    call INTERACTIVE_SendMsg(a:msg, a:action)
    normal G$
endfunction

function <SID>GetHistory(action)
    if a:action == 'next'
        try
            call setline(line('$'), s:prompt . ' ' . s:history[b:searchPos])
            let b:searchPos += 1
        catch
            call setline(line('$'), s:prompt . ' ')
        endtry
    else
        try
            if b:searchPos == 1
                let b:searchPos = len(s:history)
                throw 'error'
            endif
            call setline(line('$'), s:prompt . ' ' . s:history[b:searchPos - 1])
            let b:searchPos -= 1
        catch
            call setline(line('$'), s:prompt . ' ')
        endtry
    endif
    normal G$
endfunction

function <SID>GdbCmdComplete()
    let l:ind = 5 
    let l:str = getline(line('$'))
    let l:len = len(l:str)
    while l:str[l:ind] !~ '\w' && l:ind <= l:len
        let l:ind += 1
    endwhile
    call complete(l:ind + 1, s:cmdlist)
    return ''
endfunction

