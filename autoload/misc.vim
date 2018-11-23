""""""""""""""""""""""""""""""""""""""""""""""""""""
" Author: CY <844757727@qq.com>
" Description: Miscellaneous function
""""""""""""""""""""""""""""""""""""""""""""""""""""
if exists('loaded_A_Misc')
  finish
endif
let loaded_A_Misc = 1
let s:tempPath = '/tmp/'

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
        let l:breakpoint = BMBPSign#SignRecord('break tbreak')

        if empty(l:breakpoint)
            let l:cmd .= ' ' . expand('%') . "\n"
        elseif l:cmd =~ '^bash'
            call writefile(l:breakpoint, s:tempPath . '.breakpoint')
            let l:cmd = 'bashdb -x ' . s:tempPath . '.breakpoint ' . expand('%') . "\n"
        elseif &filetype == 'python'
            let l:pdb = executable('ipdb') ? ' -m ipdb ' : ' -m pdb '
            let l:cmd .= l:pdb . expand('%') . "\n" . join(l:breakpoint, ";;") . "\n"
        elseif &filetype == 'perl'
            let l:cmd .= ' -d ' . expand('%') . "\n" .
                        \ "= break b\n" .
                        \ join(map(l:breakpoint, "substitute(v:val,'\\S\\+:','','')"), "\n") .
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
    tabnew
    let l:breakpoint = BMBPSign#SignRecord('break tbreak')
    if !empty(l:breakpoint)
        call writefile(l:breakpoint, s:tempPath . '.breakpoint')
        exe 'Termdebug -x ' . s:tempPath . '.breakpoint ' . l:target
    else
        exe 'Termdebug ' . l:target
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
    let l:pos = getpos('.')
    mark z

    " Custom formatting
    if &filetype =~ '^verilog\|systemverilog$'
        silent! exe l:range . 's/\(\w\|)\|\]\)\s*\([-+=*/%><|&!?~^][=><|&~]\?\)\s*/\1 \2 /ge'
        silent! exe l:range . 's/\((\)\s*\|\s*\()\)/\1\2/ge'
        silent! exe l:range . 's/\(,\|;\)\s*\(\w\)/\1 \2/ge'
        silent! /`!`!`!`!`@#$%^&
        let l:formatCmd = ''
    elseif &filetype == 'make'
        silent! exe l:range . 's/\(\w\)\s*\(+=\|=\|:=\)\s*/\1 \2 /ge'
        silent! exe l:range . 's/\(:\)\s*\(\w\|\$\)/\1 \2/ge'
        silent! /`!`!`!`!`@#$%^&
        let l:formatCmd = 'normal =='
    endif

    " Use external tools & Config cmd 
    " Tools: clang-format, autopep8, perltidy, shfmt
    if &filetype =~ '^\(c\|cpp\|java\|javascript\)$' && executable('clang-format-7')
        let l:formatCmd = "!clang-format-7 -style='{IndentWidth: 4}'"
    elseif &filetype == 'python' && executable('yapf') && executable('yapf3')
        let l:formatCmd = getline(1) =~ 'python3' ? '!yapf3' : '!yapf'
    elseif &filetype == 'perl' && executable('perltidy')
        let l:formatCmd = '!perltidy'
    elseif &filetype == 'sh' && executable('shfmt')
        let l:formatCmd = '!shfmt -s -i 4'
    elseif &filetype != ''
        let l:formatCmd = 'normal =='
    else
        return
    endif

    " Format code
    exe l:range . l:formatCmd
    call setpos('.', l:pos)
    write
endfunction

" comment char
let s:commentChar = {
            \ 'c': '//', 'cpp': '//', 'java': '//', 'verilog': '//', 'systemverilog': '//',
            \ 'javascript': '//', 'go': '//', 'scala': '//', 'php': '//',
            \ 'sh': '#', 'python': '#', 'tcl': '#', 'perl': '#', 'make': '#', 'maple': '#',
            \ 'awk': '#', 'ruby': '#', 'r': '#', 'python3': '#',
            \ 'tex': '%', 'latex': '%', 'postscript': '%', 'matlab': '%',
            \ 'vhdl': '--', 'haskell': '--', 'lua': '--', 'sql': '--', 'openscript': '--',
            \ 'ada': '--',
            \ 'lisp': ';', 'scheme': ';',
            \ 'vim': "\""
            \ }

"  Toggle comment
function! misc#ReverseComment() range
    try
        let l:char = s:commentChar[&filetype]
    catch
        return
    endtry

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

" For Handling situations without suffixes
" WebDevIcons plugin
function! misc#GetWebIcon(...)
    if a:0 == 0
        let l:file = expand('%')
        let l:tfile = expand('%:t')
        let l:extend = expand('%:e')
    else
        let l:file = a:1
        let l:tfile = fnamemodify(a:1, ':t')
        let l:extend = fnamemodify(a:1, ':e')
    endif

    if empty(l:extend) && l:tfile !~ '^\.' && bufexists(l:file)
        let l:tfile .= '.' . getbufvar(l:file, '&filetype')
    endif

    return WebDevIconsGetFileTypeSymbol(l:tfile)
endfunction
" ############### 窗口相关 ######################################
" 最大化窗口/恢复
function! misc#WinResize()
    if exists('t:MAXMIZEWIN')
        let l:winnr = win_id2win(t:MAXMIZEWIN[2])
        exe l:winnr . 'resize ' . t:MAXMIZEWIN[0]
        exe 'vert ' . l:winnr . 'resize ' . t:MAXMIZEWIN[1]
        if t:MAXMIZEWIN[2] == win_getid()
            unlet t:MAXMIZEWIN
            return
        endif
    endif
    let t:MAXMIZEWIN = [winheight(0), winwidth(0), win_getid()]
    exe 'resize ' . max([float2nr(0.8 * &lines), t:MAXMIZEWIN[0]])
    exe 'vert resize ' . max([float2nr(0.8 * &columns), t:MAXMIZEWIN[1]])
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
            exe l:winnr . 'hide'
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
        exe bufwinnr('NERD_tree') . 'wincmd w'
        TagbarOpen
        call win_gotoid(l:id)
    endif
endfunction

"  Toggle QuickFix window
"  BMBPSign#SetQfList(type, title)
function! misc#ToggleQuickFix(...)
    let l:type = a:0 == 0 ? 'self' : a:1
    if l:type == 'book'
        call BMBPSign#SetQfList('book', 'BookMark')
    elseif l:type == 'break'
        call BMBPSign#SetQfList('break tbreak', 'BreakPoint')
    elseif l:type == 'todo'
        call BMBPSign#SetQfList('todo', 'TodoList')
    elseif match(split(execute('tabs'), 'Tab \S\+ \d\+')[tabpagenr()], '\[Quickfix \S\+\]') != -1
        cclose
        return
    endif
    copen 10
    set nowrap
endfunction
" ####################################################################

