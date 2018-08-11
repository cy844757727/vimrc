""""""""""""""""""""""""""""""""""""""""""""""""""""
" Name: BMBPSign_BookMark_BreakPoint
" Author: CY <844757727@qq.com>
""""""""""""""""""""""""""""""""""""""""""""""""""""
if exists('loaded_BMBPSign')
  finish
endif
let loaded_BMBPSign = 1

" 标记组定义
sign define BMBPSignBookMarkDef text=🚩 texthl=NormalSign
sign define BMBPSignBreakPointDef text=💊 texthl=NormalSign

let s:bookMarkVec = []
let s:breakPointVec = []
let s:newSignId = 0
let s:bookMarkFile = '.bookmark'
let s:breakPointFile = '.breakpoint'
let s:sessionFile = '.session'
let s:vimInfoFile = '.viminfo'

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

