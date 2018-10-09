""""""""""""""""""""""""""""""""""""""""""""""""""""
" Author: CY <844757727@qq.com>
" Description: BookMark_BreakPoint_ProjectManager
""""""""""""""""""""""""""""""""""""""""""""""""""""
"    针对特殊buf需要处理的操作:dict (保存/加载 工作空间时)
"    g:BMBPSign_SpecialBuf
"
"    保存工作空间前需要处理的语句:list
"    g:BMBPSign_PreSaveEvent
"
"    保存工作空间后需要处理的语句:list
"    g:BMBPSign_PostSaveEvent
"
"    加载工作空间前需要处理的语句:list
"    g:BMBPSign_PreLoadEvent
"
"    加载工作空间后需要处理的语句:list
"    g:BMBPSign_PostLoadEvent
"    
"    是否项目化管理标志
"    g:BMBPSIGNPROJECTIZED
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:home = system('echo ~')[:-2]
if !exists('g:BMBPSign_ProjectType')
    let g:BMBPSign_ProjectType = {'default': s:home . '/Documents'}
else
    call map(g:BMBPSign_ProjectType, "v:val =~ '^\\~' ? s:home . strpart(v:val, 1) : v:val")
endif

augroup BMBPSign
    autocmd!
    autocmd VimEnter ?* :call BMBPSign#VimEnterEvent()
augroup END

command! -nargs=? BMBPSignToggleBookMark :call BMBPSign#Toggle('book', '<args>')
command! -nargs=? BMBPSignToggleBreakPoint :call BMBPSign#Toggle('break', '<args>')
command! BMBPSignClearBookMark :call BMBPSign#Clear('book')
command! BMBPSignClearBreakPoint :call BMBPSign#Clear('break')
command! BMBPSignPreviousBookMark :call BMBPSign#Jump('previous')
command! BMBPSignNextBookMark :call BMBPSign#Jump('next')

command! -nargs=? -complete=custom,BMBPSign_CompleteWorkFile SWorkSpace :call BMBPSign#WorkSpaceSave('<args>')
command! -nargs=? -complete=custom,BMBPSign_CompleteWorkFile CWorkSpace :call BMBPSign#WorkSpaceClear('<args>')
command! -nargs=? -complete=custom,BMBPSign_CompleteWorkFile LWorkSpace :call BMBPSign#WorkSpaceLoad('<args>')
command! -nargs=* -complete=custom,BMBPSign_CompleteProject  Project :call BMBPSign#Project(<f-args>)
command! -nargs=* -complete=custom,BMBPSign_CompleteProject  MProject :call BMBPSign#Project(<f-args>)

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

