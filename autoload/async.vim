""""""""""""""""""""""""""""""""""""""""""""""""""""
" Author: CY <844757727@qq.com>
" Description: Asynchronous task
""""""""""""""""""""""""""""""""""""""""""""""""""""

if exists('g:loaded_A_Async') || v:version < 800
  finish
endif
let g:loaded_A_Async = 1


" ===========================================
" ===== Embeded terminal configure ===== {{{1
" ===========================================
hi AsyncDbgHl ctermbg=253 ctermfg=16 guibg=#1E1E1E guifg=#CCCCB0
sign define DBGCurrent text=⏩ texthl=AsyncDbgHl

let s:newSignId = 1
let s:displayIcon = {
            \ '1': ' ➊ ', '2': ' ➋ ', '3': ' ➌ ',
            \ '4': ' ➍ ', '5': ' ➎ ', '6': ' ➏ ',
            \ '7': ' ➐ ', '8': ' ➑ ', '9': ' ➒ '
            \ }

" ""
" Default terminal option
let s:termPrefix = '!Terminal'
let s:termOption = {
            \ 'term_rows': 15,
            \ 'term_kill': 'kill',
            \ 'term_finish': 'close',
            \ 'stoponexit': 'exit',
            \ 'norestore': 1
            \ }

" Default terminal type
let s:shell = fnamemodify(&shell, ':t')
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

" Extend terminal type & icon
if exists('g:Async_TerminalType')
    call extend(s:termType, g:Async_TerminalType)
endif

if exists('g:Async_displayIcon')
    call extend(s:displayIcon, g:Async_displayIcon)
endif


" Switch embedded terminal
" Args: action, type, postCmd
" Action: on, off, toggle (default: toggle)
" Type: specified by s:termType (default: s:shell)
" PostCmd: executing cmd after terminal started
function! async#TermToggle(...)
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
        let l:type = l:type > 0 ? l:type + 0 : l:type + len(s:displayIcon) + 1
        let l:name = s:termPrefix . get(s:displayIcon, l:type, ' ')
        let l:type = s:shell . l:type
    else
        " Custom added terminal type
        let l:name = s:termPrefix . get(s:displayIcon, l:type, ': ' . l:type . ' ')
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
function! async#TermSwitch(...)
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

" =====================================
" ===== Asynchronous task/job ==== {{{1
" =====================================

" {'jobId': cmd}
let s:asyncJob = {}
let s:maxJob = 20


" Cmd: list or string
function! async#JobRun(cmd, ...)
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
        
        if a:0 > 0
            let s:asyncJob.op = a:1
        endif
    endif
endfunction


function! s:JobOnExit(job, status)
    let l:id = matchstr(a:job, '\d\+')
    
    if get(s:asyncJob[l:id], 'op', '') == 'q'
        echo
    elseif a:status != 0
        echo 'Failed: ' . s:asyncJob[l:id].cmd
    else
        echo 'Done: ' . s:asyncJob[l:id].cmd
    endif

    unlet s:asyncJob[l:id]
endfunction


function! async#JobStop(...)
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

function! async#JobList(...)
    let l:prompt = a:0 > 0 ? a:1 : "Job List ..."

    let l:jobs = ''
    for [l:id, l:job] in items(s:asyncJob)
        let l:jobs .= printf("\n    %d:  %s", l:id, l:job.cmd)
    endfor

    return l:prompt . l:jobs
endfunction

" =====================================
" ===== Script run/debug ==== {{{1
" =====================================
let s:dbg = {
            \ 'id': 0,
            \ 'tempMsg': '',
            \ 'var': {},
            \ 'break': {},
            \ 'watch': [],
            \ 'stack': [],
            \ 'sign': {}
            \ }

function! s:dbg.sendCmd(cmd, args, ...)
    let l:args = a:args

    if a:cmd == 'condition'
        for [l:key, l:val] in items(get(t:dbg, 'break', {}))
            if l:val =~ a:args
                let l:id = l:key
                break
            endif
        endfor

        if exists('l:id')
            let l:args = l:id . ' ' . (a:0 > 0 ? a:1 : '')
        endif
    endif

    if has_key(self, 'dbgBufnr')
        call term_sendkeys(self.dbgBufnr, a:cmd.' '.l:args."\n")
    endif
endfunction


function! async#RunScript(...)
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



" Debug a script file
function! async#DbgScript(...)
    let l:file = a:0 > 0 && a:1 != '%' ? a:1 : expand('%')
    let l:breakPoint = a:0 > 1 ? a:2 : []
    
    if !filereadable(l:file)
        return
    elseif !bufexists(l:file)
        exe 'badd ' . l:file
    endif

    " Analyze script type & set var: cmd, postCmd, prompt, re...
    let l:dbg = s:DbgScriptAnalyze(l:file, l:breakPoint)
    if !has_key(l:dbg, 'cmd')
        return -1
    endif

    " Generate debug id
    let l:idList = map(range(tabpagenr('$')), "get(gettabvar(v:val+1,'dbg',{}),'id',-1)")
    while index(l:idList, l:dbg.id) != -1
        let l:dbg.id += 1
    endwhile

    " Ui initialization & maping
    call s:DbgUIInitalize(l:dbg)
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


