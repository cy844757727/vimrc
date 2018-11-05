""""""""""""""""""""""""""""""""""""""""""""""""""""
" Author: CY <844757727@qq.com>
" Description: Miscellaneous function
""""""""""""""""""""""""""""""""""""""""""""""""""""
if exists('loaded_A_Misc')
  finish
endif
let loaded_A_Misc = 1

"	Compile c/cpp/verilog, Run script language ...
function! misc#CompileRun()
    wall
    if &filetype == 'nerdtree'
        silent call nerdtree#ui_glue#invokeKeyMap('R')
        echo 'Nerdtree: Refresh done!'
    elseif &filetype == 'tagbar'
        " Refresh tags file, " Tool: ctags
        call job_start("ctags -R -f .tags", {'in_io': 'null', 'out_io': 'null', 'err_io': 'null'})
        echo 'Tagbar: Refresh Done (.tags file)!'
    elseif &filetype =~ '^git\(log\|commit\|status\|branch\)$'
        silent call git#Refresh()
    elseif &filetype =~ '^\(sh\|python\|perl\|tcl\)$' && getline(1) =~ '^#!'
        " script language
        let l:cmd = matchstr(getline(1), '\(/\(env\s\+\)\?\)\zs[^/]*$')
        if !filereadable('.breakpoint')
            let l:cmd .= ' ' . expand('%') . "\n"
        elseif l:cmd =~ '^bash'
            let l:cmd = 'bashdb -x .breakpoint ' . expand('%') . "\n"
        elseif &filetype == 'python'
            let l:pdb = executable('ipdb') ? ' -m ipdb ' : ' -m pdb '
            let l:cmd .= l:pdb . expand('%') . "\n" .
                        \ join(readfile('.breakpoint'), ";;") . "\n"
        elseif &filetype == 'perl'
            let l:cmd .= ' -d ' . expand('%') . "\n" .
                        \ "= break b\n" .
                        \ join(map(readfile('.breakpoint'), "substitute(v:val,'\\S\\+:','','')"), "\n") .
                        \ "\n=\n"
            "            "= break b\nsource .breakpoint\n" other way but not
            "            work, confused
            "            ====================================================
        else
            let l:cmd .= ' ' . expand('%') . "\n"
        endi

        " Display & switch to terminal & run/debug
        let l:bufnr = misc#ToggleEmbeddedTerminal('on')
        call term_sendkeys(l:bufnr, "clear\n" . l:cmd)
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

" Specified range code formatting
function! misc#CodeFormat() range
    " Determine range
    let l:range = a:firstline == a:lastline ? '%' : a:firstline . ',' . a:lastline

    " Custom formatting
    if &filetype =~ '^verilog\|systemverilog$'
        silent! exe l:range . 's/\(\w\|)\|\]\)\s*\([-+=*/%><|&!?~^][=><|&~]\?\)\s*/\1 \2 /ge'
        silent! exe l:range . 's/\((\)\s*\|\s*\()\)/\1\2/ge'
        silent! exe l:range . 's/\(,\|;\)\s*\(\w\)/\1 \2/ge'
        silent! /`!`!`!`!`@#$%^&
        return
    elseif &filetype == 'make'
        silent! exe l:range . 's/\(\w\)\s*\(+=\|=\|:=\)\s*/\1 \2 /ge'
        silent! exe l:range . 's/\(:\)\s*\(\w\|\$\)/\1 \2/ge'
        silent! /`!`!`!`!`@#$%^&
        normal ==
        return
    endif

    " Use external tools & Config cmd 
    " Tools: clang-format, autopep8, perltidy, shfmt
    if &filetype =~ '^\(c\|cpp\|java\|javascript\)$'
        let l:formatCmd = "!clang-format-7 -style='{IndentWidth: 4}'"
    elseif &filetype == 'python'
        let l:formatCmd = getline(1) =~ 'python3' ? '!yapf3' : '!yapf'
    elseif &filetype == 'perl'
        let l:formatCmd = '!perltidy'
    elseif &filetype == 'sh'
        let l:formatCmd = '!shfmt -s -i 4'
    elseif &filetype != '' 
        normal ==
        return
    else
        return
    endif

    " Format code
    let l:pos = getpos('.')
    mark z
    exe l:range . l:formatCmd
    call setpos('.', l:pos)
    write
