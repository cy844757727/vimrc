""""""""""""""""""""""""""""""""""""""""""""""""""""
" Author: CY <844757727@qq.com>
" Description: Miscellaneous function
""""""""""""""""""""""""""""""""""""""""""""""""""""
if exists('loaded_A_Misc')
  finish
endif
let loaded_A_Misc = 1

"	编译运行
function! misc#CompileRun()
    wall
    if &filetype == 'nerdtree'
        silent call nerdtree#ui_glue#invokeKeyMap('R')
        echo 'Refresh Done!'
    elseif &filetype =~ '^git\(log\|commit\|status\|branch\)$'
        silent call git#Refresh()
    elseif &filetype =~ '^\(sh\|python\|perl\|tcl\)$' && getline(1) =~ '^#!'
        let l:winid = -1
        let l:cmd = split(getline(1), '/')[-1]
        if !filereadable('.breakpoint')
            let l:winid = win_getid()
            let l:cmd .= " './" . expand('%') . "'\n"
        elseif l:cmd =~ '^bash'
            let l:cmd = "bashdb -x .breakpoint './" . expand('%') . "'\n"
        elseif &filetype == 'python'
            let l:cmd .= " -m pdb './" . expand('%') . "'\n" .
                        \ join(readfile('.breakpoint'), "\n") .
                        \ "\nbreak\n"
        elseif &filetype == 'perl'
            let l:cmd .= " -d './" . expand('%') . "'\n" .
                        \ "= break b\n" .
                        \ join(map(readfile('.breakpoint'), "substitute(v:val,'\\S\\+:','','')"), "\n") .
                        \ "\n=\n"
            "            "= break b\nsource .breakpoint\n" other way but not
            "            work, confused
            "            ====================================================
        else
            let l:winid = win_getid()
            let l:cmd .= " './" . expand('%') . "'\n"
        endif
        let l:bufnr = bufnr('!bash')
        if l:bufnr == -1
            belowright terminal ++kill=kill ++close ++rows=15 bash
            let l:bufnr = bufnr('!bash')
        elseif bufwinnr('!bash') == -1
            belowright 15new | exec l:bufnr . 'buffer'
        endif
        call term_sendkeys(l:bufnr, l:cmd)
        call win_gotoid(l:winid)
    elseif filereadable('makefile') || filereadable('Makefile')
        AsyncRun make
    elseif &filetype == 'c'
        AsyncRun gcc -Wall -O0 -g3 % -o binFile
    elseif &filetype == 'cpp'
        AsyncRun g++ -Wall -O0 -g3 % -o binFile
    elseif &filetype == 'verilog'
        if isdirectory('work')
            AsyncRun vlog -work work %
        else
            AsyncRun vlib work && vmap work work && vlog -work work %
        endif
    endif
endfunction

function! misc#Debug(target)
    if !exists(':Termdebug')
        packadd termdebug
    endif
    if a:target == '%'
        let l:target = expand('%')
    else
        let l:target = a:target
    endif
    tabnew
    if filereadable('.breakpoint')
        exec 'Termdebug -x .breakpoint ' . l:target
    else
        exec 'Termdebug ' . l:target
    endif
    autocmd BufUnload <buffer> 1close
endfunction

"	转换鼠标范围（a，v）
function! misc#CutMouseBehavior()
    if &mouse == 'a'
        set nonumber
        set mouse=v
    else
        set number
        set mouse=a
    endif
endfunction