" Analyze script type & set val: cmd, postCmd, prompt, re
" Cmd: Debug statement       " PostCmd: Excuting after starting a debug
" Prompt: command prompt     " Re: Regular expressions used to match msg
function! s:DbgScriptAnalyze(file, breakPoint)
    let l:lineOne = getbufline(a:file, 1)[0]
    let l:interpreter = matchstr(l:lineOne, '^\(#!.*/\(env\s*\)\?\)\zs\w\+')

    " No #!, try to use filetype
    if empty(l:interpreter)
        let l:interpreter = getbufvar(a:file, '&filetype')
    endif

    let l:dbg = copy(s:dbg)
    let l:dbg.file = a:file

    if l:interpreter == 'bash' && executable('bashdb')
        " Bash script
        let l:dbg.name = 'bash'
        let l:dbg.tool = 'bashdb'
        let l:breakFile = tempname()
        call writefile(a:breakPoint, l:breakFile)
        let l:dbg.cmd = 'bashdb -x ' . l:breakFile . ' ' . a:file
        let l:dbg.prompt = 'bashdb<\d\+>'
        let l:dbg.fileNr = '^(\(\S\+\):\(\d\+\)):'
        let l:dbg.varVal = '^ \d\+: \(\S\+\) = \(.*\)$'
        let l:dbg.breakNr = '^Breakpoint \(\d\+\) set in file \(\S\+\), line \(\d\+\).'
        let l:dbg.stackLine =  '^\(->\|##\)\d\+ '
        let l:dbg.watchLine = '^\(watchpoint \d\+: \|  old value: \|  new value: \)'
        let l:dbg.d = "\n"
        let l:dbg.win = ['var', 'watch', 'stack']
    elseif l:interpreter =~ 'python' && executable('pdb')
        " Python script
        let l:dbg.name = 'python'
        let l:dbg.tool = 'pdb'
        let l:dbg.cmd = l:interpreter . ' -m pdb ' . a:file
        let l:breakPoint = map(a:breakPoint, "join(split(v:val,'\\(:\\d\\+\\)\\zs\\s\\+'),' ,')")
        let l:dbg.postCmd = join(l:breakPoint + ['alias finish return'], ';;')
        let l:dbg.prompt = '(Pdb)'
        let l:dbg.fileNr = '^> \(\S\+\)(\(\d\+\))'
        let l:dbg.varVal = '^display \([^:]\+\): \(.*\)$'
        let l:dbg.breakNr = '^Breakpoint \(\d\+\) at \(\S\+\):\(\d\+\)'
        let l:dbg.stackLine = '-^'
        let l:dbg.watchLine = '-^'
        let l:dbg.d = ';;'
        let l:dbg.win = ['var', 'stack']
    elseif l:interpreter =~ 'perl'
        " Perl script
        let l:dbg.name = 'perl'
        let l:dbg.tool = 'perl -d'
        let l:alias = [
                    \ '= break b', '= bt T', '= step s',
                    \ '= continue c', '= next n', '= watch w',
                    \ '= run R', '= quit q'
                    \ ]
        let l:breakFile = tempname()
        call writefile(l:alias + a:breakPoint, l:breakFile)
        let l:dbg.cmd = l:interpreter . ' -d ' . a:file
        let l:dbg.postCmd = 'source ' . l:breakFile
        let l:dbg.prompt = ' DB<\d\+> '
        let l:dbg.fileNr = '(\(\S\+\):\(\d\+\))'
        let l:dbg.varVal = '-^'
        let l:dbg.breakNr = '-^'
        let l:dbg.stackLine = '@ = '
        let l:dbg.watchLine = '-^'
        let l:dbg.d = "\n"
        let l:dbg.win = []
    endif

    return l:dbg
endfunction


