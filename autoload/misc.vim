""""""""""""""""""""""""""""""""""""""""""""""""""""
" Author: CY <844757727@qq.com>
" Description: Miscellaneous function
""""""""""""""""""""""""""""""""""""""""""""""""""""
"if exists('g:loaded_A_Misc')
"  finish
"endif
"let g:loaded_A_Misc = 1


augroup MISC_autocmd
    autocmd!
    " Auto record buf history for each window
    autocmd BufEnter *[^0-9] call misc#BufHisInAWindow()
augroup END

command Qa :call misc#VimExit()

function misc#VimExit()
    " Hide all terminal window in current tabpage
    while 1
        let l:winnr = bufwinnr('^!')
        if l:winnr != -1
            exe l:winnr . 'hide'
        else
            break
        endif
    endwhile
    qall
endfunction

" Update NerdTree, refresh tags file ...
" diffupdate in diffmode
" Compile c/cpp/verilog, Run  & debug script language ...
function! misc#F5FunctionKey(...)
    wall
    if &filetype == 'nerdtree'
        if a:0 > 0 && exists('t:RecordOfTree')
            " Recovery status of last closed
            call search('^/\S*/$')
            silent normal oX
            call misc#RecordOfNERDTree('.', t:RecordOfTree)
        else
            call g:NERDTreeKeyMap.Invoke('R')
        endif
    elseif &filetype == 'tagbar'
        Async ctags -R -f .tags
    elseif &filetype =~ '^git\(log\|commit\|status\|branch\)$'
        call git#Refresh()
    elseif &diff
        diffupdate
    elseif &filetype == 'verilog'
        if isdirectory('work')
            AsyncRun vlog -work work %
        else
            AsyncRun vlib work && vmap work work && vlog -work work %
        endif
    else
        " Compile, Run, Debug
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
    let l:char = get(s:commentChar, &filetype, '')

    " Processing
    if !empty(l:char)
        silent exe a:firstline . ',' . a:lastline . 's+^+' . l:char . '+e'
        silent exe a:firstline . ',' . a:lastline . 's+^' . l:char . l:char . '++e'
    endif
endfunction


"  Refresh NERTree
function! misc#UpdateNERTreeView()
    let l:nerd = bufwinnr('NERD_tree')
    if l:nerd != -1
        let l:id = win_getid()
        exe l:nerd . 'wincmd w'
        call b:NERDTree.root.refresh()
        call b:NERDTree.render()
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
            update
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
        return 'ﲵ'
    elseif &buftype == 'help'
        return ''
    elseif exists('g:BMBPSign_Projectized')
        return ''
    endif

    return ''
endfunction


