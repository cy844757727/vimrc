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
hi default AsyncDbgHl ctermfg=16 guifg=#8bebff
sign define DBGCurrent text= texthl=AsyncDbgHl

let s:displayIcon = {
            \ '1': ' ➊ ', '2': ' ➋ ', '3': ' ➌ ',
            \ '4': ' ➍ ', '5': ' ➎ ', '6': ' ➏ ',
            \ '7': ' ➐ ', '8': ' ➑ ', '9': ' ➒ '
            \ }

" Default terminal type
let s:shell = fnamemodify(&shell, ':t')
let s:termType = [s:shell]
let s:termPrefix = '!Term'

" Default terminal option
let s:termOption = {
            \ 'term_kill':   'kill',
            \ 'term_finish': 'close',
            \ 'stoponexit':  'term',
            \ 'norestore':   1
            \ }

" Specify an interactive interpreter for a type
let s:interactive = {
            \ 'sh': s:shell,
            \ 'ruby': 'irb'
            \ }

" Extend terminal type & icon
if exists('g:Async_TerminalType')
    call extend(s:termType, g:Async_TerminalType)
endif

if exists('g:Async_displayIcon')
    call extend(s:displayIcon, g:Async_displayIcon)
endif

if exists('g:Async_interactive')
    call extend(s:interactive, g:Async_interactive)
endif