" Configure new tabpage for debug
" and set t:dbg variable
function! s:DbgUIInitalize(dbg)
    " Source view window
    exe 'tabedit ' . a:dbg.file
    let l:suffix = get(s:displayIcon, a:dbg.id, ' ')
    let t:tab_lable = ['', '-- Debug'.l:suffix.'--']
    let t:dbg = a:dbg
    let t:dbg.srcWinId = win_getid()

    " Debug console window
    belowright 10split
    let t:dbg.dbgWinId = win_getid()

    " Variables window
    if index(t:dbg.win, 'var') != -1
        exe 'topleft 40vnew var_'.t:dbg.id.'.dbgvar'
        let t:dbg.varWinId = win_getid()
        set buftype=nofile
        set filetype=dbgvar
        setlocal statusline=\ Variables
    endif

    " Watch point window
    if index(t:dbg.win, 'watch') != -1
        exe 'belowright 20new Watch_'.t:dbg.id.'.dbgwatch'
        let t:dbg.watchWinId = win_getid()
        set buftype=nofile
        set filetype=dbgwatch
        setlocal statusline=\ Watch%{get(t:dbg,'watchFlag','')}
    endif

    " Call stack window
    if index(t:dbg.win, 'stack') != -1
        exe 'belowright 10new stack_'.t:dbg.id.'.dbgstack'
        let t:dbg.stackWinId = win_getid()
        set nowrap
        set nonumber
        set buftype=nofile
        set filetype=dbgstack
        setlocal statusline=\ Call\ Stack
    endif
endfunction


" Creat maping for easy debuging
function! s:DbgMaping(...)
    if exists('t:dbg.varWinId')
        call win_gotoid(t:dbg.varWinId)
        noremap <buffer> <silent> <CR> :call <SID>DbgSendCmd('')<CR>
        noremap <buffer> <silent> c :call <SID>DbgSendCmd("continue")<CR>
        noremap <buffer> <silent> C :call <SID>DbgSendCmd("condition")<CR>
        noremap <buffer> <silent> s :call <SID>DbgSendCmd("step")<CR>
        noremap <buffer> <silent> S :call <SID>DbgSendCmd("skip")<CR>
        noremap <buffer> <silent> n :call <SID>DbgSendCmd("next")<CR>
        noremap <buffer> <silent> j :call <SID>DbgSendCmd('jump')<CR>
        noremap <buffer> <silent> u :call <SID>DbgSendCmd('until')<CR>
        noremap <buffer> <silent> q :call <SID>DbgSendCmd('quit')<CR>
        noremap <buffer> <silent> p :call <SID>DbgSendCmd('p')<CR>
        noremap <buffer> <silent> v :call <SID>DbgSendCmd('display')<CR>
        noremap <buffer> <silent> w :call <SID>DbgSendCmd('watch')<CR>
        noremap <buffer> <silent> W :call <SID>DbgSendCmd('watche')<CR>
        noremap <buffer> <silent> \d :call <SID>DbgSendCmd('undisplay')<CR>
        noremap <buffer> <silent> i :call <SID>DbgSendCmd('_send')<CR>
        noremap <buffer> <silent> r :call <SID>DbgSendCmd('return')<CR>
        noremap <buffer> <silent> f :call <SID>DbgSendCmd('finish')<CR>
        noremap <buffer> <silent> R :call <SID>DbgSendCmd('run')<CR>
        noremap <buffer> <silent> <space> :call <SID>DbgVarDispaly()<CR>
        noremap <buffer> <silent> 2 :2wincmd w<CR>
        noremap <buffer> <silent> 3 :3wincmd w<CR>
        noremap <buffer> <silent> 4 :4wincmd w<CR>
        noremap <buffer> <silent> 5 :5wincmd w<CR>
    endif

    if exists('t:dbg.watchWinId')
        call win_gotoid(t:dbg.watchWinId)
        noremap <buffer> <silent> 1 :1wincmd w<CR>
        noremap <buffer> <silent> <space> :echo getline('.')<CR>
    endif

    if exists('t:dbg.stackWinId')
        call win_gotoid(t:dbg.stackWinId)
        noremap <buffer> <silent> u :call <SID>DbgSendCmd('up')
        noremap <buffer> <silent> d :call <SID>DbgSendCmd('down')
        noremap <buffer> <silent> <space> :echo getline('.')<CR>
        noremap <buffer> <silent> 1 :1wincmd w<CR>
    endif
endfunction


