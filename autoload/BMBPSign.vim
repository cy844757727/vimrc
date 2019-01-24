""""""""""""""""""""""""""""""""""""""""""""""
" File: BMBPSign.vim
" Author: Cy <844757727@qq.com>
" Description: BookMark_TodoList_BreakPoint_ProjectManager
" Last Modified: 2019年01月15日 星期二 12时46分27秒
""""""""""""""""""""""""""""""""""""""""""""""

if exists('g:loaded_A_BMBPSign') || !has('signs')
    finish
endif
let g:loaded_A_BMBPSign = 1

" sign highlight definition
hi default BookMark    ctermfg=16 guifg=#CC7832
hi default TodoList    ctermfg=16 guifg=#619FC6
hi default BreakPoint  ctermfg=16 guifg=#DE3D3B

" Sign name rule: 'BMBPSign' . type [. 'Attr']
sign define BMBPSignbook text= texthl=BookMark
sign define BMBPSigntodo text= texthl=TodoList
sign define BMBPSignbreak text= texthl=BreakPoint
sign define BMBPSigntbreak text= texthl=BreakPoint
sign define BMBPSignbookAttr text=. texthl=BookMark
sign define BMBPSigntodoAttr text=. texthl=TodoList
sign define BMBPSignbreakAttr text=. texthl=BreakPoint
sign define BMBPSigntbreakAttr text=. texthl=BreakPoint

" SignVec Record
" Bookmark: book    " TodoList: todo    " BreakPoint: break, tbreak
" Content: 'type': [{'id': ..., 'file': ..., 'attr': ...}]
let s:signDefHead = 'BMBPSign'
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


" TODO: event handle
let s:signToggleEvent = get(g:, 'BMBPSign_ToggleEvent', {})
" Default project type associate with specified path
let s:projectType = get(g:, 'BMBPSign_ProjectType', {})
call extend(s:projectType, {'default': $HOME.'/Documents'}, 'keep')

" Project record file defination
let s:projectFile = get(
            \ g:, 'BMBPSign_ProjectFile',
            \ $HOME.(has('unix') || has('mac') ?
            \ '/.vim/.projectitem' :
            \ '/vimfiles/.projectitem')
            \ )

" Default content to save
let s:vimInfo = get(g:, 'BMBPSign_VimInfo', "'50,!,:100,/100,@100")
let s:sessionOptions = get(g:, 'BMBPSign_SessionOption',
            \ 'blank,buffers,curdir,folds,help,options,tabpages,winsize,terminal')

" Load project items
let s:projectItem = filereadable(s:projectFile) ? readfile(s:projectFile) : []

" For $HOME path substitute
call map(s:projectType, "fnamemodify(v:val, ':p')")

" Sign type extendsion: customized
for l:sign in get(g:, 'BMBPSignTypeExtend', [])
    try
        let l:type = l:sign.type
        let l:name = s:signDefHead.l:type
        let l:text = get(l:sign, 'text', '')
        let l:texthl = get(l:sign, 'texthl', 'BMBPSignHl')
        let l:linehl = get(l:sign, 'linehl', 'Normal')
        let l:textAttr = get(l:sign, 'textAttr', strpart(l:text.'.'), 0, 2)
        let l:texthlAttr = get(l:sign, 'texthl', l:texthlAttr)
        let l:linehlAttr = get(l:sign, 'linehl', l:linehlAttr)
        exe 'sign define '.l:name.' text='.l:text.' texthl='.l:texthl.' linehl='.l:linehl
        exe 'sign define '.l:name.'Attr text='.l:textAttr.' texthl='.l:texthlAttr.' linehl='.l:linehlAttr
        let s:signVec[l:type] = []
    catch
        continue
    endtry
endfor


