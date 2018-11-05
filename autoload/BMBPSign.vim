""""""""""""""""""""""""""""""""""""""""""""""""""""
" Author: CY <844757727@qq.com>
" Description: BookMark_BreakPoint_ProjectManager
""""""""""""""""""""""""""""""""""""""""""""""""""""
if exists('loaded_A_BMBPSign')
  finish
endif
let loaded_A_BMBPSign = 1

" sign definition
hi NormalSign  ctermbg=253  ctermfg=16
sign define BMBPSignBookMarkDef text=🚩 texthl=NormalSign
sign define BMBPSignBreakPointDef text=💊 texthl=NormalSign

" [{'attr': ..., 'id': ..., 'file': ...} ...]
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
" Toggle sign in the specified line of the specified file
" Attr: Additional attributes of the sign (break, book, todo, tbreak)
" Type: bookmark or breakpoint (book, break)
function s:SignToggle(file, line, type, attr)
    let [l:vec, l:signFile, l:signDef] = a:type == 'book' ?
                \ [s:bookMarkVec, s:bookMarkFile, 'BMBPSignBookMarkDef'] :
                \ [s:breakPointVec, s:breakPointFile, 'BMBPSignBreakPointDef']
    let l:signPlace = execute('sign place')
    let l:match = matchlist(l:signPlace, '    \S\+=' . a:line . '  id=\(\d\+\)' . '  \S\+=' . l:signDef)
    if empty(l:match)
        " Ensure id uniqueness
        let s:newSignId += 1
        while !empty(matchlist(l:signPlace, '    \S\+=\d\+' . '  id=' . s:newSignId . '  '))
            let s:newSignId += 1
        endwhile

        " Set sign
        exec 'sign place ' . s:newSignId . ' line=' . a:line . ' name=' . l:signDef . ' file=' . a:file
        call add(l:vec, {'id': s:newSignId, 'file': a:file, 'attr': a:attr})
    else
        " Unset sign
        exec 'sign unplace ' . l:match[1] . ' file=' . a:file
        call filter(l:vec, 'v:val.id != ' . l:match[1])
    endif

    " Refresh default sign file
    call s:SignSave(l:vec, l:signFile)
endfunction

" BookMark jump
" Action: next, previous
function s:Signjump(action)
    if !empty(s:bookMarkVec)
        if a:action == 'next'
            " Jump next
            call add(s:bookMarkVec, remove(s:bookMarkVec, 0))
        else
            " Jump previous
            call insert(s:bookMarkVec, remove(s:bookMarkVec, -1))
        endif

        try
            exec 'sign jump ' . s:bookMarkVec[-1].id . ' file=' . s:bookMarkVec[-1].file
        catch
            " For invalid sign
            call remove(s:bookMarkVec, -1)
            call s:Signjump(a:action)
        endtry
    endif
endfunction

" clear sign which match attr in vec
function s:SignClear(vec, signFile, attr)
    for l:mark in a:vec
        if l:mark.attr =~ a:attr
            exec 'sign unplace ' . l:mark.id . ' file=' . l:mark.file
        endif
    endfor

    call filter(a:vec, "v:val.attr !~ '" . a:attr . "'")
    " update signFile
    call s:SignSave(a:vec, a:signFile)
endfunction

" Generate todo statement
function s:TodoStatement()
    let l:todo = ' TODO: '

    " Comment out statement
    if &filetype =~ '^\(c\|cpp\|java\|javascript\|verilog\|systemverilog\)$'
        let l:todo ='//' . l:todo
    elseif &filetype == 'matlab'
        let l:todo='%' . l:todo
    elseif &filetype == 'vhdl'
        let l:todo='--' . l:todo
    elseif &filetype =~ '^\(sh\|make\|python\)$'
        let l:todo='#' . l:todo
    elseif &filetype == 'vim'
        let l:todo="\"" . l:todo
    endif

    return l:todo
endfunction

" Load & set bookmark/breakpoint sign
" Pre: file prefix
function s:SignLoad(pre, type)
    if a:type == 'book'
        let [l:vec, l:signFile, l:signDef] = [s:bookMarkVec, s:bookMarkFile, 'BMBPSignBookMarkDef']
    elseif a:type == 'break'
        let [l:vec, l:signFile, l:signDef] = [s:breakPointVec, s:breakPointFile, 'BMBPSignBreakPointDef']
    else
        return
    endif

    " Do not load default twice
    if empty(a:pre) && !empty(l:vec)
        return
    endif

    if filereadable(a:pre . l:signFile)
        " Read specifid sign file
        let l:signList = readfile(a:pre . l:signFile)

        " Empty default sign & Copy file to default file
        if !empty(a:pre)
            call s:SignClear(l:vec, l:signFile, '')
            call writefile(l:signList, l:signFile)
        endif

        " Load specified sign
        for l:item in l:signList
            let l:list = split(l:item, '[ :]')
            if filereadable(l:list[1])
                exec 'silent badd ' . l:list[1]
                let s:newSignId += 1
                let l:signPlace = execute('sign place')
                while !empty(matchlist(l:signPlace, '    \S\+=\d\+' . '  id=' . s:newSignId . '  '))
                    let s:newSignId += 1
                endwhile
                exec 'sign place ' . s:newSignId . ' line=' . l:list[2] . ' name=' . l:signDef . ' file=' . l:list[1]
                call add(l:vec, {'id': s:newSignId, 'file': l:list[1], 'attr': l:list[0]})
            endif
        endfor
    endif

    filetype detect
