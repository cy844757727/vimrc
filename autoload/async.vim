""""""""""""""""""""""""""""""""""""""""""""""""""""
" Author: CY <844757727@qq.com>
" Description: Asynchronous task
""""""""""""""""""""""""""""""""""""""""""""""""""""

"if exists('g:loaded_A_Async') || v:version < 800
"  finish
"endif
"let g:loaded_A_Async = 1

hi AsyncDbgHl ctermbg=253 ctermfg=16 guibg=#1E1E1E guifg=#CCCCB0
sign define DBGCurrent text=⏩ texthl=AsyncDbgHl

let s:newSignId = 1
" Get default shell interpreter
let s:shell = fnamemodify(&shell, ':t')
let s:termPrefix = '!Terminal'
let s:termIcon = {
            \ '1': ' ➊ ', '2': ' ➋ ', '3': ' ➌ ',
            \ '4': ' ➍ ', '5': ' ➎ ', '6': ' ➏ ',
            \ '7': ' ➐ ', '8': ' ➑ ', '9': ' ➒ '
            \ }

" ""
" Default terminal option
let s:termOption = {
            \ 'term_rows': 15,
            \ 'term_kill': 'kill',
            \ 'term_finish': 'close',
            \ 'stoponexit': 'exit',
            \ 'norestore': 1
            \ }

" Default terminal type
let s:termType = {
            \ s:shell: s:shell,
            \ s:shell . '1': s:shell,
            \ s:shell . '2': s:shell,
            \ s:shell . '3': s:shell,
            \ s:shell . '4': s:shell,
            \ s:shell . '5': s:shell,
            \ s:shell . '6': s:shell,
            \ s:shell . '7': s:shell,
            \ s:shell . '8': s:shell,
            \ s:shell . '9': s:shell
            \ }

let s:asyncJob = {}
let s:maxJob = 20
" Extend terminal type & icon
if exists('g:Async_TerminalType')
    call extend(s:termType, g:Async_TerminalType)
endif

if exists('g:Async_TermIcon')
    call extend(s:termIcon, g:Async_TermIcon)
endif

" Debug a script file
function! async#DbgScript(...)
    let l:file = a:0 > 0 && a:1 != '%' ? a:1 : expand('%')
    let l:breakPoint = a:0 > 1 ? a:2 : []
    
    " Ui & var initialization
    call s:DbgUIInitalize(l:file)
    
    " Analyze script type & set var: cmd, postCmd, prompt, re
    call s:DbgScriptAnalyze(l:file, l:breakPoint)
    if !has_key(t:dbg, 'cmd')
        call s:DbgOnExit()
        return -1
    endif

    call s:DbgMaping()

    " Start debug
    call win_gotoid(t:dbg.dbgWinId)
    let l:option = copy(s:termOption)
    let l:option['curwin'] = 1
    let l:option['term_rows'] = 10
    let l:option['out_cb'] = function('s:DbgMsgHandle')
    let l:option['exit_cb'] = function('s:DbgOnExit')
    let t:dbg.dbgBufnr = term_start(t:dbg.cmd, l:option)

    " Excuting postCmd
    if has_key(t:dbg, 'postCmd')
        call term_sendkeys(t:dbg.dbgBufnr, t:dbg.postCmd . "\n")
    endif

    if has_key(t:dbg, 'varWinId')
        call win_gotoid(t:dbg.varWinId)
    endif
endfunction