" == Sign Def ========================================= {{{1
" Toggle sign in the specified line of the specified file
" Type: book, todo, break, tbreak ...
" Attr: Additional attribute
" Skip: Whether to unset if sign existing (set 1 for merging: forbiden unset)
function s:SignToggle(file, line, type, attr, skip)
    let l:def = s:signDefHead.a:type.(empty(a:attr) ? '' : 'Attr')
    let l:vec = s:signVec[a:type]
    let l:signPlace = execute('sign place file='.a:file)
    let l:id = matchlist(l:signPlace, '\v    \S+\='.a:line.'  id\=(\d+)  \S+\='.l:def)
    let g:BMBPSign_SignSetFlag = 1

    if empty(l:id)
        " Plus first, ensure id global uniqueness
        let s:newSignId += 1
        while !empty(matchlist(l:signPlace, '\v    \S+\=\d+  id\='.s:newSignId.'  '))
            let s:newSignId += 1
        endwhile

        " Set sign
        exe 'sign place '.s:newSignId.' line='.a:line.' name='.l:def.' file='.a:file
        call add(l:vec, {'id': s:newSignId, 'file': a:file, 'attr': a:attr})
        let s:signId[s:newSignId] = [a:type, a:file]

        " Support async.vim script debug
        if exists('t:dbg') && a:type =~# 'break'
            call t:dbg.sendCmd(a:type, a:file.':'.a:line)
        endif
    elseif a:skip == 0
        " Unset sign
        exe 'sign unplace '.l:id[1].' file='.a:file
        call filter(l:vec, 'v:val.id != '.l:id[1])
        unlet s:signId[l:id[1]]

        " Support async.vim script debug
        if exists('t:dbg') && a:type =~# 'break'
            call t:dbg.sendCmd('clear', a:file.':'.a:line)
        endif
    endif
endfunction


" BookMark jump
" Action: next, previous
function s:SignJump(types, action, id, attrs, file)
    if !empty(a:action)
        let l:vec = s:signVec[a:types[0]]

        if empty(l:vec)
            return
        endif

        if a:action ==# 'next'
            call add(l:vec, remove(l:vec, 0))
        else
            call insert(l:vec, remove(l:vec, -1))
        endif

        let l:id = l:vec[-1].id
        let l:file = l:vec[-1].file
    elseif !empty(a:id) && has_key(s:signId, a:id)
        let l:id = a:id
        let l:file = s:signId[a:id][1]
    else
        let l:items = s:SignFilter(a:types, a:file, '', a:attrs)

        if !empty(l:items)
            let l:str = input(s:SignDisplayStr(l:items).'Selete id: ') + 0

            if has_key(l:items, l:str)
                let l:id = l:str
                let l:file = l:items[l:id].sign.file
            endif
        endif
    endif

    if !exists('l:id')
        return
    endif

    " Try jumping to a tab containing this buf or new tabpage
    if exists('*misc#EditFile')
        call misc#EditFile(l:file, 'tabedit')
    else
        let l:bufnr = bufnr(l:file)
        if index(tabpagebuflist(), l:bufnr) == -1
            let l:winId = win_findbuf(l:bufnr)

            if !empty(l:winId)
                exe win_id2tabwin(l:winId[0])[0].'tabnext'
            else
                exe 'tabedit '.l:file
            endif
        endif
    endif

    exe 'sign jump '.l:id.' file='.l:file
endfunction


" clear sign of types specified
" Types -> list
function s:SignClear(types)
    for l:type in a:types
        let l:vec = s:signVec[l:type]

        " Unset sign
        for l:sign in l:vec
            if l:sign.attr !~? '\v&keep'
                exe 'sign unplace '.l:sign.id.' file='.l:sign.file
                unlet s:signId[l:sign.id]
            endif
        endfor

        " Empty vec
        call filter(l:vec, "v:val.attr =~? '\\v&keep'")
    endfor
endfunction


" Load & set sign from a file
" File Name: a:pre . s:signFile
" Types -> list: Specify the types to clear first
" Signs that have not been cleared are merged
" Pre: file prefix: does not contain points and underscores
function s:SignLoad(signFile, types)
    " Read sign file
    let l:signList = readfile(a:signFile)

    " Clear sign of types
    if !empty(a:types)
        call s:SignClear(a:types)
    endif

    " Load sign
    let l:types = []
    for l:str in l:signList
        try
            let [l:type, l:file, l:line] = split(l:str, '\v[ :]+')[0:2]
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

        let l:attr = matchstr(l:str, '\v(:\d+\s+)\zs.*$')
        call s:SignToggle(l:file, l:line, l:type, l:attr, 1)
    endfor

    if !empty(l:types)
        call s:QfListUpdate(uniq(l:types))
    endif