endfunction

" Save bookmark/breakpoint sign to a file
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

    call insert(s:projectItem, l:item)
    call writefile(s:projectItem, s:projectFile)
    set noautochdir

    " cd path
    if l:path != getcwd()
        if !isdirectory(l:path)
            call mkdir(l:path, 'p')
        endif
        exec 'silent cd ' . l:path
        silent %bwipeout
    endif

    let s:projectized = 1
    echo substitute(l:item, ' ' . s:home, ' ~', '')
endfunction

function s:ProjectSwitch(sel)
    " Empty the workspace
    if exists('s:projectized')
        silent %bwipeout
        unlet s:projectized
        let s:bookMarkVec = []
        let s:breakPointVec = []
    endif

    set noautochdir
    exec 'silent cd ' . split(s:projectItem[a:sel])[-1]
    call s:SignLoad('', 'book')
    call s:SignLoad('', 'break')
    call s:WorkSpaceLoad('')
    call insert(s:projectItem, remove(s:projectItem, a:sel))
    call writefile(s:projectItem, s:projectFile)
    echo substitute(s:projectItem[0], ' ' . s:home, ' ~', '')
endfunction

" Menu UI
function s:ProjectUI(start, tip)
    " ten items per page
    let l:page = a:start / 10 + 1

    " ui: head
    let l:ui = "** Project option (cwd: " . substitute(getcwd(), s:home, '~', '') .
                \ '     num: ' . len(s:projectItem) . "     page: " . l:page . ")\n" .
                \ "   s:select  d:delete  m:modify  p:pageDown  P:pageUp  q:quit  " .
                \ "Q:vimleave  a/n:new  0-9:item\n" .
                \ "   !?:selection mode,  Del:deletion mode,  Mod:modification mode\n" .
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

" Save current workspace to specified file
" Content: session, viminfo
" Pre: specify file name prefix
function s:WorkSpaceSave(pre)
    " Pre-save processing
    if exists('g:BMBPSign_PreSaveEventList')
        call execute(g:BMBPSign_PreSaveEventList)
    endif

    " Save session & viminfo
    let s:projectized = 1
    set noautochdir
    exec 'mksession! ' . a:pre . s:sessionFile
    let l:temp = &viminfo
    set viminfo='50,!,:100,/100,@100
    exec 'wviminfo! ' . a:pre . s:vimInfoFile
    exec 'set viminfo=' . l:temp

    " For special buf situation(modify session file)
    if exists('g:BMBPSign_SpecialBuf')
        for l:item in items(g:BMBPSign_SpecialBuf)
            call system("sed -i 's/^file " . l:item[0] . ".*$/" . l:item[1] . "/' " . a:pre . s:sessionFile)
        endfor
    endif

    " Remember the current window of each tab(modify session file)
    let l:sub = ''
    for l:i in range(1, tabpagenr('$'))
        let l:sub .= l:i . 'tabdo ' . tabpagewinnr(l:i) . 'wincmd w\n'
    endfor
    call system("sed -i 's/^\\(tabnext " . tabpagenr() . "\\)$/" . l:sub . "\\1/' " . a:pre . s:sessionFile)

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

" Restore workspace from specified file
" Context: session, viminfo
" Pre: specify file name prefix
function s:WorkSpaceLoad(pre)
    " Pre-load processing
    if exists('g:BMBPSign_PreLoadEventList')
        call execute(g:BMBPSign_PreLoadEventList)
    endif

    " Empty workspace
    if exists('s:projectized')
        %bwipeout

        " Restore sign (bwipeout will clear all sign)
        let s:bookMarkVec = []
        let s:breakPointVec =[]
        call s:SignLoad('', 'book')
        call s:SignLoad('', 'break')
    endif

    " Copy file to default file
    if !empty(a:pre)
        if filereadable(a:pre . s:sessionFile)
            call writefile(readfile(a:pre . s:sessionFile), s:sessionFile)
        endif
        if filereadable(a:pre . s:vimInfoFile)
            call writefile(readfile(a:pre . s:vimInfoFile), s:vimInfoFile)
        endif
    endif

    " Load viminfo
    if filereadable(a:pre . s:vimInfoFile)
        let l:temp = &viminfo
        set viminfo='50,!,:100,/100,@100
        exec 'silent! rviminfo! ' . a:pre . s:vimInfoFile
        exec 'set viminfo=' . l:temp
    endif

    " Load session
    if filereadable(a:pre . s:sessionFile)
        exec 'silent! source ' . a:pre . s:sessionFile
    endif

    set noautochdir
    let s:projectized = 1

    " Post-load processing
    if exists('g:BMBPSign_PostLoadEventList')
        call execute(g:BMBPSign_PostLoadEventList)
    endif
