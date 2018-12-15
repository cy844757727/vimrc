""""""""""""""""""""""""""""""""""""""""""""""""""""
" Author: CY <844757727@qq.com>
" Description: BookMark_TodoList_BreakPoint_ProjectManager
""""""""""""""""""""""""""""""""""""""""""""""""""""
if exists('g:loaded_A_BMBPSign') || !has('signs')
  finish
endif
let g:loaded_A_BMBPSign = 1

" sign highlight definition
hi BMBPSignHl  ctermbg=253 ctermfg=16 guibg=#1E1E1E guifg=#FCD133
hi BreakPoint  ctermbg=253 ctermfg=16 guibg=#1E1E1E guifg=#DE3D3B

" Sign name rule: 'BMBPSign' . type
sign define BMBPSignBook text=🚩 texthl=BMBPSignHl
sign define BMBPSignTodo text=🔖 texthl=BMBPSignHl
sign define BMBPSignBreak text=💊 texthl=BreakPoint
sign define BMBPSignTBreak text=💊 texthl=BreakPoint

" SignVec Record
" Bookmark: book    " TodoList: todo    " BreakPoint: break, tbreak
" Content: 'type': [{'id': ..., 'file': ..., 'attr': ...}]
let s:signVec = {
            \ 'book':   [],
            \ 'todo':   [],
            \ 'break':  [],
            \ 'tbreak': []
            \ }

let s:newSignId = 0
" Type grouping for qflist 
" Quickfix window autoupdating depends on it
let s:typesGroup = {}
" Sign id record
" Content: 'id': ['type', 'file']
let s:signId = {}

" Sign type binding
" Content: 'type': 'signDef'
let s:signDef = {
            \ 'book':   'BMBPSignBook',
            \ 'todo':   'BMBPSignTodo',
            \ 'break':  'BMBPSignBreak',
            \ 'tbreak': 'BMBPSignTBreak'
            \ }

" Default File name
if has('unix') || has('mac')
    let s:signFile = '.signrecord'
    let s:sessionFile = '.session'
    let s:vimInfoFile = '.viminfo'
else
    let s:signFile = '_signrecord'
    let s:sessionFile = '_session'
    let s:vimInfoFile = '_viminfo'
endif

" Default project type associate with specified path
let s:projectType = {'default': $HOME . '/Documents'}
" Default content to save
let s:sessionOptions = 'blank,buffers,curdir,folds,help,options,tabpages,winsize,terminal'
let s:vimInfo="'50,!,:100,/100,@100"

" Project record file defination
if has('unix') || has('mac')
    let s:projectFile = $HOME . '/.vim/.projectitem'
else
    let s:projectFile = $HOME . '/vimfiles/.projectitem'
endif



if exists('g:BMBPSign_SessionOption')
    let s:sessionOptions = g:BMBPSign_SessionOption
endif

if exists('g:BMBPSign_VimInfo')
    let s:vimInfo = g:BMBPSign_VimInfo
endif

if exists('g:BMBPSign_ProjectFile')
    let s:projectFile = g:BMBPSign_ProjectFile
endif

" Load project items
let s:projectItem = filereadable(s:projectFile) ? readfile(s:projectFile) : []

if exists('g:BMBPSign_ProjectType')
    call extend(s:projectType, g:BMBPSign_ProjectType, 'force')
endif

" For $HOME path substitute
call map(s:projectType, "v:val =~ '^\\~' ? $HOME . strpart(v:val, 1) : v:val")

