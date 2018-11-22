""""""""""""""""""""""""""""""""""""""""""""""""""""
" Author: CY <844757727@qq.com>
" Description: BookMark_BreakPoint_ProjectManager
""""""""""""""""""""""""""""""""""""""""""""""""""""
if exists('loaded_A_BMBPSign')
  finish
endif
let loaded_A_BMBPSign = 1

" sign definition
hi NormalSign  ctermbg=253 ctermfg=16 guibg=#1E1E1E guifg=#FFFFFF
hi BreakPoint  ctermbg=253 ctermfg=16 guibg=#1E1E1E guifg=#CC1100
sign define BMBPSignBook text=🚩 texthl=NormalSign
sign define BMBPSignTodo text=🔖 texthl=NormalSign
sign define BMBPSignBreak text=💊 texthl=BreakPoint

let s:newSignId = 0
let s:signFile = '.signrecord'

" Bookmark: book    " TodoList: todo    " BreakPoint: break, tbreak
let s:allSignType = ['book', 'todo', 'break', 'tbreak']

" SignVec Record
" 'type': ['signDef', [{'id': ..., 'file': ..., 'attr': ...}]]
let s:signVec = {
            \ 'book': ['BMBPSignBook', []],
            \ 'todo': ['BMBPSignTodo', []],
            \ 'break': ['BMBPSignBreak', []],
            \ 'tbreak': ['BMBPSignBreak', []]
            \ }

" Workspace & project related
let s:sessionFile = '.session'
let s:vimInfoFile = '.viminfo'
let s:home = system('echo ~')[:-2]
let s:projectFile = s:home . '/.vim/.projectitem'
let s:projectItem = filereadable(s:projectFile) ? readfile(s:projectFile) : []

" ==========================================================
" == Sign Def ========================================= {{{1
" ==========================================================
" Toggle sign in the specified line of the specified file
" Type: Sign type: book, todo, break, tbreak
function s:SignToggle(file, line, type, attr)
    let l:def = s:signVec[a:type][0]
    let l:vec = s:signVec[a:type][-1]

    let l:signPlace = execute('sign place file=' . a:file)
    let l:id = matchlist(l:signPlace, '    \S\+=' . a:line . '  id=\(\d\+\)' . '  \S\+=' . l:def)
    if empty(l:id)
        " Ensure id uniqueness
        let s:newSignId += 1
        while !empty(matchlist(l:signPlace, '    \S\+=\d\+' . '  id=' . s:newSignId . '  '))
            let s:newSignId += 1
        endwhile

        " Set sign
        exe 'sign place ' . s:newSignId . ' line=' . a:line . ' name=' . l:def . ' file=' . a:file
        call add(l:vec, {'id': s:newSignId, 'file': a:file, 'attr': a:attr})
    else
        " Unset sign
        exe 'sign unplace ' . l:id[1] . ' file=' . a:file
        call filter(l:vec, 'v:val.id != ' . l:id[1])
    endif
endfunction

" BookMark jump
" Action: next, previous
function s:Signjump(type, action)
    let l:vec = s:signVec[a:type][-1]
    if !empty(l:vec)
        if a:action == 'next'
            " Jump next
            call add(l:vec, remove(l:vec, 0))
        else
            " Jump previous
            call insert(l:vec, remove(l:vec, -1))
        endif

        try
            exe 'sign jump ' . l:vec[-1].id . ' file=' . l:vec[-1].file
        catch
            " For invalid sign
            call remove(l:vec, -1)
            call s:Signjump(a:action)
        endtry
    endif
endfunction

" clear sign of a type
function s:SignClear(type)
    " Unset sign
    for l:sign in s:signVec[a:type][-1]
        exe 'sign unplace ' . l:sign.id . ' file=' . l:sign.file
    endfor

    " Empty vec
    let s:signVec[a:type][-1] = []
endfunction

