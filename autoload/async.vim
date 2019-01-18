""""""""""""""""""""""""""""""""""""""""""""""
" File: async.vim
" Author: Cy <844757727@qq.com>
" Description: Asynchronous job & embedded terminal manager
"              run or debug script language
" Last Modified: 2019年01月06日 星期日 16时59分49秒
""""""""""""""""""""""""""""""""""""""""""""""

if exists('g:loaded_A_Async') || v:version < 800
    finish
endif
let g:loaded_A_Async = 1


" === Embeded terminal === {{{1
hi default AsyncDbgHl ctermfg=16 guifg=#8BEBFF
sign define DBGCurrent text= texthl=AsyncDbgHl

let s:displayIcon = {
            \ '1': ' ➊ ', '2': ' ➋ ', '3': ' ➌ ',
            \ '4': ' ➍ ', '5': ' ➎ ', '6': ' ➏ ',
            \ '7': ' ➐ ', '8': ' ➑ ', '9': ' ➒ '
            \ }

" ""
" Default terminal option
let s:termPrefix = '!Terminal'
let s:termOption = {
            \ 'term_rows': get(g:, 'BottomWinHeight', 15),
            \ 'term_kill': 'kill',
            \ 'term_finish': 'close',
            \ 'stoponexit': 'exit',
            \ 'norestore': 1
            \ }

" Default terminal type
let s:shell = fnamemodify(&shell, ':t')
let s:termType = {
            \ s:shell: s:shell,
            \ s:shell.'1': s:shell,
            \ s:shell.'2': s:shell,
            \ s:shell.'3': s:shell,
            \ s:shell.'4': s:shell,
            \ s:shell.'5': s:shell,
            \ s:shell.'6': s:shell,
            \ s:shell.'7': s:shell,
            \ s:shell.'8': s:shell,
            \ s:shell.'9': s:shell
            \ }

" Extend terminal type & icon
if exists('g:Async_TerminalType')
    call extend(s:termType, g:Async_TerminalType)
endif

if exists('g:Async_displayIcon')
    call extend(s:displayIcon, g:Async_displayIcon)
endif


" Switch embedded terminal {{{2
" Args: action, type, postCmd
" Action: on, off, toggle (default: toggle)
" Type: specified by s:termType (default: s:shell)
" PostCmd: executing cmd after terminal started
function! async#TermToggle(...)
    " Ensure starting insert mode
    if bufname('%') =~# '\v^!' && mode() ==# 'n'
        normal a
    endif

    let [l:action, l:type, l:name, l:postCmd] = ['toggle', s:shell, s:termPrefix, '']

    for l:i in range(len(a:000))
        if index(['toggle', 'on', 'off'], a:000[l:i]) != -1
            let l:action = a:000[l:i]
        elseif index(keys(s:termType), a:000[l:i]) != -1
            let l:type = a:000[l:i]
            let l:name .= get(s:displayIcon, l:type, ': '.l:type.' ')
        elseif a:000[l:i]
            let l:type = a:000[l:i] > 0 ? a:000[l:i] + 0 : a:000[l:i] + 10
            let l:name .= get(s:displayIcon, l:type, ' ')
            let l:type = s:shell.l:type
        else
            let l:postCmd = matchstr(join(a:000[l:i:], ' '), '\w.*')
            break
        endif
    endfor

    let l:cmd = s:termType[l:type]
    let l:winnr = bufwinnr(l:name)
    let l:bufnr = bufnr(l:name)

    if l:winnr != -1
        if l:action ==# 'on'
            exe l:winnr.'wincmd w'
        elseif index(['toggle', 'off'], l:action) != -1
            exe l:winnr.'hide'
        endif
    elseif index(['toggle', 'on'], l:action) != -1
        " Hide other terminal
        let l:other = bufwinnr(s:termPrefix)
        if l:other != -1
            exe l:other.'hide'
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
            exe 'belowright '.get(s:termOption, 'term_rows', 15).'split'
            let l:bufnr = term_start(l:cmd, l:option)
        else
            " Display terminal
            silent exe 'belowright '.get(s:termOption, 'term_rows', 15).'split +'.l:bufnr.'buffer'
        endif
    elseif l:action ==# 'off' && !empty(l:postCmd) && l:bufnr == -1
        " Allow background execution when first starting
        let l:option = copy(s:termOption)
        let l:option['term_name'] = l:name
        let l:option['hidden'] = 1
        let l:bufnr = term_start(l:cmd, l:option)
        call setbufvar(l:bufnr, '&buftype', 'terminal')
    endif

    " Excuting postCmd after establishing a terminal
    if !empty(l:postCmd) && l:bufnr != -1
        call term_sendkeys(l:bufnr, l:postCmd."\n")
    endif

    return l:bufnr