" Sign type extendsion: customized
if exists('g:BMBPSignTypeExtend')
    for l:sign in g:BMBPSignTypeExtend
        try
            let l:type = l:sign.type
            let l:name = get(l:sign, 'name', 'BMBPSign' . toupper(l:type[0]) . l:type[1:])

            " Naming rule check
            if l:name !~ 'BMBPSign' . l:type
                let l:name = 'BMBPSign' . toupper(l:type[0]) . l:type[1:]
            endif

            let l:text = get(l:sign, 'text', '🎈')
            let l:texthl = get(l:sign, 'texthl', 'BMBPSignHl')
            let l:linehl = get(l:sign, 'linehl', 'Normal')
            exe 'sign define ' . l:name . ' text=' . l:text . ' texthl=' . l:texthl . ' linehl=' . l:linehl
            let s:signVec[l:type] = []
            let s:signDef[l:type] = l:name
        catch
            continue
        endtry
    endfor
endif

" == Sign Def ========================================= {{{1
" Toggle sign in the specified line of the specified file
" Type: book, todo, break, tbreak ...
" Attr: Additional attribute
" Skip: Whether to unset if sign existing (set 1 for merging: forbiden unset)
function s:SignToggle(file, line, type, attr, skip)
    let l:def = get(s:signDef, a:type, a:type)
    let l:vec = get(s:signVec, a:type, [])
    let l:signPlace = execute('sign place file=' . a:file)
    let l:id = matchlist(l:signPlace, '    \S\+=' . a:line . '  id=\(\d\+\)' . '  \S\+=' . l:def)
    let g:BMBPSign_SignSetFlag = 1

    if empty(l:id)
        " Ensure id uniqueness
        let s:newSignId += 1
        while !empty(matchlist(l:signPlace, '    \S\+=\d\+' . '  id=' . s:newSignId . '  '))
            let s:newSignId += 1
        endwhile

        " Set sign
        exe 'sign place ' . s:newSignId . ' line=' . a:line . ' name=' . l:def . ' file=' . a:file
        call add(l:vec, {'id': s:newSignId, 'file': a:file, 'attr': a:attr})
        let s:signId[s:newSignId] = [a:type, a:file]

        if exists('t:dbg') && a:type =~ 'break'
            call t:dbg.sendCmd(a:type, a:file.':'.a:line)
        endif
    elseif a:skip == 0
        " Unset sign
        exe 'sign unplace ' . l:id[1] . ' file=' . a:file
        call filter(l:vec, 'v:val.id != ' . l:id[1])
        unlet s:signId[l:id[1]]

        if exists('t:dbg') && a:type =~ 'break'
            call t:dbg.sendCmd('clear', a:file.':'.a:line)
        endif
    endif
endfunction

" BookMark jump
" Action: next, previous
function s:Signjump(type, action)
    let l:vec = get(s:signVec, a:type, [])

    if !empty(l:vec)
        if a:action == 'next'
            call add(l:vec, remove(l:vec, 0))
        else
            call insert(l:vec, remove(l:vec, -1))
        endif

        " Try jumping to a tab containing this buf
        let l:bufnr = bufnr(l:vec[-1].file)
        if index(tabpagebuflist(), l:bufnr) == -1
            let l:winId = win_findbuf(l:bufnr)

            if !empty(l:winId)
               exe win_id2tabwin(l:winId[0])[0] . 'tabnext'
           endif
       endif

        try
            exe 'sign jump ' . l:vec[-1].id . ' file=' . l:vec[-1].file
        catch
            " For invalid sign
            unlet s:signId[l:vec[-1].id]
            call remove(l:vec, -1)
            call s:Signjump(a:type, a:action)
        endtry
    endif
endfunction

" clear sign of types specified
" Types -> list
function s:SignClear(types)
    for l:type in a:types
        let l:vec = get(s:signVec, l:type, [])

        " Unset sign
        for l:sign in l:vec
            exe 'sign unplace ' . l:sign.id . ' file=' . l:sign.file
            unlet s:signId[l:sign.id]
        endfor

        " Empty vec
        if !empty(l:vec)
            unlet l:vec[:]
        endif
    endfor
endfunction

