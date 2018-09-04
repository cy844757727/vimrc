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
if !exists('g:BMBPSign_ProjectType')
    let g:BMBPSign_ProjectType = {
                \ 'c':       s:home . '/Documents/WorkSpace',
                \ 'cpp':     s:home . '/Documents/WorkSpace',
                \ 'fpga':    s:home . '/Documents/Altera',
                \ 'verilog': s:home . '/Documents/Modelsim',
                \ 'altera':  s:home . '/Documents/Altera',
                \ 'xilinx':  s:home . '/Documents/Xilinx',
                \ 'default': s:home . '/Documents'
                \ }
else
    for l:item in items(g:BMBPSign_ProjectType)
        if l:item[1] =~ '^~'
            let g:BMBPSign_ProjectType[l:item[0]] = s:home . strpart(l:item[1], 1) 
        endif
    endfor
endif

let s:projectFile = s:home . '/.vim/.projectitem'
if filereadable(s:projectFile)
    let s:projectItem = readfile(s:projectFile)
else
    let s:projectItem = []
endif

"augroup BMBPSign
"    autocmd!
"    autocmd VimEnter * if empty(expand('%'))|call s:LoadWorkSpace('')|endif
"augroup END

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
    let l:vec = a:name == 'BMBPSignBookMarkDef' ? s:bookMarkVec : s:breakPointVec
    let l:signFile = a:name == 'BMBPSignBookMarkDef' ? s:bookMarkFile : s:breakPointFile
    " 获取所有sign
    redir @z
    silent sign place
    redir END
    let l:match = matchlist(@z, '    \S\+=' . a:line . '  id=\(\d\+\)' . '  \S\+=' . a:name)
    if empty(l:match)
        let s:newSignId += 1
        " 判断ID是否唯一
        while !empty(matchlist(@z, '    \S\+=\d\+' . '  id=' . s:newSignId . '  '))
            let s:newSignId += 1
        endwhile
        " 设置标记
        exec 'sign place ' . s:newSignId . ' line=' . a:line . ' name=' . a:name . ' file=' . a:file
        call add(l:vec, {'id': s:newSignId, 'file': a:file})
    else
        " 撤销标记
        exec 'sign unplace ' . l:match[1] . ' file=' . a:file
        call filter(l:vec, 'v:val.id != ' . l:match[1])
    endif
    call s:SaveSignFile(l:vec, l:signFile)
endfunction

" 撤销所有断点/书签
function s:ClearSign(name)
    let l:vec = a:name == 'BMBPSignBookMarkDef' ? s:bookMarkVec : s:breakPointVec
    for l:mark in l:vec
        exec 'sign unplace ' . l:mark.id . ' file=' . l:mark.file
    endfor
    " 清空断点/书签
    if !empty(l:vec)
        unlet l:vec[:]
    endif
    call delete(a:name == 'BMBPSignBookMarkDef' ? s:bookMarkFile : s:breakPointFile)
endfunction

function s:JumpSign(action)
    if !empty(s:bookMarkVec)
        if a:action == 'next'
            call add(s:bookMarkVec, s:bookMarkVec[0])
            call remove(s:bookMarkVec, 0)
        else
            call insert(s:bookMarkVec, s:bookMarkVec[-1])
            call remove(s:bookMarkVec, -1)
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
        redir @z
        silent sign place
        redir END
        exec "redir! > " . a:signFile
        exec "redir >> " . a:signFile
        for l:mark in a:vec
            let l:line = matchlist(@z, '    \S\+=\(\d\+\)' . '  id=' . l:mark.id . '  ')
            if empty(l:line)
                continue
            endif
            silent echo l:prefix l:mark.file ':' l:line[1] 
        endfor
        redir END
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
        exec 'cd ' . l:path
        silent %bwipeout
    endif
    echo substitute(l:item, ' ' . s:home, ' ~', '')
endfunction

function s:SwitchProject(sel)
    exec 'cd ' . split(s:projectItem[a:sel])[-1]
    call s:LoadWorkSpace('')
    call insert(s:projectItem, remove(s:projectItem, a:sel))
    call writefile(s:projectItem, s:projectFile)
    echo substitute(s:projectItem[0], ' ' . s:home, ' ~', '')
endfunction

function s:ProjectUI(start, tip)
    let l:page = a:start / 10 + 1
    let l:selection = "** Project option (pwd: " .
                \ substitute(getcwd(), s:home, '~', '') . '   num: ' . len(s:projectItem) .
                \ "   page: " . l:page . ")\n" .
                \ "   s:select  -/d:delete  m:modify  p:pageDown  P:pageUp  q:quit  +/a/n:new  0-9:item\n" .
                \ "   !?:selection mode,  Del:deletion mode,  Mod:modification mode,  New:new project\n" .
                \ repeat('=', min([&columns - 10, 80])) . "\n"
    let l:copy = s:projectItem[a:start:a:start+9]
    for l:i in range(len(l:copy))
        let l:item = substitute(l:copy[l:i], ' ' . s:home, ' ~', '',)
        let l:item = printf(' %3d: %s', l:i, l:item)
        let l:selection .= l:item . "\n"
    endfor
    return l:selection . a:tip
endfunction