endfunction


" Switch terminal window between exists terminal {{{2
function! async#TermSwitch(...)
    if bufname('%') !~# s:termPrefix
        return
    endif

    let l:action = a:0 > 0 ? a:1 : 'next'
    let l:termList = filter(split(execute('ls R'), "\n"), "v:val =~ '!Terminal'")

    if len(l:termList) > 1
        call map(l:termList, "split(v:val)[0] + 0")
        let l:ind = index(l:termList, bufnr('%'))

        if l:action ==# 'next'
            let l:ind = (l:ind + 1) % len(l:termList)
        else
            let l:ind -= 1
        endif

        hide
        silent exe 'belowright '.get(s:termOption, 'term_rows', 15).'split +'.l:termList[l:ind].'buffer'
        let l:buf = map(l:termList, "' '.bufname(v:val)")
        let l:buf[l:ind] = '['.l:buf[l:ind][1:-2].']'
        echo strpart(join(l:buf), 0, &columns)
    endif
endfunction

" === Asynchronous task/job === {{{1
" {'jobId': cmd}
let s:asyncJob = {}
let s:maxJob = 20


" Cmd: list or string
function! async#JobRun(cmd, bang)
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
    if job_status(l:job) ==# 'run'
        let l:id = matchstr(l:job, '\d\+')
        let s:asyncJob[l:id] = {'cmd': a:cmd, 'job': l:job}

        if !empty(a:bang)
            let s:asyncJob[l:id].quiet = 1
        endif
    endif
endfunction


function! s:JobOnExit(job, status)
    let l:id = matchstr(a:job, '\d\+')
    let l:ex = ["echom 'async: ".s:asyncJob[l:id].cmd.' '.(a:status == 0 ? '[Done]' : '[Failed]')."'"]

    if has_key(s:asyncJob[l:id], 'quiet')
        let l:ex += ["echo ' '"]
    endif

    call execute(l:ex, '')

    unlet s:asyncJob[l:id]
endfunction


function! async#JobStop(how)
    if empty(s:asyncJob)
        return
    endif

    let l:how = empty(a:how) ? 'term' : 'kill'

    let l:prompt = 'Select jobs to stop ('.l:how.') ...'
    for [l:id, l:job] in items(s:asyncJob)
        let l:prompt .= printf("\n    %d:  %s", l:id, l:job.cmd)
    endfor

    while 1
        let l:jobIds = input(l:prompt."\nInput id: ", '', 'custom,async#JobIds_complete')

        if l:jobIds !~# '\v\S'
            return
        endif

        for l:jobId in split(l:jobIds, '\v\s+')
            if has_key(s:asyncJob, l:jobId)
                call job_stop(s:asyncJob[l:jobId].job, l:how)
                return
            endif
        endfor

        redraw!
    endwhile
endfunction


function! async#JobRuning()
    return len(s:asyncJob)
endfunction

function! async#JobIds_complete(L, C, P)
    return join(keys(s:asyncJob), "\n")
endfunction

" === Script run/debug === {{{1
let s:dbgWinHeight = get(g:, 'BottomWinHeight', 15) * 2 / 3
let s:dbgSideWidth = get(g:, 'SideWinWidth', 30) * 4 / 3