" Load & set sign from a file
" File Name: a:pre . s:signFile
" Types -> list: Specify the types to clear first
" Signs that have not been cleared are merged
" Pre: file prefix: does not contain points and underscores
function s:SignLoad(pre, types)
    let l:signFile = a:pre . s:signFile

    if filereadable(l:signFile)
        " Read sign file
        let l:signList = readfile(l:signFile)

        " Clear sign of types
        call s:SignClear(a:types)

        " Load sign
        let l:types = []
        for l:str in l:signList
            try
                let [l:type, l:file, l:line] = split(l:str, '[ :]\+')[0:2]
                let l:types += [l:type]
            catch
                " Ignore damaged item
                continue
            endtry

            if !filereadable(l:file)
                continue
            elseif !bufexists(l:file)
                exe 'silent badd ' . l:file
            endif

            let l:attr = matchstr(l:str, '\(:\d\+\s\+\)\zs.*$')
            call s:SignToggle(l:file, l:line, l:type, l:attr, 1)
        endfor

        if !empty(l:types)
            call s:QfListUpdate(uniq(l:types))
        endif
    endif
endfunction

" Save sign of types to a file
" File Name: a:pre . s:signFile
" Types -> list
function s:SignSave(pre, types)
    let l:signFile = a:pre . s:signFile

    " Get all valid BMBPSign of types
    " Content: 'id': lineNr
    let l:signs = {}
    let l:def = '\(' . join(a:types, '\|') . '\)'
    for l:item in split(execute('sign place'), "\n")
        let l:match = matchlist(l:item, '    \S\+=\(\d\+\)' . '  id=\(\d\+\)  \S\+=BMBPSign' . l:def)

        if !empty(l:match)
            let l:signs[l:match[2]] = l:match[1]
        endif
    endfor

    " set l:content
    let l:content = []
    for l:type in a:types
        for l:sign in get(s:signVec, l:type, [])
            try
                let l:line = l:signs[l:sign.id]
            catch
                " Ignore invalid data
                continue
            endtry

            let l:content += [l:type . ' ' . l:sign.file . ':' . l:line]

            if !empty(l:sign.attr)
                let l:content[-1] .= '  '.l:sign.attr
            endif
        endfor
    endfor

    " Udate signFile
    if !empty(l:content)
        call writefile(l:content, l:signFile)
    else
        call delete(l:signFile)
    endif
endfunction

" Add attr to a sign
function s:SignAddAttr(types, file, lin)
    let l:signPlace = execute('sign place '.(!empty(a:file) ? 'file='.a:file : ''))

    let l:items = {}
    for l:type in empty(a:types) ? keys(s:signVec) : a:types
        for l:item in s:signVec[l:type]
            let l:list = matchlist(l:signPlace, '    \S\+=\(\d\+\)  id='.l:item.id.'  \S\+=BMBPSign')
            
            if !empty(l:list) && l:list[1] =~ a:lin
                let l:items[l:item.id] = {'file': l:item.file, 'type': l:type, 'lin': l:list[1]}
            endif
        endfor
    endfor

    if empty(l:items)
        return
    endif

    let l:str = "  id      type      where\n"
    for [l:id, l:val] in items(l:items)
        let l:str .= printf('  %-3d     %-6s    %s:%d',
                    \ l:id, l:val.type, substitute(l:val.file, getcwd().'/', '', ''), l:val.lin)."\n"
    endfor

    if len(l:items) > 1
        let l:id = input(l:str."Select Id: ")
        let l:val = get(l:items, l:id, {})
        let l:str = ''
    endif

    if empty(l:val)
        return
    endif

    " Add attr to a sign
    for l:sign in s:signVec[l:val.type]
        if l:sign.id == l:id
            let l:sign.attr = matchstr(input(l:str.'Input attr('.l:id.':'.l:val.type.'): ', l:sign.attr), '\S.*')
            break
        endif
    endfor

    call s:QfListUpdate([l:type])
    
    if exists('t:dbg') && l:type =~ 'break'
        call t:dbg.sendCmd('condition', l:val['file'].':'.l:val['lin'], l:sign.attr)
    endif