endfunction


" Save sign of types to a file
" File Name: a:pre . s:signFile
" Types -> list
function s:SignSave(signFile, types)
    " Get all valid BMBPSign of types
    " Content: 'id': lineNr
    let l:signs = {}
    let l:def = s:signDefHead.'('.join(a:types, '|').')'
    for l:item in split(execute('sign place'), "\n")
        let l:match = matchlist(l:item, '\v    \S+\=(\d+)  id\=(\d+)  \S+\='.l:def)

        if !empty(l:match)
            let l:signs[l:match[2]] = l:match[1]
        endif
    endfor

    " set l:content
    let l:content = []
    for l:type in a:types
        for l:sign in get(s:signVec, l:type, [])
            if has_key(l:signs, l:sign.id)
                let l:line = l:signs[l:sign.id]
            else
                " Ignore invalid data
                continue
            endif

            let l:content += [l:type.' '.l:sign.file.':'.l:line]

            if !empty(l:sign.attr)
                let l:content[-1] .= '  '.l:sign.attr
            endif
        endfor
    endfor

    " Udate signFile
    if !empty(l:content)
        call writefile(l:content, a:signFile)
    else
        call delete(a:signFile)
    endif
endfunction

function s:strMatch(str, words)
    for l:word in a:words
        if a:str !~? l:word
            return 0
        endif
    endfor

    return 1
endfunction

" Filter sign by types & file & lin
" Content: {'id': {'sign': ..., 'lin': ..., 'type': ...,}}
function s:SignFilter(types, file, lin, attrs)
    let l:signPlace = execute('sign place '.(empty(a:file) ? '' : 'file='.a:file))

    let l:items = {}
    for l:type in a:types
        for l:sign in s:signVec[l:type]
            let l:list = matchlist(l:signPlace, '\v    \S+\=(\d+)  id\='.
                        \ l:sign.id.'  \S+\='.s:signDefHead)

            if !empty(l:list) && l:list[1] =~? a:lin && s:strMatch(l:sign.attr, a:attrs)
                let l:items[l:sign.id] = {'sign': l:sign, 'type': l:type, 'lin': l:list[1]}
            endif
        endfor
    endfor

    return l:items
endfunction


" Format items into pretty-printed string
function s:SignDisplayStr(items)
    let l:str = "  id      type      where\n"

    for [l:id, l:val] in items(a:items)
        let l:str .= printf('  %-3d     %-6s    %s:%d', l:id, l:val.type,
                    \ substitute(l:val.sign.file, getcwd().'/', '', ''), l:val.lin
                    \ ).'   '.l:val.sign.attr."\n"
    endfor

    return l:str
endfunction


" Add attr to a sign
function s:SignAddAttr(types, file, lin, attrs)
    let l:items = s:SignFilter(a:types, a:file, a:lin, a:attrs)

    if empty(l:items)
        return
    endif

    let l:str = s:SignDisplayStr(l:items)
    let l:arg = split(input(l:str.'Input id and attr: '), '\v^(\d+)\zs\s+')
    let l:val = get(l:items, get(l:arg, 0, ''), {})

    if empty(l:val)
        return
    endif

    if (empty(l:val.sign.attr) && len(l:arg) > 1) ||
                \ (!empty(l:val.sign.attr) && len(l:arg) < 2)
        exe 'sign unplace '.l:val.sign.id.' file='.l:val.sign.file
        exe 'sign place '.l:val.sign.id.' line='.l:val.lin.
                    \ ' name='.s:signDefHead.l:val.type.(len(l:arg) > 1 ? 'Attr' : '').
                    \ ' file='.l:val.sign.file
    endif

    let l:val.sign.attr = get(l:arg, 1, '')
    call s:QfListUpdate([l:val.type])

    " Support async.vim script debug
    if exists('t:dbg') && l:val.type =~# 'break'
        call t:dbg.sendCmd('condition', l:val.sign['file'].':'.l:val['lin'], l:val.sign.attr)
    endif
