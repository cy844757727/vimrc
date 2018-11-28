"
"
"
"
if exists('g:loaded_A_Async') && v:version >= 800
  finish
endif
let g:loaded_A_Async = 1

hi AsyncDbg ctermbg=253 ctermfg=16 guibg=#1E1E1E guifg=#CCCCB0
sign define DBGCurrent text=⏩ texthl=AsyncDbg

let s:newSignId = 1
" Get default shell interpreter
let s:shell = fnamemodify(&shell, ':t')
let s:terminalType = {
            \ s:shell: s:shell,
            \ s:shell . '1': s:shell,
            \ s:shell . '2': s:shell,
            \ s:shell . '3': s:shell,
            \ s:shell . '4': s:shell,
            \ s:shell . '5': s:shell,
            \ 'ipython': 'ipython',
            \ 'python': 'python',
            \ 'python3': 'python3'
            \ }

if exists('g:Async_TerminalType')
    call extend(s:terminalType, g:Async_TerminalType, 'force')
endif


" Debug a script file
function async#DbgScript(...)
    if a:0 == 0
        return
    endif

    let l:file = a:1
    let l:breakPoint = a:0 > 1 ? a:2 : []
    
    " Ui & val initialization
    exe 'tabedit ' . l:file
    let t:dbg = {}
    let t:dbg.srcWinId = win_getid()
    let t:dbg.srcBufnr = bufnr('%')
    belowright 15new
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
    let t:dbg.dbgBufnr = term_start(t:dbg.cmd, {
                \ 'term_rows': 15,
                \ 'out_cb': function('s:DbgMsgHandle'),
                \ 'exit_cb': function('s:DbgOnExit'),
                \ 'term_kill': 'q',
                \ 'term_finish': 'close', 
                \ 'norestore': 1,
                \ 'curwin': 1
                \ })

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
    elseif l:interpreter == 'perl'
        " Perl script
        let l:breakFile = tempname()
        call writefile(['= break b'] + a:breakPoint, l:breakFile)
        let t:dbg.cmd = 'perl -d ' . a:file
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

        if !empty(t:dbg.match) && filereadable(t:dbg.match[1])
            call win_gotoid(t:dbg.srcWinId)
            exe 'edit ' . t:dbg.match[1]
            call cursor(t:dbg.match[2], 1)
            call s:setSign(expand('%'), t:dbg.match[2])
            call win_gotoid(t:dbg.dbgWinId)
        endif
    else
        let t:dbg.tempMsg .= a:msg
    endif
endfunction

" 
function s:setSign(file, line)
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
            call win_gotoid(t:srcWinId)
            unlet t:dbg
        endtry
    endif
endfunction


function async#RunScript(file)
    if !filereadable(a:file)
        return
    elseif !bufexists(a:file)
        exe 'badd ' . a:file
    endif

    let l:lineOne = getbufline(a:file, 1)[0]
    let l:interpreter = matchstr(l:lineOne, '\(/\(env\s\+\)\?\)\zs[^/]*$')

    if empty(l:interpreter)
        let l:interpreter = &filetype
    endif

    let l:cmd = l:interpreter . ' ' . a:file
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

    if !empty(l:breakPoint)
        let l:tempFile = tempname()
        call writefile(l:breakPoint, l:tempFile)

        exe 'Termdebug -x ' . l:tempFile .  ' ' . l:binFile
    else
        exe 'Termdebug ' . l:binFile
    endif

    autocmd BufUnload <buffer> unlet t:dbg|1close
endfunction

" Switch embedded terminal
" Args: action, type, postCmd
" Action: on, off, toggle (default: toggle)
" Type: specified by s:terminalType (default: bash)
" PostCmd: executing cmd when terminal started
function async#ToggleTerminal(...)
    let l:action = a:0 > 0 && !empty(a:1) ? a:1 : 'toggle'
    let [l:type, l:name] = a:0 > 1 && !empty(a:2) ? [a:2, '!' . a:2] : [s:shell, '!' . s:shell]
    let l:postCmd = a:0 > 2 ? a:3 : ''

    try
        if l:type
            let l:type = s:shell . l:type
            let l:name = '!' . l:type
        endif

        let l:cmd = s:terminalType[l:type]
    catch
        return
    endtry

    let l:winnr = bufwinnr(l:name)
    let l:bufnr = bufnr(l:name)

    if l:type == 'ipython' && l:bufnr == -1 && empty(l:postCmd)
        let l:postCmd = 'cd ' . getcwd()
    endif

    if l:winnr != -1
        if l:action == 'on'
            exe l:winnr . 'wincmd w'
        elseif l:action =~ 'off\|toggle'
            exe l:winnr . 'hide'
        endif
    elseif l:action =~ 'on\|toggle'
        " Hide other terminal
        for l:type in keys(s:terminalType)
            let l:otherWin = bufwinnr('!' . l:type)
            if l:otherWin != -1
                exe l:otherWin . 'hide'
            endif
        endfor

        if l:bufnr == -1
            " Start a terminal
            belowright 15new
            let l:bufnr = term_start(l:cmd, {
                        \ 'term_kill': 'kill',
                        \ 'term_finish': 'close',
                        \ 'curwin' : 1,
                        \ 'term_name': l:name,
                        \ 'norestore': 1
                        \ })
        else
            " Display terminal
            exe 'belowright 15new +' . l:bufnr . 'buffer'
        endif
    endif

    " Excuting postCmd after establishing terminal
    if !empty(l:postCmd)
        call term_sendkeys(l:bufnr, l:postCmd . "\n")
    endif

    return l:bufnr
endfunction