" Load & set sign from a signFile
function s:SignLoad()
    if filereadable(s:signFile)
        " Read sign file
        let l:signList = readfile(s:signFile)

        " Load sign
        for l:str in l:signList
            try
                let [l:type, l:file, l:line] = split(l:str, '[ :]\+')[0:2]
            catch
                " Ignore damaged item
                continue
            endtry
            let l:attr = matchstr(l:str, '\(:\d\+\s\+\)\zs.*$')
            if filereadable(l:file)
                if !bufexists(l:file)
                    exe 'silent badd ' . l:file
                endif
                call s:SignToggle(l:file, l:line, l:type, l:attr)
            endif
        endfor
    endif
endfunction

" Save sign to a file
function s:SignSave()
    let l:content = []
    let l:signs = {}
    for l:item in split(execute('sign place'), "\n")
        let l:match = matchlist(l:item, '    \S\+=\(\d\+\)' . '  id=\(\d\+\)  \S\+=BMBPSign\S\+')
        if !empty(l:match)
            let l:signs[l:match[2]] = l:match[1]
        endif
    endfor

    " Get row information & set l:content
    for [l:type, l:vec] in items(s:signVec)
        for l:sign in l:vec[-1]
            try
                let l:line = l:signs[l:sign.id]
            catch
                " Ignore invalid data
                continue
            endtry
            let l:content += [l:type . ' ' . l:sign.file . ':' . l:line . ' ' . l:sign.attr]
        endfor
    endfor

    " Udate signFile
    if !empty(l:content)
        call writefile(l:content, s:signFile)
    else
        call delete(s:signFile)
    endif
endfunction

" Add attr to a sign
function s:SignAddAttr(file, line)
    try
        let l:signPlace = split(execute('sign place file=' . a:file), "\n")[2:]
    catch
        " No sign set 
        return
    endtry

    " Consider multiple signs setint at same line
    let l:getSign = []
    let l:ind = 1
    for l:sign in l:signPlace
        let l:list = matchlist(l:sign, '    \S\+' . a:line . '  id=\(\d\+\)' . '  \S\+=BMBPSign\(\S\+\)')
        if !empty(l:list)
            let l:getSign += [{'ind': l:ind, 'type': tolower(l:list[2]), 'id': l:list[1]}]
            let l:ind += 1
        endif
    endfor

    if empty(l:getSign)
        return
    elseif len(l:getSign) == 1
        let l:target = l:getSign[0]
    else
        echo l:getSign
        try
            let l:target = l:getSign[input('Select one (ind): ') + 1]
        catch
            return
        endtry
    endif

    " Add attr to a sign
    for l:sign in s:signVec[l:target.type][-1]
        if l:target.id == l:sign.id
            let l:sign.attr = input("Input attr: ")
            break
        endif
    endfor
endfunction

" ===================================================================
" == Project def =============================================== {{{1
" ===================================================================
" New project & save workspace or modify current project
function s:ProjectNew(name, type, path)
    " path -> absolute path | Default state
    let l:type = a:type == '.' ? 'undef' : a:type
    let l:path = a:path == '.' ? getcwd() : a:path

    " Whether it already exists
    for l:i in range(len(s:projectItem))
        if l:path == split(s:projectItem[l:i])[-1]
            let l:item = remove(s:projectItem, l:i)
            break
        endif
    endfor

    " For new item or modifing item(already exists)
    if a:path == '.' || !exists('l:item')
        let l:item = printf('%-20s  Type: %-12s  Path: %s', a:name, l:type, l:path)
    endif

    set noautochdir
    " Put the item first.
    call insert(s:projectItem, l:item)
    call writefile(s:projectItem, s:projectFile)

    " cd path
    if l:path != getcwd()
        if !isdirectory(l:path)
            call mkdir(l:path, 'p')
        endif
        exe 'silent cd ' . l:path
        silent %bwipeout
    endif

    let s:projectized = 1
    echo substitute(l:item, ' ' . s:home, ' ~', '')
endfunction