let s:TabLineStart = 0
let s:TabLineChars = 500
" Customize tabline
function! misc#TabLine()
    let l:s = ''
    let l:cur = tabpagenr() - 1
    let l:num = tabpagenr('$')
    let l:tabList = map(range(l:num), "' '.misc#TabLabel(v:val+1).' '")
    let l:str = join(l:tabList)
    let l:width = &columns - 3

    if strdisplaywidth(l:str) > l:width
        let l:B = strchars(join(l:tabList[:l:cur])) - 1
        let l:A = l:B - strchars(l:tabList[l:cur]) + 1

        if  l:A < s:TabLineStart
            let s:TabLineStart = l:A
            let s:TabLineChars = l:width

            while strdisplaywidth(strcharpart(l:str, s:TabLineStart, s:TabLineChars)) > l:width
                let s:TabLineChars -= 1
            endwhile
        elseif strdisplaywidth(strcharpart(l:str, s:TabLineStart, l:B - s:TabLineStart + 1)) > l:width
            let s:TabLineStart = max([0, l:B - l:width + 1])
            let s:TabLineChars = l:width

            while strdisplaywidth(strcharpart(l:str, s:TabLineStart, s:TabLineChars)) > l:width
                let s:TabLineChars -= 1
                let s:TabLineStart += 1
            endwhile
        endif

        let l:endSpace = repeat(' ',
                    \ l:width - strdisplaywidth(strcharpart(l:str, s:TabLineStart, s:TabLineChars)))
    else
        let l:endSpace = ''
    endif

    for l:i in range(l:num)
        let l:chars = strchars(join(l:tabList[:l:i]))

        if s:TabLineStart >= l:chars
            continue
        endif

        " the label is made by misc#TabLabel()
        if empty(l:s)
            " The first lable
            let l:width = s:TabLineStart - l:chars + 1
            let l:lable = s:TabLineStart > 0 ? '<' : ' '
            let l:lable .= '%{misc#TabLabel('.(l:i+1).','.l:width.')} '
        elseif s:TabLineStart + s:TabLineChars == l:chars + 1
            " Encounter segmentation symbols (last tab)
            let l:lable = ' %{misc#TabLabel('.(l:i+1).')} ' . l:endSpace . '>'
            let l:last = 1
        elseif s:TabLineStart + s:TabLineChars == l:chars + 2
            " After segmentation symbols (last tab)
            let l:lable = ' %{misc#TabLabel('.(l:i+1).')} '
            let l:lable .= '%#TabLineSeparator#│' . l:endSpace . '%#TabLine#>'
            let l:last = 1
        elseif s:TabLineStart + s:TabLineChars == l:chars
            let l:lable = ' %{misc#TabLabel('.(l:i+1).')}' . l:endSpace
            let l:lable .= l:i != l:num - 1 ? '>' : ' '
            let l:last = 1
        elseif s:TabLineStart + s:TabLineChars < l:chars
            let l:width = strchars(l:tabList[l:i]) - l:chars + s:TabLineStart + s:TabLineChars - 2
            let l:lable = ' %{misc#TabLabel('.(l:i+1).','.l:width.')}' . l:endSpace
            let l:lable .=  '>'
            let l:last = 1
        else
            let l:lable = ' %{misc#TabLabel('.(l:i+1).')} '
        endif

        " select the highlighting & tab page number (for mouse clicks)
        let l:s .= l:i == l:cur ? '%#TabLineSel#' : '%#TabLine#'
        let l:s .= '%' . (l:i + 1) . 'T' . l:lable

        " Separator symbols
        if !exists('l:last') && l:i != l:num - 1
            let l:s .= l:i != l:cur && l:i + 1 != l:cur ? '%#TabLineSeparator#│' : ' '
        else
            break
        endif
    endfor

    " after the last tab fill with TabLineFill and reset tab page nr
    let l:s .= '%#TabLineFill#%T'

    " right-align the label to close the current tab page
    if tabpagenr('$') > 1
        let l:s .= '%=%#TabLine#%999X ✘ '
    endif

    return l:s
endfunction


