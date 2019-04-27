""""""""""""""""""""""""""""""""""""""""""""""
" File: sign.vim
" Author: Cy <844757727@qq.com>
" Description: BookMark_TodoList_BreakPoint_ProjectManager
""""""""""""""""""""""""""""""""""""""""""""""

if exists('g:loaded_a_sign') || !has('signs')
    finish
endif
let g:loaded_a_sign = 1

" sign highlight definition
hi default BookMark    ctermfg=16 guifg=#CC7832
hi default TodoList    ctermfg=16 guifg=#619FC6
hi default BreakPoint  ctermfg=16 guifg=#DE3D3B

" Sign name rule: 'sign' . type [. 'Attr']
sign define Signbook       text=  texthl=BookMark
sign define Signtodo       text=  texthl=TodoList
sign define Signbreak      text=  texthl=BreakPoint
sign define Signtbreak     text=  texthl=BreakPoint
sign define SignbookAttr   text=. texthl=BookMark
sign define SigntodoAttr   text=. texthl=TodoList
sign define SignbreakAttr  text=. texthl=BreakPoint
sign define SigntbreakAttr text=. texthl=BreakPoint

" SignVec Record
" Bookmark: book    " TodoList: todo    " BreakPoint: break, tbreak
" Content: 'type': [{'id': ..., 'file': ..., 'attr': ...}]
let s:defPrefix = 'Sign'
let s:signVec = {'book': [], 'todo': [], 'break': [], 'tbreak': []}
let s:icon = {'book': '', 'todo': '', 'break': '', 'tbreak': ''}

let s:newSignId = 0
" Type grouping for qflist
" Quickfix window autoupdating depends on it
let s:typesGroup = {}
" Sign id record
" Content: 'id': ['type', 'file']
let s:signId = {}

" Default File name
if has('unix') || has('mac')
    let s:signFile    = '.signrecord'
    let s:sessionFile = '.session'
    let s:vimInfoFile = '.viminfo'
else
    let s:signFile    = '_signrecord'
    let s:sessionFile = '_session'
    let s:vimInfoFile = '_viminfo'
endif


" Default project type associate with specified path
let s:projectType = extend({'default': '~/Documents/'},
            \ get(g:, 'sign_projectType', {}))
" For $HOME path substitute (using full path)
call map(s:projectType, 'fnamemodify(v:val, '':p'')')

" Project record file defination
let s:projectFile = get(g:, 'sign_projectFile',
            \ $HOME.(has('unix') || has('mac') ?
            \ '/.vim/.projectitem' :
            \ '/vimfiles/.projectitem'))

" Default content to save
let s:vimInfo = "'50,!,:100,/100,@100"
let s:sessionOptions = 'blank,buffers,curdir,folds,help,localoptions,tabpages,winsize,terminal'

" Sign type extendsion: customized
for l:sign in get(g:, 'sign_typeExtend', [])
    try
        let l:type = l:sign.type
        let l:name = s:defPrefix.l:type
        let l:text = get(l:sign, 'text', '')
        let l:texthl = get(l:sign, 'texthl', 'signHl')
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
    let l:def = s:defPrefix.a:type.(empty(a:attr) ? '' : 'Attr')
    let l:vec = s:signVec[a:type]
    let l:signPlace = execute('sign place file='.a:file)
    let l:id = matchlist(l:signPlace, '\v    \S+\='.a:line.'  id\=(\d+)  \S+\='.l:def)
    let g:Sign_signSetFlag = 1

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
    elseif !a:skip
        " Unset sign
        exe 'sign unplace '.l:id[1].' file='.a:file
        call filter(l:vec, 'v:val.id != '.l:id[1])
        unlet s:signId[l:id[1]]
    else
        return
    endif

    " Support async.vim script debug
    if exists('t:dbg') && a:type =~# 'break'
        call t:dbg.sendCmd(empty(l:id) ? a:type : 'clear', a:file.':'.a:line)
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
            if l:sign.attr !~? '\v&keep' && bufexists(l:sign.file)
                exe 'sign unplace '.l:sign.id.' file='.l:sign.file
                unlet s:signId[l:sign.id]
            endif
        endfor

        " Empty vec
        call filter(l:vec, 'v:val.attr =~? ''\v&keep''')
    endfor
endfunction