let s:dbgShared = {}
let s:dbg = {
            \ 'id': 0,
            \ 'sign': {},
            \ 'tempMsg': '',
            \ 'map': {
            \ 'C': 'condition', 'D': 'disable',   'E': 'enable',
            \ 'B': 'clear',     'b': 'break',     '<CR>': ' ',
            \ 'c': 'continue',  's': 'step',      'n': 'next',
            \ 'p': 'print',     'R': 'run',       'i': 'send',
            \ 'v': 'display',   'V': 'undisplay', '\d': '_undisplay',
            \ 'q': 'quit',      'r': 'return'
            \ }
            \ }

function! s:dbg.sendCmd(cmd, args, ...)
    let l:args = a:args
    let g:temp =1

    if a:cmd ==# 'condition'
        let l:breakInfo = t:dbg.name ==# 'bash' ? 'info break' : 'break'
        call term_sendkeys(t:dbg.dbgBufnr, l:breakInfo."\n")

        let l:counts = 10
        while get(t:dbg, 'breakFlag', 1) != 1 && l:counts > 0
            sleep 100m
            let l:counts -= 1
        endwhile

        for l:str in get(t:dbg, 'break', [])
            if l:str =~# substitute(a:args, getcwd().'/', '', '')
                let l:id = matchstr(l:str, '^\d\+')
                break
            endif
        endfor

        if exists('l:id')
            let l:args = l:id.' '.(a:0 > 0 ? a:1 : '')
        else
            return
        endif
    endif

    if has_key(self, 'dbgBufnr')
        call term_sendkeys(self.dbgBufnr, a:cmd.' '.l:args."\n")
    endif
endfunction


function! async#RunScript(...)
    let l:file = a:0 > 0 && a:1 !=# '%' ? a:1 : expand('%')

    if !filereadable(l:file)
        return
    elseif !executable('sed') && !bufloaded(l:file)
        exe '0vsplit +hide '.l:file
    endif

    let l:lineOne = executable('sed') ? system('sed -n 1p '.l:file)[:-2] : getbufline(l:file, 1)[0]
    let l:interpreter = matchstr(l:lineOne, '\v^(#!.*/(env\s+)?)\zs.*$')

    " No #!, try to use filetype
    if empty(l:interpreter)
        if !bufexists(l:file)
            exe 'badd '.l:file
        endif

        let l:interpreter = getbufvar(l:file, '&filetype')
    endif

    let l:cmd = l:interpreter.' '.l:file
    let l:bufnr = async#TermToggle('on')
    call term_sendkeys(l:bufnr, "clear\n".l:cmd."\n")
endfunction


" Debug a script file
function! async#DbgScript(...)
    let l:file = a:0 > 0 && a:1 !=# '%' ? a:1 : expand('%:p')
    let l:breakPoint = a:0 > 1 ? a:2 : []

    if !filereadable(l:file)
        return
    elseif !executable('sed') && !bufloaded(l:file)
        exe '0vsplit +hide '.l:file
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

    " Set sign id
    let l:dbg.sign.id = (l:dbg.id + 1) * 10

    " Ui initialization & maping
    call s:DbgUIInitalize(l:dbg)
    call s:DbgMaping()

    " Start debug
    call win_gotoid(t:dbg.dbgWinId)
    let l:option = copy(s:termOption)
    let l:option['curwin'] = 1
    let l:option['term_rows'] = s:dbgWinHeight
    let l:option['out_cb'] = function('s:DbgMsgHandle')
    let l:option['exit_cb'] = function('s:DbgOnExit')
    let t:dbg.dbgBufnr = term_start(t:dbg.cmd, l:option)

    " Excuting postCmd
    if has_key(t:dbg, 'postCmd')
        call term_sendkeys(t:dbg.dbgBufnr, t:dbg.postCmd."\n")
    endif

    if has_key(t:dbg, 'varWinId')
        call win_gotoid(t:dbg.varWinId)
    endif
endfunction