endfunction

" Unset sign by ids
" Ids -> list
function s:SignUnsetById(ids)
    let l:types = []

    for l:id in a:ids
        let [l:type, l:file] = get(s:signId, l:id, ['invalid', ''])

        if bufexists(l:file)
            exe 'sign unplace ' . l:id . ' file=' . l:file
            call filter(s:signVec[l:type], 'v:val.id != ' . l:id)
            unlet s:signId[l:id]
            let l:types += [l:type]
        endif
    endfor

    if !empty(l:types)
        call s:QfListUpdate(uniq(l:types))
    endif
endfunction

" == Project def =============================================== {{{1
" New project & save workspace or modify current project
function s:ProjectNew(name, type, path)
    set noautochdir
    let g:BMBPSign_Projectized = 1

    " path -> absolute path | Default
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

    echo substitute(l:item, ' ' . $HOME, ' ~', '')
endfunction

" Switch to path & load workspace
function s:ProjectSwitch(sel)
    set noautochdir
    let l:path = split(s:projectItem[a:sel])[-1]

    " Do not load twice
    if l:path == getcwd() && exists('g:BMBPSign_Projectized')
        return
    endif

    if l:path != getcwd()
        " Save current workspace
        if exists('g:BMBPSign_SignSetFlag')
            call s:SignSave('', keys(s:signVec))
        endif

        if exists('g:BMBPSign_Projectized')
            call s:WorkSpaceSave('')
        endif

        exe 'silent cd ' . l:path

        " Empth workspace
        silent! %bwipeout
    endif

    if exists('g:BMBPSign_SignSetFlag')
        unlet g:BMBPSign_SignSetFlag
    endif

    if exists('g:BMBPSign_Projectized')
        unlet g:BMBPSign_Projectized
    endif
    
    " Load target sign & workspace
    call s:SignLoad('', keys(s:signVec))
    call s:WorkSpaceLoad('')

    " Put item first
    call insert(s:projectItem, remove(s:projectItem, a:sel))
    call writefile(s:projectItem, s:projectFile)

    echo substitute(s:projectItem[0], ' ' . $HOME, ' ~', '')
endfunction

" Menu UI
function s:ProjectUI(start, tip)
    " ten items per page
    let l:page = a:start / 10 + 1

    " ui: head
    let l:ui = "** Project option  (cwd: " . substitute(getcwd(), $HOME, '~', '') .
                \ '     num: ' . len(s:projectItem) . "     page: " . l:page . ")\n" .
                \ "   s:select  d:delete  m:modify  p:pageDown  P:pageUp  q:quit  " .
                \ "Q:vimleave  a/n:new  0-9:item\n" .
                \ "   !?:selection mode    Del:deletion mode    Mod:modification mode\n" .
                \ repeat('=', min([&columns - 10, 90])) . "\n"

    " ui: body (Path conversion)
    let l:ui .= join(
                \ map(s:projectItem[a:start:a:start+9],
                \ "printf(' %3d: ', v:key) . substitute(v:val, ' ' . $HOME, ' ~', '')"),
                \ "\n") . "\n" .
                \ a:tip

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
            if l:mode == 's' && !(getcwd() == split(s:projectItem[l:start[0] + l:char])[-1] && exists('g:BMBPSign_Projectized'))
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
        let l:type = has_key(s:projectType, a:argv[1]) ? a:argv[1] : 'default'
        let l:path = s:projectType[l:type] . '/' . a:argv[0]
        call s:ProjectNew(a:argv[0], l:type, l:path)
    elseif a:argc == 3
        call s:ProjectNew(a:argv[0], a:argv[1], a:argv[2] =~ '^\~' ? $HOME . strpart(a:argv[2], 1) : a:argv[2])
    endif
