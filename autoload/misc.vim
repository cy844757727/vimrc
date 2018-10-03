"
if exists('loaded_A_Misc')
  finish
endif
let loaded_A_Misc = 1

"	编译运行: F5
function! misc#CompileRun()
    wall
    if &filetype == 'nerdtree'
        silent call nerdtree#ui_glue#invokeKeyMap('R')
        echo 'Refresh Done!'
    elseif &filetype =~ '^git\(log\|commit\|status\|branch\)$'
        silent call git#Refresh()
    elseif filereadable('makefile') || filereadable('Makefile')
        AsyncRun make
    elseif &filetype =~ '^c\|cpp$'
        AsyncRun g++ -Wall -O0 -g3 % -o binFile
    elseif &filetype == 'verilog'
        if isdirectory('work')
            exec 'AsyncRun vlog -work work %'
        else
            exec 'AsyncRun vlib work && vmap work work && vlog -work work %'
        endif
    elseif &filetype == 'sh'
        if filereadable('.breakpoint')
            exec 'SShell bash -x ' . expand('%:p')
        else
            exec 'SShell bash -c ' . expand('%:p')
        endif
    endif
endfunction

"	转换鼠标范围（a，v）: \c
function! misc#CutMouseBehavior()
    if &mouse == 'a'
        set nonumber
        set mouse=v
    else
        set number
        set mouse=a
    endif
endfunction

