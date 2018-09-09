""""""""""""""""""""""""""""""""""""""""""""""""""""
" Name: BMBPSign_BookMark_BreakPoint
" Author: CY <844757727@qq.com>
""""""""""""""""""""""""""""""""""""""""""""""""""""
if exists('loaded_BMBPSign')
  finish
endif
let loaded_BMBPSign = 1

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

if !exists('g:BMBPSign_WinSpecial')
    let g:BMBPSign_WinSpecial = {}
endif

if !exists('g:BMBPSign_ProjectType')
    let g:BMBPSign_ProjectType = {'default': s:home . '/Documents'}
else
    call map(g:BMBPSign_ProjectType, "v:val =~ '^\\~' ? s:home . strpart(v:val, 1) : v:val")
endif

command BMBPSignToggleBookMark :call BMBPSign_ToggleBookMark()
command BMBPSignToggleBreakPoint :call BMBPSign_ToggleBreakPoint()
command BMBPSignClearBookMark :call BMBPSign_Clear('BMBPSignBookMarkDef')
command BMBPSignClearBreakPoint :call BMBPSign_Clear('BMBPSignBreakPointDef')
command BMBPSignPreviousBookMark :call BMBPSign_Jump('previous')
command BMBPSignNextBookMark :call BMBPSign_Jump('next')

command -nargs=? -complete=custom,BMBPSign_CompleteWorkFile SWorkSpace :call BMBPSign_SaveWorkSpace('<args>')
command -nargs=? -complete=custom,BMBPSign_CompleteWorkFile CWorkSpace :call BMBPSign_ClearWorkSpace('<args>')
command -nargs=? -complete=custom,BMBPSign_CompleteWorkFile LWorkSpace :call BMBPSign_LoadWorkSpace('<args>')
command -nargs=* -complete=custom,BMBPSign_CompleteProject  Project :call BMBPSign_Project(<f-args>)
" ==========================================================
" ==========================================================
" 在指定文件对应行切换断点/书签
function s:ToggleSign(file,line,name)
    let [l:vec, l:signFile] = a:name == 'BMBPSignBookMarkDef' ?
                \ [s:bookMarkVec, s:bookMarkFile] :
                \ [s:breakPointVec, s:breakPointFile]
    let l:signPlace = execute('sign place')
    let l:match = matchlist(l:signPlace, '    \S\+=' . a:line . '  id=\(\d\+\)' . '  \S\+=' . a:name)
    if empty(l:match)
        let s:newSignId += 1
        while !empty(matchlist(l:signPlace, '    \S\+=\d\+' . '  id=' . s:newSignId . '  '))
            let s:newSignId += 1
        endwhile
        exec 'sign place ' . s:newSignId . ' line=' . a:line . ' name=' . a:name . ' file=' . a:file
        call add(l:vec, {'id': s:newSignId, 'file': a:file})
    else
        exec 'sign unplace ' . l:match[1] . ' file=' . a:file
        call filter(l:vec, 'v:val.id != ' . l:match[1])
    endif
    call s:SaveSignFile(l:vec, l:signFile)
endfunction

" 撤销所有断点/书签
function s:ClearSign(name)
    let [l:vec, l:signFile] = a:name == 'BMBPSignBookMarkDef' ?
                \ [s:bookMarkVec, s:bookMarkFile] :
                \ [s:breakPointVec, s:breakPointFile]
    for l:mark in l:vec
        exec 'sign unplace ' . l:mark.id . ' file=' . l:mark.file
    endfor
    if !empty(l:vec)
        unlet l:vec[:]
    endif
    call delete(l:signFile)
endfunction

function s:JumpSign(action)
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
            call s:JumpSign(a:action)
        endtry
    endif
endfunction