endfunction

" Save current workspace to a file
" Content: session, viminfo
" File Name: a:pre . s:sessionFile, a:pre . s:vimInfoFile
function s:WorkSpaceSave(pre)
    " Pre-save processing
    if exists('g:BMBPSign_PreSaveEventList')
        call execute(g:BMBPSign_PreSaveEventList)
    endif

    set noautochdir
    let g:BMBPSign_Projectized = 1
    let l:sessionFile = a:pre . s:sessionFile
    let l:vimInfoFile = a:pre . s:vimInfoFile

    " Save session
    let l:temp = &sessionoptions
    exe 'set sessionoptions=' . s:sessionOptions
    exe 'mksession! ' . l:sessionFile
    exe 'set sessionoptions=' . l:temp

    " Save viminfo
    let l:temp = &viminfo
    exe 'set viminfo=' . s:vimInfo
    exe 'wviminfo! ' . l:vimInfoFile
    exe 'set viminfo=' . l:temp

    " For special buf situation(modify session file)
    if exists('g:BMBPSign_SpecialBuf') && executable('sed')
        for l:item in items(g:BMBPSign_SpecialBuf)
            call system("sed -i 's/^file " . l:item[0] . ".*$/" . l:item[1] . "/' " . l:sessionFile)
        endfor
    endif

    " Remember the current window of each tab(modify session file: append)
    let l:curWin = range(1, tabpagenr('$'))
    unlet l:curWin[tabpagenr() - 1]
    call map(l:curWin, "v:val . 'tabdo ' . tabpagewinnr(v:val) . 'wincmd w'")
    call writefile(l:curWin + ['tabnext ' . tabpagenr()], l:sessionFile, 'a')

    " Project processing
    let [l:type, l:path] = ['undef', getcwd()]
    let l:parentPath = fnamemodify(l:path, ':h')
    for l:item in items(s:projectType)
        if l:item[1] == l:parentPath
            let l:type = l:item[0]
            break
        endif
    endfor
    call s:ProjectNew(fnamemodify(l:path, ':t'), l:type, l:path)

    " Post-save processing
    if exists('g:BMBPSign_PostSaveEventList')
        call execute(g:BMBPSign_PostSaveEventList)
    endif
endfunction

" Restore workspace from a file
" Context: session, viminfo
" File Name: a:pre . s:sessionFile, a:pre . s:vimInfoFile
function s:WorkSpaceLoad(pre)
    " Pre-load processing
    if exists('g:BMBPSign_PreLoadEventList')
        call execute(g:BMBPSign_PreLoadEventList)
    endif

    " Empty workspace
    if exists('g:BMBPSign_Projectized')
        silent wall
        call s:SignSave('', keys(s:signVec))
        silent %bwipeout!
        call s:SignLoad('', [])
    endif

    set noautochdir
    let g:BMBPSign_Projectized = 1
    let l:sessionFile = a:pre . s:sessionFile
    let l:vimInfoFile = a:pre . s:vimInfoFile

    " Load viminfo
    if filereadable(l:vimInfoFile)
        let l:temp = &viminfo
        exe 'set viminfo=' . s:vimInfo
        exe 'silent! rviminfo! ' . l:vimInfoFile
        exe 'set viminfo=' . l:temp
    endif

    " Load session
    if filereadable(l:sessionFile)
        exe 'silent! source ' . l:sessionFile
    endif

    " Post-load processing
    if exists('g:BMBPSign_PostLoadEventList')
        call execute(g:BMBPSign_PostLoadEventList)
    endif
endfunction