endfunction


" Unset sign by ids
" Ids -> list
function s:SignUnsetById(ids)
    let l:types = []
    for l:id in a:ids
        let [l:type, l:file] = get(s:signId, l:id, ['invalid', ''])

        if bufexists(l:file)
            exe 'sign unplace '.l:id.' file='.l:file
            call filter(s:signVec[l:type], 'v:val.id != '.l:id)
            unlet s:signId[l:id]
            let l:types += [l:type]
        endif

        " Support async.vim script debug
        if exists('t:dbg') && exists('l:items') && l:items[l:id].type =~# 'break'
            call t:dbg.sendCmd('clear', l:file.':'.l:items[l:id].lin)
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
    let l:type = a:type ==# '.' ? 'undef' : a:type
    let l:path = a:path ==# '.' ? getcwd() : a:path

    " Whether it already exists
    for l:i in range(len(s:projectItem))
        if l:path ==# split(s:projectItem[l:i])[-1]
            let l:item = remove(s:projectItem, l:i)
            break
        endif
    endfor

    " For new item or modifing item(already exists)
    if a:path ==# '.' || !exists('l:item')
        let l:item = printf('%-20s  Type: %-12s  Path: %s', a:name, l:type, l:path)
    endif

    " Put the item first.
    call insert(s:projectItem, l:item)
    call writefile(s:projectItem, s:projectFile)

    " cd path
    if l:path !=# getcwd()
        if !isdirectory(l:path)
            call mkdir(l:path, 'p')
        endif

        exe 'silent cd '.l:path
        silent %bwipeout
    endif

    exe 'set titlestring=\ \ '.fnamemodify(getcwd(), ':t')
    echo substitute(l:item, ' '.$HOME, ' ~', '')
endfunction


" Switch to path & load workspace
function s:ProjectSwitch(sel)
    set noautochdir
    let l:path = split(s:projectItem[a:sel])[-1]

    " Do not load twice
    if l:path ==# getcwd() && exists('g:BMBPSign_Projectized')
        return
    endif

    if l:path !=# getcwd()
        " Save current workspace
        if exists('g:BMBPSign_SignSetFlag')
            call s:SignSave(s:signFile, keys(s:signVec))
        endif

        if exists('g:BMBPSign_Projectized')
            call s:WorkSpaceSave('')
        endif

        exe 'silent cd '.l:path

        " Empty workspace
        silent! %bwipeout
    endif

    if exists('g:BMBPSign_SignSetFlag')
        unlet g:BMBPSign_SignSetFlag
    endif

    if exists('g:BMBPSign_Projectized')
        unlet g:BMBPSign_Projectized
    endif

    " Load target sign & workspace
    if filereadable(s:signFile)
        call s:SignLoad(s:signFile, keys(s:signVec))
    endif
    call s:WorkSpaceLoad('')

    " Put item first
    call insert(s:projectItem, remove(s:projectItem, a:sel))
    call writefile(s:projectItem, s:projectFile)

    echo substitute(s:projectItem[0], ' '.$HOME, ' ~', '')
endfunction