function! misc#TabLabel(n, ...)
    let l:buflist = tabpagebuflist(a:n)
    let l:winnr = tabpagewinnr(a:n) - 1
    " Extend buflist
    let l:buflist = l:buflist + l:buflist[0:l:winnr]

    " Display filename which buftype is empty
    while !empty(getbufvar(l:buflist[l:winnr], '&buftype')) && l:winnr < len(l:buflist) - 1
        let l:winnr += 1
    endwhile

    " Add a flag if current buf is modified
    let l:modFlag = getbufvar(l:buflist[l:winnr], '&modified') ? '' : ' '

    " Append the buffer name
    let l:name = fnamemodify(bufname(l:buflist[l:winnr]), ':t')

    " Append the glyph & modify name
    let [l:glyph, l:name] = gettabvar(a:n, 'tab_lable', [misc#GetWebIcon(l:name), l:name])

    let l:lable = l:glyph . ' ' . l:name . ' ' . l:modFlag

    " Cut out a section of lable
    if a:0 == 0
        return l:lable
    elseif a:1 == 0
        return ''
    elseif a:1 < 0
        return strcharpart(l:lable, a:1)
    else
        return strcharpart(l:lable, 0, a:1)
    endif
endfunction


" Custom format instead of default
function! misc#FoldText()
    let l:str = getline(v:foldstart)
    let l:num = printf('%5d', v:foldend - v:foldstart + 1)
    return '▶' . l:num . ': ' . l:str . '  '
endfunction


" Record statue of NERDTree
" Can used for restoring
function! misc#RecordOfNERDTree(...)
    let l:bufnr = a:0 > 0 && a:1 != '.' ? a:1 : bufnr('%')
    let l:record = a:0 > 1 ? a:2 : {}

    if getbufvar(l:bufnr, '&filetype') != 'nerdtree'
        return {}
    endif

    if empty(l:record)
        let l:holeBuf = getbufline(l:bufnr, 1, '$')
        let l:length = len(l:holeBuf)
        let l:curLin = getbufinfo(l:bufnr)[0].lnum - 1

        let l:record.list = []
        let l:record.cur = matchstr(l:holeBuf[l:curLin], '[^]]*$')
        " Opened path
        let l:openIcon = get(g:, 'NERDTreeDirArrowCollapsible', '▾')

        " Root path (index 0)
        let l:i = 0
        while l:i < l:length
            if l:holeBuf[l:i] =~ '^/\S*/$'
                let l:path = [l:holeBuf[l:i]]
                break
            endif

            let l:i += 1
        endwhile

        let l:i += 1
        while l:i < l:length
            let l:indent = matchstr(l:holeBuf[l:i], '^\s*' . l:openIcon)

            " Not opened directory
            if empty(l:indent)
                let l:i += 1
                continue
            endif

            let l:indent = (strchars(l:indent) + 1)/2
            let l:str = matchstr(l:holeBuf[l:i], '\S*$')

            " Apend l:str to l:path
            if l:indent >= len(l:path)
                let l:path += [l:str]
            else
                let l:path[l:indent] = l:str
            endif

            " Expand l:str to multiple paths
            " (like lib/cur/... to lib/, lib/cur/, lib/cur/...)
            let l:list = [join(l:path[0:l:indent-1], '')]
            for l:item in split(l:str, '/')
                let l:list += [l:list[-1] . l:item . '/']
            endfor

            let l:i += 1
            " Start from 1 to avoid duplicating parent directories
            let l:record.list += l:list[1:]
        endwhile

        if empty(l:record.list)
            return {}
        else
            return l:record
        endif
    else
        " Recovery statue
        for l:absPath in get(l:record, 'list', [])
            let l:path = g:NERDTreePath.New(l:absPath)
            let l:node = b:NERDTree.root.findNode(l:path)
            call l:node.open()
        endfor

        call b:NERDTree.render()
        call search(get(l:record, 'cur', 1), 'e')
    endif
endfunction


" a:1 if exists define the action
" otherwise record the history to w:bufHis
function! misc#BufHisInAWindow(...)
    if !empty(&buftype) || empty(expand('%'))
        return
    endif

    if a:0 == 0
        let l:name = expand('%:p')

        if !exists('w:bufHis')
            let w:bufHis = {'list': [l:name], 'init': l:name, 'start': 0, 'chars': -1}
        elseif l:name != w:bufHis.list[-1]
            " When existing, remove first
            let l:ind = index(w:bufHis.list, l:name)
            if l:ind != -1
                call remove(w:bufHis.list, l:ind)
            endif

            " Put it to last position
            let w:bufHis.list += [l:name]
        endif
    elseif exists('w:bufHis') && len(get(w:bufHis, 'list', [])) > 1
        if a:1 == 'previous'
            call insert(w:bufHis.list, remove(w:bufHis.list, -1))
        elseif a:1 == 'next'
            call add(w:bufHis.list, remove(w:bufHis.list, 0))
        else
            return
        endif

        if bufexists(w:bufHis.list[-1]) && empty(getbufvar(w:bufHis.list[-1], '&bt', ''))
            silent exe 'buffer ' . w:bufHis.list[-1]
            call s:EchoBufHistory()
        else
            " Discard invalid item
            if w:bufHis.list[-1] == w:bufHis.init
                let w:bufHis.init = w:bufHis.list[0]
            endif
            call remove(w:bufHis.list, -1)
            call misc#BufHisInAWindow(a:1)
        endif
    endif
endfunction

function! s:EchoBufHistory()
    let l:bufList = map(copy(w:bufHis.list), "' '.bufnr(v:val).'-'.fnamemodify(v:val,':t').' '")
    " Mark out the current item
    let l:bufList[-1] = '[' . l:bufList[-1][1:-2] . ']'

    " Readjusting position (Put the initial edited text first)
    let l:ind = index(w:bufHis.list, w:bufHis.init)
    let l:bufList = remove(l:bufList, l:ind, -1) + l:bufList

    let l:str = join(l:bufList)
    let l:width = &columns - 1

    " Make displayed width to adapt one line ↓↓↓↓↓
    if strdisplaywidth(l:str) > l:width
        let l:allChars = strchars(l:str)
        let l:ind = len(l:bufList) - l:ind - 1

        " Current item start position: A, end point: B
        let l:B = strchars(join(l:bufList[:l:ind])) - 1
        let l:A = l:B - strchars(l:bufList[l:ind]) + 1

        " Determine the start pos & chars of l:str to display
        if l:A < w:bufHis.start
            let w:bufHis.start = max([0, l:A - 1])
            let w:bufHis.chars = l:width

            while strdisplaywidth(strcharpart(l:str, w:bufHis.start, w:bufHis.chars)) > l:width
                let w:bufHis.chars -= 1
            endwhile
        elseif strdisplaywidth(strcharpart(l:str, w:bufHis.start, l:B - w:bufHis.start + 1)) > l:width
            let w:bufHis.start = max([0, l:B - l:width + 2])
            let w:bufHis.chars = l:width

            while strdisplaywidth(strcharpart(l:str, w:bufHis.start, w:bufHis.chars)) > l:width
                let w:bufHis.chars -= 1
                let w:bufHis.start += 1
            endwhile
        endif

        " Cut out a section of l:str
        let l:str = strcharpart(l:str, w:bufHis.start, w:bufHis.chars)
        let l:str .= repeat(' ', l:width - strdisplaywidth(l:str))

        " Add prefix to head when not displayed completely
        if w:bufHis.start > 0
            let l:str = '<' . strcharpart(l:str, 1)
        endif

        " Add suffix to tail when not displayed completely
        if w:bufHis.start + w:bufHis.chars < l:allChars
            let l:str = strcharpart(l:str, 0, strchars(l:str) - 1) . '>'
        endif
    endif

    echo l:str
endfunction

" ############### 窗口相关 ######################################
" 最大化窗口/恢复
function! misc#WinResize()
    if !empty(&buftype)
        return
    endif

    if exists('t:MaxmizeWin')
        let l:winnr = win_id2win(t:MaxmizeWin[2])
        exe l:winnr . 'resize ' . t:MaxmizeWin[0]
        exe 'vert ' . l:winnr . 'resize ' . t:MaxmizeWin[1]
        if t:MaxmizeWin[2] == win_getid()
            unlet t:MaxmizeWin
            return
        endif
    endif

    let t:MaxmizeWin = [winheight(0), winwidth(0), win_getid()]
    exe 'resize ' . max([float2nr(0.8 * &lines), t:MaxmizeWin[0]])
    exe 'vert resize ' . max([float2nr(0.8 * &columns), t:MaxmizeWin[1]])
endfunction

" Combine nerdtree & tagbar
" Switch between the two
function! misc#ToggleSidebar(...)
    let l:nerd = bufwinnr('NERD_tree') == -1 ? 0 : 1
    let l:tag = bufwinnr('Tagbar') == -1 ? 0 : 2
    let l:statue = l:nerd + l:tag

    if a:0 > 0
        if l:statue > 0
            if l:nerd != -1
                call misc#ToggleNERDTree()
            endif

            if l:tag != -1
                TagbarClose
            endif
        else
            call misc#ToggleNERDTree()
            TagbarOpen
        endif
    elseif l:statue == 0
        call misc#ToggleNERDTree()
    elseif l:statue == 1
        call misc#ToggleNERDTree()
        let g:tagbar_vertical=0
        let g:tagbar_left=1
        TagbarOpen
        let g:tagbar_vertical=19
        let g:tagbar_left=0
    elseif l:statue == 2
        TagbarClose
        call misc#ToggleNERDTree()
    else
        TagbarClose
    endif
endfunction

" Toggle NERDTree window
function! misc#ToggleNERDTree()
    if bufwinnr('NERD_tree') != -1
        exe bufwinnr('NERD_tree') . 'wincmd w'
        let t:RecordOfTree = misc#RecordOfNERDTree()
        NERDTreeClose
    elseif bufwinnr('Tagbar') != -1
        TagbarClose
        if !g:NERDTree.ExistsForTab() && exists('t:RecordOfTree')
            NERDTree
            call misc#RecordOfNERDTree('.', t:RecordOfTree)
        else
            NERDTreeToggle
        endif
        TagbarOpen
    elseif !g:NERDTree.ExistsForTab() && exists('t:RecordOfTree')
        NERDTree
        call misc#RecordOfNERDTree('.', t:RecordOfTree)
    else
        NERDTreeToggle
    endif

    if exists('t:RecordOfTree') && empty(t:RecordOfTree)
        unlet t:RecordOfTree
    endif
endfunction

"  Toggle TagBar window
function! misc#ToggleTagbar()
    if bufwinnr('Tagbar') != -1
        TagbarClose
    elseif bufwinnr('NERD_tree') == -1
        let g:tagbar_vertical=0
        let g:tagbar_left=1
        TagbarOpen
        let g:tagbar_vertical=19
        let g:tagbar_left=0
    else
        let l:id = win_getid()
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
    elseif getqflist({'winid': 1}).winid != 0
        cclose
    else
        copen 10
    endif
endfunction
" ####################################################################