endfunction

"  Toggle comment
function! misc#ReverseComment() range
    " Comment char
    if &filetype =~ '^\(c\|cpp\|java\|javascript\|php\|verilog\|systemverilog\)$'
        let l:char='//'
    elseif &filetype == 'matlab'
        let l:char='%'
    elseif &filetype == 'vhdl'
        let l:char='--'
    elseif &filetype =~ '^\(sh\|make\|python\|perl\|tcl\)$'
        let l:char='#'
    elseif &filetype == 'vim'
        let l:char="\""
    else
        return
    endif

    " Processing
    silent exe a:firstline . ',' . a:lastline . 's+^+' . l:char . '+e'
    silent exe a:firstline . ',' . a:lastline . 's+^' . l:char . l:char . '++e'
endfunction

"  Refresh NERTree
function! misc#UpdateNERTreeView()
    let l:nrOfNerd_tree=bufwinnr('NERD_tree')
    if l:nrOfNerd_tree != -1
        let l:id=win_getid()
        exe l:nrOfNerd_tree . 'wincmd w'
        silent call nerdtree#ui_glue#invokeKeyMap('R')
        call win_gotoid(l:id)
    endif
endfunction

" 字符串查找替换
function! misc#StrSubstitute(str)
    let l:subs=input('Replace ' . "\"" . a:str . "\"" . ' with: ')
    if l:subs != ''
        let l:pos = getpos('.')
        exe '%s/' . a:str . '/' . l:subs . '/Ig'
        call setpos('.', l:pos)
    endif
endfunction

" File save
function! misc#SaveFile()
    let l:file = expand('%')
    if !empty(&buftype)
        return
    elseif empty(l:file)
        exe 'file ' . input('Set file name: ')
        filetype detect
        write
        call misc#UpdateNERTreeView()
    elseif exists('s:DoubleClick_500MSTimer')
        wall
        echo 'Save all'
    else
        if !filereadable(l:file)
            write
            call misc#UpdateNERTreeView()
        else
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

" Switch embedded terminal (action: on/off/toggle)
function! misc#ToggleEmbeddedTerminal(...)
    let l:action = a:0 == 0 ? 'toggle' : a:1
    let l:winnr = bufwinnr('!bash')
    let l:bufnr = bufnr('!bash')

    if l:winnr != -1
        if l:action == 'on'
            exe l:winnr . 'wincmd w'
        else
            exec l:winnr . 'hide'
        endif
    elseif l:action =~ 'on\|toggle'
        if l:bufnr == -1
            belowright terminal ++kill=kill ++close ++rows=15 bash
            let l:bufnr = bufnr('%')
        else
            belowright 15new | silent exe l:bufnr . 'buffer'
        endif
    endif

    return l:bufnr
endfunction

" Toggle NERDTree window
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

"  Toggle TagBar window
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

"  Toggle QuickFix window
function! misc#ToggleQuickFix(...)
    let l:type = a:0 == 0 ? 'self' : a:1
    if l:type == 'book'
        call setqflist([], 'r', {'title': 'BookMark', 'items': BMBPSign#GetList('book')})
    elseif l:type == 'break'
        call setqflist([], 'r', {'title': 'BreakPoint', 'items': BMBPSign#GetList('break')})
    elseif match(split(execute('tabs'), 'Tab \S\+ \d\+')[tabpagenr()], '\[Quickfix \S\+\]') != -1
        cclose
        return
    endif
    copen 10
endfunction
" ####################################################################