function! s:DbgUIInitalize(file)
    " Source window
    exe 'tabedit ' . a:file
    let t:tab_lable = ['', '-- Debug --']
    let t:dbg = {}
    let t:dbg.srcWinId = win_getid()
    let t:dbg.srcBufnr = bufnr('%')

    let t:dbg.tempMsg = ''
    let t:dbg.var = {}
    let t:dbg.sign = {}
    let t:dbg.re = {}

    " Dbg console window
    belowright 10split
    let t:dbg.dbgWinId = win_getid()

    " Variables window
    exe 'topleft 40vnew Variables'
    let t:dbg.varWinId = win_getid()
    set buftype=nofile
    setlocal statusline=\ Variables

    " Watch point window
    if getbufvar(t:dbg.srcBufnr, '&filetype') != 'python'
        belowright 20new Watch
        let t:dbg.watchWinId = win_getid()
        set buftype=nofile
        setlocal statusline=\ Watch
    endif

    " Call stack window
    exe 'belowright 10new Call Stack'
    let t:dbg.stackWinId = win_getid()
    set nowrap
    set nonumber
    set buftype=nofile
    setlocal statusline=\ Call\ Stack
endfunction

" Analyze script type & set val: cmd, postCmd, prompt, re
" Cmd: Debug statement       " PostCmd: Excuting after starting a debug
" Prompt: command prompt     " Re: Regular expressions used to match msg
function! s:DbgScriptAnalyze(file, breakPoint)
    if !filereadable(a:file)
        return
    elseif !bufexists(a:file)
        exe 'badd ' . a:file
    endif

    let l:lineOne = getbufline(a:file, 1)[0]
    let l:interpreter = matchstr(l:lineOne, '^\(#!.*/\(env\s*\)\?\)\zs\w\+')

    " No #!, try to use filetype
    if empty(l:interpreter)
        let l:interpreter = getbufvar(a:file, '&filetype')
    endif

    if l:interpreter == 'bash' && executable('bashdb')
        " Bash script
        let t:dbg.name = 'bash'
        let l:breakFile = tempname()
        call writefile(a:breakPoint, l:breakFile)
        let t:dbg.cmd = 'bashdb -x ' . l:breakFile . ' ' . a:file
        let t:dbg.prompt = 'bashdb<\d\+>'
        let t:dbg.re.fileNr = '(\(/\S\+\):\(\d\+\)):'
        let t:dbg.re.var = '^ \d\+: \S\+ = '
        let t:dbg.re.val = '\(\S\+\)\s\+=\(.*\)$'
        let t:dbg.re.stack =  '^\(->\|##\)\d\+ '
    elseif l:interpreter =~ 'python' && executable('pdb')
        " Python script
        let t:dbg.name = 'python'
        let t:dbg.cmd = l:interpreter . ' -m pdb ' . a:file
        let t:dbg.postCmd = join(a:breakPoint, ';;')
        let t:dbg.prompt = '(Pdb)'
        let t:dbg.re.fileNr = '> \(\S\+\)(\(\d\+\))'
        let t:dbg.re.var = '^display'
        let t:dbg.re.val = '\(\w*\):\(.*\)$'
        let t:dbg.re.stack = repeat('-',10)
    elseif l:interpreter =~ 'perl'
        " Perl script
        let t:dbg.name = 'perl'
        let l:breakFile = tempname()
        call writefile(['= break b'] + a:breakPoint, l:breakFile)
        let t:dbg.cmd = l:interpreter . ' -d ' . a:file
        let t:dbg.postCmd = 'source ' . l:breakFile
        let t:dbg.prompt = ' DB<\d\+> '
        let t:dbg.re.fileNr = '(\(\S\+\):\(\d\+\))'
        let t:dbg.re.var = repeat('-',10)
        let t:dbg.re.val = repeat('-',10)
        let t:dbg.re.stack = '^@ = '
    endif
endfunction