" Switch to path & load workspace
function s:ProjectSwitch(sel)
    set noautochdir
    let l:path = split(s:projectItem[a:sel])[-1]

    " Do not load twice
    if l:path == getcwd() && exists('s:projectized')
        return
    endif

    if l:path != getcwd()
        " Save current sign
        call s:SignSave()

        " Empty signVec
        for l:value in values(s:signVec)
            let l:value[-1] = []
        endfor

        exe 'silent cd ' . l:path

        " Empth workspace
        silent %bwipeout
    endif

    if exists('s:projectized')
        unlet s:projectized
    endif
    
    " Load target sign & workspace
    call s:SignLoad()
    call s:WorkSpaceLoad()

    " Put item first
    call insert(s:projectItem, remove(s:projectItem, a:sel))
    call writefile(s:projectItem, s:projectFile)

    echo substitute(s:projectItem[0], ' ' . s:home, ' ~', '')
endfunction

" Menu UI
function s:ProjectUI(start, tip)
    " ten items per page
    let l:page = a:start / 10 + 1

    " ui: head
    let l:ui = "** Project option  (cwd: " . substitute(getcwd(), s:home, '~', '') .
                \ '     num: ' . len(s:projectItem) . "     page: " . l:page . ")\n" .
                \ "   s:select  d:delete  m:modify  p:pageDown  P:pageUp  q:quit  " .
                \ "Q:vimleave  a/n:new  0-9:item\n" .
                \ "   !?:selection mode    Del:deletion mode    Mod:modification mode\n" .
                \ repeat('=', min([&columns - 10, 90])) .
                \ "\n"

    " ui: body (Path conversion)
    let l:ui .= join(
                \ map(s:projectItem[a:start:a:start+9],
                \ "printf(' %3d: ', v:key) . substitute(v:val, ' ' . s:home, ' ~', '')"),
                \ "\n") . "\n" . a:tip

    return [l:ui, l:page]
endfunction

function s:ProjectMenu()
    let [l:tip, l:mode] = ['!?:', 's']
    let l:start = empty(s:projectItem) ? [0] : range(0, len(s:projectItem) - 1, 10)
    while 1
        " Disply UI
        let [l:ui, l:page]= s:ProjectUI(l:start[0], l:tip)
        echo l:ui
        let l:char = nr2char(getchar())
        redraw!

        " options & Mode selection
        if l:char ==# 'p' && l:start != []
            call add(l:start, remove(l:start, 0))
        elseif l:char ==# 'P' && l:start != []
            call insert(l:start, remove(l:start, -1))
        elseif l:char == 's'
            let [l:tip, l:mode] = ['!?:', 's']
        elseif l:char =~ 'd'
            let [l:tip, l:mode] = ['Del:', 'd']
        elseif l:char == 'm'
            let [l:tip, l:mode] = ['Mod:', 'm']
        elseif l:char ==# 'q' || l:char == "\<Esc>"
            return
        elseif l:char ==# 'Q'
            qall
        elseif l:char == "\<cr>"
            let l:tip = matchstr(l:tip, '\S*$')
        elseif l:char =~ '\d\|\s' && l:char < len(s:projectItem)
            " Specific operation
            if l:mode == 's' && !(getcwd() == split(s:projectItem[l:start[0] + l:char])[-1] && exists('s:projectized'))
                " select
                call s:ProjectSwitch(l:char + 10 * (l:page - 1))
                break
            elseif l:mode == 'd'
                " delete
                call remove(s:projectItem, l:char)
                call writefile(s:projectItem, s:projectFile)
            elseif l:mode == 'm'
                " modify
                let l:path = split(s:projectItem[l:char])[-1]
                echo s:ProjectUI(l:start[0], '▼ Modelify item ' . str2nr(l:char))
                let l:argv = split(input("<name > <type>: "))
                redraw!
                if len(l:argv) == 2
                    let s:projectItem[l:char] = printf('%-20s  Type: %-12s  Path: %s',
                                \ l:argv[0], l:argv[1], l:path)
                    call writefile(s:projectItem, s:projectFile)
                else
                    let l:tip = 'Wrong Argument, Reselect. Mod:'
                endif
            endif
        elseif l:char =~ '[an]'
            " new
            echo s:ProjectUI(l:start[0], '▼ New Project')
            let l:argv = split(input('<name> <type> [path]: ', '', 'file'))
            let l:argc = len(l:argv)
            redraw!
            if l:argc == 2 || l:argc == 3
                call s:ProjectManager(l:argc, l:argv)
                break
            else
                let l:tip = 'Wrong Argument, Reselect. ' . matchstr(l:tip, '\S*$')
            endif
        else
            let l:tip = 'Invalid(' . l:char . '), Reselect. ' . matchstr(l:tip, '\S*$')
        endif
    endwhile