" Analyze script type & set val: cmd, postCmd, prompt
" Cmd: Debug statement       " PostCmd: Excuting after starting a debug
" Prompt: command prompt
function! s:DbgScriptAnalyze(file, breakPoint)
    let l:lineOne = executable('sed') ? system('sed -n 1p '.a:file)[:-2] : getbufline(a:file, 1)[0]
    let l:interpreter = matchstr(l:lineOne, '\v^(#!.*/(env\s*)?)\zs\w+')

    " No #!, try to use filetype
    if empty(l:interpreter)
        if !bufexists(l:file)
            exe 'badd '.a:file
        endif

        let l:interpreter = getbufvar(a:file, '&filetype')
    endif

    let l:dbg = deepcopy(s:dbg)
    call extend(l:dbg, {
                \ 'file': a:file,
                \ 'cwd': getcwd(),
                \ 'var': copy(get(s:dbgShared, a:file, {}))
                \ })

    let l:dbg.varFlag = len(l:dbg.var) ? 1 : 0

    if l:interpreter ==# 'bash' && executable('bashdb')
        " Bash script
        let l:dbg.name = 'bash'
        let l:dbg.tool = 'bashdb'
        let l:breakFile = tempname()
        let l:var = map(keys(l:dbg.var), "'display '.v:val")
        call writefile(l:var + a:breakPoint + ['set args -q '.a:file], l:breakFile)
        let l:dbg.cmd = 'bashdb -q -x '.l:breakFile.' '.a:file
        let l:dbg.prompt = '\mbashdb<\d\+>'
        let l:dbg.fileNr = '\v\((\S+):(\d+)\):'
        let l:dbg.varVal = '\v^ \d+: (\S+) = (.*)$'
        let l:dbg.breakLine = '\vNum  *Type  *Disp  *Enb'
        let l:dbg.stackLine =  '\v^(->|##)\d+ '
        let l:dbg.watchLine = '\v^(watchpoint \d+: |  old value: |  new value: )'
        let l:dbg.d = "\n"
        let l:dbg.win = ['var', 'watch', 'stack']
        call extend(l:dbg.map, {'B': 'delete', 'S': 'skip', 'f': 'finish',
                    \ 'w': 'watch', 'W': 'watche', 'P': 'x'})
    elseif l:interpreter =~# 'python' && executable('pdb')
        " Python script
        let l:dbg.name = 'python'
        let l:dbg.tool = 'pdb'
        let l:dbg.cmd = l:interpreter.' -m pdb '.a:file
        let l:breakPoint = map(a:breakPoint, "substitute(v:val,'\\v(:\\d+)\\zs\\s+,?', ' ,', '')")
        let l:var = map(keys(l:dbg.var), "'display '.v:val")
        let l:dbg.postCmd = join(l:var + l:breakPoint, ';;')
        let l:dbg.prompt = '\v\(Pdb\)'
        let l:dbg.fileNr = '\v^\> (\S+)\((\d+)\)'
        let l:dbg.varVal = '\v^display ([^:]+): (.*)$'
        let l:dbg.breakLine = '\v^Num  *Type  *Disp  *Enb'
        let l:dbg.stackLine =  '\v  \S+/bdb.py\(\d+\)'
        let l:dbg.d = ';;'
        let l:dbg.win = ['var', 'stack']
        call extend(l:dbg.map, {'p': 'p', 'P': 'pp', 'j': 'jump', 'u': 'until'})
    elseif l:interpreter =~# 'perl'
        " Perl script
        let l:dbg.name = 'perl'
        let l:dbg.tool = 'perl'
        let l:alias = [
                    \ '= break b', '= bt T', '= step s',
                    \ '= continue c', '= next n', '= watch w',
                    \ '= run R', '= quit q'
                    \ ]
        let l:breakFile = tempname()
        call writefile(l:alias + a:breakPoint, l:breakFile)
        let l:dbg.cmd = l:interpreter.' -d '.a:file
        let l:dbg.postCmd = 'source '.l:breakFile
        let l:dbg.prompt = '\m DB<\d\+> '
        let l:dbg.fileNr = '\v\((\S+):(\d+)\)'
        let l:dbg.stackLine = '\m@ = '
        let l:dbg.win = []
        call extend(l:dbg.map, {'w': 'watch'})
    endif

    return l:dbg
