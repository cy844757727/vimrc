""""""""""""""""""""""""""""""""""""""""""""""""""""
" Author: CY <844757727@qq.com>
" Description: BookMark_BreakPoint_ProjectManager
""""""""""""""""""""""""""""""""""""""""""""""""""""
if exists('loaded_A_BMBPSign')
  finish
endif
let loaded_A_BMBPSign = 1

" 标记组定义
hi NormalSign  ctermbg=253  ctermfg=16
sign define BMBPSignBookMarkDef text=🚩 texthl=NormalSign
sign define BMBPSignBreakPointDef text=💊 texthl=NormalSign

let s:bookMarkVec = []
let s:breakPointVec = []
let s:newSignId = 0
let s:bookMarkFile = '.bookmark'
let s:breakPointFile = '.breakpoint'
let s:sessionFile = '.session'
let s:vimInfoFile = '.viminfo'
let s:home = system('echo ~')[:-2]
let s:projectFile = s:home . '/.vim/.projectitem'
let s:projectItem = filereadable(s:projectFile) ? readfile(s:projectFile) : []

" ==========================================================
" ==========================================================
" 在指定文件对应行切换断点/书签
function s:SignToggle(file, line, vec, signFile, signDef, attr)
    let l:signPlace = execute('sign place')
    let l:match = matchlist(l:signPlace, '    \S\+=' . a:line . '  id=\(\d\+\)' . '  \S\+=' . a:signDef)
    if empty(l:match)
        let s:newSignId += 1
        while !empty(matchlist(l:signPlace, '    \S\+=\d\+' . '  id=' . s:newSignId . '  '))
            let s:newSignId += 1
        endwhile
        exec 'sign place ' . s:newSignId . ' line=' . a:line . ' name=' . a:signDef . ' file=' . a:file
        call add(a:vec, {'id': s:newSignId, 'file': a:file, 'attr': a:attr})
    else
        exec 'sign unplace ' . l:match[1] . ' file=' . a:file
        call filter(a:vec, 'v:val.id != ' . l:match[1])
    endif
    call s:SignSave(a:vec, a:signFile)
endfunction

function s:Signjump(action)
    if !empty(s:bookMarkVec)
        if a:action == 'next'
            call add(s:bookMarkVec, remove(s:bookMarkVec, 0))
        else
            call insert(s:bookMarkVec, remove(s:bookMarkVec, -1))
        endif
        try
            exec 'sign jump ' . s:bookMarkVec[-1].id . ' file=' . s:bookMarkVec[-1].file
        catch
            call remove(s:bookMarkVec, -1)
            call s:Signjump(a:action)
        endtry
    endif
endfunction

" 撤销所有断点/书签
function s:SignClear(vec, signFile)
    for l:mark in a:vec
        if l:mark.attr != 'todo'
            exec 'sign unplace ' . l:mark.id . ' file=' . l:mark.file
        endif
    endfor
    call filter(a:vec, "v:val.attr == 'todo'")
    call s:SignSave(a:vec, a:signFile)
endfunction

" just for s:SignLoad()
function s:SignSet(vec, signFile, signDef)
    for l:item in readfile(a:signFile)
        let l:list = split(l:item, '[ :]')
        if filereadable(l:list[1])
            exec 'silent badd ' . l:list[1]
            let s:newSignId += 1
            let l:signPlace = execute('sign place')
            while !empty(matchlist(l:signPlace, '    \S\+=\d\+' . '  id=' . s:newSignId . '  '))
                let s:newSignId += 1
            endwhile
            exec 'sign place ' . s:newSignId . ' line=' . l:list[2] . ' name=' . a:signDef . ' file=' . l:list[1]
            call add(a:vec, {'id': s:newSignId, 'file': l:list[1], 'attr': l:list[0]})
        endif
    endfor
endfunction

function s:SignLoad(pre)
    if filereadable(a:pre . s:bookMarkFile)
        if a:pre != ''
            call s:SignClear(s:bookMarkVec, s:bookMarkFile)
        endif
        call s:SignSet(s:bookMarkVec, a:pre . s:bookMarkFile, 'BMBPSignBookMarkDef',)
    endif
    if filereadable(a:pre . s:breakPointFile)
        if a:pre != ''
            call s:SignClear(s:breakPointVec, s:breakPointFile)
        endif
        call s:SignSet(s:breakPointVec, a:pre . s:breakPointFile, 'BMBPSignBreakPointDef',)
    endif
    filetype detect
endfunction

" 保存断点/书签到指定文件
function s:SignSave(vec,signFile)
    if empty(a:vec)
        call delete(a:signFile)
    else
        let l:content = []
        let l:signPlace = execute('sign place')
        for l:mark in a:vec
            let l:line = matchlist(l:signPlace, '    \S\+=\(\d\+\)' . '  id=' . l:mark.id . '  ')
            if !empty(l:line)
                let l:content += [l:mark.attr . ' ' . l:mark.file . ':' . l:line[1]]
            endif
        endfor
        call writefile(l:content, a:signFile)
    endif