" Load & set sign from a file
" File Name: a:pre . s:signFile
" Types -> list: Specify the types to clear first
" Signs that have not been cleared are merged
" Pre: file prefix: does not contain points and underscores
function s:SignLoad(signFile, types)
    " Clear signs of a:types before loading
    if !empty(a:types)
        call s:SignClear(a:types)
    endif

    " Load sign
    let l:types = []
    for l:str in readfile(a:signFile)
        try
            let [l:type, l:file, l:line, l:attr] =
                        \ matchlist(l:str, '\v^(\w+)\s*(.*):(\d+)\s*(.*)$')[1:4]
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
    " Get all valid sign of types
    " Content: 'id': lineNr
    let l:signIdLin = {}
    let l:def = s:defPrefix.'('.join(a:types, '|').')'
    for l:item in split(execute('sign place'), "\n")
        let l:match = matchlist(l:item, '\v    \S+\=(\d+)  id\=(\d+)  \S+\='.l:def)

        if !empty(l:match)
            let l:signIdLin[l:match[2]] = l:match[1]
        endif
    endfor

    " set l:content
    let l:content = []
    for l:type in a:types
        for l:sign in get(s:signVec, l:type, [])
            if has_key(l:signIdLin, l:sign.id)
                let l:content += [l:type.' '.l:sign.file.':'.l:signIdLin[l:sign.id].' '.l:sign.attr]
            endif
        endfor
    endfor

    " Udate signFile
    if empty(l:content)
        call delete(a:signFile)
    else
        call writefile(l:content, a:signFile)
    endif
endfunction

function s:StrMatch(str, words)
    for l:word in a:words
        if a:str =~? l:word
            return 1
        endif
    endfor

    return 0
endfunction

" Filter sign by types & file & lin
" Content: {'id': {'sign': ..., 'lin': ..., 'type': ...,}}
function s:SignFilter(types, file, lin, attrs)
    let l:signPlace = execute('sign place '.(empty(a:file) ? '' : 'file='.a:file))

    let l:items = {}
    for l:type in a:types
        for l:sign in s:signVec[l:type]
            let l:list = matchlist(l:signPlace, '\v    \S+\=(\d+)  id\='.
                        \ l:sign.id.'  \S+\='.s:defPrefix)

            if !empty(l:list) && l:list[1] =~? a:lin &&
                        \ (empty(a:attrs) || s:StrMatch(l:sign.attr, a:attrs))
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

    if xor(empty(l:val.sign.attr), len(l:arg) == 1)
        exe 'sign unplace '.l:val.sign.id.' file='.l:val.sign.file
        exe 'sign place '.l:val.sign.id.' line='.l:val.lin.
                    \ ' name='.s:defPrefix.l:val.type.(len(l:arg) > 1 ? 'Attr' : '').
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
function s:ProjectNew(name, type, path) abort
    set noautochdir
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

    if get(g:, 'Sign_projectized', 0)
        let g:Sign_projectized = 1
        exe 'set titlestring=\ \ '.fnamemodify(getcwd(), ':t')
    endif
endfunction


" Switch to path & load workspace
function s:ProjectSwitch(sel)
    set noautochdir
    let l:path = split(s:projectItem[a:sel])[-1]
    exe 'set titlestring=\ \ '.matchstr(s:projectItem[a:sel], '\v^\w+')

    " Do not load twice
    if l:path ==# getcwd() && get(g:, 'Sign_projectized', 0)
        return
    endif

    if l:path !=# getcwd()
        " Save current workspace
        if get(g:, 'Sign_signSetFlag', 0)
            call s:SignSave(s:signFile, keys(s:signVec))
        endif

        if get(g:, 'Sign_projectized', 0)
            silent call s:WorkSpaceSave('')
        endif

        exe 'silent cd '.l:path

        " Empty workspace
        silent! %bwipeout
    endif

    unlet! g:Sign_signSetFlag g:Sign_projectized

    " Load target sign & workspace
    if filereadable(s:signFile)
        call s:SignLoad(s:signFile, keys(s:signVec))
    endif
    call s:WorkSpaceLoad('')

    " Put item first
    call insert(s:projectItem, remove(s:projectItem, a:sel))
    call writefile(s:projectItem, s:projectFile)
endfunction


" Menu UI
function s:ProjectUI(page, tip)
    " ten items per page
    let l:pages = (len(s:projectItem) - 1) / 10
    let l:page = a:page < 0 ? 0 : a:page > l:pages ? l:pages : a:page

    " ui: head
    let l:ui = '** Project menu (cwd: '.fnamemodify(getcwd(), ':~').
                \ '     num: '.len(s:projectItem).'     page: '.(l:page+1).'/'.(l:pages+1).")\n".
                \ '   s:select  d:delete  m:modify  p:pageDown  P:pageUp  q:quit  '.
                \ "Q:vimleave  n:new  0-9:item\n".repeat('=', min([&columns - 10, 90]))."\n"

    " ui: body (Path conversion)
    let l:start = l:page * 10
    let l:ui .= join(map(s:projectItem[l:start:l:start+9],
                \ "printf(' %3d: ', v:key).substitute(v:val, ' '.$HOME, ' ~', '')"),
                \ "\n")."\n".a:tip

    echo l:ui
    return l:page