function! <SID>DbgSendCmd(cmd)
    if a:cmd == 'quit' && confirm('Quit debug ?', "&Yes\n&No", 2) == 2
        return
    elseif a:cmd == 'jump' || a:cmd == 'until'
        let l:cmd = a:cmd . ' ' . input('Enter line number: ')
    elseif index(['display', 'watch', 'watche', 'p'], a:cmd) != -1
        let l:var = input('Input var name or expression: ', '', 'tag')
        let l:cmd = a:cmd . ' ' . l:var
    elseif a:cmd == 'undisplay'
        let l:var = matchstr(getline('.'), '^[^:]*')
        let l:cmd = 'undisplay ' . l:var
        unlet t:dbg.var[l:var]
    elseif a:cmd == 'run' && t:dbg.name == 'python'
        let l:cmd = join(['run'] + map(keys(t:dbg.var), "'display '.v:val"), ';;')
    elseif a:cmd == 'skip' && t:dbg.name == 'bash'
        let l:cmd = 'skip ' . input('Input counts: ')
    elseif a:cmd == '_send'
        let l:cmd = input('Input dbg cmd: ')
    elseif a:cmd == 'condition'
        if empty(t:dbg.break)
            return
        endif

        let l:str = "  num   where\n"
        for [l:key, l:val] in items(t:dbg.break)
            let l:str .= printf('  %-3d   %s', l:key, l:val)."\n"
        endfor

        let l:num = input(l:str."Select num: ")
        if has_key(t:dbg.break, l:num)
            let l:cmd = 'condition ' . l:num .' '. input('Input condition('.l:num.'): ')
        else
            return
        endif
    else
        let l:cmd = a:cmd
    endif

    if index(['continue', 'next', 'step', 'jump', 'until'], a:cmd) != -1
        if t:dbg.name == 'python'
            let l:cmd .= ";;print('bt start:');;bt;;print('bt end:')"
        elseif t:dbg.name == 'bash'
            let l:cmd .= "\nbt"
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
    let t:dbg.watch = []
    let l:winId = win_getid()

    " Message analysis
    for l:item in split(t:dbg.tempMsg . a:msg, "\r*\n")
        if l:item =~ '^bt start:'
            let l:btMode = 1
        elseif l:item =~ '^bt end:'
            unlet l:btMode
        elseif exists('l:btMode') || l:item =~ t:dbg.stackLine
            let l:item = substitute(l:item, getcwd().'/', '', '')
            let t:dbg.stack += [l:item]
        elseif l:item =~ t:dbg.watchLine
            let t:dbg.watch += [l:item]
        else
            " Try varVal match: Monitoring Variable Change
            let l:match = matchlist(l:item, t:dbg.varVal)
            if !empty(l:match) && l:match[2] != get(t:dbg.var, l:match[1], '')
                let l:varFlag = 1
                let t:dbg.var[l:match[1]] = l:match[2]
                continue
            endif

            " Try fileNr match: jump line
            let l:match = matchlist(l:item, t:dbg.fileNr)
            if !empty(l:match) && filereadable(l:match[1])
                let l:fileNr = [l:match[1], l:match[2]]
                continue
            endif

            " Record breakpoint info
            let l:match = matchlist(l:item, t:dbg.breakNr)
            if !empty(l:match)
                let t:dbg.break[l:match[1]] = l:match[2].':'.l:match[3]
            endif
        endif
    endfor

    " Excute action
    " Udate watch window
    if !empty(t:dbg.watch)
        call win_gotoid(t:dbg.watchWinId)
        silent edit!
        call setline(1, t:dbg.watch)
        set filetype=dbgwatch
        let t:dbg.watchFlag = ' '
    elseif has_key(t:dbg, 'watchFlag') && empty(t:dbg.stack)
        unlet t:dbg.watchFlag
    endif

    " Update variables window
    if exists('l:varFlag')
        let l:list = []
        for [l:var, l:val] in items(t:dbg.var)
            let l:val = substitute(l:val, '\s*\[old: .*\]$', '', '')
            let l:list += [l:var . ': ' . l:val]
        endfor

        call win_gotoid(t:dbg.varWinId)
        silent edit!
        call setline(1, l:list)
        set filetype=dbgvar
    endif

    " Line jump
    if exists('l:fileNr')
        call win_gotoid(t:dbg.srcWinId)

        if expand('%') !~ l:fileNr[0]
            silent! exe 'edit ' . l:fileNr[0]
        endif

        if l:fileNr[1] != line('.')
            call cursor(l:fileNr[1], 1)
            call s:DbgSetSign(l:fileNr[0], l:fileNr[1])
        endif
    endif

    " Update call stack window
    if !empty(t:dbg.stack)
        call win_gotoid(t:dbg.stackWinId)
        silent edit!
        call setline(1, t:dbg.stack)
        set filetype=dbgstack
    endif

    let t:dbg.tempMsg = ''
    call win_gotoid(l:winId)
endfunction


" Indicates the current debugging line
function! s:DbgSetSign(file, line)
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
    echo l:var . ': ' . t:dbg.var[l:var]
endfunction

" 
function! s:DbgOnExit(...)
    if !empty(t:dbg.sign)
        exe 'sign unplace ' . t:dbg.sign.id . ' file=' . t:dbg.sign.file
    endif

    if exists('t:dbg')
        try
            tabclose
        catch
            call win_gotoid(t:dbg.srcWinId)
            unlet t:dbg
            unlet t:tab_lable
        endtry
    endif
endfunction


" Gdb tool： debug binary file
" BreakPoint: list type
function! async#GdbStart(...)
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

function! s:GdbOnExit()
    if exists('t:dbg')
        try
            tabclose
        catch
            unlet t:tab_lable
        endtry
    endif
endfunction

" set foldmethod=marker