endfunction

function s:ProjectNew(name, type, path)
    " path -> absolute path
    let l:type = a:type == '.' ? 'undef' : a:type
    let l:path = a:path == '.' ? getcwd() : a:path
    for l:i in range(len(s:projectItem))
        if l:path == split(s:projectItem[l:i])[-1]
            let l:item = remove(s:projectItem, l:i)
            break
        endif
    endfor
    if a:path == '.' || !exists('l:item')
        let l:item = printf('%-20s  Type: %-12s  Path: %s', a:name, l:type, l:path)
    endif
    call insert(s:projectItem, l:item)
    call writefile(s:projectItem, s:projectFile)
    if l:path != getcwd()
        if !isdirectory(l:path)
            call mkdir(l:path, 'p')
        endif
        exec 'silent cd ' . l:path
        silent %bwipeout
    endif
    let g:BMBPSIGNPROJECTIZED = 1
    echo substitute(l:item, ' ' . s:home, ' ~', '')
endfunction

function s:ProjectSwitch(sel)
    silent %bwipeout
    exec 'silent cd ' . split(s:projectItem[a:sel])[-1]
    call s:SignLoad('')
    call s:WorkSpaceLoad('')
    call insert(s:projectItem, remove(s:projectItem, a:sel))
    call writefile(s:projectItem, s:projectFile)
    echo substitute(s:projectItem[0], ' ' . s:home, ' ~', '')
endfunction

function s:ProjectUI(start, tip)
    let l:page = a:start / 10 + 1
    let l:head = "** Project option (cwd: " . substitute(getcwd(), s:home, '~', '') .
                \ '     num: ' . len(s:projectItem) . "     page: " . l:page . ")\n" .
                \ "   s:select  d:delete  m:modify  p:pageDown  P:pageUp  q:quit  " .
                \ "Q:vimleave  a/n:new  0-9:item\n" .
                \ "   !?:selection mode,  Del:deletion mode,  Mod:modification mode\n" .
                \ repeat('=', min([&columns - 10, 90]))
    let l:body = s:projectItem[a:start:a:start+9]
    call map(l:body, "printf(' %3d: ', v:key) . substitute(v:val, ' ' . s:home, ' ~', '')")
    return l:head . "\n" . join(l:body, "\n") . "\n" . a:tip
endfunction

function s:ProjectMenu()
    let [l:tip, l:mode] = ['!?:', 's']
    let l:start = empty(s:projectItem) ? [0] : range(0, len(s:projectItem) - 1, 10)
    while 1
        echo s:ProjectUI(l:start[0], l:tip)
        let l:char = nr2char(getchar())
        redraw!
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
            if l:mode == 's' && !(getcwd() == split(s:projectItem[l:start[0] + l:char])[-1] && exists('g:BMBPSIGNPROJECTIZED'))
                call s:ProjectSwitch(l:char)
                break
            elseif l:mode == 'd'
                call remove(s:projectItem, l:char)
                call writefile(s:projectItem, s:projectFile)
            elseif l:mode == 'm'
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

" 保存当前工作空间
function s:WorkSpaceSave(pre)
    if exists('g:BMBPSign_PreSaveEvent')
        for l:statement in g:BMBPSign_PreSaveEvent
            call execute(l:statement)
        endfor
    endif
    if a:pre != ''
        call s:SignSave(s:bookMarkVec, a:pre . s:bookMarkFile)
        call s:SignSave(s:breakPointVec, a:pre . s:breakPointFile)
    endif
    exec 'mksession! ' . a:pre . s:sessionFile
    let l:temp = &viminfo
    set viminfo='50,!,:100,/100,@100
    exec 'wviminfo! ' . a:pre . s:vimInfoFile
    exec 'set viminfo=' . l:temp
    if exists('g:BMBPSign_SpecialBuf')
        for l:item in items(g:BMBPSign_SpecialBuf)
            call system("sed -i 's/^file " . l:item[0] . ".*$/" . l:item[1] . "/' " . a:pre . s:sessionFile)
        endfor
    endif
    let l:sub = ''
    for l:i in range(1, tabpagenr('$'))
        let l:sub .= l:i . 'tabdo ' . tabpagewinnr(l:i) . 'wincmd w\n'
    endfor
    call system("sed -i 's/^\\(tabnext " . tabpagenr() . "\\)$/" . l:sub . "\\1/' " . a:pre . s:sessionFile)
    let [l:type, l:path] = ['undef', getcwd()]
    let l:parent = substitute(l:path, '/\w*$', '', '')
    for l:item in items(g:BMBPSign_ProjectType)
        if l:item[1] == l:parent
            let l:type = l:item[0]
            break
        endif
    endfor
    call s:ProjectNew(matchstr(l:path, '[^/]*$'), l:type, l:path)
    if exists('g:BMBPSign_PostSaveEvent')
        for l:statement in g:BMBPSign_PostSaveEvent
            call execute(l:statement)
        endfor
    endif
endfunction