" 保存断点/书签到指定文件
function s:SaveSignFile(vec,signFile)
    if empty(a:vec)
        call delete(a:signFile)
    else
        let l:prefix = matchstr(a:signFile, '\..*$') == s:bookMarkFile ? 'book' : 'break'
        let l:signPlace = execute('sign place')
        let l:content = []
        for l:mark in a:vec
            let l:line = matchlist(l:signPlace, '    \S\+=\(\d\+\)' . '  id=' . l:mark.id . '  ')
            if !empty(l:line)
                let l:content += [l:prefix . ' ' . l:mark.file . ':' . l:line[1]]
            endif
        endfor
        call writefile(l:content, a:signFile)
    endif
endfunction

function s:NewProject(name, type, path)
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
    echo substitute(l:item, ' ' . s:home, ' ~', '')
endfunction

function s:SwitchProject(sel)
    exec 'silent cd ' . split(s:projectItem[a:sel])[-1]
    call s:LoadWorkSpace('')
    call insert(s:projectItem, remove(s:projectItem, a:sel))
    call writefile(s:projectItem, s:projectFile)
    echo substitute(s:projectItem[0], ' ' . s:home, ' ~', '')
endfunction

function s:ProjectUI(start, tip)
    let l:page = a:start / 10 + 1
    let l:head = "** Project option (cwd: " . substitute(getcwd(), s:home, '~', '') .
                \ '     num: ' . len(s:projectItem) . "     page: " . l:page . ")\n" .
                \ "   s:select  d:delete  m:modify  p:pageDown  P:pageUp  q:quit  Q:vimleave  a/n:new  0-9:item\n" .
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
            if l:mode == 's' && getcwd() != split(s:projectItem[l:start[0] + l:char])[-1]
                call s:SwitchProject(l:char)
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
            let l:argv = split(input("<name> <type> [path]: ", '', 'file'))
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
        call s:SwitchProject(a:argv[0])
    elseif a:argc == 2
        let l:key = has_key(g:BMBPSign_ProjectType, a:argv[1]) ? a:argv[1] : 'default'
        let l:path = g:BMBPSign_ProjectType[l:key] . '/' . a:argv[0]
        call s:NewProject(a:argv[0], a:argv[1], l:path)
    elseif a:argc == 3
        call s:NewProject(a:argv[0], a:argv[1], a:argv[2] =~ '^\~' ? s:home . strpart(a:argv[2], 1) : a:argv[2])
    endif
endfunction

" 保存当前工作状态
function s:SaveWorkSpace(pre)
    call s:SaveSignFile(s:bookMarkVec, a:pre . s:bookMarkFile)
    call s:SaveSignFile(s:breakPointVec, a:pre . s:breakPointFile)
    exec 'mksession! ' . a:pre . s:sessionFile
    exec 'wviminfo! ' . a:pre . s:vimInfoFile
    for l:item in items(g:BMBPSign_SpecialBuf)
        exec "call system(\"sed -i 's/^file " . l:item[0] . ".*$/bw|" . l:item[1] . "/' " . a:pre . s:sessionFile . "\")"
    endfor 
    let [l:type, l:path] = ['undef', getcwd()]
    let l:parent = substitute(l:path, '/\w*$', '', '')
    for l:item in items(g:BMBPSign_ProjectType)
        if l:item[1] == l:parent
            let l:type = l:item[0]
            break
        endif
    endfor
    call s:NewProject(matchstr(l:path, '[^/]*$'), l:type, l:path)
endfunction

" 恢复工作空间
function s:LoadWorkSpace(pre)
    if a:pre != ''
        call s:ClearSign('BMBPSignBookMarkDef')
        call s:ClearSign('BMBPSignBreakPointDef')
    endif
    silent %bwipeout
    if filereadable(a:pre . s:bookMarkFile)
        let l:sign = readfile(a:pre . s:bookMarkFile)
        for l:item in l:sign
            let l:list = split(l:item, '[ :]')
            if filereadable(l:list[1])
                exec 'silent edit ' . l:list[1]
                call s:ToggleSign(l:list[1], l:list[2], 'BMBPSignBookMarkDef')
            endif
        endfor
    endif
    if filereadable(a:pre . s:breakPointFile)
        let l:sign = readfile(a:pre . s:breakPointFile)
        for l:item in l:sign
            let l:list = split(l:item, '[ :]')
            if filereadable(l:list[1])
                exec 'silent edit ' . l:list[1]
                call s:ToggleSign(l:list[1], l:list[2], 'BMBPSignBreakPointDef')
            endif
        endfor
    endif
    filetype detect
    if filereadable(a:pre . s:vimInfoFile)
        exec 'silent! rviminfo! ' . a:pre . s:vimInfoFile
    endif
    if filereadable(a:pre . s:sessionFile)
        exec 'silent! source ' . a:pre . s:sessionFile
    endif