" Switch embedded terminal {{{2
" Args: action, cmd, postCmd
" Action: on, off, toggle (default: toggle)
" Cmd: specified by s:termType (default: s:shell)
" PostCmd: executing cmd after starting a terminal
function! async#TermToggle(...) abort
    " Ensure starting insert mode
    if bufname('%') =~# '\v^!' && mode() ==# 'n'
        normal a
    endif

    " Default variables
    let [l:action, l:cmd, l:name, l:postCmd] =
                \ ['toggle', s:shell, s:termPrefix.': '.s:shell.' ', '']

    " Configure variables
    for l:i in range(len(a:000))
        if index(['toggle', 'on', 'off'], a:000[l:i]) != -1
            let l:action = a:000[l:i]
        elseif index(s:termType, a:000[l:i]) != -1
            let l:cmd = a:000[l:i]
            let l:name = s:termPrefix . get(s:displayIcon, l:cmd, ': '.l:cmd.' ')
        elseif a:000[l:i]
            let l:cmd = s:shell
            let l:num = a:000[l:i] + (a:000[l:i] > 0 ? 0 : 10)
            let l:name = s:termPrefix . get(s:displayIcon, l:num, ': '.l:num.' ')
        else
            let l:postCmd = join(map(copy(a:000[l:i:]), "substitute(v:val, ' ', '\\\\ ', 'g')"), ' ')
            break
        endif
    endfor

    let l:winnr = bufwinnr(l:name)
    let l:bufnr = bufnr(l:name)
    let l:other = bufwinnr(s:termPrefix)

    if l:winnr != -1 
        exe l:winnr.(l:action ==# 'on' ? 'wincmd w' : 'hide')
    elseif l:name ==# s:termPrefix.': '.s:shell.' ' && l:other != -1
        " For default key always switch terminal window
        exe l:other.'hide'
    elseif l:action !=# 'off'
        " Hide other terminal
        if l:other != -1
            exe l:other.'hide'
        endif

        " Skip window containing buf with nonempty buftype
        let l:num = winnr('$')
        while !empty(&buftype) && l:num > 0
            wincmd w
            let l:num -= 1
        endwhile

        " Terminal window height
        let l:height = get(g:, 'BottomWinHeight', 15)

        if l:bufnr == -1
            " Creat a terminal
            let l:option = copy(s:termOption)
            let l:option['term_name'] = l:name
            let l:option['curwin'] = 1
            exe 'belowright '.l:height.'split'
            let l:bufnr = term_start(l:cmd, l:option)
        else
            " Display terminal
            silent exe 'belowright '.l:height.'split +'.l:bufnr.'buffer'
        endif

        setlocal winfixheight
    elseif !empty(l:postCmd) && l:bufnr == -1
        " Allow background execution when first creating terminal
        let l:option = copy(s:termOption)
        let l:option['term_name'] = l:name
        let l:option['hidden'] = 1
        let l:bufnr = term_start(l:cmd, l:option)
        " Without this, buftype may be empty
        call setbufvar(l:bufnr, '&buftype', 'terminal')
    endif

    " Excuting postCmd after establishing a terminal
    if !empty(l:postCmd) && l:bufnr != -1
        call term_sendkeys(l:bufnr, l:postCmd."\n")
    endif

    return l:bufnr
endfunction


" Switch terminal window between exists terminal {{{2
function! async#TermSwitch(...) abort
    if bufname('%') !~# s:termPrefix
        return
    endif

    let l:termList = filter(split(execute('ls R'), "\n"), "v:val =~# '".s:termPrefix."'")

    if len(l:termList) > 1
        call map(l:termList, "split(v:val)[0] + 0")
        let l:ind = index(l:termList, bufnr('%'))
        let l:ind = a:0 == 0 || a:1 == 'next' ?
                    \ (l:ind + 1) % len(l:termList) :
                    \ l:ind - 1

        hide
        silent exe 'belowright '.get(g:, 'BottomWinHeight', 15).'split +'.l:termList[l:ind].'buffer'
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
function! async#JobRun(bang, cmd) abort
    if len(s:asyncJob) > s:maxJob
        return
    endif

    let l:job = job_start(a:cmd, {
                \ 'exit_cb': function('s:JobOnExit'),
                \ 'in_io':   'null',
                \ 'out_io':  'null',
                \ 'err_io':  'null'
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
    let l:ex = ["echom 'async: ".s:asyncJob[l:id].cmd.' '.
                \ (a:status == 0 ? '[Done]' : '[Failed]')."'"]

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
        let l:jobIds = input(l:prompt."\nInput id: ", '', 'custom,async#CompleteIds')

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

function! async#CompleteIds(L, C, P)
    return join(keys(s:asyncJob), "\n")
endfunction

" === Script run/debug === {{{1
let s:dbgShared = {}
let s:dbg = {
            \ 'id': 0, 'sign': {}, 'tempMsg': '', 'map': {
            \ 'C': 'condition', 'D': 'disable',   'E':  'enable',
            \ 'B': 'clear',     'b': 'break',     'r':  'return',
            \ 'c': 'continue',  's': 'step',      'n':  'next',
            \ 'p': 'print',     'R': 'run',       'i':  'send',
            \ 'v': 'display',   'V': 'undisplay', '\d': '_undisplay',
            \ 'k': 'up',        'j': 'down',      'q':  'quit',
            \ '<CR>': ' '}
            \ }

function! s:dbg.sendCmd(cmd, args, ...) abort
    let l:args = a:args

    if index(['condition', 'disable', 'enable'], a:cmd) != -1
        call term_sendkeys(self.dbgBufnr,
                    \ (self.name ==# 'bash' ? 'info break' : 'break')."\n")

        let l:counts = 10
        while get(self, 'breakFlag', 1) != 1 && l:counts > 0
            sleep 100m
            let l:counts -= 1
        endwhile

        for l:str in get(self, 'break', [])
            if l:str =~# substitute(a:args, getcwd().'/', '', '')
                let l:id = matchstr(l:str, '^\d\+')
                let l:args = l:id.' '.(a:0 > 0 ? a:1 : '')
                break
            endif
        endfor

        if !exists('l:id')
            return
        endif
    endif

    if has_key(self, 'dbgBufnr')
        call term_sendkeys(self.dbgBufnr, a:cmd.' '.l:args."\n")
    endif
endfunction


function! async#RunScript(file) abort
    let l:file = a:file ==# 'visual' ? expand('%') : a:file

    if !filereadable(l:file)
        return
    elseif !executable('sed') && !bufloaded(l:file)
        exe '0vsplit +hide '.l:file
    endif

    let l:interpreter = matchstr(executable('sed') ? system('sed -n 1p '.shellescape(l:file))[:-2] :
                \ getbufline(l:file, 1)[0], '\v^(#!.*/(env\s+)?)\zs.*$')

    " No #!, try to use filetype
    if empty(l:interpreter)
        if !bufexists(l:file)
            exe 'badd '.l:file
        endif

        let l:interpreter = getbufvar(l:file, '&filetype')
    endif

    if a:file ==# 'visual'
        let l:interpreter = matchstr(l:interpreter, '^\S*')
        let l:cmd = get(s:interactive, l:interpreter, l:interpreter)
        call term_sendkeys(async#TermToggle('on', l:cmd), trim(getreg('*'), "\n")."\n")
    else
        call term_sendkeys(async#TermToggle('on', s:shell),
                    \ "clear\n".l:interpreter.' '.shellescape(l:file)."\n")
    endif
endfunction


" Debug a script file
function! async#DbgScript(file, breakPoint) abort
    if !filereadable(a:file)
        return
    elseif !executable('sed') && !bufloaded(a:file)
        exe '0vsplit +hide '.a:file
    endif

    " Analyze script type & set var: cmd, postCmd, prompt, re...
    let l:dbg = s:DbgScriptAnalyze(a:file, a:breakPoint)
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

    " Determinal dbg window height & side window width
    let l:height = get(g:, 'BottomWinHeight', 15) * 2 / 3
    let l:width = get(g:, 'SideWinWidth', 30) * 4 / 3

    " Ui initialization & maping
    call s:DbgUIInitalize(l:dbg, l:height, l:width)
    call s:DbgMaping()

    " Start debug
    call win_gotoid(t:dbg.dbgWinId)
    let l:option = copy(s:termOption)
    let l:option['curwin'] = 1
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
    let l:interpreter = matchstr(executable('sed') ? system('sed -n 1p '.shellescape(a:file))[:-2] :
                \ getbufline(a:file, 1)[0], '\v^(#!.*/(env\s+)?)\zs\S+')

    " No #!, try to use filetype
    if empty(l:interpreter)
        if !bufexists(l:file)
            exe 'badd '.a:file
        endif

        let l:interpreter = getbufvar(a:file, '&filetype')
    endif

    let l:dbg = deepcopy(s:dbg)
    let l:dbg.file = a:file
    let l:dbg.cwd = getcwd()
    " Using full path to prevent file conflict (fnamemodify)
    let l:dbg.var = copy(get(s:dbgShared, fnamemodify(a:file, ':p'), {}))
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
    elseif l:interpreter =~# 'perl' && executable('perl')
        " Perl script
        let l:dbg.name = 'perl'
        let l:dbg.tool = 'perl'
        let l:alias = ['= break b', '= bt T', '= step s',
                    \ '= continue c', '= next n', '= watch w',
                    \ '= run R', '= quit q']
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
function! s:DbgUIInitalize(dbg, height, width)
    if exists('t:dbg')
        1wincmd w
    endif

    " Source view window
    exe 'tabedit '.a:dbg.file
    let t:tab_lable = ' -- Debug'.get(s:displayIcon, a:dbg.id, ' ').'--'
    let t:task = "call t:dbg.sendCmd('q', '')"
    let t:dbg = a:dbg
    let t:dbg.srcWinId = win_getid()

    " Debug console window
    exe 'belowright '.a:height.'split'
    let t:dbg.dbgWinId = win_getid()
    setlocal winfixheight

    " Variables window
    if index(t:dbg.win, 'var') != -1
        exe 'topleft '.a:width.'vnew var_'.t:dbg.id.'.dbgvar'
        let t:dbg.varWinId = win_getid()
        setlocal wrap nonu nobuflisted winfixwidth
        setlocal buftype=nofile filetype=dbgvar
        setlocal statusline=\ Variables
    endif

    " Watch point window
    if index(t:dbg.win, 'watch') != -1
        exe 'belowright '.((&lines - a:height - 9)/2).'new Watch_'.t:dbg.id.'.dbgwatch'
        let t:dbg.watchWinId = win_getid()
        setlocal wrap nonu nobuflisted winfixheight
        setlocal buftype=nofile filetype=dbgwatch
        setlocal statusline=\ Watch%{get(t:dbg,'watchFlag',0)?'\ ':''}
    endif

    " Call stack window
    if index(t:dbg.win, 'stack') != -1
        exe 'belowright '.a:height.'new stack_'.t:dbg.id.'.dbgstack'
        let t:dbg.stackWinId = win_getid()
        setlocal nowrap nonu nobuflisted winfixheight
        setlocal buftype=nofile filetype=dbgstack
        setlocal statusline=\ Call\ Stack
    endif
endfunction

function <SID>DbgHelpDoc()
    let [l:s, l:i] = ['  ', 1]

    for [l:key, l:action] in items(t:dbg.map)
        let l:s .= printf('%-15s', l:key.':'.l:action).(l:i % 3 ? '' : "\n  ")
        let l:i += 1
    endfor 

    echo l:s
endfunction

" Creat maping for easy debuging
function! s:DbgMaping()
    let l:mapPrefix = 'nnoremap <buffer> <silent> '

    if exists('t:dbg.varWinId')
        call win_gotoid(t:dbg.varWinId)

        for [l:key, l:cmd] in items(t:dbg.map)
            exe l:mapPrefix.l:key." :call <SID>DbgSendCmd('".l:cmd."')<CR>"
        endfor

        for l:i in [1, 2, 3, 4, 5]
            exe l:mapPrefix.l:i.' :'.l:i.'wincmd w<CR>'
        endfor

        nnoremap <buffer> <silent> ? :call <SID>DbgHelpDoc()<CR>
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
            \ 'x': 'Pretty Print a variable or expression: ',
            \ 'pp': 'Pretty print a variable or expression: ',
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
            call term_sendkeys(t:dbg.dbgBufnr,
                        \ (t:dbg.name ==# 'bash' ? 'info break' : 'break')."\n")

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
    if a:msg !~# t:dbg.prompt
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
function! s:DbgOnExit(job, status)
    if has_key(t:dbg.sign, 'file')
        exe 'sign unplace '.t:dbg.sign.id.' file='.t:dbg.sign.file
    endif

    if exists('t:dbg')
        " Using full path to prevent file conflict (fnamemodify)
        call extend(s:dbgShared, {fnamemodify(t:dbg.file, ':p'): t:dbg.var})

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
function! async#GdbStart(binFile, breakPoint) abort
    if filereadable(a:binFile)
        let l:binFile = a:binFile
    else
        let l:files = filter(glob('*', '', 1),
                    \ "!isdirectory(v:val) && executable('./'.v:val)")
        let l:num = len(l:files)

        if l:num == 0
            return
        elseif l:num == 1
            let l:binFile = fnameescape(l:files[0])
        else
            let [l:i, l:str] = [0, "Selete target to debug: \n"]
            for l:file in l:files
                let l:str .= printf("  %-2d:  %s\n", l:i, l:file)
                let l:i += 1
            endfor
            let l:sel = input(l:str.'!?: ')

            if empty(l:sel)
                return
            endif

            let l:binFile = fnameescape(l:files[l:sel])
        endif
    endif

    if !exists(':Termdebug')
        packadd termdebug
    endif

    " New tab to debug
    tabnew
    let t:tab_lable = ' -- Debug --'

    if empty(a:breakPoint)
        exe 'silent Termdebug '.l:binFile
    else
        let l:tempFile = tempname()
        call writefile(a:breakPoint, l:tempFile)
        exe 'silent Termdebug -x '.l:tempFile.' '.l:binFile
    endif

    " Gdb on exit
    autocmd BufUnload <buffer> call s:GdbOnExit()
    let t:task = 'call term_sendkeys('.bufnr('%').",'q\ny\n')"
endfunction

function! s:GdbOnExit()
    if exists('t:tab_lable')
        try
            tabclose
        catch
            unlet t:task
            unlet t:tab_lable
        endtry
    endif
endfunction

" vim:foldmethod=marker