function! s:DbgMaping(...)
    if exists('t:dbg.varWinId')
        call win_gotoid(t:dbg.varWinId)
        noremap <buffer> <silent> <CR> :call <SID>DbgSendCmd('')<CR>
        noremap <buffer> <silent> c :call <SID>DbgSendCmd("continue")<CR>
        noremap <buffer> <silent> s :call <SID>DbgSendCmd("step")<CR>
        noremap <buffer> <silent> n :call <SID>DbgSendCmd("next")<CR>
        noremap <buffer> <silent> j :call <SID>DbgSendCmd('jump')<CR>
        noremap <buffer> <silent> u :call <SID>DbgSendCmd('until')<CR>
        noremap <buffer> <silent> q :call <SID>DbgSendCmd('quit')<CR>
        noremap <buffer> <silent> p :call <SID>DbgSendCmd('p')<CR>
        noremap <buffer> <silent> a :call <SID>DbgSendCmd('display')<CR>
        noremap <buffer> <silent> \d :call <SID>DbgSendCmd('undisplay')<CR>
        noremap <buffer> <silent> i :call <SID>DbgSendCmd('_send')<CR>
        noremap <buffer> <silent> R :call <SID>DbgSendCmd('run')<CR>
        noremap <buffer> <silent> <space> :call <SID>DbgVarDispaly()<CR>
        noremap <buffer> <silent> 2 :2wincmd w<CR>
        noremap <buffer> <silent> 3 :3wincmd w<CR>
        noremap <buffer> <silent> 4 :4wincmd w<CR>
        noremap <buffer> <silent> 5 :5wincmd w<CR>
    endif

    if exists('t:dbg.watchWinId')
        noremap <buffer> <silent> <CR> :call <SID>DbgSendCmd('')<CR>
        noremap <buffer> <silent> c :call <SID>DbgSendCmd("continue")<CR>
        noremap <buffer> <silent> s :call <SID>DbgSendCmd("step")<CR>
        noremap <buffer> <silent> n :call <SID>DbgSendCmd("next")<CR>
        noremap <buffer> <silent> j :call <SID>DbgSendCmd('jump')<CR>
        noremap <buffer> <silent> u :call <SID>DbgSendCmd('until')<CR>
        noremap <buffer> <silent> q :call <SID>DbgSendCmd('quit')<CR>
        noremap <buffer> <silent> p :call <SID>DbgSendCmd('p')<CR>
        noremap <buffer> <silent> i :call <SID>DbgSendCmd('_send')<CR>
        noremap <buffer> <silent> 1 :1wincmd w<CR>
        noremap <buffer> <silent> 3 :3wincmd w<CR>
        noremap <buffer> <silent> 4 :4wincmd w<CR>
        noremap <buffer> <silent> 5 :5wincmd w<CR>
    endif

    if exists('t:dbg.stackWinId')
        noremap <buffer> <silent> <CR> :call <SID>DbgSendCmd('')<CR>
        noremap <buffer> <silent> c :call <SID>DbgSendCmd("continue")<CR>
        noremap <buffer> <silent> s :call <SID>DbgSendCmd("step")<CR>
        noremap <buffer> <silent> n :call <SID>DbgSendCmd("next")<CR>
        noremap <buffer> <silent> j :call <SID>DbgSendCmd('jump')<CR>
        noremap <buffer> <silent> u :call <SID>DbgSendCmd('until')<CR>
        noremap <buffer> <silent> q :call <SID>DbgSendCmd('quit')<CR>
        noremap <buffer> <silent> p :call <SID>DbgSendCmd('p')<CR>
        noremap <buffer> <silent> <space> :echo getline('.')<CR>
        noremap <buffer> <silent> 1 :1wincmd w<CR>
        noremap <buffer> <silent> 2 :2wincmd w<CR>
        noremap <buffer> <silent> 4 :4wincmd w<CR>
        noremap <buffer> <silent> 5 :5wincmd w<CR>
    endif
endfunction

function! <SID>DbgSendCmd(cmd)
    if a:cmd == 'quit' && confirm('Quit debug ?', "&Yes\n&No", 2) == 2
        return
    elseif a:cmd == 'jump' || a:cmd == 'until'
        let l:cmd = a:cmd . ' ' . input('Enter line number: ')
    elseif a:cmd == 'p'
        let l:cmd = 'p ' . input('Input Expression to print: ')
    elseif a:cmd == 'display'
        let l:cmd = 'display ' . input('Input var name or expression: ', '', 'tag')
    elseif a:cmd == 'undisplay'
        let l:var = matchstr(getline('.'), '^[^:]*')
        let l:cmd = 'undisplay ' . l:var . ";;print('display ')"
        unlet t:dbg.var[l:var]
    elseif a:cmd == '_send'
        let l:cmd = input('Input dbg cmd: ')
    else
        let l:cmd = a:cmd
    endif

    if a:cmd =~ '^\(c\|n\|s\|continue\|next\|step\|jump\|until\)'
        if t:dbg.name == 'python'
            let l:cmd .= ";;print('bt start:');;bt;;print('bt end:')"
        elseif t:dbg.name == 'bash'
            let l:cmd .= "\nbt"