endfunction


" Configure new tabpage for debug
" and set t:dbg variable
function! s:DbgUIInitalize(dbg)
    if exists('t:dbg')
        1wincmd w
    endif

    " Source view window
    exe 'tabedit '.a:dbg.file
    let l:suffix = get(s:displayIcon, a:dbg.id, ' ')
    let t:tab_lable = ' -- Debug'.l:suffix.'--'
    let t:task = "call t:dbg.sendCmd('q', '')"
    let t:dbg = a:dbg
    let t:dbg.srcWinId = win_getid()

    " Debug console window
    exe 'belowright '.s:dbgWinHeight.'split'
    let t:dbg.dbgWinId = win_getid()
    set winfixheight

    " Variables window
    if index(t:dbg.win, 'var') != -1
        exe 'topleft '.s:dbgSideWidth.'vnew var_'.t:dbg.id.'.dbgvar'
        let t:dbg.varWinId = win_getid()
        setlocal wrap
        setlocal nonumber
        setlocal nobuflisted
        setlocal winfixwidth
        setlocal buftype=nofile
        setlocal filetype=dbgvar
        setlocal statusline=\ Variables
    endif

    " Watch point window
    if index(t:dbg.win, 'watch') != -1
        let l:height = (&lines - s:dbgWinHeight - 3)/2 - 3
        exe 'belowright '.l:height.'new Watch_'.t:dbg.id.'.dbgwatch'
        let t:dbg.watchWinId = win_getid()
        setlocal wrap
        setlocal nonumber
        setlocal nobuflisted
        setlocal winfixheight
        setlocal buftype=nofile
        setlocal filetype=dbgwatch
        setlocal statusline=\ Watch%{get(t:dbg,'watchFlag',0)?'\ ':''}
    endif

    " Call stack window
    if index(t:dbg.win, 'stack') != -1
        exe 'belowright '.s:dbgWinHeight.'new stack_'.t:dbg.id.'.dbgstack'
        let t:dbg.stackWinId = win_getid()
        setlocal nowrap
        setlocal nonumber
        setlocal nobuflisted
        setlocal winfixheight
        setlocal buftype=nofile
        setlocal filetype=dbgstack
        setlocal statusline=\ Call\ Stack
    endif
endfunction


" Creat maping for easy debuging
function! s:DbgMaping(...)
    let l:mapPrefix = 'nnoremap <buffer> <silent> '

    if exists('t:dbg.varWinId')
        call win_gotoid(t:dbg.varWinId)

        for [l:key, l:cmd] in items(t:dbg.map)
            exe l:mapPrefix.l:key." :call <SID>DbgSendCmd('".l:cmd."')<CR>"
        endfor

        for l:i in [1, 2, 3, 4, 5]
            exe l:mapPrefix.l:i.' :'.l:i.'wincmd w<CR>'
        endfor

        nnoremap <buffer> <silent> <space> :call <SID>DbgVarDispaly()<CR>
    endif

    if exists('t:dbg.watchWinId')
        call win_gotoid(t:dbg.watchWinId)

        for l:i in [1, 2, 3, 4, 5]
            exe l:mapPrefix.l:i.' :'.l:i.'wincmd w<CR>'
        endfor

        nnoremap <buffer> <silent> <space> :echo getline('.')<CR>
    endif

    if exists('t:dbg.stackWinId')
        call win_gotoid(t:dbg.stackWinId)

        for l:i in [1, 2, 3, 4, 5]
            exe l:mapPrefix.l:i.' :'.l:i.'wincmd w<CR>'
        endfor

        nnoremap <buffer> <silent> u :call <SID>DbgSendCmd('up')<CR>
        nnoremap <buffer> <silent> d :call <SID>DbgSendCmd('down')<CR>
        nnoremap <buffer> <silent> <space> :echo getline('.')<CR>
    endif
endfunction