endfunction
" ==========================================================
" ============== 全局量定义 ================================
function BMBPSign_Project(...)
    call s:ProjectManager(a:0, a:000)
endfunction

function BMBPSign_CompleteProject(L, C, P)
    let l:num = len(split(strpart(a:C, 0, a:P)))
    if (a:L == '' && l:num == 1) || (a:L != '' && l:num == 2)
        return join(range(len(s:projectItem)), "\n")
    elseif (a:L == '' && l:num == 2) || (a:L != '' && l:num == 3)
        return join(keys(g:BMBPSign_ProjectType), "\n")
    elseif (a:L == '' && l:num ==3) || (a:L != '' && l:num == 4)
        return system("find ~/ -type d -regex '" . '[a-zA-Z0-9_/]*' . "'|sed 's/^\\/\\w\\+\\/\\w\\+/~/'")
    endif
endfunction

function BMBPSign_CompleteWorkFile(L, C, P)
    return system('ls -1 *.session|sed s/.session$//')
endfunction

" 切换标记
function BMBPSign_ToggleBookMark()
    if expand('%') == ''
        echo 'Invalid file name!'
    elseif &filetype !~ '^tagbar\|nerdtree\|qf$'
        call s:ToggleSign(expand('%'), line('.'), 'BMBPSignBookMarkDef')
    endif
endfunction

" 书签跳转
function BMBPSign_Jump(action)
    call s:JumpSign(a:action)
endfunction

" 撤销所有标记
function BMBPSign_Clear(name)
    call s:ClearSign(a:name)
    if a:name == 'BMBPSignBreakPointDef'
        let l:pos = line('.')
        if &filetype == 'python'
            :%s/^\s*#*pdb.set_trace()\s*\n//Ig
        elseif &filetype == 'sh'
            :%s/^\s*#*set [-+]x\s*\n//Ig
        endif
        call cursor(l:pos, 1)
    endif
endfunction

" 插入断点
function BMBPSign_ToggleBreakPoint()
    if expand('%') == ''
        echo 'Invalid file name!'
    elseif &filetype == 'python'
        if match(getline('.'),'pdb.set_trace()') == -1
            normal Opdb.set_trace()
        else
            normal dd
        endif
        call s:ToggleSign(expand('%'), line('.'), 'BMBPSignBreakPointDef')
    elseif &filetype == 'sh'
        if match(getline('.'),'set [-+]x') == -1
            if len(s:breakPointVec)%2 == 0
                normal Oset -x
            else
                normal Oset +x
            endif
        else
            normal dd
        endif
        call s:ToggleSign(expand('%'), line('.'), 'BMBPSignBreakPointDef')
    elseif &filetype =~ '^c\|cpp$'
        call s:ToggleSign(expand('%'), line('.'), 'BMBPSignBreakPointDef')
    endif
endfunction

function BMBPSign_SaveWorkSpace(pre)
    call s:SaveWorkSpace(matchstr(a:pre, '^[^.]*'))
endfunction

function BMBPSign_LoadWorkSpace(pre)
    call s:LoadWorkSpace(matchstr(a:pre, '^[^.]*'))
endfunction

function BMBPSign_ClearWorkSpace(pre)
    let l:pre= matchstr(a:pre, '^[^.]*')
    call delete(l:pre . s:sessionFile)
    call delete(l:pre . s:vimInfoFile)
    call delete(l:pre . s:bookMarkFile)
    call delete(l:pre . s:breakPointFile)
endfunction