" == misc def ============================================== {{{1
" Return qfList used for seting quickfix
" Types -> list
function s:QfListSet(title, types)
    let l:qf = {'items': []}
    let l:signPlace = execute('sign place')

    for l:type in a:types
        for l:sign in get(s:signVec, l:type, [])
            let l:line = matchlist(l:signPlace, '    \S\+=\(\d\+\)'.'  id='.l:sign.id.'  \S\+=BMBPSign')

            if !filereadable(l:sign.file) || empty(l:line)
                continue
            elseif !bufexists(l:sign.file)
                exe 'badd ' . l:sign.file
            endif

            let l:text = '[' . l:type . ':' . l:sign.id
            let l:text .= empty(l:sign.attr) ? '] ' : ':' . l:sign.attr . '] '

            let l:qf.items += [{
                        \ 'bufnr': bufnr(l:sign.file),
                        \ 'filename': l:sign.file,
                        \ 'lnum': l:line[1],
                        \ 'text': l:text . get(getbufline(l:sign.file, l:line[1]), 0, '')
                        \ }]
        endfor
    endfor

    if !empty(a:title)
        let l:qf.title = a:title
    endif

    call setqflist([], 'r', l:qf)
endfunction

" Update quickfix when sign changes
function s:QfListUpdate(types)
    let l:group = tolower(getqflist({'title': 1}).title)

    for l:type in get(s:typesGroup, l:group, [])
        if index(a:types, l:type) != -1
            call s:QfListSet('', l:list)
            break
        endif
    endfor
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
function s:TodoStatement(filetype)
    return get(s:commentChar, a:filetype, '') . ' TODO: '
endfunction

" == Global def =================================== {{{1
function BMBPSign#Project(...)
    call s:ProjectManager(a:0, a:000)
endfunction

" Toggle sign of a type
function BMBPSign#SignToggle(...)
    let [l:type, l:file, l:lin] = ['book', expand('%:p'), line('.')]

    for l:arg in a:000
        if has_key(s:signVec, l:arg)
            let l:type = l:arg
        elseif l:arg
            let l:lin = l:arg
        elseif filereadable(l:arg)
            let l:file = l:arg
        else
            return
        endif
    endfor

    if !bufexists(l:file)
        exe 'badd ' . l:file
    endif

    if empty(getbufvar(l:file, '&buftype'))
        if l:type == 'todo' && get(getbufline(l:file, l:lin), 0, '') !~ 'TODO:'
            exe 'buffer ' . l:file
            call cursor(l:lin, 1)
            call append('.', s:TodoStatement(getbufvar(l:file, '&filetype')))
            normal j==
            silent write
            let l:lin += 1
        endif

        call s:SignToggle(l:file, l:lin, l:type, '', 0)
        call s:QfListUpdate([l:type])
    endif
endfunction

function BMBPSign#SignJump(...)
    let [l:type, l:action] = ['book', 'next']

    for l:arg in a:000
        if has_key(s:signVec, l:arg)
            let l:type = l:arg
        elseif index('next', 'previous'], l:arg) != -1
            let l:action = l:arg
        else
            return
        endif
    endfor

    call s:Signjump(l:type , l:action)
endfunction

" Cancel sign of types | ids or delete sign file
" Pre: file prefix: does not contain points and underscores
function BMBPSign#SignClear(...)
    let [l:types, l:ids, l:pres] = [[], [], []]

    for l:arg in a:000
        if has_key(s:signVec, l:arg)
            let l:types += [l:arg]
        elseif l:arg
            let l:ids += [l:arg]
        else
            let l:pres += [l:arg]
        endif
    endfor

    if !empty(l:types)
        call s:SignClear(l:types)
        call s:QfListUpdate(l:types)
    endif

    if !empty(l:ids)
        call s:SignUnsetById(l:ids)
        let l:types = uniq(map(l:ids, "get(s:signId,v:val,[''])[0]"))
        call s:QfListUpdate(l:types)
    endif

    for l:file in map(l:pres, "matchstr(v:val,'^[^_.]*').'".s:signFile."'")
        call delete(l:file)
    endfor
endfunction