" 恢复工作空间
function s:WorkSpaceLoad(pre)
    if exists('g:BMBPSign_PreLoadEvent')
        for l:statement in g:BMBPSign_PreLoadEvent
            call execute(l:statement)
        endfor
    endif
    if a:pre != '' || (empty(s:bookMarkVec + s:breakPointVec) && (filereadable(s:bookMarkFile) || filereadable(s:breakPointFile)))
        call s:SignLoad(a:pre)
    endif
    if filereadable(a:pre . s:vimInfoFile)
        let l:temp = &viminfo
        set viminfo='50,!,:100,/100,@100
        exec 'silent! rviminfo! ' . a:pre . s:vimInfoFile
        exec 'set viminfo=' . l:temp
    endif
    if filereadable(a:pre . s:sessionFile)
        exec 'silent! source ' . a:pre . s:sessionFile
    endif
    if exists('g:BMBPSign_PostLoadEvent')
        for l:statement in g:BMBPSign_PostLoadEvent
            call execute(l:statement)
        endfor
    endif
endfunction

function s:WorkSpaceClear(pre)
    call delete(a:pre . s:sessionFile)
    call delete(a:pre . s:vimInfoFile)
    if a:pre != ''
        call delete(a:pre . s:bookMarkFile)
        call delete(a:pre . s:breakPointFile)
    endif
endfunction
" ==========================================================
" ============== 全局量定义 ================================
function BMBPSign#Project(...)
    call s:ProjectManager(a:0, a:000)
endfunction

" 切换书签/断点
function BMBPSign#Toggle(type, attr)
    if filereadable(expand('%')) && empty(&buftype)
        if a:type == 'break' && &filetype !~ '^\(c\|cpp\|sh\|python\|perl\)$'
            return
        elseif a:type == 'book' && a:attr == 'todo'
            if &filetype =~ '^\(c\|cpp\|java\|verilog\|systemverilog\)$'
                let l:char='//'
            elseif &filetype == 'matlab'
                let l:char='%'
            elseif &filetype =~ '^\(sh\|make\|python\|tcl\)$'
                let l:char='#'
            elseif &filetype == 'vim'
                let l:char="\""
            else
                let l:char=''
            endif
            if l:char != ''
                call append('.', l:char . ' TODO: ')
                normal j==
                write
            endif
        endif
        let l:attr = a:attr == '' ? a:type : a:attr
        let [l:vec, l:signFile, l:signDef] = a:type == 'book' ?
                    \ [s:bookMarkVec, s:bookMarkFile, 'BMBPSignBookMarkDef'] :
                    \ [s:breakPointVec, s:breakPointFile, 'BMBPSignBreakPointDef']
        call s:SignToggle(expand('%'), line('.'), l:vec, l:signFile, l:signDef, l:attr)
    else
        echo 'Invalid object or unsaved'
    endif
endfunction

" 书签跳转
function BMBPSign#Jump(action)
    call s:Signjump(a:action)
endfunction

" 撤销所有书签/断点
function BMBPSign#Clear(type)
    if a:type == 'book'
        call s:SignClear(s:bookMarkVec, s:bookMarkFile)
    elseif a:type == 'break'
        call s:SignClear(s:breakPointVec, s:breakPointFile)
    endif
endfunction

function BMBPSign#WorkSpaceSave(pre)
    call s:WorkSpaceSave(matchstr(a:pre, '^[^.]*'))
endfunction

function BMBPSign#WorkSpaceLoad(pre)
    call s:WorkSpaceLoad(matchstr(a:pre, '^[^.]*'))
endfunction

function BMBPSign#WorkSpaceClear(pre)
    call s:WorkSpaceClear(matchstr(a:pre, '^[^.]*'))
endfunction

function BMBPSign#GetList(str)
    let l:qf = []
    let l:signFile = a:str == 'book' ? s:bookMarkFile : s:breakPointFile
    if filereadable(l:signFile)
        for l:item in readfile(l:signFile)
            let l:list = split(l:item, '[ :]\+')
            if bufexists(l:list[1])
                let l:text = system("sed -n '" . l:list[2] . "p' " . l:list[1])[:-2]
                let l:qf += [{
                            \ 'bufnr': bufnr(l:list[1]),
                            \ 'filename': l:list[1],
                            \ 'lnum': l:list[2],
                            \ 'text': '(' . l:list[0] . ')  ' . l:text
                            \ }]
            endif
        endfor
    endif
    return l:qf
endfunction

function BMBPSign#VimEnterEvent()
    if exists('g:BMBPSIGNPROJECTIZED')
        return
    endif
    let l:list = []
    let l:file = expand('%')
    if filereadable(s:bookMarkFile)
        let l:list += systemlist("grep '" . l:file . "' " . s:bookMarkFile)
    endif
    if filereadable(s:breakPointFile)
        let l:list += systemlist("grep '" . l:file . "' " . s:breakPointFile)
    endif
    if !empty(l:list)
        call s:SignLoad('')
    endif
endfunction