endfunction


function s:ProjectMenu()
    let [l:page, l:tip, l:err, l:mode, l:loop] = [0, '!?:', '', 's', 1]
    let l:modeTip = {'s': '!?:', 'd': 'Deletion:', 'm': 'Modification:'}
    let l:operator = {'p': 'let l:page+=1', 'P': 'let l:page-=1',
                \ 'q': 'let l:loop=0', 'Q': 'qall', "\<Esc>": 'let l:loop=0'}

    while l:loop
        " Disply UI
        let l:page = s:ProjectUI(l:page, l:err.l:tip)
        let l:char = nr2char(getchar())
        let l:err = ''

        " options & Mode selection
        if has_key(l:operator, l:char)
            exe l:operator[l:char]
        elseif has_key(l:modeTip, l:char)
            let [l:tip, l:mode] = [l:modeTip[l:char], l:char]
        elseif l:char =~# '\v[0-9 ]'
            " Specific operation
            let l:sel = l:char + l:page * 10

            if l:sel >= len(s:projectItem)
                let l:err = 'Out of range! '
            elseif l:mode ==# 's'   " select
                call s:ProjectSwitch(l:sel)
                let l:loop=0
            elseif l:mode ==# 'd'   " delete
                call remove(s:projectItem, l:sel)
                call writefile(s:projectItem, s:projectFile)
            elseif l:mode ==# 'm'   " modify
                let l:item = split(s:projectItem[l:sel])
                let l:argv = split(input('▼ Modify item '.str2nr(l:char).' <name> <type>: ',
                            \ l:item[0].' '.l:item[2]))

                if len(l:argv) == 2
                    let s:projectItem[l:sel] = printf('%-20s  Type: %-12s  Path: %s',
                                \ l:argv[0], l:argv[1], l:item[-1])
                    call writefile(s:projectItem, s:projectFile)
                else
                    let l:err = 'Wrong Argument, Reselect. '
                endif
            endif
        elseif l:char ==# 'n'
            " new
            let l:argv = split(input('▼ New Project <name> <type> [path]: ', '', 'file'))
            let l:argc = len(l:argv)

            if l:argc == 2 || l:argc == 3
                call s:ProjectManager(l:argc, l:argv)
                let l:loop=0
            else
                let l:err = 'Wrong Argument, Reselect. '
            endif
        else
            let l:err = 'Invalid('.l:char.'), Reselect. '
        endif

        redraw!
    endwhile
endfunction


function s:ProjectManager(argc, argv)
    let s:projectItem = filereadable(s:projectFile) ? readfile(s:projectFile) : []

    if a:argc == 0
        call s:ProjectMenu()
    elseif a:argc == 1
        call s:ProjectSwitch(a:argv[0])
    elseif a:argc == 2
        let l:type = has_key(s:projectType, a:argv[1]) ? a:argv[1] : 'default'
        let l:path = s:projectType[l:type].a:argv[0]
        call s:ProjectNew(a:argv[0], a:argv[1], l:path)
    elseif a:argc == 3
        call s:ProjectNew(a:argv[0], a:argv[1], a:argv[2])
    endif

    if get(g:, 'Sign_projectized', 0)
        echo substitute(s:projectItem[0], ' '.$HOME, ' ~', '')
    endif
endfunction


" Save current workspace to a file
" Content: session, viminfo
" File Name: a:pre . s:sessionFile, a:pre . s:vimInfoFile
function s:WorkSpaceSave(pre)
    silent doautocmd User WorkSpaceSavePre

    set noautochdir
    let g:Sign_projectized = 1
    let l:sessionFile = a:pre.s:sessionFile
    let l:vimInfoFile = a:pre.s:vimInfoFile

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
    if exists('g:sign_specialBuf') && executable('sed')
        for l:item in items(g:sign_specialBuf)
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
    call s:ProjectManager(3, [fnamemodify(l:path, ':t'), l:type, l:path])

    silent doautocmd User WorkSpaceSavePost
endfunction


" Restore workspace from a file
" Context: session, viminfo
" File Name: a:pre . s:sessionFile, a:pre . s:vimInfoFile
function s:WorkSpaceLoad(pre)
    silent doautocmd User WorkSpaceLoadPre

    " Empty workspace
    if get(g:, 'Sign_projectized', 0)
        silent wall
        call s:SignSave(s:signFile, keys(s:signVec))
        silent %bwipeout!
        call s:SignLoad(s:signFile, [])
    endif

    set noautochdir
    let g:Sign_projectized = 1
    let l:sessionFile = a:pre.s:sessionFile
    let l:vimInfoFile = a:pre.s:vimInfoFile

    " Load viminfo
    if filereadable(l:vimInfoFile)
        silent doautocmd User VimInfoLoadPre
        let l:temp = &viminfo
        exe 'set viminfo='.s:vimInfo
        exe 'silent! rviminfo! '.l:vimInfoFile
        exe 'set viminfo='.l:temp
        silent doautocmd User VimInfoLoadPost
    endif

    " Load session
    if filereadable(l:sessionFile)
        exe 'silent! source '.l:sessionFile
    endif

    silent doautocmd User WorkSpaceLoadPost
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
                        \ '\v    \S+\=(\d+)  id\='.l:sign.id.'  \S+\='.s:defPrefix)

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


