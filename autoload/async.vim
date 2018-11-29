""""""""""""""""""""""""""""""""""""""""""""""""""""
" Author: CY <844757727@qq.com>
" Description: Asynchronous task
""""""""""""""""""""""""""""""""""""""""""""""""""""

if exists('g:loaded_A_Async') && v:version >= 800
  finish
endif
let g:loaded_A_Async = 1

hi AsyncDbgHl ctermbg=253 ctermfg=16 guibg=#1E1E1E guifg=#CCCCB0
sign define DBGCurrent text=⏩ texthl=AsyncDbgHl

let s:newSignId = 1
" Get default shell interpreter
let s:shell = fnamemodify(&shell, ':t')
let s:termPrefix = '!Terminal'
let s:termIcon = {
            \ '1': ' ➊', '2': ' ➋', '3': ' ➌',
            \ '4': ' ➍', '5': ' ➎', '6': ' ➏',
            \ '7': ' ➐', '8': ' ➑', '9': ' ➒'
            \ }

" Default terminal option
let s:termOption = {
            \ 'term_rows': 15,
            \ 'term_kill': 'kill',
            \ 'term_finish': 'close',
            \ 'stoponexit': 'exit',
            \ 'norestore': 1
            \ }

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
    call extend(s:termIcon, g:Async_TermIcom)
endif

" Debug a script file
function async#DbgScript(...)
    let l:file = a:0 > 0 && a:1 != '%' ? a:1 : expand('%')
    let l:breakPoint = a:0 > 1 ? a:2 : []
    
    " Ui & val initialization
    exe 'tabedit ' . l:file
    let t:tab_lable = ['', '-- Debug --']
    let t:dbg = {}
    let t:dbg.srcWinId = win_getid()
    let t:dbg.srcBufnr = bufnr('%')
    belowright 15split
    let t:dbg.dbgWinId = win_getid()
    let t:dbg.tempMsg = ''
    let t:dbg.sign = {}

    " Analyze script type & set val: cmd, postCmd, prompt, re
    call s:DbgScriptAnalyze(l:file, l:breakPoint)
    if !has_key(t:dbg, 'cmd')
        call s:DbgOnExit()
        return 0
    endif

    " Start debuge
    let l:option = copy(s:termOption)
    let l:option['curwin'] = 1
    let l:option['out_cb'] = function('s:DbgMsgHandle')
    let l:option['exit_cb'] = function('s:DbgOnExit')
    let t:dbg.dbgBufnr = term_start(t:dbg.cmd, l:option)

    " Excuting postCmd
    if has_key(t:dbg, 'postCmd')
        call term_sendkeys(t:dbg.dbgBufnr, t:dbg.postCmd . "\n")
    endif
endfunction


" Analyze script type & set val: cmd, postCmd, prompt, re
function s:DbgScriptAnalyze(file, breakPoint)
    if !filereadable(a:file)
        return
    elseif !bufexists(a:file)
        exe 'badd ' . a:file
    endif

    let l:lineOne = getbufline(a:file, 1)[0]
    let l:interpreter = matchstr(l:lineOne, '\(/\(env\s\+\)\?\)\zs\w\+\ze\([^/]*\)$')

    if empty(l:interpreter)
        let l:interpreter = getbufvar(a:file, '&filetype')
    endif

    if l:interpreter == 'bash' && executable('bashdb')
        " Bash script
        let l:breakFile = tempname()
        call writefile(a:breakPoint, l:breakFile)
        let t:dbg.cmd = 'bashdb -x ' . l:breakFile . ' ' . a:file
        let t:dbg.prompt = 'bashdb<\d\+>'
        let t:dbg.re = '(\(/\S\+\):\(\d\+\))'
    elseif l:interpreter =~ 'python' && (executable('ipdb') || executable('pdb'))
        " Python script
        let l:pdb = executable('ipdb') ? 'ipdb' : 'pdb'
        let t:dbg.cmd = l:interpreter . ' -m ' . l:pdb . ' ' . a:file
        let t:dbg.postCmd = join(a:breakPoint, ';;')
        let t:dbg.prompt = executable('ipdb') ? 'ipdb>' : '(Pdb)'
        let t:dbg.re = executable('ipdb') ? '\(/[/a-zA-Z0-9_.]\+\).*(\(\d\+\))' : '> \(\S\+\)(\(\d\+\))'
    elseif l:interpreter =~ 'perl'
        " Perl script
        let l:breakFile = tempname()
        call writefile(['= break b'] + a:breakPoint, l:breakFile)
        let t:dbg.cmd = l:interpreter . ' -d ' . a:file
        let t:dbg.postCmd = 'source ' . l:breakFile
        let t:dbg.prompt = ' DB<\d\+> '
        let t:dbg.re = '(\(\S\+\):\(\d\+\))'
    endif
endfunction


