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
if exists('g:loaded_BMBPSign') || !has('signs')
    finish
endif
let g:loaded_BMBPSign = 1

augroup BMBPSign
    autocmd!
    autocmd VimEnter ?* :call s:VimEnterEvent()
    autocmd VimLeavePre * :call s:VimLeaveEvent()
augroup END

" sign command
com! -nargs=* -complete=custom,BMBPSign_CompleteSignFileType CSign :call BMBPSign#SignClear(<f-args>)
com! -nargs=* -complete=custom,BMBPSign_CompleteSignType TSign :call BMBPSign#SignToggle(<f-args>)
com! -nargs=* -complete=custom,BMBPSign_CompleteSignFileType SSign :call BMBPSign#SignSave(<f-args>)
com! -nargs=* -complete=custom,BMBPSign_CompleteSignFileType LSign :call BMBPSign#SignLoad(<f-args>)
com! -nargs=* -complete=custom,BMBPSign_CompleteSignType NSign :call BMBPSign#SignJump('next', <f-args>)
com! -nargs=* -complete=custom,BMBPSign_CompleteSignType PSign :call BMBPSign#SignJump('previous', <f-args>)
com! -nargs=* -complete=custom,BMBPSign_CompleteSignType ASignAttr :call BMBPSign#SignAddAttr(<f-args>)

" workspace command
com! -nargs=? -complete=custom,BMBPSign_CompleteWorkFile SWorkSpace :call BMBPSign#WorkSpaceSave(<q-args>)
com! -nargs=? -complete=custom,BMBPSign_CompleteWorkFile CWorkSpace :call BMBPSign#WorkSpaceClear(<q-args>)
com! -nargs=? -complete=custom,BMBPSign_CompleteWorkFile LWorkSpace :call BMBPSign#WorkSpaceLoad(<q-args>)

" project command
com! -nargs=* -complete=custom,BMBPSign_CompleteProject  Project :call BMBPSign#Project(<f-args>)
com! -nargs=* -complete=custom,BMBPSign_CompleteProject  MProject :call BMBPSign#Project(<f-args>)

" Completion function
function! BMBPSign_CompleteProject(L, C, P)
    let l:num = len(split(strpart(a:C, 0, a:P)))
    if (a:L == '' && l:num == 2) || (a:L != '' && l:num == 3)
        return join(keys(g:BMBPSign_ProjectType), "\n")
    elseif (a:L == '' && l:num ==3) || (a:L != '' && l:num == 4)
        return glob(a:L . '*')
    endif
endfunction

function! BMBPSign_CompleteWorkFile(L, C, P)
    return substitute(glob('*session'), '[_.]\w*', '', 'g')
endfunction

function! BMBPSign_CompleteSignFile(L, C, P)
    return substitute(glob('*signrecord'), '[_.]\w*', '', 'g')
endfunction

function! BMBPSign_CompleteSignType(L, C, P)
    return join(BMBPSign#SignTypeList(), "\n")
endfunction

function! BMBPSign_CompleteSignFileType(L, C, P)
    return BMBPSign_CompleteSignFile(a:L, a:C, a:P) .
                \ "\n|\n" .
                \ BMBPSign_CompleteSignType(a:L, a:C, a:P)
endfunction

" AutoCmd for VimEnter event
" Load sign when starting with a file
function s:VimEnterEvent()
    " Stop load twice when signs already exists
    " Occurs after loading the project
    if exists('g:BMBPSign_SignSetFlag')
        return
    endif

    let l:file = expand('%')
    if filereadable('.signrecord') && !empty(l:file) && !empty(systemlist('grep ' . l:file . ' .signrecord'))
        call BMBPSign#SignLoad()
    endif
endfunction

" AutoCmd for VimLeave event
" For saving | updating signFile
" And save workspace when set g:BMBPSign_Projectized
function s:VimLeaveEvent()
    if exists('g:BMBPSign_SignSetFlag')
        call BMBPSign#SignSave()
    endif

    if exists('g:BMBPSign_Projectized')
        call BMBPSign#WorkSpaceSave()
    endif
endfunction