"        elseif t:dbg.name == 'perl'
"            let l:cmd .= "\nT"
        endif
    endif

    call term_sendkeys(t:dbg.dbgBufnr, l:cmd . "\n")
endfunction

" 
function! s:DbgMsgHandle(job, msg)
    " Use command prompt to determine a message block
    if a:msg !~ t:dbg.prompt
        let t:dbg.tempMsg .= a:msg
        return
    endif

    let t:dbg.stack = []
    let l:winId = win_getid()

    " Message analysis and processing
    for l:item in split(t:dbg.tempMsg . a:msg, "\r*\n")
        if t:dbg.name == 'python' && l:item =~ '^bt start:'
            let l:btMode = 1
        elseif t:dbg.name == 'python' && l:item =~ '^bt end:'
            unlet l:btMode
        elseif t:dbg.name == 'python' && exists('l:btMode')
            let l:item = substitute(l:item, getcwd().'/', '', '')
            let t:dbg.stack += [l:item]
        elseif l:item =~ t:dbg.re.stack
            " Record callStack info
            let l:item = substitute(l:item, getcwd().'/', '', '')
            let t:dbg.stack += [l:item]
        elseif l:item =~ t:dbg.re.var
            " Monitoring Variable Change
            let l:var = matchlist(l:item, t:dbg.re.val)

            if !empty(l:var)
                let t:dbg.var[l:var[1]] = l:var[2]
            endif
        else
            " Jump line
            let l:match = matchlist(l:item, t:dbg.re.fileNr)

            if !empty(l:match) && filereadable(l:match[1]) && l:match[2] != line('.')
                call win_gotoid(t:dbg.srcWinId)
                silent exe 'edit ' . l:match[1]
                call cursor(l:match[2], 1)
                call s:DbgSetSign(expand('%'), l:match[2])
            endif
        endif
    endfor

    " Update Var
    if exists('l:var')
        call win_gotoid(t:dbg.varWinId)
        let l:list = []
        silent edit!

        for [l:var, l:val] in items(t:dbg.var)
            let l:val = substitute(l:val, '\s*\[old: .*\]$', '', '')
            let l:list += [l:var . ':' . l:val]
        endfor

        call setline(1, l:list)
    endif

    " Update call stack
    if !empty(t:dbg.stack)
        call win_gotoid(t:dbg.stackWinId)
        silent edit!
        call setline(1, t:dbg.stack)
        normal G
    endif

    let t:dbg.tempMsg = ''
    call win_gotoid(l:winId)
endfunction

" Indicates the current debugging line
function s:DbgSetSign(file, line)
    let l:signPlace = execute('sign place file=' . a:file)

    if !empty(t:dbg.sign)
        exe 'sign unplace ' . t:dbg.sign.id . ' file=' . t:dbg.sign.file
    endif

    " Ensure id uniqueness
    while !empty(matchlist(l:signPlace, '    \S\+=\d\+' . '  id=' . s:newSignId . '  '))
        let s:newSignId += 1
    endwhile

    exe 'sign place ' . s:newSignId . ' line=' . a:line . ' name=DBGCurrent' . ' file=' . a:file
    let t:dbg.sign = {'id': s:newSignId, 'file': a:file}
endfunction


function! <SID>DbgVarDispaly()
    let l:var = matchstr(getline('.'), '^[^:]*')
    echo l:var . ':' . t:dbg.var[l:var]
endfunction