let s:cmdPromptInfo = {
            \ 'quit': 'Quit debug ?',
            \ 'jump': 'Jump to line number: ',
            \ 'until': 'Execute until line number: ',
            \ 'break': 'Set breakpoint: ',
            \ 'tbreak': 'Set one-time breakpoint: ',
            \ 'skip': 'Enter the number of statements to skip: ',
            \ 'display': 'Monitor a variable or expression: ',
            \ 'undisplay': 'Cancel a variable or expression monitoring: ',
            \ 'watch': 'watch a variable: ',
            \ 'watche': 'Watch a expression: ',
            \ 'condition': 'Input break number and condition: ',
            \ 'clear': 'Clear break numbers: ',
            \ 'delete': 'Clear break numbers: ',
            \ 'disable': 'Disable break numbers: ',
            \ 'enable': 'Enable break numbers: ',
            \ 'p': 'Print a variable or expression: ',
            \ 'x': 'Print a variable or expression: ',
            \ 'pp': 'Print a variable or expression: ',
            \ 'print': 'Print a variable or expression: ',
            \ 'send': 'Execute a debug command: '
            \ }

function! <SID>DbgSendCmd(cmd)
    let l:prompt = get(s:cmdPromptInfo, a:cmd, '*****: ')

    if a:cmd ==# 'quit' && confirm(l:prompt, "&Yes\n&No", 2) == 2
        return
    elseif a:cmd ==# 'send'
        let l:cmd = matchstr(input(l:prompt), '\v\S.*')
    elseif index(['jump', 'until', 'skip', 'break', 'tbreak'], a:cmd) != -1
        let l:cmd = a:cmd.' '.input(l:prompt)
    elseif index(['display', 'undisplay', 'watch', 'watche', 'print', 'p', 'pp', 'x'], a:cmd) != -1
        let l:cmd = a:cmd.' '.input(l:prompt, '', 'tag')
    elseif a:cmd ==# 'run' && t:dbg.name ==# 'python'
        let l:cmd = join(['run'] + map(keys(t:dbg.var), "'display '.v:val"), ';;')
    elseif a:cmd ==# '_undisplay'
        let l:var = matchstr(getline('.'), '\v^[^:]*')
        let l:cmd = 'undisplay '.l:var
        unlet t:dbg.var[l:var]
        let t:dbg.varFlag = 1
    elseif index(['condition', 'disable', 'enable', 'clear', 'delete'], a:cmd) != -1
        if !get(t:dbg, 'breakFlag', 0)
            let l:breakInfo = t:dbg.name ==# 'bash' ? 'info break' : 'break'
            call term_sendkeys(t:dbg.dbgBufnr, l:breakInfo."\n")

            let l:counts = 10
            while get(t:dbg, 'breakFlag', 1) != 1 && l:counts > 0
                sleep 100m
                let l:counts -= 1
            endwhile
        endif

        if len(get(t:dbg, 'break', [])) < 2
            return
        endif

        let l:in = input('  '.join(t:dbg.break,"\n  ")."\n".l:prompt)

        if empty(l:in)
            return
        endif

        let l:cmd = a:cmd.' '.l:in
    else
        let l:cmd = a:cmd
    endif

    " Update stack infomation
    if index(['continue', 'next', 'step', 'jump',
                \ 'until', 'skip', 'finish', 'return'], a:cmd) != -1 && has_key(t:dbg, 'd')
        let l:cmd = join([l:cmd, 'bt'], t:dbg.d)
    endif

    if !empty(l:cmd)
        call term_sendkeys(t:dbg.dbgBufnr, l:cmd."\n")
    endif
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
    let t:dbg.break = []
    let t:dbg.breakFlag = 0
    let t:dbg.stackFlag = 0
    let l:winId = win_getid()

    " Message analysis
    for l:item in split(t:dbg.tempMsg.a:msg, "\r*\n")
        if l:item =~# t:dbg.prompt
            continue
        elseif t:dbg.breakFlag == 1 || l:item =~# get(t:dbg, 'breakLine', '\v-^')
            let t:dbg.break += [substitute(l:item, t:dbg.cwd.'/', '', '')]
            let t:dbg.breakFlag = 1
        elseif t:dbg.stackFlag == 1 || l:item =~# get(t:dbg, 'stackLine', '\v-^')
            let t:dbg.stack += [substitute(l:item, t:dbg.cwd.'/', '', '')]
            let t:dbg.stackFlag = 1
        elseif l:item =~# get(t:dbg, 'watchLine', '\v-^')
            let t:dbg.watch += [l:item]
        else
            " Try varVal match: Monitoring Variable Change
            let l:match = matchlist(l:item, get(t:dbg, 'varVal', '\v-^'))
            if !empty(l:match) && l:match[2] != get(t:dbg.var, l:match[1], '')
                let t:dbg.varFlag = 1
                let t:dbg.var[l:match[1]] = l:match[2]
                continue
            endif

            " Try fileNr match: jump line
            let l:match = matchlist(l:item, get(t:dbg, 'fileNr', '\v-^'))
            if !empty(l:match) && filereadable(l:match[1])
                let l:fileNr = [l:match[1], l:match[2]]
                let t:dbg.watchFlag = 0
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
        let t:dbg.watchFlag = 1
    endif

    " Update variables window
    if get(t:dbg, 'varFlag', 0)
        let l:list = []
        for [l:var, l:val] in items(t:dbg.var)
            let l:val = substitute(l:val, '\s*\[old: .*\]$', '', '')
            let l:list += [l:var.': '.l:val, '']
        endfor

        call win_gotoid(t:dbg.varWinId)
        silent edit!
        call setline(1, l:list[0:-2])
        set filetype=dbgvar
        let t:dbg.varFlag = 0
    endif

    " Line jump
    if exists('l:fileNr')
        call win_gotoid(t:dbg.srcWinId)

        if expand('%') !~# l:fileNr[0]
            silent! exe 'edit '.l:fileNr[0]
        endif

        if l:fileNr[1] != line('.')
            call cursor(l:fileNr[1], 1)
            call s:DbgSetSign(l:fileNr[0], l:fileNr[1])
        endif
    endif

    " Update call stack window
    if !empty(t:dbg.stack)
        if t:dbg.tool =~# 'pdb'
            call remove(t:dbg.stack, 0, 2)
            call filter(t:dbg.stack, "v:val !~ '^->'")
        endif

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
    if has_key(t:dbg.sign, 'file')
        exe 'sign unplace '.t:dbg.sign.id.' file='.t:dbg.sign.file
    endif

    let l:signPlace = execute('sign place file='.a:file)
    " Ensure id uniqueness
    while !empty(matchlist(l:signPlace, '    \S\+=\d\+'.'  id='.t:dbg.sign.id.'  '))
        let t:dbg.sign.id += 1
    endwhile

    exe 'sign place '.t:dbg.sign.id.' line='.a:line.' name=DBGCurrent'.' file='.a:file
    let t:dbg.sign.file = a:file
endfunction


function! <SID>DbgVarDispaly()
    let l:var = matchstr(getline('.'), '^[^:]*')

    if l:var =~ '\S'
        echo l:var.': '.t:dbg.var[l:var]
    endif
endfunction


" 
function! s:DbgOnExit(...)
    if has_key(t:dbg.sign, 'file')
        exe 'sign unplace '.t:dbg.sign.id.' file='.t:dbg.sign.file
    endif

    if exists('t:dbg')
        call extend(s:dbgShared, {t:dbg.file: t:dbg.var})

        try
            tabclose
        catch
            call win_gotoid(t:dbg.srcWinId)
            unlet t:dbg
            unlet t:task
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
    let t:tab_lable = ' -- Debug --'

    if empty(l:breakPoint)
        exe 'Termdebug '.l:binFile
    else
        let l:tempFile = tempname()
        call writefile(l:breakPoint, l:tempFile)
        exe 'Termdebug -x '.l:tempFile. ' '.l:binFile
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

" vim:foldmethod=marker
