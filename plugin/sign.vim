""""""""""""""""""""""""""""""""""""""""""""""
" File: sign.vim
" Author: Cy <844757727@qq.com>
" Description: BookMark_BreakPoint_ProjectManager
" Last Modified: 2019年01月06日 星期日 16时59分11秒
""""""""""""""""""""""""""""""""""""""""""""""
"    针对特殊buf需要处理的操作:dict (保存/加载 工作空间时)
"    g:sign_SpecialBuf
"
"    Enent:
"       WorkSpaceSavePre:    before save workspace
"       WorkSpaceSavePost:   after save workspace
"
"       WorkSpaceLoadPre:    before load workspace
"       VimInfoLoadPre:      before load viminfo file
"       VimInfoLoadPost:     after load viminfo file
"       WorkSpaceLoadPost:   after load workspace
"
""""""""""""""""""""""""""""""""""""""""""""""""""""
if exists('g:loaded_sign') || !has('signs')
    finish
endif
let g:loaded_sign = 1

augroup Sign_
    autocmd!
    autocmd VimEnter ?* :call s:VimEnterEvent()
    autocmd VimLeavePre * :call s:VimLeaveEvent()
augroup END

" sign command
com! -nargs=* -complete=custom,Sign_CompleteTypeFile CSign :call sign#Clear(<f-args>)
com! -nargs=* -complete=custom,Sign_CompleteType TSign :call sign#Toggle(<f-args>)
com! -nargs=* -complete=custom,Sign_CompleteTypeFile SSign :call sign#Save(<f-args>)
com! -nargs=* -complete=custom,Sign_CompleteTypeFile LSign :call sign#Load(<f-args>)
com! -nargs=* -complete=custom,Sign_CompleteType NSign :call sign#Jump('next', <f-args>)
com! -nargs=* -complete=custom,Sign_CompleteType PSign :call sign#Jump('previous', <f-args>)
com! -nargs=* -complete=custom,Sign_CompleteType JSign :call sign#Jump(<f-args>)
com! -nargs=* -complete=custom,Sign_CompleteType ASignAttr :call sign#AddAttr(<f-args>)

" workspace command
com! -nargs=? -complete=custom,Sign_CompleteWorkFile  SWorkSpace :call sign#WorkSpaceSave(<q-args>)
"com! -nargs=? -complete=custom,sign_CompleteWorkFile  CWorkSpace :call sign#WorkSpaceClear(<q-args>)
com! -nargs=? -complete=custom,Sign_CompleteWorkFile  LWorkSpace :call sign#WorkSpaceLoad(<q-args>)

" project command
com! -nargs=* -complete=custom,Sign_CompleteProject MProject :call sign#Project(<f-args>)

" Completion function
function! Sign_CompleteProject(L, C, P)
    let l:num = len(split(strpart(a:C, 0, a:P)))
    if (a:L == '' && l:num == 2) || (a:L != '' && l:num == 3)
        return join(keys(g:sign_ProjectType), "\n")
    elseif (a:L == '' && l:num ==3) || (a:L != '' && l:num == 4)
        return join(getcompletion(a:L.'*', 'dir'), "\n")
    endif
endfunction

function! Sign_CompleteWorkFile (L, C, P)
    return substitute(glob('*session'), '[_.]\w*', '', 'g')
endfunction

function! Sign_CompleteFile(L, C, P)
    return substitute(glob('*signrecord'), '[_.]\w*', '', 'g')
endfunction

function! Sign_CompleteType(L, C, P)
    return join(sign#TypeList(), "\n")
endfunction

function! Sign_CompleteTypeFile(L, C, P)
    return Sign_CompleteFile(a:L, a:C, a:P).
                \ "\n|\n".
                \ Sign_CompleteType(a:L, a:C, a:P)
endfunction

" AutoCmd for VimEnter event
" Load sign when starting with a file
function s:VimEnterEvent()
    " Stop load twice when signs already exists
    " Occurs after loading the project
    if get(g:, 'Sign_signSetFlag', 0)
        return
    endif

    let l:file = expand('%')
    if filereadable('.signrecord') && !empty(l:file) &&
                \ !empty(systemlist('grep '.l:file.' .signrecord'))
        call sign#Load()
    endif
endfunction

" AutoCmd for VimLeave event
" For saving | updating signFile
" And save workspace when set g:Sign_projectized
function s:VimLeaveEvent()
    if get(g:, 'Sign_signSetFlag', 0)
        call sign#Save()
    endif

    if get(g:, 'Sign_projectized', 0)
        call sign#WorkSpaceSave()
    endif
endfunction


