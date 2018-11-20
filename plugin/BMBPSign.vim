""""""""""""""""""""""""""""""""""""""""""""""""""""
" Author: CY <844757727@qq.com>
" Description: BookMark_BreakPoint_ProjectManager
""""""""""""""""""""""""""""""""""""""""""""""""""""
"    针对特殊buf需要处理的操作:dict (保存/加载 工作空间时)
"    g:BMBPSign_SpecialBuf
"
"    保存工作空间前需要处理的语句:list
"    g:BMBPSign_PreSaveEventList
"
"    保存工作空间后需要处理的语句:list
"    g:BMBPSign_PostSaveEventList
"
"    加载工作空间前需要处理的语句:list
"    g:BMBPSign_PreLoadEventList
"
"    加载工作空间后需要处理的语句:list
"    g:BMBPSign_PostLoadEventList
"    
""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:home = system('echo ~')[:-2]
if !exists('g:BMBPSign_ProjectType')
    let g:BMBPSign_ProjectType = {'default': s:home . '/Documents'}
else
    call map(g:BMBPSign_ProjectType, "v:val =~ '^\\~' ? s:home . strpart(v:val, 1) : v:val")
endif

augroup BMBPSign
    autocmd!
    autocmd VimEnter ?* :call BMBPSign#VimEnterEvent()
    autocmd VimLeavePre * :call BMBPSign#VimLeaveEvent()
augroup END

" sign command
com! -nargs=+ -complete=custom,BMBPSign_CompleteSignTypeFile CSignTypeFile :call BMBPSign#SignClear('<args>')
com! -nargs=1 -complete=custom,BMBPSign_CompleteSignType TSignType :call BMBPSign#SignToggle('<args>')
com! -nargs=? -complete=custom,BMBPSign_CompleteSignFile SSignFIle :call BMBPSign#SignSave('<args>')
com! -nargs=? -complete=custom,BMBPSign_CompleteSignFile LSignFIle :call BMBPSign#SignLoad('<args>')

" workspace command
com! -nargs=? -complete=custom,BMBPSign_CompleteWorkFile SWorkSpace :call BMBPSign#WorkSpaceSave('<args>')
com! -nargs=? -complete=custom,BMBPSign_CompleteWorkFile CWorkSpace :call BMBPSign#WorkSpaceClear('<args>')
com! -nargs=? -complete=custom,BMBPSign_CompleteWorkFile LWorkSpace :call BMBPSign#WorkSpaceLoad('<args>')

" project command
com! -nargs=* -complete=custom,BMBPSign_CompleteProject  Project :call BMBPSign#Project(<f-args>)
com! -nargs=* -complete=custom,BMBPSign_CompleteProject  MProject :call BMBPSign#Project(<f-args>)

function BMBPSign_CompleteProject(L, C, P)
    let l:num = len(split(strpart(a:C, 0, a:P)))
    if (a:L == '' && l:num == 2) || (a:L != '' && l:num == 3)
        return join(keys(g:BMBPSign_ProjectType), "\n")
    elseif (a:L == '' && l:num ==3) || (a:L != '' && l:num == 4)
        return glob(a:L . '*')
    endif
endfunction

function BMBPSign_CompleteWorkFile(L, C, P)
    return substitute(glob('*.session'), '\.\w*', '', 'g')
endfunction

function BMBPSign_CompleteSignFile(L, C, P)
    return substitute(glob('*.signrecord'), '\.\w*', '', 'g')
endfunction

function BMBPSign_CompleteSignType(L, C, P)
    return join(BMBPSign#SignTypeList(), "\n")
endfunction

function BMBPSign_CompleteSignTypeFile(L, C, P)
    return substitute(glob('*.signrecord'), '\.\w*', '', 'g') .
                \ "\n|\n" .
                \ join(BMBPSign#SignTypeList(), "\n")
endfunction