"	指定范围代码格式化: CFormat
function! misc#CodeFormat()
    if &filetype =~ '^c\|cpp$'
        silent! s/\(\w\|)\|\]\)\s*\([-+=*/%><|&:!?^][-+=/><|&:]\?=\?\)\s*/\1 \2 /ge
        silent! s/\s*\(++\|--\|::\)\s*/\1/ge
        silent! s/\s*\(<\)\s*\(.\+\w\+\)\s*\(>\)\s*/ \1\2\3 /ge
        silent! s/\((\)\s*\|\s*\()\)/\1\2/ge
        silent! s/\(,\|;\)\s*\(\w\)/\1 \2/ge
        silent! s/\(\s*\n*\s*\)*{/ {/ge
        silent! s/\(\s*\n\+\)\{3,}/\="\n\n"/ge
        normal ==
    elseif &filetype == 'matlab'
        silent! s/\(\w\|)\)\s*\(\.\?[-+=*/><~|&^][=&|]\?\)\s*/\1 \2 /ge
        silent! s/\((\)\s*\|\s*\()\)/\1\2/ge
        silent! s/\(;\)\s*\(\w\)/\1 \2/ge
        silent! s/\(\s*\n\+\)\{3,}/\="\n\n"/ge
        normal ==
    elseif &filetype == 'make'
        silent! s/\(\w\)\s*\(+=\|=\|:=\)\s*/\1 \2 /ge
        silent! s/\(:\)\s*\(\w\|\$\)/\1 \2/ge
        silent! s/\(\s*\n\+\)\{3,}/\="\n\n"/ge
        normal ==
    elseif &filetype == 'python'
        silent! s/\(\w\|)\|\]\|}\)\s*\([-+=*/%><|&~!^][=*/><]\?=\?\)\s*/\1 \2 /ge
        silent! s/\((\|\[\|{\)\s*\|\s*\()\|\]\|}\)/\1\2/ge
        silent! s/\(,\|;\)\s*\(\w\)/\1 \2/ge
        silent! s/\(\s*\n\+\)\{3,}/\="\n\n"/ge
        normal ==
    elseif &filetype =~ '^verilog\|systemverilog$'
        silent! s/\(\w\|)\|\]\)\s*\([-+=*/%><|&!?~^][=><|&~]\?\)\s*/\1 \2 /ge
        silent! s/\((\)\s*\|\s*\()\)/\1\2/ge
        silent! s/\(,\|;\)\s*\(\w\)/\1 \2/ge
        silent! s/\(\s*\n\+\)\{3,}/\="\n\n"/ge
    endif
    silent! /`!`!`!`!`@#$%^&
endfunction

"   切换注释状态: \q
function! misc#ReverseComment()
    if &filetype =~ '^c\|cpp\|verilog\|systemverilog$'
        let l:char='//'
    elseif &filetype == 'matlab'
        let l:char='%'
    elseif &filetype =~ '^sh\|make\|python$'
        let l:char='#'
    elseif &filetype == 'vim'
        let l:char="\""
    else
        return
    endif
    exec 's+^+' . l:char . '+e'
    exec 's+^' . l:char . l:char . '++e'
endfunction

"  刷新目录树
function! misc#UpdateNERTreeView()
    let l:nrOfNerd_tree=bufwinnr('NERD_tree')
    if l:nrOfNerd_tree != -1
        let l:id=win_getid()
        exec l:nrOfNerd_tree . 'wincmd w'
        silent call nerdtree#ui_glue#invokeKeyMap('R')
        call win_gotoid(l:id)
    endif
endfunction

" 字符串查找替换: ctrl+h
function! misc#StrSubstitute(str)
    let l:pos = getpos('.')
    let l:subs=input('Replace ' . "\"" . a:str . "\"" . ' with: ')
    if l:subs != ''
        exec '%s/' . a:str . '/' . l:subs . '/Ig'
        call setpos('.', l:pos)
    endif
endfunction

" 文件保存及后期处理: F3
function! misc#SaveFile(file)
    if exists('g:DoubleClick_500MSTimer')
        wall
        echo 'Save all'
    elseif filereadable(a:file)
        let g:DoubleClick_500MSTimer = 1
        let l:id = timer_start(500, 'misc#TimerHandle500MS')
        write
    elseif empty(a:file)
        exec 'file ' . input('Set file name')
        filetype detect
        write
        call misc#UpdateNERTreeView()
    else
        write
    endif
endfunction

function! misc#TimerHandle500MS(id)
    unlet g:DoubleClick_500MSTimer
endfunction

" 切换16进制显示: \h
function! misc#HEXCovent()
    if empty(matchstr(getline(1), '^00000000: \S'))
        :%!xxd
        let b:ale_enabled = 0
    else
        :%!xxd -r
        let b:ale_enabled = 1
    endif
endfunction

" 最大化窗口/恢复：f4
function! misc#WinResize()
    let l:winId = win_getid()
    if !exists('g:MAXMIZEWIN')
        let g:MAXMIZEWIN = [winheight(0), winwidth(0), l:winId]
        exec 'resize ' . max([float2nr(0.8 * &lines), g:MAXMIZEWIN[0]])
        exec 'vert resize ' . max([float2nr(0.8 * &columns), g:MAXMIZEWIN[1]])
    elseif g:MAXMIZEWIN[2] == l:winId
        exec 'resize ' . g:MAXMIZEWIN[0]
        exec 'vert resize ' . g:MAXMIZEWIN[1]
        unlet g:MAXMIZEWIN
    else
        if win_gotoid(g:MAXMIZEWIN[2]) == 1
            exec 'resize ' . g:MAXMIZEWIN[0]
            exec 'vert resize ' . g:MAXMIZEWIN[1]
            call win_gotoid(l:winId)
        endif
        let g:MAXMIZEWIN = [winheight(0), winwidth(0), l:winId]
        exec 'resize ' . max([float2nr(0.8 * &lines), g:MAXMIZEWIN[0]])
        exec 'vert resize ' . max([float2nr(0.8 * &columns), g:MAXMIZEWIN[1]])
    endif
endfunction

" ############### 窗口相关 ######################################
"  切换NERDTree窗口: F9
function! misc#ToggleNERDTree()
    if bufwinnr('NERD_tree') != -1
        NERDTreeClose
    elseif bufwinnr('Tagbar') != -1
        TagbarClose
        NERDTree
        TagbarOpen
    else
        NERDTree
    endif
endfunction

"  切换TagBar窗口: F8
function! misc#ToggleTagbar()
    let l:id=win_getid()
    if bufwinnr('Tagbar') != -1
        TagbarClose
    elseif bufwinnr('NERD_tree') == -1
        let g:tagbar_vertical=0
        let g:tagbar_left=1
        TagbarOpen
        let g:tagbar_vertical=19
        let g:tagbar_left=0
        call win_gotoid(l:id)
    else
        exec bufwinnr('NERD_tree') . 'wincmd w'
        TagbarOpen
        call win_gotoid(l:id)
    endif
endfunction

"  切换QuickFix窗口: F10
function! misc#ToggleQuickFix()
    let l:id=win_getid()
    exec tabpagewinnr(tabpagenr(),'$') . 'wincmd w'
    if &ft == 'qf'
        cclose
    else
        copen 10
        call win_gotoid(l:id)
    endif
endfunction
"#####################################################################