endfunction

function s:ProjectManager(argc, argv)
    if a:argc == 0
        call s:ProjectMenu()
    elseif a:argc == 1
        call s:ProjectSwitch(a:argv[0])
    elseif a:argc == 2
        let l:key = has_key(g:BMBPSign_ProjectType, a:argv[1]) ? a:argv[1] : 'default'
        let l:path = g:BMBPSign_ProjectType[l:key] . '/' . a:argv[0]
        call s:ProjectNew(a:argv[0], a:argv[1], l:path)
    elseif a:argc == 3
        call s:ProjectNew(a:argv[0], a:argv[1], a:argv[2] =~ '^\~' ? s:home . strpart(a:argv[2], 1) : a:argv[2])
    endif
endfunction

" Save current workspace to a file
" Content: session, viminfo
function s:WorkSpaceSave()
    " Pre-save processing
    if exists('g:BMBPSign_PreSaveEventList')
        call execute(g:BMBPSign_PreSaveEventList)
    endif

    " Save session & viminfo
    let s:projectized = 1
    set noautochdir
    exe 'mksession! ' . s:sessionFile
    let l:temp = &viminfo
    set viminfo='50,!,:100,/100,@100
    exe 'wviminfo! ' . s:vimInfoFile
    exe 'set viminfo=' . l:temp

    " For special buf situation(modify session file)
    if exists('g:BMBPSign_SpecialBuf')
        for l:item in items(g:BMBPSign_SpecialBuf)
            call system("sed -i 's/^file " . l:item[0] . ".*$/" . l:item[1] . "/' " . s:sessionFile)
        endfor
    endif

    " Remember the current window of each tab(modify session file)
    let l:sub = ''
    for l:i in range(1, tabpagenr('$'))
        let l:sub .= l:i . 'tabdo ' . tabpagewinnr(l:i) . 'wincmd w\n'
    endfor
    call system("sed -i 's/^\\(tabnext " . tabpagenr() . "\\)$/" . l:sub . "\\1/' " . s:sessionFile)

    " Project processing
    let [l:type, l:path] = ['undef', getcwd()]
    let l:parent = substitute(l:path, '/\w*$', '', '')
    for l:item in items(g:BMBPSign_ProjectType)
        if l:item[1] == l:parent
            let l:type = l:item[0]
            break
        endif
    endfor
    call s:ProjectNew(matchstr(l:path, '[^/]*$'), l:type, l:path)

    " Post-save processing
    if exists('g:BMBPSign_PostSaveEventList')
        call execute(g:BMBPSign_PostSaveEventList)
    endif
endfunction

" Restore workspace from a file
" Context: session, viminfo
function s:WorkSpaceLoad()
    " Pre-load processing
    if exists('g:BMBPSign_PreLoadEventList')
        call execute(g:BMBPSign_PreLoadEventList)
    endif

    set noautochdir
    let s:projectized = 1

    " Empty workspace
    if exists('s:projectized')
        " Restore sign (bwipeout will clear all sign)
        " For update signFile
        call s:SignSave()

        " Empty signVec
        for l:value in values(s:signVec)
            let l:value[-1] = []
        endfor

        %bwipeout
        " Restore sign
        call s:SignLoad()
    endif

    " Load viminfo
    if filereadable(s:vimInfoFile)
        let l:temp = &viminfo
        set viminfo='50,!,:100,/100,@100
        exe 'silent! rviminfo! ' . s:vimInfoFile
        exe 'set viminfo=' . l:temp
    endif

    " Load session
    if filereadable(s:sessionFile)
        exe 'silent! source ' . s:sessionFile
    endif

    " Post-load processing
    if exists('g:BMBPSign_PostLoadEventList')
        call execute(g:BMBPSign_PostLoadEventList)
    endif