" Menu UI
function s:ProjectUI(start, tip)
    " ten items per page
    let l:page = a:start / 10 + 1

    " ui: head
    let l:ui = '** Project option  (cwd: '.fnamemodify(getcwd(), ':~').
                \ '     num: '.len(s:projectItem).'     page: '.l:page.")\n".
                \ '   s:select  d:delete  m:modify  p:pageDown  P:pageUp  q:quit  '.
                \ "Q:vimleave  a/n:new  0-9:item\n".
                \ "   !?:selection mode    Del:deletion mode    Mod:modification mode\n".
                \ repeat('=', min([&columns - 10, 90]))."\n"

    " ui: body (Path conversion)
    let l:ui .= join(map(s:projectItem[a:start:a:start+9],
                \ "printf(' %3d: ', v:key).substitute(v:val, ' '.$HOME, ' ~', '')"), "\n"
                \ )."\n".a:tip

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
        elseif l:char ==# 's'
            let [l:tip, l:mode] = ['!?:', 's']
        elseif l:char =~# 'd'
            let [l:tip, l:mode] = ['Del:', 'd']
        elseif l:char ==# 'm'
            let [l:tip, l:mode] = ['Mod:', 'm']
        elseif l:char ==# 'q' || l:char == "\<Esc>"
            return
        elseif l:char ==# 'Q'
            qall
        elseif l:char == "\<cr>"
            let l:tip = matchstr(l:tip, '\S*$')
        elseif l:char =~# '\v\d|\s' && l:char < len(s:projectItem)
            " Specific operation
            if l:mode ==# 's' && !(getcwd() ==# split(s:projectItem[l:start[0] + l:char])[-1]
                        \ && exists('g:BMBPSign_Projectized'))
                " select
                call s:ProjectSwitch(l:char + 10 * (l:page - 1))
                break
            elseif l:mode ==# 'd'
                " delete
                call remove(s:projectItem, l:char)
                call writefile(s:projectItem, s:projectFile)
            elseif l:mode ==# 'm'
                " modify
                let l:path = split(s:projectItem[l:char])[-1]
                echo s:ProjectUI(l:start[0], '▼ Modelify item '.str2nr(l:char))
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
        elseif l:char =~# '\v[an]'
            " new
            echo s:ProjectUI(l:start[0], '▼ New Project')
            let l:argv = split(input('<name> <type> [path]: ', '', 'file'))
            let l:argc = len(l:argv)
            redraw!

            if l:argc == 2 || l:argc == 3
                call s:ProjectManager(l:argc, l:argv)
                break
            else
                let l:tip = 'Wrong Argument, Reselect. '.matchstr(l:tip, '\S*$')
            endif
        else
            let l:tip = 'Invalid('.l:char.'), Reselect. '.matchstr(l:tip, '\S*$')
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
        let l:path = s:projectType[l:type].'/'.a:argv[0]
        call s:ProjectNew(a:argv[0], l:type, l:path)
    elseif a:argc == 3
        call s:ProjectNew(a:argv[0], a:argv[1], fnamemodify(a:argv[2], ':p'))
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
    let l:sessionFile = a:pre.s:sessionFile
    let l:vimInfoFile = a:pre.s:vimInfoFile
    exe 'set titlestring=\ \ '.fnamemodify(getcwd(), ':t')

    " Save session
    let l:temp = &sessionoptions
    exe 'set sessionoptions='.s:sessionOptions
    exe 'mksession! '.l:sessionFile
    exe 'set sessionoptions='.l:temp

    " Save viminfo
    let l:temp = &viminfo
    exe 'set viminfo='.s:vimInfo
    exe 'wviminfo! '.l:vimInfoFile
    exe 'set viminfo='.l:temp

    " For special buf situation(modify session file)
    if exists('g:BMBPSign_SpecialBuf') && executable('sed')
        for l:item in items(g:BMBPSign_SpecialBuf)
            call system("sed -i 's/^file ".l:item[0].".*$/".l:item[1]."/' ".l:sessionFile)
        endfor
    endif

    " Remember the current window of each tab(modify session file: append)
    let l:curWin = range(1, tabpagenr('$'))
    unlet l:curWin[tabpagenr() - 1]
    call map(l:curWin, "v:val.'tabdo '.tabpagewinnr(v:val).'wincmd w'")
    call writefile(l:curWin + ['tabnext '.tabpagenr()], l:sessionFile, 'a')

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
        call s:SignSave(s:signFile, keys(s:signVec))
        silent %bwipeout!
        call s:SignLoad(s:signFile, [])
    endif

    set noautochdir
    let g:BMBPSign_Projectized = 1
    let l:sessionFile = a:pre.s:sessionFile
    let l:vimInfoFile = a:pre.s:vimInfoFile

    " Load viminfo
    if filereadable(l:vimInfoFile)
        let l:temp = &viminfo
        exe 'set viminfo='.s:vimInfo
        exe 'silent! rviminfo! '.l:vimInfoFile
        exe 'set viminfo='.l:temp
    endif

    exe 'set titlestring=\ \ '.fnamemodify(getcwd(), ':t')

    " Load session
    if filereadable(l:sessionFile)
        exe 'silent! source '.l:sessionFile
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
            let l:line = matchlist(l:signPlace,
                        \ '\v    \S+\=(\d+)  id\='.l:sign.id.'  \S+\='.s:signDefHead)

            if empty(l:line) || !filereadable(l:sign.file)
                continue
            elseif !executable('sed') && !bufloaded(l:sign.file)
                exe '0vsplit +hide '.l:sign.file
            endif

            let l:text = '['.l:sign.id.':'.l:type.(empty(l:sign.attr) ? '' : ':'.l:sign.attr).'] '.(
                        \ executable('sed') ? 
                        \ system('sed -n '.l:line[1].'p '.l:sign.file)[:-2] :
                        \ getbufline(l:sign.file, l:line[1])[0]
                        \ )

            let l:qf.items += [{
                        \ 'bufnr': bufnr(l:sign.file),
                        \ 'filename': l:sign.file,
                        \ 'lnum': l:line[1],
                        \ 'text': l:text
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
            call s:QfListSet('', a:types)
            break
        endif
    endfor
endfunction


" == Global def =================================== {{{1
function BMBPSign#Project(...)
    call s:ProjectManager(a:0, a:000)
endfunction


" Toggle sign of a type
function BMBPSign#SignToggle(...)
    let [l:type, l:file, l:lins, l:attr] = exists('t:dbg') ? 
                \ ['break', t:dbg.sign.file, [], ''] :
                \ ['book', expand('%:p'), [], '']

    for l:i in range(len(a:000))
        if has_key(s:signVec, a:000[l:i])
            let l:type = a:000[l:i]
        elseif a:000[l:i] ==# '.'
            let l:cur = 1
        elseif a:000[l:i]
            let l:lins += [a:000[l:i]]
        elseif filereadable(a:000[l:i])
            let l:file = a:000[l:i]
        else
            let l:attr = join(a:000[l:i:], ' ')
            break
        endif
    endfor

    if !filereadable(l:file)
        return
    elseif !bufexists(l:file)
        exe 'badd ' . l:file
    endif

    if empty(l:lins) || exists('l:cur')
        let l:lins += [line('.')]
    endif

    for l:lin in uniq(sort(l:lins))
        call s:SignToggle(l:file, l:lin, l:type, l:attr, 0)
    endfor

    call s:QfListUpdate([l:type])
endfunction


function BMBPSign#SignJump(...)
    let [l:types, l:action, l:id, l:attrs, l:file] = [[], '', '', [], '']

    for l:i in range(len(a:000))
        if has_key(s:signVec, a:000[l:i])
            let l:types += [a:000[l:i]]
        elseif index(['next', 'previous'], a:000[l:i]) != -1
            let l:action = a:000[l:i]
        elseif a:000[l:i]
            let l:id = a:000[l:i]
        elseif filereadable(a:000[l:i])
            let l:file = a:000[l:i]
        elseif a:000[l:i] ==# '%'
            let l:file = expand('%')
        else
            let l:attrs = a:000[l:i:]
            break
        endif
    endfor

    if empty(l:types)
        let l:types = exists('t:dbg') ? ['break', 'tbreak'] :
                    \ empty(l:action) ? keys(s:signVec) : ['book']
    endif

    call s:SignJump(l:types, l:action, l:id, l:attrs, l:file)
endfunction


" Cancel sign of types | ids or delete sign file
" Pre: file prefix: does not contain points and underscores
function BMBPSign#SignClear(...)
    let [l:types, l:ids, l:pres] = [[], [], []]

    if a:0 == 0
        let l:items = s:SignFilter(keys(s:signVec), '', '', [])
        let l:str = s:SignDisplayStr(l:items)
        let l:ids = split(input(l:str.'Select ids to clear: '), '\v\s+')
    endif

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
    endif

    if !empty(l:ids)
        call s:SignUnsetById(l:ids)
        let l:types += uniq(map(l:ids, "get(s:signId,v:val,[''])[0]"))
    endif

    for l:file in map(l:pres, "matchstr(v:val,'^[^_.]*').'".s:signFile."'")
        call delete(l:file)
    endfor

    call s:QfListUpdate(l:types)
endfunction


" Save sign to file, Can specify types to save
" Default saving none
function BMBPSign#SignSave(...)
    let [l:pre, l:types] = ['', []]

    for l:arg in a:000
        if index(keys(s:signVec), l:arg) != -1
            let l:types += [l:arg]
        else
            let l:pre = matchstr(l:arg, '^[^_.]*')
        endif
    endfor

    if empty(l:types)
        let l:types = keys(s:signVec)
    endif

    call s:SignSave(l:pre . s:signFile, l:types)
endfunction


" Load sign from file, Can specify types to clear first
" Default clearing none
function BMBPSign#SignLoad(...)
    let [l:pre, l:types] = ['', []]

    for l:arg in a:000
        if index(keys(s:signVec), l:arg) != -1
            let l:types += [l:arg]
        else
            let l:pre = matchstr(l:arg, '^[^_.]*')
        endif
    endfor

    if filereadable(l:pre . s:signFile)
        if !empty(l:pre)
            call s:SignSave(s:signFile, l:types)
        endif

        call s:SignLoad(l:pre . s:signFile, l:types)
    endif
endfunction


" Append attribution to sign
function BMBPSign#SignAddAttr(...)
    let [l:types, l:file, l:lin, l:attrs] = [[], '', '', []]

    for l:i in range(len(a:000))
        if has_key(s:signVec, a:000[l:i])
            let l:types += [a:000[l:i]]
        elseif a:000[l:i]
            let l:lin = a:000[l:i] + 0
        elseif a:000[l:i] == '.'
            let l:lin = line('.')
        elseif a:000[l:i] == '%'
            let l:file = expand('%')
        elseif filereadable(a:000[l:i])
            let l:file = a:000[l:i]
        else
            let l:attrs = a:000[l:i:]
            break
        endif
    endfor

    if empty(l:types)
        let l:types = exists('t:dbg') ? ['break', 'tbreak'] : keys(s:signVec)
    endif

    call s:SignAddAttr(l:types, l:file, l:lin, l:attrs)
endfunction


function BMBPSign#WorkSpaceSave(...)
    let l:pre = a:0 > 0 ? matchstr(a:1, '^[^_.]*') : ''
    call s:WorkSpaceSave(l:pre)
    call s:SignSave(l:pre . s:signFile, keys(s:signVec))
endfunction


function BMBPSign#WorkSpaceLoad(...)
    let l:pre = a:0 > 0 ? matchstr(a:1, '^[^_.]*') : ''

    if !empty(l:pre)
        call s:WorkSpaceSave('')
        call s:SignSave(s:signFile, keys(s:signVec))
    endif

    call s:WorkSpaceLoad(l:pre)
    call s:SignLoad(l:pre . s:signFile, keys(s:signVec))
endfunction


function BMBPSign#WorkSpaceClear(...)
    let l:pre = a:0 > 0 ? matchstr(a:1, '^[^_.]*') : ''
    call delete(l:pre . s:sessionFile)
    call delete(l:pre . s:vimInfoFile)

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
        exe 'copen '.get(g:, 'BottomWinHeight', 15)
        setlocal nowrap
    endif

    if !has_key(s:typesGroup, l:group) && a:0 > 1
        let s:typesGroup[l:group] = a:000[1:]
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
            let l:line = matchlist(l:signPlace, '\v    \S+\=(\d+)'.
                        \ '  id\='.l:sign.id.'  \S+\='.s:signDefHead)

            if !empty(l:line)
                let l:signRecord += [l:type.' '.l:sign.file.':'.l:line[1]]

                if !empty(l:sign.attr)
                    let l:signRecord[-1] .= ' '.l:sign.attr
                endif
            endif
        endfor
    endfor

    return l:signRecord
endfunction

" vim:  set foldmethod=marker
