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
    let s:prompt = '>>'
    setlocal complete=s~/.vim/misc/gdb.cmd
    let s:cmdlist = readfile('/home/cy/.vim/misc/shell.cmd')
    nnoremap <buffer> i :call <SID>SendMsg(input("Input a cmd to execute: ", '', 'file'), 0)<CR>
    nnoremap <buffer> q :call <SID>SendMsg('exit', 0)<CR>
elseif &filetype == 'dbg'
    setlocal complete=s~/.vim/misc/shell.cmd
    let s:prompt = '(gdb)'
    let s:cmdlist = readfile('/home/cy/.vim/misc/gdb.cmd')
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
let s:logFile = '.' . &filetype . 'log'
if filereadable(s:logFile)
    let s:history = split(system("sed -n 's/^\$>\\s*\\(\\S\\+.*\\S\\+\\)\\s*$/\\1/p' " . s:logFile . "|uniq"), '\n\+')
else
    let s:history =[]
endif
let s:searchPos = len(s:history)

if !exists("*<SID>ScreenInput")
    function <SID>ScreenInput()
        let l:str = matchstr(getline('$'), '^\(' . s:prompt . '\s*\)\zs\S*.*\S\+')
        if !empty(l:str)
            let s:history += [l:str]
            let s:searchPos = len(s:history)
            call setline(line('$'), ['', '$> ' . l:str, s:prompt . ' '])
            if &filetype == 'gdb'
                call INTERACTIVE_SendMsg(l:str, 1)
            else
                call INTERACTIVE_SendMsg(l:str, 0)
            endif
        else
            call append(line('$'), s:prompt . ' ')
        endif
        normal G$
    endfunction
endif

if !exists("*<SID>SendMsg")
    function <SID>SendMsg(msg, action)
        let l:end = line('$')
        if getline(l:end) =~ '^' . s:prompt
            call setline(l:end, ['', '$> ' . a:msg, s:prompt . ' '])
        else
            call append(l:end, ['', '$> ' . a:msg, s:prompt . ' '])
        endif
        let s:history += [a:msg]
        let s:searchPos = len(s:history)
        call INTERACTIVE_SendMsg(a:msg, a:action)
        normal G$
    endfunction
endif

if !exists("*<SID>GetHistory")
    function <SID>GetHistory(action)
        if a:action == 'next'
            try
                call setline(line('$'), s:prompt . ' ' . s:history[s:searchPos])
                let s:searchPos += 1
            catch
                call setline(line('$'), s:prompt . ' ')
            endtry
        else
            try
                if s:searchPos == 1
                    let s:searchPos = len(s:history)
                    throw 'error'
                endif
                call setline(line('$'), s:prompt . ' ' . s:history[s:searchPos - 1])
                let s:searchPos -= 1
            catch
                call setline(line('$'), s:prompt . ' ')
            endtry
        endif
        normal G$
    endfunction
endif

if !exists("*<SID>GdbCmdComplete")
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
endif