endfunction

" ===============================================================
" == misc def ============================================== {{{1
" ===============================================================
" Return qfList used for seting quickfix
" Type: book, break, todo, tbreak
function s:GetQfList(type)
    let l:qf = []
    let l:signPlace = execute('sign place')

    for l:sign in s:signVec[a:type][-1]
        let l:line = matchlist(l:signPlace, '    \S\+=\(\d\+\)' . '  id=' . l:sign.id . '  ')
        if !empty(l:line)
            let l:text = system("sed -n '" . l:line[1] . "p' " . l:sign.file)[:-2]
            if l:sign.attr =~ '\S'
                let l:text = '[' . a:type . ':' . l:sign.attr . '] ' . l:text
            else
                let l:text = '['. a:type . '] ' . l:text
            endif

            let l:qf += [{
                        \ 'bufnr': bufnr(l:sign.file),
                        \ 'filename': l:sign.file,
                        \ 'lnum': l:line[1],
                        \ 'text': l:text
                        \ }]
        endif
    endfor

    return l:qf
endfunction

" comment char
let s:commentChar = {
            \ 'c': '//', 'cpp': '//', 'java': '//', 'verilog': '//', 'systemverilog': '//',
            \ 'javascript': '//', 'go': '//', 'scala': '//', 'php': '//',
            \ 'sh': '#', 'python': '#', 'tcl': '#', 'perl': '#', 'make': '#', 'maple': '#',
            \ 'awk': '#', 'ruby': '#', 'r': '#', 'python3': '#',
            \ 'tex': '%', 'latex': '%', 'postscript': '%', 'matlab': '%',
            \ 'vhdl': '--', 'haskell': '--', 'lua': '--', 'sql': '--', 'openscript': '--',
            \ 'ada': '--',
            \ 'lisp': ';', 'scheme': ';',
            \ 'vim': "\""
            \ }

" Generate todo statement
function s:TodoStatement()
    try
        let l:todo = s:commentChar[&filetype] . ' TODO: '
    catch
        let l:todo = ' TODO: '
    endtry
    
    return l:todo
endfunction

" ======================================================
" == Global def =================================== {{{1
" ======================================================
function BMBPSign#Project(...)
    call s:ProjectManager(a:0, a:000)
endfunction

" Toggle sign of a type
" Type: book,todo,break,tbreak
function BMBPSign#SignToggle(type)
    let l:file = expand('%')

    if empty(&buftype) && filereadable(l:file)
        if a:type == 'todo' && getline('.') !~ 'TODO:'
            call append('.', s:TodoStatement())
            normal j==
            silent write
        endif

        call s:SignToggle(l:file, line('.'), a:type, '')
    endif
endfunction

function BMBPSign#SignJump(type, action)
    call s:Signjump(a:type, a:action)
endfunction

" Cancel sign of a type
" Type: book, todo, break, tbreak
" Multiple parameters are separated by spaces
function BMBPSign#SignClear(type)
    let l:pre = matchstr(a:type, '^[^.]*')
    if filereadable(l:pre . s:signFile)
        call delete(l:pre . s:signFile)
    else
        for l:type in split(a:type, '\s\+')
            call s:SignClear(l:type)
        endfor
    endif
endfunction

function BMBPSign#SignSave(pre)
    call s:SignSave()
    let l:pre = matchstr(a:pre, '^[^.]*')
    if !empty(l:pre)
        call system('cp ' . s:signFile . ' ' . l:pre . s:signFile)
    endif