endfunction
" ==========================================================
" ============== Global ================================
function BMBPSign#Project(...)
    call s:ProjectManager(a:0, a:000)
endfunction

" Toggle bookmark/breakpoint
" Type: book/break. " Attr: book,todo,break,tbreak or other
function BMBPSign#Toggle(type, attr)
    if filereadable(expand('%')) && empty(&buftype)
        if a:type == 'break' && &filetype !~ '^\(c\|cpp\|sh\|python\|perl\)$'
            return
        elseif a:type == 'book' && a:attr == 'todo' && getline('.') !~ 'TODO:'
            call append('.', s:TodoStatement())
            write | normal j==
        endif

        let l:attr = a:attr == '' ? a:type : a:attr
        call s:SignToggle(expand('%'), line('.'), a:type, l:attr)
    else
        echo 'Invalid object or unsaved'
    endif
endfunction

function BMBPSign#Jump(action)
    call s:Signjump(a:action)
endfunction

function BMBPSign#SignSave(pre, type)
    let l:pre = matchstr(a:pre, '^[^.]*')
    if a:type =~ 'book\|all'
        call s:SignSave(s:bookMarkVec, l:pre . s:bookMarkFile)
    endif
    if a:type =~ 'break\|all'
        call s:SignSave(s:breakPointVec, l:pre . s:breakPointFile)
    endif
endfunction

" Cancel bookmark/breakpoint
" Pre: file prefix    " Type: book, break
function BMBPSign#SignClear(pre, type)
    let l:pre = matchstr(a:pre, '^[^.]*')
    if !empty(l:pre)
        if a:type =~ 'book\|all'
            call delete(l:pre . s:bookMarkFile)
        endif
        if a:type =~ 'break\|all'
            call delete(l:pre . s:breakPointFile)
        endif
    else
        if a:type =~ 'book\|all'
            call s:SignClear(s:bookMarkVec, s:bookMarkFile, 'book')
        endif
        if a:type =~ 'break\|all'
            call s:SignClear(s:breakPointVec, s:breakPointFile, '')
        endif
    endif
endfunction

function BMBPSign#SignLoad(pre, type)
    let l:pre = matchstr(a:pre, '^[^.]*')
    if a:type =~ 'book\|all'
        call s:SignLoad(l:pre, 'book')
    endif
    if a:type =~ 'break\|all'
        call s:SignLoad(l:pre, 'break')
    endif
endfunction

function BMBPSign#WorkSpaceSave(pre)
    call s:WorkSpaceSave(matchstr(a:pre, '^[^.]*'))
endfunction

function BMBPSign#WorkSpaceLoad(pre)
    call s:WorkSpaceLoad(matchstr(a:pre, '^[^.]*'))
endfunction

function BMBPSign#WorkSpaceClear(pre)
    let l:pre = matchstr(a:pre, '^[^.]*')
    call delete(l:pre . s:sessionFile)
    call delete(l:pre . s:vimInfoFile)
endfunction

" Return qfList used for seting quickfix
" Type: book, break
function BMBPSign#GetList(type)
    let l:qf = []
    let l:signFile = a:type == 'book' ? s:bookMarkFile : s:breakPointFile

    if filereadable(l:signFile)
        for l:item in readfile(l:signFile)
            let l:list = split(l:item, '[ :]\+')
            if bufexists(l:list[1])
                let l:text = system("sed -n '" . l:list[2] . "p' " . l:list[1])[:-2]
                let l:qf += [{
                            \ 'bufnr': bufnr(l:list[1]),
                            \ 'filename': l:list[1],
                            \ 'lnum': l:list[2],
                            \ 'text': '[' . l:list[0] . ']  ' . l:text
                            \ }]
            endif
        endfor
    endif

    return l:qf
endfunction

" AutoCmd for VimEnter event
" Load sign when starting with a file
" which has bookmark/breakpoint set
function BMBPSign#VimEnterEvent()
    if !empty(s:bookMarkVec + s:breakPointVec)
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
        call BMBPSign#SignLoad('', 'all')
    endif
endfunction