"	指定范围代码格式化
function! misc#CodeFormat() range
    let l:range = a:firstline . ',' . a:lastline
    if &filetype =~ '^c\|cpp$'
        silent! exec l:range . 's/\(\w\|)\|\]\)\s*\([-+=*/%><|&:!?^][-+=/><|&:]\?=\?\)\s*/\1 \2 /ge'
        silent! exec l:range . 's/\s*\(++\|--\|::\)\s*/\1/ge'
        silent! exec l:range . 's/\s*\(<\)\s*\(.\+\w\+\)\s*\(>\)\s*/ \1\2\3 /ge'
        silent! exec l:range . 's/\((\)\s*\|\s*\()\)/\1\2/ge'
        silent! exec l:range . 's/\(,\|;\)\s*\(\w\)/\1 \2/ge'
        silent! exec l:range . 's/\(\s*\n*\s*\)*{/ {/ge'
        normal ==
    elseif &filetype == 'matlab'
        silent! exec l:range . 's/\(\w\|)\)\s*\(\.\?[-+=*/><~|&^][=&|]\?\)\s*/\1 \2 /ge'
        silent! exec l:range . 's/\((\)\s*\|\s*\()\)/\1\2/ge'
        silent! exec l:range . 's/\(;\)\s*\(\w\)/\1 \2/ge'
        normal ==
    elseif &filetype == 'make'
        silent! exec l:range . 's/\(\w\)\s*\(+=\|=\|:=\)\s*/\1 \2 /ge'
        silent! exec l:range . 's/\(:\)\s*\(\w\|\$\)/\1 \2/ge'
        normal ==
    elseif &filetype == 'python'
        silent! exec l:range . 's/\(\w\|)\|\]\|}\)\s*\([-+=*/%><|&~!^][=*/><]\?=\?\)\s*/\1 \2 /ge'
        silent! exec l:range . 's/\((\|\[\|{\)\s*\|\s*\()\|\]\|}\)/\1\2/ge'
        silent! exec l:range . 's/\(,\|;\)\s*\(\w\)/\1 \2/ge'
        normal ==
    elseif &filetype =~ '^verilog\|systemverilog$'
        silent! exec l:range . 's/\(\w\|)\|\]\)\s*\([-+=*/%><|&!?~^][=><|&~]\?\)\s*/\1 \2 /ge'
        silent! exec l:range . 's/\((\)\s*\|\s*\()\)/\1\2/ge'
        silent! exec l:range . 's/\(,\|;\)\s*\(\w\)/\1 \2/ge'
    endif
    silent! /`!`!`!`!`@#$%^&
endfunction

"   切换注释状态
function! misc#ReverseComment() range
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
    silent exec a:firstline . ',' . a:lastline . 's+^+' . l:char . '+e'
    silent exec a:firstline . ',' . a:lastline . 's+^' . l:char . l:char . '++e'
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

" 字符串查找替换
function! misc#StrSubstitute(str)
    let l:subs=input('Replace ' . "\"" . a:str . "\"" . ' with: ')
    if l:subs != ''
        let l:pos = getpos('.')
        exec '%s/' . a:str . '/' . l:subs . '/Ig'
        call setpos('.', l:pos)
    endif
endfunction

" 文件保存及后期处理
function! misc#SaveFile(file)
    if empty(a:file)
        exec 'file ' . input('Set file name: ')
        filetype detect
        write
        call misc#UpdateNERTreeView()
    elseif exists('s:DoubleClick_500MSTimer')
        wall
        echo 'Save all'
    else
        if !filereadable(a:file)
            write
            call misc#UpdateNERTreeView()
        elseif match(execute('ls %'), '+') != -1
            write
        endif
        let s:DoubleClick_500MSTimer = 1
        let l:id = timer_start(500, 'misc#TimerHandle500MS')
    endif
endfunction
" ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑
function! misc#TimerHandle500MS(id)
    unlet s:DoubleClick_500MSTimer
endfunction

" 切换16进制显示
function! misc#HEXCovent()
    if empty(matchstr(getline(1), '^00000000: \S'))
        :%!xxd
        let b:ale_enabled = 0
    else
        :%!xxd -r
        let b:ale_enabled = 1
    endif
endfunction

" ############### 窗口相关 ######################################
" 最大化窗口/恢复
function! misc#WinResize()
    if exists('t:MAXMIZEWIN')
        let l:winnr = win_id2win(t:MAXMIZEWIN[2])
        exec l:winnr . 'resize ' . t:MAXMIZEWIN[0]
        exec 'vert ' . l:winnr . 'resize ' . t:MAXMIZEWIN[1]
        if t:MAXMIZEWIN[2] == win_getid()
            unlet t:MAXMIZEWIN
            return
        endif
    endif
    let t:MAXMIZEWIN = [winheight(0), winwidth(0), win_getid()]
    exec 'resize ' . max([float2nr(0.8 * &lines), t:MAXMIZEWIN[0]])
    exec 'vert resize ' . max([float2nr(0.8 * &columns), t:MAXMIZEWIN[1]])
endfunction

"  切换嵌入式终端
function! misc#ToggleEmbeddedTerminal()
    if !bufexists('!bash')
        belowright terminal ++kill=kill ++close ++rows=15 bash
    elseif bufwinnr('!bash') == -1
        belowright 15new | silent exec bufnr('!bash') . 'buffer'
    else
        exec bufwinnr('!bash') . 'hide'
    endif
endfunction

"  切换NERDTree窗口
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

"  切换TagBar窗口
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

"  切换QuickFix窗口
function! misc#ToggleQuickFix(...)
    if a:0 > 0
        if a:1 == 'book'
            call setqflist([], 'r', {'title': 'BookMark', 'items': BMBPSign#GetList('book')})
        elseif a:1 == 'break'
            call setqflist([], 'r', {'title': 'BreakPoint', 'items': BMBPSign#GetList('break')})
        elseif a:1 == 'ale'
            if &filetype == 'qf'
                wincmd W
            endif
            call setqflist([], 'r', {'title': 'ale: syntax check', 'items': ale#engine#GetLoclist(bufnr('%'))})
        endif
        copen 10
    elseif match(split(execute('tabs'), 'Tab \S\+ \d\+')[tabpagenr()], '\[Quickfix \S\+\]') == -1
        copen 10
    else
        cclose
    endif
endfunction
"#####################################################################