endfunction

function BMBPSign#SignLoad(pre)
    let l:pre = matchstr(a:pre, '^[^.]*')
    if !empty(l:pre) && filereadable(l:pre . s:signFile)
        call system('cp ' . l:pre . s:signFile . ' ' . s:signFile)
    endif
    if filereadable(s:signFile)
        for l:type in s:allSignType
            call s:SignClear(l:type)
        endfor
        call s:SignLoad()
    endif
endfunction

function BMBPSign#SignAddAttr()
    call s:SignAddAttr(expand('%'), line('.'))
endfunction

function BMBPSign#WorkSpaceSave(pre)
    let l:pre = matchstr(a:pre, '^[^.]*')
    call s:WorkSpaceSave()
    if !empty(l:pre)
        call system('cp ' . s:sessionFile . ' ' . l:pre . s:sessionFile)
        call system('cp ' . s:vimInfoFile . ' ' . l:pre . s:vimInfoFile)
    endif
endfunction

function BMBPSign#WorkSpaceLoad(pre)
    let l:pre = matchstr(a:pre, '^[^.]*')
    if !empty(l:pre) && filereadable(l:pre . s:sessionFile)
        call system('cp ' . l:pre . s:sessionFile . ' ' . s:sessionFile)
        call system('cp ' . l:pre . s:vimInfoFile . ' ' . s:vimInfoFile)
    endif
    if filereadable(s:sessionFile)
        call s:WorkSpaceLoad()
    endif
endfunction

function BMBPSign#WorkSpaceClear(pre)
    let l:pre = matchstr(a:pre, '^[^.]*')
    call delete(l:pre . s:sessionFile)
    call delete(l:pre . s:vimInfoFile)
    if empty(l:pre) && exists('s:projectized')
        unlet s:projectized
    endif
endfunction

" Set QuickFix window with qfList
" Type: book, todo, break, tbreak
" Multiple parameters are separated by spaces
function BMBPSign#SetQfList(type, title)
    let l:qf = []
    for l:type in split(a:type, '\s\+')
        let l:qf += s:GetQfList(l:type)
    endfor

    call setqflist([], 'r', {'title': a:title, 'items': l:qf})
endfunction

function BMBPSign#SignTypeList()
    return s:allSignType
endfunction

" AutoCmd for VimEnter event
" Load sign when starting with a file
function BMBPSign#VimEnterEvent()
    " Stop load when signs already exists
    for l:vec in values(s:signVec)
        if !empty(l:vec[-1])
            return
        endif
    endfor

    let l:file = expand('%')
    if filereadable(s:signFile) && !empty(l:file) && !empty(systemlist("grep '" . l:file . "' " . s:signFile))
        call s:SignLoad()
    endif
endfunction

" AutoCmd for VimLeave event
" For storing | updating signFile
function BMBPSign#VimLeaveEvent()
    call s:SignSave()
    if exists('s:projectized')
        call s:WorkSpaceSave()
    endif
endfunction

" Api: Get sign record info for other purpose
" like breakpoint for debug (similar to s:SignSave())
" Multiple parameters are separated by spaces 
function BMBPSign#SignRecord(type)
    let l:signRecord = []
    let l:signPlace = execute('sign place')

    " Get row information & set l:signRecord
    for l:type in split(a:type, '\s\+')
        for l:sign in s:signVec[l:type][-1]
            let l:line = matchlist(l:signPlace, '    \S\+=\(\d\+\)' . '  id=' . l:sign.id . '  ')
            if !empty(l:line)
                let l:signRecord += [l:type . ' ' . l:sign.file . ':' . l:line[1] . ' ' . l:sign.attr]
            endif
        endfor
    endfor

    return l:signRecord
endfunction

" Return status whether saving workspace when :qa
function BMBPSign#ProjectStatus()
    if exists('s:projectized')
        return 1
    endif
    return 0
endfunction