function s:ProjectMenu()
    let l:flag = 's'
    let l:tip = '!?:'
    let l:start = range(0, len(s:projectItem) - 1, 10)
    while 1
        echo s:ProjectUI(l:start[0], l:tip)
        let l:char = nr2char(getchar())
        redraw!
        if l:char ==# 'p'
            call add(l:start, l:start[0])
            call remove(l:start, 0)
        elseif l:char ==# 'P'
            call insert(l:start, remove(l:start, -1))
        elseif l:char == 's'
            let l:tip = '!?:'
            let l:flag = 's'
        elseif l:char =~ '[-d]'
            let l:flag = 'd'
            let l:tip = 'Del:'
        elseif l:char == 'm'
            let l:flag = 'm'
            let l:tip = 'Mod:'
        elseif l:char == 'q'
            return
        elseif l:char =~ '\d\|\s' && l:char < len(s:projectItem)
            if l:flag == 's'
                call s:SwitchProject(l:char)
                break
            elseif l:flag == 'd'
                call remove(s:projectItem, l:char)
                call writefile(s:projectItem, s:projectFile)
            elseif l:flag == 'm'
                let l:list = split(s:projectItem[l:char])
                let l:argv = split(input("templete: <name> <type>\nMod: ", l:list[0] . ' ' . l:list[2]))
                redraw!
                if len(l:argv) == 2
                    let s:projectItem[l:char] = printf('%-20s  Type: %-12s  Path: %s',
                                \ l:argv[0], l:argv[1], l:list[-1])
                    call writefile(s:projectItem, s:projectFile)
                else
                    let l:tip = 'Wrong Argument, Reselect. Mod:'
                endif
            endif
        elseif l:char =~ '[+an]'
            let l:argv = split(input("templete: <name>  <type>  [path]\nNew: "))
            let l:argc = len(l:argv)
            redraw!
            if l:argc == 2 || l:argc == 3
                call s:ProjectManager(l:argc, l:argv)
                break
            else
                let l:tip = 'Wrong Argument, Reselect. !?:'
            endif
        else
            let l:tip = 'Unvalid(' . l:char . '), Reselect. !?:'
        endif
    endwhile
endfunction

function s:ProjectManager(argc, argv)
    if a:argc == 0
        call s:ProjectMenu()
    elseif a:argc == 1
        call s:SwitchProject(a:argv[0])
    elseif a:argc == 2
        if has_key(g:BMBPSign_ProjectType, a:argv[1])
            let l:path = g:BMBPSign_ProjectType[a:argv[1]] . '/' . a:argv[0]
        else
            let l:path = g:BMBPSign_ProjectType['default'] . '/' . a:argv[0]
        endif
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
    call system("sed -i 's/^file NERD_tree.*/close|NERDTree/' " . a:pre . s:sessionFile)
    call system("sed -i \"s/^file __Tagbar__.*/" .
                \ "close\\\\n" .
                \ "if bufwinnr('NERD_tree') != -1\\\\n" .
                \ "    exec bufwinnr('NERD_tree') . 'wincmd w'\\\\n" .
                \ "    TagbarOpen\\\\n" .
                \ "else\\\\n" .
                \ "    let g:tagbar_vertical=0\\\\n" .
                \ "    let g:tagbar_left=1\\\\n" .
                \ "    TagbarOpen\\\\n" .
                \ "    let g:tagbar_vertical=19\\\\n" .
                \ "    let g:tagbar_left=0\\\\n" .
                \ "endif\\\\n" .
                \ "exec bufwinnr('Tagbar') . 'wincmd w'/\" " .
                \ a:pre . s:sessionFile
                \ )
    let l:type = 'undef'
    let l:path = getcwd()
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
    call s:ClearSign('BMBPSignBookMarkDef')
    call s:ClearSign('BMBPSignBreakPointDef')
    silent %bwipeout
    if filereadable(a:pre . s:bookMarkFile)
        let l:sign = split(system("sed -n 's/^book //p' " . a:pre . s:bookMarkFile), '[ :\n]\+')
        for l:i in range(0, len(l:sign)-1, 2)
            if filereadable(l:sign[l:i])
                exec 'edit ' . l:sign[l:i]
                call s:ToggleSign(l:sign[l:i],l:sign[l:i+1], 'BMBPSignBookMarkDef')
            endif
        endfor
    endif
    if filereadable(a:pre . s:breakPointFile)
        let l:sign = split(system("sed -n 's/^break //p' " . a:pre . s:breakPointFile), '[ :\n]\+')
        for l:i in range(0, len(l:sign)-1, 2)
            if filereadable(l:sign[l:i])
                exec 'edit ' . l:sign[l:i]
                call s:ToggleSign(l:sign[l:i],l:sign[l:i+1], 'BMBPSignBreakPointDef')
            endif
        endfor
    endif
    filetype detect
    if filereadable(a:pre . s:sessionFile)
        exec 'silent source ' . a:pre . s:sessionFile
    endif
    if filereadable(a:pre . s:vimInfoFile)
        exec 'rviminfo ' . a:pre . s:vimInfoFile
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
        return
    endif
    if &filetype == 'tagbar' || &filetype == 'nerdtree' || &filetype == 'qf'
        return
    endif
    call s:ToggleSign(expand('%'), line('.'), 'BMBPSignBookMarkDef')
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
        return
    endif
    if &filetype == 'python'
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
    elseif &filetype == 'c' || &filetype == 'cpp'
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

