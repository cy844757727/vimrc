""""""""""""""""""""""""""""""""""""""""""""""""""""
" Author: CY <844757727@qq.com>
" Description: BookMark_TodoList_BreakPoint_ProjectManager
""""""""""""""""""""""""""""""""""""""""""""""""""""
if exists('g:loaded_A_BMBPSign') || !has('signs')
  finish
endif
let g:loaded_A_BMBPSign = 1

" sign highlight definition
hi BMBPSignHl  ctermbg=253 ctermfg=16 guibg=#1E1E1E guifg=#CCCCB0
hi BreakPoint  ctermbg=253 ctermfg=16 guibg=#1E1E1E guifg=#D73130

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

" Project record file defination
if exists('g:BMBPSign_ProjectFile')
    let s:projectFile = g:BMBPSign_ProjectFile
elseif has('unix') || has('mac')
    let s:projectFile = $HOME . '/.vim/.projectitem'
else
    let s:projectFile = $HOME . '/vimfiles/.projectitem'
endif

" Load project items
let s:projectItem = filereadable(s:projectFile) ? readfile(s:projectFile) : []

" Default project type associate with specified path
if exists('g:BMBPSign_ProjectType')
    let s:projectType = g:BMBPSign_ProjectType
    " For $HOME path substitute
    call map(s:projectType, "v:val =~ '^\\~' ? $HOME . strpart(v:val, 1) : v:val")
else
    let s:projectType = {}
endif

if !has_key(s:projectType , 'default')
    let s:projectType['default'] = $HOME . '/Documents'
endif

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
    elseif a:skip == 0
        " Unset sign
        exe 'sign unplace ' . l:id[1] . ' file=' . a:file
        call filter(l:vec, 'v:val.id != ' . l:id[1])
        unlet s:signId[l:id[1]]
    endif
endfunction

" BookMark jump
" Action: next, previous
function s:Signjump(type, action)
    let l:vec = get(s:signVec, a:type, [])

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
                call s:SignToggle(l:file, l:line, l:type, l:attr, 1)
            endif
        endfor
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
            let l:content += [l:type . ' ' . l:sign.file . ':' . l:line . ' ' . l:sign.attr]
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
function s:SignAddAttr(file, line)
    try
        let l:signPlace = split(execute('sign place file=' . a:file), "\n")[2:]
    catch
        " No sign set 
        return
    endtry

    " Consider multiple signs set at same line
    " Content: l:ind: ['id', 'type']
    let l:signs = {}
    let l:ind = 1
    for l:sign in l:signPlace
        let l:list = matchlist(l:sign, '    \S\+' . a:line . '  id=\(\d\+\)' . '  \S\+=BMBPSign\(\S\+\)')
        if !empty(l:list)
            let l:signs[l:ind] = [l:list[1], tolower(l:list[2])]
            let l:ind += 1
        endif
    endfor

    if l:ind == 1
        return
    elseif l:ind == 2
        let [l:id, l:type] = l:signs['1']
    else
        " Multiple signs
        let l:str = 'Select one(ind   type)!'
        for [l:ind, l:sign] in items(l:signs)
            let l:str .= printf("\n  %-3d   %s", l:ind, l:sign[1])
        endfor
        echo l:str
        let [l:id, l:type] = get(l:signs, nr2char(getchar()), [-1, 'invalid'])
    endif

    " Add attr to a sign
    for l:sign in get(s:signVec, l:type, [])
        if l:sign.id == l:id
            let l:sign.attr = input('Input attr(' . l:type . '): ', l:sign.attr)
            break
        endif
    endfor
endfunction

" Unset sign by ids
" Ids -> list
function s:SignUnsetById(ids)
    for l:id in a:ids
        let [l:type, l:file] = get(s:signId, l:id, ['invalid', ''])

        if bufexists(l:file)
            exe 'sign unplace ' . l:id . ' file=' . l:file
            call filter(s:signVec[l:type], 'v:val.id != ' . l:id)
            unlet s:signId[l:id]
        endif
    endfor
endfunction

" == Project def =============================================== {{{1
" New project & save workspace or modify current project
function s:ProjectNew(name, type, path)
    set noautochdir
    let s:projectized = 1

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
    if l:path == getcwd() && exists('s:projectized')
        return
    endif

    if l:path != getcwd()
        " Save current workspace
        call s:SignSave('', keys(s:signVec))
        if exists('s:projectized')
            call s:WorkSpaceSave('')
        endif

        exe 'silent cd ' . l:path

        " Empth workspace
        silent %bwipeout
    endif

    if exists('s:projectized')
        unlet s:projectized
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
    let s:projectized = 1
    let l:sessionFile = a:pre . s:sessionFile
    let l:vimInfoFile = a:pre . s:vimInfoFile

    " Save session & viminfo
    let l:temp = &sessionoptions
    set sessionoptions=blank,buffers,curdir,folds,help,options,tabpages,winsize,terminal
    exe 'mksession! ' . l:sessionFile
    exe 'set sessionoptions=' . l:temp
    let l:temp = &viminfo
    set viminfo='50,!,:100,/100,@100
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

    set noautochdir
    let s:projectized = 1
    let l:sessionFile = a:pre . s:sessionFile
    let l:vimInfoFile = a:pre . s:vimInfoFile

    " Empty workspace
    if exists('s:projectized')
        tabnew
        tabonly
    endif

    " Load viminfo
    if filereadable(l:vimInfoFile)
        let l:temp = &viminfo
        set viminfo='50,!,:100,/100,@100
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
function s:GetQfList(types)
    let l:qf = []
    let l:signPlace = execute('sign place')

    for l:type in a:types
        for l:sign in get(s:signVec, l:type, [])
            let l:line = matchlist(l:signPlace, '    \S\+=\(\d\+\)' . '  id=' . l:sign.id . '  \S\+=BMBPSign')
            if !empty(l:line) && filereadable(l:sign.file)
                if !bufexists(l:sign.file)
                    exe 'badd ' . l:sign.file
                endif

                if l:sign.attr =~ '\S'
                    let l:text = '[' . l:type . ':' . l:sign.id . ':' . l:sign.attr . '] '
                else
                    let l:text = '[' . l:type . ':' . l:sign.id . '] '
                endif

                let l:text .= getbufline(l:sign.file, l:line[1])[0]

                let l:qf += [{
                            \ 'bufnr': bufnr(l:sign.file),
                            \ 'filename': l:sign.file,
                            \ 'lnum': l:line[1],
                            \ 'text': l:text
                            \ }]
            endif
        endfor
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