" 
function s:DbgOnExit(...)
    if !empty(t:dbg.sign)
        exe 'sign unplace ' . t:dbg.sign.id . ' file=' . t:dbg.sign.file
    endif

    if exists('t:dbg')
        try
            tabclose
        catch
            call win_gotoid(t:dbg.srcWinId)
            unlet t:dbg
        endtry
    endif
endfunction


function async#RunScript(...)
    let l:file = a:0 > 0 && a:1 != '%' ? a:1 : expand('%')

    if !filereadable(l:file)
        return
    elseif !bufexists(l:file)
        exe 'badd ' . l:file
    endif

    let l:lineOne = getbufline(l:file, 1)[0]
    let l:interpreter = matchstr(l:lineOne, '^\(#!.*/\(env\s*\)\?\)\zs.*$')

    " No #!, try to use filetype
    if empty(l:interpreter)
        let l:interpreter = getbufvar(l:file, '&filetype')
    endif

    let l:cmd = l:interpreter . ' ' . l:file
    let l:bufnr = async#TermToggle('on')
    call term_sendkeys(l:bufnr, "clear\n" . l:cmd . "\n")
endfunction


" Gdb tool： debug binary file
" BreakPoint: list type
function async#GdbStart(...)
    if a:0 == 0
        return
    endif

    let l:binFile = a:1
    let l:breakPoint = a:0 > 1 ? a:2 : []

    if !exists(':Termdebug')
        packadd termdebug
    endif

    " New tab to debug
    tabnew
    let t:tab_lable = ['', '-- Debug --']

    if empty(l:breakPoint)
        exe 'Termdebug ' . l:binFile
    else
        let l:tempFile = tempname()
        call writefile(l:breakPoint, l:tempFile)
        exe 'Termdebug -x ' . l:tempFile .  ' ' . l:binFile
    endif

    " Gdb on exit
    autocmd BufUnload <buffer> call s:GdbOnExit()
endfunction

function s:GdbOnExit()
    if exists('t:dbg')
        try
            tabclose
        catch
            unlet t:tab_lable
        endtry
    endif
endfunction


" Switch embedded terminal
" Args: action, type, postCmd
" Action: on, off, toggle (default: toggle)
" Type: specified by s:termType (default: s:shell)
" PostCmd: executing cmd after terminal started
function async#TermToggle(...)
    " Ensure starting insert mode
    if &buftype == 'terminal' && mode() == 'n'
        normal a
    endif

    let l:action = a:0 > 0 && a:1 != '.' ? a:1 : 'toggle'
    let l:type = a:0 > 1 && a:2 != '.' ? a:2 : ''
    let l:postCmd = a:0 > 2 ? join(a:000[2:], ' ') : ''

    if empty(l:type)
        " Default terminal
        let l:type = s:shell
        let l:name = s:termPrefix
    elseif l:type
        " Default numbered terminal (1..9, -1..-9)
        let l:type = l:type > 0 ? l:type + 0 : l:type + len(s:termIcon) + 1
        let l:name = s:termPrefix . get(s:termIcon, l:type, ' ')
        let l:type = s:shell . l:type
    else
        " Custom added terminal type
        let l:name = s:termPrefix . get(s:termIcon, l:type, ': ' . l:type . ' ')
    endif

    try
        let l:cmd = s:termType[l:type]
    catch 'E716'
        " Invalid type
        return
    endtry

    let l:winnr = bufwinnr(l:name)
    let l:bufnr = bufnr(l:name)

    if l:winnr != -1
        if l:action == 'on'
            exe l:winnr . 'wincmd w'
        elseif l:action =~ 'off\|toggle'
            exe l:winnr . 'hide'
        endif
    elseif l:action =~ 'on\|toggle'
        " Hide other terminal
        let l:other = bufwinnr(s:termPrefix)
        if l:other != -1
            exe l:other . 'hide'
        endif

        " Skip window containing buf with nonempty buftype
        let l:num = winnr('$')
        while !empty(&buftype) && l:num > 0
            wincmd w
            let l:num -= 1
        endwhile

        if l:bufnr == -1
            " Creat a terminal
            let l:option = copy(s:termOption)
            let l:option['term_name'] = l:name
            let l:option['curwin'] = 1
            exe 'belowright ' . get(s:termOption, 'term_rows', 15) . 'split'
            let l:bufnr = term_start(l:cmd, l:option)
        else
            " Display terminal
            silent exe 'belowright ' . get(s:termOption, 'term_rows', 15) . 'split +' . l:bufnr . 'buffer'
        endif
    elseif l:action == 'off' && !empty(l:postCmd) && l:bufnr == -1
        " Allow background execution
        let l:option = copy(s:termOption)
        let l:option['term_name'] = l:name
        let l:option['hidden'] = 1
        let l:bufnr = term_start(l:cmd, l:option)
    endif

    " Ensure starting insert mode
    if &buftype == 'terminal' && mode() == 'n'
        normal a
    endif

    " Excuting postCmd after establishing a terminal
    if !empty(l:postCmd) && l:bufnr != -1
        call term_sendkeys(l:bufnr, l:postCmd . "\n")
    endif

    return l:bufnr
