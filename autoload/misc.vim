""""""""""""""""""""""""""""""""""""""""""""""""""""
" Author: CY <844757727@qq.com>
" Description: Miscellaneous function
""""""""""""""""""""""""""""""""""""""""""""""""""""
if exists('g:loaded_A_Misc')
  finish
endif
let g:loaded_A_Misc = 1


"	Compile c/cpp/verilog, Run script language ...
function! misc#CompileRun(...)
    wall
    if &filetype == 'nerdtree'
        silent call nerdtree#ui_glue#invokeKeyMap('R')
        echo 'Nerdtree: Refresh done!'
    elseif &filetype == 'tagbar'
        " Refresh tags file, " Tool: ctags
        Async ctags -R -f .tags
        echo 'Tagbar: Refresh Done (.tags file)!'
    elseif &filetype =~ '^git\(log\|commit\|status\|branch\)$'
        silent call git#Refresh()
    elseif &filetype == 'verilog'
        if isdirectory('work')
            AsyncRun vlog -work work %
        else
            AsyncRun vlib work && vmap work work && vlog -work work %
        endif
    else
        let l:breakPoint = BMBPSign#SignRecord('break', 'tbreak')
        let l:runMode = (empty(l:breakPoint) && a:0 == 0) || (!empty(l:breakPoint) && a:0 > 0)

        if &ft == 'make' || ((filereadable('makefile') || filereadable('Makefile')) && &ft =~ 'c\|cpp')
            if l:runMode
                AsyncRun make
            else
                let l:binFile = filter(glob('*', '', 1), "!isdirectory(v:val) && getfperm(v:val) =~ 'x'")
                if len(l:binFile) == 1
                    call async#GdbStart(l:binFile[0], l:BreakPoint)
                endif
            endif
        elseif &filetype =~ '^\(sh\|python\|perl\|tcl\|ruby\|awk\)$'
            " script language
            if l:runMode
                call async#RunScript(expand('%'))
            else
                call async#DbgScript(expand('%'), l:breakPoint)
            endif
        elseif &filetype =~ 'c\|cpp'
            if l:runMode
                AsyncRun g++ -Wall -O0 -g3 % -o binFile
            else
                call async#GdbStart('binFile', l:BreakPoint)
            endif
        endif
    endif
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
    endif

    " Format code
    if exists('l:formatCmd')
        exe l:range . l:formatCmd
    endif

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


function! misc#StatuslineIcon()
    if bufname('%') =~ '^!'
        return ''
    elseif BMBPSign_Status()
        return ''
    else
        return ''
    endif
endfunction


" Customize tabline
function! misc#TabLine()
    let s = ''
    for i in range(tabpagenr('$'))
        " select the highlighting
        if i + 1 == tabpagenr()
            let s .= '%#TabLineSel#'
        else
            let s .= '%#TabLine#'
        endif

        " set the tab page number (for mouse clicks)
        let s .= '%' . (i + 1) . 'T'

        " the label is made by MyTabLabel()
        let s .= ' %{misc#TabLabel(' . (i + 1) . ')} '

        " Separator
        if i + 1 != tabpagenr() && i + 2 != tabpagenr() && i + 1 != tabpagenr('$')
            let s .= '%#TabLineSeparator#│'
        else
            let s .= ' '
        endif
    endfor

    " after the last tab fill with TabLineFill and reset tab page nr
    let s .= '%#TabLineFill#%T'

    " right-align the label to close the current tab page
    if tabpagenr('$') > 1
        let s .= '%=%#TabLine#%999X ✘ '
    endif

    return s
endfunction


function! misc#TabLabel(n)
    let l:buflist = tabpagebuflist(a:n)
    let l:winnr = tabpagewinnr(a:n) - 1
    " Extend buflist
    let l:buflist = l:buflist + l:buflist[0:l:winnr]

    " Display filename which buftype is empty
    while !empty(getbufvar(l:buflist[l:winnr], '&buftype')) && l:winnr < len(l:buflist) - 1
        let l:winnr += 1
    endwhile

    " Add a flag if current buf is modified
    if getbufvar(l:buflist[l:winnr], '&modified')
        let l:label = ''
    else
        let l:label = ' '
    endif

    " Append the buffer name
    let l:bufname = fnamemodify(bufname(l:buflist[l:winnr]), ':t')

    " Append the glyph
    if l:bufname =~ '^\.Git_'
        let l:bufname = 'Git-Manager'
        let l:glyph = ''
    elseif !empty(gettabvar(a:n, 'dbg', ''))
        let l:bufname = '-- Debug --'
        let l:glyph = ''
    else
        let l:glyph = misc#GetWebIcon(l:bufname)
    endif

    return l:glyph . ' ' . l:bufname . ' ' . l:label
endfunction


function! misc#FoldText()
    let l:str = getline(v:foldstart)
    let l:num = printf('%5d', v:foldend - v:foldstart + 1)
    return '▶' . l:num . ': ' . l:str . '  '
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
        call BMBPSign#SetQfList('BookMark', 'book')
    elseif l:type == 'break'
        call BMBPSign#SetQfList('BreakPoint', 'break', 'tbreak')
    elseif l:type == 'todo'
        call BMBPSign#SetQfList('TodoList', 'todo')
    elseif max(map(tabpagebuflist(), "getbufvar(v:val, '&ft') == 'qf'"))
        cclose
        return
    endif

    copen 10
    set nowrap
endfunction
" ####################################################################