" 
function s:DbgMsgHandle(job, msg)
    if a:msg =~ t:dbg.prompt
        let t:dbg.match = matchlist(t:dbg.tempMsg . a:msg, t:dbg.re)
        let t:dbg.tempMsg = ''

        " Jump line
        if !empty(t:dbg.match) && filereadable(t:dbg.match[1])
            call win_gotoid(t:dbg.srcWinId)
            exe 'edit ' . t:dbg.match[1]
            call cursor(t:dbg.match[2], 1)
            call s:DbgSetSign(expand('%'), t:dbg.match[2])
            call win_gotoid(t:dbg.dbgWinId)
        endif
    else
        let t:dbg.tempMsg .= a:msg
    endif
endfunction


" 
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
    let l:interpreter = matchstr(l:lineOne, '\(/\(env\s\+\)\?\)\zs[^/]*$')

    if empty(l:interpreter)
        let l:interpreter = getbufvar(l:file, '&filetype')
    endif

    let l:cmd = l:interpreter . ' ' . l:file
    let l:bufnr = async#ToggleTerminal('on')
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
    let t:dbg = 1

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
            unlet t:dbg
        endtry
    endif
endfunction


" Switch embedded terminal
" Args: action, type, postCmd
" Action: on, off, toggle (default: toggle)
" Type: specified by s:termType (default: s:shell)
" PostCmd: executing cmd when terminal started
function async#ToggleTerminal(...)
    let l:action = a:0 > 0 && a:1 != '.' ? a:1 : 'toggle'
    let l:type = a:0 > 1 && a:2 != '.' ? a:2 : ''
    let l:postCmd = a:0 > 2 ? join(a:000[2:], ' ') : ''

    if empty(l:type)
        let l:type = s:shell
        let l:name = s:termPrefix
    elseif l:type
        let l:type = l:type > 0 ? l:type + 0 : l:type + len(s:termIcon) + 1
        let l:name = s:termPrefix . get(s:termIcon, l:type, '')
        let l:type = s:shell . l:type
    else
        let l:name = s:termPrefix . get(s:termIcon, l:type, ': ') . l:type
    endif

    let l:cmd = get(s:termType, l:type, '')

    if empty(l:cmd)
        " Invalid type
        return
    endif

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

        " Skip window containing buf with non empty buftype
        let l:num = winnr('$')
        while !empty(&buftype) && l:num > 0
            wincmd w
            let l:num -= 1
        endwhile

        if l:bufnr == -1
            " Start a terminal
            let l:option = copy(s:termOption)
            let l:option['term_name'] = l:name . ' '
            let l:option['curwin'] = 1
            belowright 15split
            let l:bufnr = term_start(l:cmd, l:option)
        else
            " Display terminal
            silent exe 'belowright 15split +' . l:bufnr . 'buffer'
        endif

        " Ensure starting insert mode
        if mode() == 'n'
            normal a
        endif
    elseif l:action == 'off' && !empty(l:postCmd) && l:bufnr == -1
        " Allow background execution
        let l:option = copy(s:termOption)
        let l:option['term_name'] = l:name . ' '
        let l:option['hidden'] = 1
        let l:bufnr = term_start(l:cmd, l:option)
    endif

    " Excuting postCmd after establishing a terminal
    if !empty(l:postCmd)
        call term_sendkeys(l:bufnr, l:postCmd . "\n")
    endif

    return l:bufnr
endfunction


" Cmd: list or string
function async#RunJob(cmd)
    if len(s:asyncJob) > s:maxJob
        return
    endif

    let l:job = job_start(a:cmd, {
                \ 'exit_cb': function('s:JobOnExit'),
                \ 'in_io': 'null',
                \ 'out_io': 'null',
                \ 'err_io': 'null'
                \ })

    if job_status(l:job) == 'run'
        let l:id = matchstr(l:job, '\d\+')
        let s:asyncJob[l:id] = {'cmd': a:cmd, 'job': l:job}
    endif
endfunction


function s:JobOnExit(job, status)
    let l:id = matchstr(a:job, '\d\+')
    
    if a:status > 0
        echo 'Failed: ' . s:asyncJob[l:id].cmd
    else
        echo 'Done: ' . s:asyncJob[l:id].cmd
    endif

    unlet s:asyncJob[l:id]
endfunction


function async#StopJob(...)
    if !empty(s:asyncJob)
        let l:how = a:0 > 0 ? a:1 : 'term'
        let l:prompt = async#ListJob("Select one to stop ...")
        
        while 1
            let l:job = get(s:asyncJob, input(l:prompt . "\nInput id: "), {'job': ''}).job

            if empty(l:job)
                redraw
            else
                call job_stop(l:job, l:how)
                break
            endif
        endwhile
    endif
endfunction

function async#ListJob(...)
    let l:prompt = a:0 > 0 ? a:1 : "Job List ..."

    for [l:id, l:job] in items(s:asyncJob)
        let l:prompt .= printf("\n    %d:  %s", l:id, l:job.cmd)
    endfor

    return l:prompt
endfunction