" == Global def =================================== {{{1
function BMBPSign#Project(...)
    call s:ProjectManager(a:0, a:000)
endfunction

" Toggle sign of a type
function BMBPSign#SignToggle(type)
    let l:file = expand('%')

    if empty(&buftype) && filereadable(l:file)
        if a:type == 'todo' && getline('.') !~ 'TODO:'
            call append('.', s:TodoStatement())
            normal j==
            silent write
        endif

        call s:SignToggle(l:file, line('.'), a:type, '', 0)
    endif
endfunction

function BMBPSign#SignJump(type, action)
    call s:Signjump(empty(a:type) ? 'book' : a:type, a:action)
endfunction

" Cancel sign of types | ids or delete sign file
" Pre: file prefix: does not contain points and underscores
function BMBPSign#SignClear(...)
    if a:0 == 0
        return
    endif

    let l:pre = matchstr(a:1, '^[^_.]*')

    if filereadable(l:pre . s:signFile)
        for l:pre in a:000
            call delete(matchstr(l:pre, '^[^.]*') . s:signFile)
        endfor
    elseif a:1
        call s:SignUnsetById(a:000)
    else
        call s:SignClear(a:000)
    endif
endfunction

" Save sign to file, Can specify types to save
" Default saving none
function BMBPSign#SignSave(...)
    let l:pre = a:0 != 0 ? matchstr(a:1, '^[^_.]*') : ''
    let l:types = a:0 > 1 ? a:000[1:] : []

    call s:SignSave(l:pre, l:types)
endfunction

" Load sign from file, Can specify types to clear first
" Default clearing none
function BMBPSign#SignLoad(...)
    let l:pre = a:0 != 0 ? matchstr(a:1, '^[^_.]*') : ''
    let l:types = a:0 > 1 ? a:000[1:] : []

    if !empty(l:pre)
        call s:SignSave('', l:types)
    endif

    call s:SignLoad(l:pre, l:types)
endfunction

function BMBPSign#SignAddAttr()
    call s:SignAddAttr(expand('%'), line('.'))
endfunction

function BMBPSign#WorkSpaceSave(pre)
    let l:pre = matchstr(a:pre, '^[^_.]*')
    call s:WorkSpaceSave(l:pre)
    call s:SignSave(l:pre, keys(s:signVec))
endfunction

function BMBPSign#WorkSpaceLoad(pre)
    let l:pre = matchstr(a:pre, '^[^_.]*')
    if !empty(l:pre)
        call s:WorkSpaceSave('')
        call s:SignSave('', keys(s:signVec))
    endif
    call s:WorkSpaceLoad(l:pre)
    call s:SignLoad(l:pre, keys(s:signVec))
endfunction

function BMBPSign#WorkSpaceClear(pre)
    let l:pre = matchstr(a:pre, '^[^_.]*')
    call delete(l:pre . s:sessionFile)
    call delete(l:pre . s:vimInfoFile)
    call delete(l:pre . s:signFile)
    if empty(l:pre) && exists('s:projectized')
        unlet s:projectized
    endif
endfunction

" Set QuickFix window with qfList
function BMBPSign#SetQfList(title, ...)
    if a:0 == 0
        return
    endif

    call setqflist([], 'r', {'title': a:title, 'items': s:GetQfList(a:000)})
endfunction

function BMBPSign#SignTypeList()
    return keys(s:signVec)
endfunction

" AutoCmd for VimEnter event
" Load sign when starting with a file
function BMBPSign#VimEnterEvent()
    " Stop load twice when signs already exists
    " Occurs after loading the project
    if exists('s:projectized')
        return
    endif

    let l:file = expand('%')
    if filereadable(s:signFile) && !empty(l:file) && !empty(systemlist('grep ' . l:file . ' ' . s:signFile))
        call s:SignLoad('', [])
    endif
endfunction

" AutoCmd for VimLeave event
" For saving | updating signFile
" And save workspace when set s:projectized
function BMBPSign#VimLeaveEvent()
    call s:SignSave('', keys(s:signVec))

    if exists('s:projectized')
        call s:WorkSpaceSave('')
    endif
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

" set foldmethod=marker