function s:InfoWinSet(title, types)
    let l:dict = {'title': a:title, 'content': {}, 'type': 'sign'}
    let l:signPlace = execute('sign place')

    for l:type in a:types
        for l:sign in get(s:signVec, l:type, [])
            let l:line = matchlist(l:signPlace,
                        \ '\v    \S+\=(\d+)  id\='.l:sign.id.'  \S+\='.s:defPrefix)

            if empty(l:line) || !filereadable(l:sign.file)
                continue
            elseif !executable('sed') && !bufloaded(l:sign.file)
                exe '0vsplit +hide '.l:sign.file
            endif

            let l:file = fnamemodify(l:sign.file, ':.')
            if !has_key(l:dict.content, l:file)
                let l:dict.content[l:file] = []
            endif

            let l:dict.content[l:file] += [
                        \ printf('%-5s %s   %s', l:line[1].':', (trim(executable('sed') ? 
                        \ system('sed -n '.l:line[1].'p '.l:sign.file)[:-2] :
                        \ getbufline(l:sign.file, l:line[1])[0])),
                        \ '['.s:icon[l:type].' '.l:sign.id.(empty(l:sign.attr) ? '' : ':  '.l:sign.attr).']')
                        \ ]
        endfor
    endfor

    call infoWin#Set(l:dict)
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
function sign#Project(...)
    call s:ProjectManager(a:0, a:000)
endfunction


" Toggle sign of a type
function sign#Toggle(...)
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


function sign#Jump(...)
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
function sign#Clear(...)
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
function sign#Save(...)
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
function sign#Load(...)
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
function sign#AddAttr(...)
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


function sign#WorkSpaceSave(...)
    let l:pre = a:0 > 0 ? matchstr(a:1, '^[^_.]*') : ''
    call s:WorkSpaceSave(l:pre)
    call s:SignSave(l:pre . s:signFile, keys(s:signVec))
endfunction


function sign#WorkSpaceLoad(...)
    let l:pre = a:0 > 0 ? matchstr(a:1, '^[^_.]*') : ''

    if !empty(l:pre)
        call s:WorkSpaceSave('')
        call s:SignSave(s:signFile, keys(s:signVec))
    endif

    call s:WorkSpaceLoad(l:pre)
    call s:SignLoad(l:pre . s:signFile, keys(s:signVec))
endfunction


function sign#WorkSpaceClear(...)
    let l:pre = a:0 > 0 ? matchstr(a:1, '^[^_.]*') : ''
    call delete(l:pre . s:sessionFile)
    call delete(l:pre . s:vimInfoFile)

    if empty(l:pre) && get(g:, 'Sign_projectized', 0)
        unlet! g:Sign_projectized
    endif
endfunction


" Set QuickFix window with qfList
function sign#SetQfList(...)
    if a:0 == 0
        return
    endif

    let l:group = tolower(a:1)
    let l:types = a:0 > 1 ? a:000[1:] : get(s:typesGroup, l:group, [])

    if empty(l:types)
        return
    elseif get(g:, 'Infowin_output', 0)
        cclose
        call s:InfoWinSet(a:1, l:types)
    else
        call s:QfListSet(a:1, l:types)
        exe 'copen '.get(g:, 'BottomWinHeight', 15)
        setlocal nowrap
    endif

    if !has_key(s:typesGroup, l:group) && a:0 > 1
        let s:typesGroup[l:group] = a:000[1:]
    endif
endfunction


function sign#TypeList()
    return keys(s:signVec)
endfunction


" Api: Get sign record info for other purpose
" like breakpoint for debug (format similar to s:SignSave())
" Return list
function sign#Record(...)
    let l:signRecord = []
    let l:signPlace = execute('sign place')

    " Get row information & set l:signRecord
    for l:type in a:000
        for l:sign in get(s:signVec, l:type, [])
            let l:line = matchlist(l:signPlace, '\v    \S+\=(\d+)'.
                        \ '  id\='.l:sign.id.'  \S+\='.s:defPrefix)

            if !empty(l:line)
                let l:signRecord += [l:type.' '.l:sign.file.':'.l:line[1].' '.l:sign.attr]
            endif
        endfor
    endfor

    return l:signRecord
endfunction

" vim:  set foldmethod=marker