" Save sign to file, Can specify types to save
" Default saving none
function BMBPSign#SignSave(...)
    let l:pre = a:0 > 0 ? matchstr(a:1, '^[^_.]*') : ''
    let l:types = a:0 > 1 ? a:000[1:] : keys(s:signVec)
    call s:SignSave(l:pre, l:types)
endfunction

" Load sign from file, Can specify types to clear first
" Default clearing none
function BMBPSign#SignLoad(...)
    let l:pre = a:0 > 0 ? matchstr(a:1, '^[^_.]*') : ''
    let l:types = a:0 > 1 ? a:2 == 'all' ? keys(s:signVec) : a:000[1:] : []

    if !empty(l:pre)
        call s:SignSave('', l:types)
    endif

    call s:SignLoad(l:pre, l:types)
endfunction

function BMBPSign#SignAddAttr(...)
    let [l:types, l:file, l:lin] = [[], '', '']

    for l:arg in a:000
        if has_key(s:signVec, l:arg)
            let l:types += [l:arg]
        elseif l:arg
            let l:lin = l:arg + 0
        elseif l:arg == '.'
            let l:lin = line('.')
        elseif l:arg == '%'
            let l:file = expand('%')
        elseif filereadable(l:arg)
            let l:file = l:arg
        endif
    endfor

    call s:SignAddAttr(l:types, l:file, l:lin)
endfunction

function BMBPSign#WorkSpaceSave(...)
    let l:pre = a:0 > 0 ? matchstr(a:1, '^[^_.]*') : ''
    call s:WorkSpaceSave(l:pre)
    call s:SignSave(l:pre, keys(s:signVec))
endfunction

function BMBPSign#WorkSpaceLoad(...)
    let l:pre = a:0 > 0 ? matchstr(a:1, '^[^_.]*') : ''

    if !empty(l:pre)
        call s:WorkSpaceSave('')
        call s:SignSave('', keys(s:signVec))
    endif

    call s:WorkSpaceLoad(l:pre)
    call s:SignLoad(l:pre, keys(s:signVec))
endfunction

function BMBPSign#WorkSpaceClear(...)
    let l:pre = a:0 > 0 ? matchstr(a:1, '^[^_.]*') : ''
    call delete(l:pre . s:sessionFile)
    call delete(l:pre . s:vimInfoFile)
    call delete(l:pre . s:signFile)

    if empty(l:pre) && exists('g:BMBPSign_Projectized')
        unlet g:BMBPSign_Projectized
    endif
endfunction

" Set QuickFix window with qfList
function BMBPSign#SetQfList(...)
    if a:0 == 0
        return
    endif
    let l:group = tolower(a:1)
    let l:types = a:0 > 1 ? a:000[1:] : get(s:typesGroup, l:group, [])

    if !empty(l:types)
        call s:QfListSet(a:1, l:types)
        copen
        set nowrap
    endif

    if !has_key(s:typesGroup, l:group) && a:0 > 1
        call extend(s:typesGroup, {l:group: a:000[1:]})
    endif
endfunction

function BMBPSign#SignTypeList()
    return keys(s:signVec)
endfunction

" Api: Get sign record info for other purpose
" like breakpoint for debug (format similar to s:SignSave())
" Return list
function BMBPSign#SignRecord(...)
    let l:signRecord = []
    let l:signPlace = execute('sign place')

    " Get row information & set l:signRecord
    for l:type in a:000
        for l:sign in get(s:signVec, l:type, [])
            let l:line = matchlist(l:signPlace, '    \S\+=\(\d\+\)' . '  id=' . l:sign.id . '  \S\+=BMBPSign')
            if !empty(l:line)
                let l:signRecord += [l:type . ' ' . l:sign.file . ':' . l:line[1]]

                if l:sign.attr =~ '\S'
                    let l:signRecord[-1] .= ' '.l:sign.attr
                endif
            endif
        endfor
    endfor

    return l:signRecord
endfunction

" set foldmethod=marker
