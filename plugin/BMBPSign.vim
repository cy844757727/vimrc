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

if !exists('g:BMBPSign_ProjectType')
    let g:BMBPSign_ProjectType = {
                \ 'c':       '~/Documents/WorkSpace/',
                \ 'cpp':     '~/Documents/WorkSpace/',
                \ 'fpga':    '~/Documents/Altera/',
                \ 'verilog': '~/Documents/Altera/',
                \ 'altera':  '~/Documents/Altera/'
                \ }
endif
let s:home = system('echo ~')[:-2]
let s:projectFile = s:home . '/.vim/.projectitem'
if filereadable(s:projectFile)
    let s:projectItem = readfile(s:projectFile)
else
    let s:projectItem = []
endif

" 在指定文件对应行切换断点/书签
function s:ToggleSign(file,line,name)
    let l:vec = a:name == 'BMBPSignBookMarkDef' ? s:bookMarkVec : s:breakPointVec
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
endfunction

" 保存断点/书签到指定文件
function s:SaveSignFile(vec,signFile)
    if empty(a:vec)
        call delete(a:signFile)
        return
    endif
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
endfunction

" 保存当前工作状态
function s:SaveWorkSpace(pre)
    call s:SaveSignFile(s:bookMarkVec,a:pre . s:bookMarkFile)
    call s:SaveSignFile(s:breakPointVec,a:pre . s:breakPointFile)
    exec 'mksession! ' . a:pre . s:sessionFile
    exec 'wviminfo! ' . a:pre . s:vimInfoFile
    call system("sed -i 's/^file NERD_tree.*/close|NERDTree/' " . a:pre . s:sessionFile)
    call system("sed -i \"s/^file __Tagbar__.*/close\\\\nif bufwinnr('NERD_tree') != -1\\\\n    exec bufwinnr('NERD_tree') . 'wincmd w'\\\\n    TagbarOpen\\\\nelse\\\\n    let g:tagbar_vertical=0\\\\n    let g:tagbar_left=1\\\\n    TagbarOpen\\\\n    let g:tagbar_vertical=19\\\\n    let g:tagbar_left=0\\\\nendif\\\\nexec bufwinnr('Tagbar') . 'wincmd w'/\" " . a:pre . s:sessionFile)
    let l:curDir = matchstr(getcwd(), '[^/]*$')
    for l:i in range(len(s:projectItem))
        if l:curDir == split(s:projectItem[l:i])[0]
            call remove(s:projectItem, l:i)
            break
        endif
    endfor
    call insert(s:projectItem, printf('%-20s  Type: undef         Path: %s', l:curDir, getcwd()))
    call writefile(s:projectItem, s:projectFile)
endfunction

" 恢复工作空间
function s:LoadWorkSpace(pre)
    call s:ClearSign('BMBPSignBookMarkDef')
    call s:ClearSign('BMBPSignBreakPointDef')
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
    if a:0 > 1
        let l:item = printf('%-20s  Type: %-12s  Path: ', a:1, a:2)
        if a:0 == 3
            let l:item .= a:3
        elseif a:0 == 2
            if has_key(g:BMBPSign_ProjectType, a:2)
                let l:item .= g:BMBPSign_ProjectType[a:2] . a:1
            else
                let l:item .= '~/Documents/' . a:1
            endif
        else
            echo '** Too many args!!!'
            return
        endif
        let l:dir = split(l:item)[-1]
        if l:dir =~ '^\~'
            let l:dir = s:home . strpart(l:dir, 1)
        endif
        if !isdirectory(l:dir)
            call mkdir(l:dir, 'p')
        endif
        exec 'cd ' . l:dir
        %bwipeout
        call insert(s:projectItem, l:item)
        call writefile(s:projectItem, s:projectFile)
    elseif !empty(s:projectItem)
        if a:0 == 1
            let l:sel == a:1
        else
            let l:option = "Select option:(eg: -1 - Delte item 1)\n" .
                        \ "======================================" .
                        \ "======================================" .
                        \ "======================================\n"
            for l:i in range(len(s:projectItem))
                let l:option .= '  ' . l:i . ':  ' . s:projectItem[l:i] . "\n"
            endfor
            let l:sel = input(l:option . '!?: ')
            if l:sel == ''
                let l:sel = '0'
            endif
        endif
        if l:sel =~ '^\d' && l:sel < len(s:projectItem)
            let l:dir = split(s:projectItem[l:sel])[-1]
            if l:dir =~ '^\~'
                let l:dir = s:home . strpart(l:dir, 1)
            endif
            exec 'cd ' . l:dir
            call s:LoadWorkSpace('')
            call insert(s:projectItem, remove(s:projectItem, l:sel))
        elseif l:sel =~ '^\-'
            let l:num = filter(split(strpart(l:sel, 1)), "v:val < " . len(s:projectItem))
            for l:i in l:num
                let s:projectItem[l:i] = ''
            endfor
            call filter(s:projectItem, "v:val != ''")
        else
            return
        endif
        call writefile(s:projectItem, s:projectFile)
    endif
endfunction

" 切换标记
function BMBPSign_Toggle(name)
    if expand('%') == ''
        echo 'Invalid file name!'
        return
    endif
    if &filetype == 'tagbar' || &filetype == 'nerdtree' || &filetype == 'qf'
        return
    endif
    call s:ToggleSign(expand('%'), line('.'), a:name)
    let l:vec = a:name == 'BMBPSignBookMarkDef' ? s:bookMarkVec : s:breakPointVec
    let l:signFile = a:name == 'BMBPSignBookMarkDef' ? s:bookMarkFile : s:breakPointFile
    call s:SaveSignFile(l:vec, l:signFile)
endfunction

" 书签跳转
function BMBPSign_Jump(action)
    if empty(s:bookMarkVec)
        return
    endif
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
        call BMBPSign_Jump(a:action)
    endtry
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
    call delete(a:name == 'BMBPSignBookMarkDef' ? s:bookMarkFile : s:breakPointFile)
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
        call BMBPSign_Toggle('BMBPSignBreakPointDef')
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
        call BMBPSign_Toggle('BMBPSignBreakPointDef')
    elseif &filetype == 'c' || &filetype == 'cpp'
        call BMBPSign_Toggle('BMBPSignBreakPointDef')
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
endfunction
" ==========================================================
" ==========================================================
augroup BMBPSign
    autocmd!
    autocmd VimEnter * if empty(expand('%'))|call s:LoadWorkSpace('')|endif
augroup END

command BMBPSignToggleBookMark :call BMBPSign_Toggle('BMBPSignBookMarkDef')
command BMBPSignToggleBreakPoint :call BMBPSign_ToggleBreakPoint()
command BMBPSignClearBookMark :call BMBPSign_Clear('BMBPSignBookMarkDef')
command BMBPSignClearBreakPoint :call BMBPSign_Clear('BMBPSignBreakPointDef')
command BMBPSignPreviousBookMark :call BMBPSign_Jump('previous')
command BMBPSignNextBookMark :call BMBPSign_Jump('next')

command -nargs=? -complete=file SWorkSpace :call BMBPSign_SaveWorkSpace('<args>')
command -nargs=? -complete=file CWorkSpace :call BMBPSign_ClearWorkSpace('<args>')
command -nargs=? -complete=file LWorkSpace :call BMBPSign_LoadWorkSpace('<args>')
command -nargs=* -complete=dir  Project :call BMBPSign_Project(<f-args>)