endfunction

" Switch terminal window between exists terminal
function async#TermSwitch(...)
    if mode() == 'n'
        normal a
    endif

    let l:action = a:0 > 0 ? a:1 : 'next'
    let l:termList = filter(split(execute('ls R'), "\n"), "v:val =~ '!Terminal'")

    if len(l:termList) > 1
        call map(l:termList, "split(v:val)[0] + 0")
        let l:ind = index(l:termList, bufnr('%'))

        if l:action == 'next'
            let l:ind = (l:ind + 1) % len(l:termList)
        else
            let l:ind -= 1
        endif

        hide
        silent exe 'belowright ' . get(s:termOption, 'term_rows', 15) . 'split +' . l:termList[l:ind] . 'buffer'
        let l:buf = map(l:termList, "' '.bufname(v:val)")
        let l:buf[l:ind] = '[' . l:buf[l:ind][1:-2] . ']'
        echo strpart(join(l:buf), 0, &columns)
    endif

    if mode() == 'n'
        normal a
    endif
endfunction

" Cmd: list or string
function async#JobRun(cmd)
    if len(s:asyncJob) > s:maxJob
        return
    endif

    let l:job = job_start(a:cmd, {
                \ 'exit_cb': function('s:JobOnExit'),
                \ 'in_io': 'null',
                \ 'out_io': 'null',
                \ 'err_io': 'null'
                \ })

    " Record a job
    if job_status(l:job) == 'run'
        let l:id = matchstr(l:job, '\d\+')
        let s:asyncJob[l:id] = {'cmd': a:cmd, 'job': l:job}
    endif
endfunction


function s:JobOnExit(job, status)
    let l:id = matchstr(a:job, '\d\+')
    
    if a:status != 0
        echo 'Failed: ' . s:asyncJob[l:id].cmd
    else
        echo 'Done: ' . s:asyncJob[l:id].cmd
    endif

    unlet s:asyncJob[l:id]
endfunction


function async#JobStop(...)
    if !empty(s:asyncJob)
        let l:how = a:0 > 0 ? a:1 : 'term'
        let l:prompt = async#JobList("Select one to stop ...")
        
        while 1
            let l:jobId = input(l:prompt . "\nInput id: ")

            if l:jobId == 'q'
                return
            endif

            let l:job = get(s:asyncJob, l:jobId, {'job': ''}).job

            if empty(l:job)
                redraw
            else
                call job_stop(l:job, l:how)
                break
            endif
        endwhile
    endif
endfunction

function async#JobList(...)
    let l:prompt = a:0 > 0 ? a:1 : "Job List ..."

    let l:jobs = ''
    for [l:id, l:job] in items(s:asyncJob)
        let l:jobs .= printf("\n    %d:  %s", l:id, l:job.cmd)
    endfor

    return l:prompt . l:jobs
endfunction

