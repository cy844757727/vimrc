" ==================================================
" File: misc.vim
" Author: Cy <844757727@qq.com>
" Description: Miscellaneous function
" Last Modified: 2019年01月07日 星期一 21时03分39秒
" ==================================================

if exists('g:loaded_A_Misc')
    finish
endif
let g:loaded_A_Misc = 1


augroup misc_autocmd
    autocmd!
    " Auto record buf history for each window
    autocmd BufEnter *[^0-9] call s:BufHisRecord()
    autocmd TabLeave * call s:TabEvent('leave')
    autocmd TabClosed * call s:TabEvent('close')
augroup END

"  Refresh NERTree
function! s:UpdateNERTreeView()
    let l:nerd = bufwinnr('NERD_tree')

    if l:nerd != -1
        let l:id = win_getid()
        exe l:nerd.'wincmd w'
        call b:NERDTree.root.refresh()
        call b:NERDTree.render()
        call win_gotoid(l:id)
    endif
endfunction


" diffupdate in diffmode
" Compile c/cpp/verilog, Run  & debug script language ...
" Parameter value: origin, task, run, debug, reverse
function! misc#F5FunctionKey(type) abort range
    if a:type ==# 'task'
        exe
                    \ exists('b:task') ? b:task :
                    \ exists('w:task') ? w:task :
                    \ exists('t:task') ? t:task :
                    \ exists('g:task') ? g:task :
                    \ get(g:, 'TASK', '')
    elseif &diff
        diffupdate
    elseif &filetype == 'nerdtree'
        call b:NERDTree.root.refresh()
        call b:NERDTree.render()
    elseif exists('t:git_tabpageManager')
        call git#Refresh()
    elseif !s:SwitchToEmptyBuftype()
        return
    elseif &filetype =~# 'verilog'
        update
        if isdirectory('work')
            AsyncRun vlog -work work %
        else
            AsyncRun vlib work && vmap work work && vlog -work work %
        endif
    elseif a:type ==# 'run'
        update
        if index(['sh', 'python', 'perl', 'tcl', 'ruby', 'awk'], &ft) != -1
            cclose
            call async#RunScript(expand('%'))
        elseif !empty(glob('[mM]ake[fF]ile'))
            AsyncRun make
        elseif index(['c', 'cpp'], &ft) != -1
            AsyncRun g++ -Wall -O0 -g3 % -o %<
        elseif &filetype ==# 'vim'
            source %
        endif
    elseif a:type ==# 'debug'
        update
        let l:breakPoint = BMBPSign#SignRecord('break', 'tbreak')

        if index(['sh', 'python', 'perl'], &ft) != -1
            call async#DbgScript(expand('%'), l:breakPoint)
        elseif !empty(glob('[mM]ake[fF]ile')) || index(['c', 'cpp'], &ft) != -1
            call async#GdbStart(expand('%<'), l:breakPoint)
        elseif &filetype ==# 'vim'
            breakdel *
            for l:item in l:breakPoint
                let l:list = split(l:item, '[ :]')
                exe 'breakadd file '.l:list[2].' '.l:list[1]
            endfor
            debug source %
        endif
    elseif a:type ==# 'visual'
        if index(['sh', 'python', 'ruby'], &ft) != -1
            call async#RunScript('visual')
        elseif &filetype ==# 'vim'
            exe getreg('*')
        endif
    endif
endfunction

function misc#F5Complete(L, C, P)
    return "run\ndebug\nvisual\ntask"
endfunction


let s:fileFilter = {
            \ 'vim': '-G .*vim$ ',
            \ 'python': '-G .*py$ ',
            \ 'c': '-G .*(c|cpp)$ ',
            \ 'cpp': '-G .*(c|cpp)$ '
            \ }

function misc#FindRef(str) range
    let l:type = &filetype
    call async#TermToggle('off')
    exe 'copen '.g:BottomWinHeight
    call setqflist([], 'r')
    let l:str = empty(a:str) ? '(?<=\\W)'.getreg('*').'(?=\\W)' : a:str
    let s:agTitle = l:str =~ '\v^\(' ? l:str[8:-8] : l:str
    let l:op = '-i --nocolor '.(l:str !~# ' -G ' ? get(s:fileFilter, l:type, '') : '')

    let l:job = job_start('ag '.l:op.l:str, {
                \ 'in_io': 'null',
                \ 'out_io': 'pipe',
                \ 'out_mode': 'nl',
                \ 'out_cb': function('s:MsgGather')
                \ })
endfunction

function s:MsgGather(job, msg)
    call setqflist([], 'a', {'efm': '%f:%l:%m', 'lines': [a:msg], 'title': 'FindRef: '.s:agTitle})
endfunction

" Switch to buffer with empty buftype
function s:SwitchToEmptyBuftype()
    if empty(&buftype)
        return 1
    elseif winnr('$') == 1
        return 0
    endif

    let l:cur = winnr()
    let l:ex = (&filetype ==# 'qf' || bufname('%') =~# '\v^!Terminal') ?
                \ 'wincmd W' : 'wincmd w'

    exe l:ex
    while winnr() != l:cur
        if empty(&buftype)
            return 1
        endif

        exe l:ex
    endwhile

    return 0
endfunction

let s:preTabNr = {'0': 1, '1': 1, 'cur': 0}
function s:TabEvent(act)
    if a:act == 'leave'
        let s:preTabNr[s:preTabNr.cur] = tabpagenr()
        let s:preTabNr.cur = !s:preTabNr.cur
    elseif a:act == 'close'
        try
            exe s:preTabNr[s:preTabNr.cur].'tabnext'
        catch 'E16'
            $tabnext
        endtry

        let s:preTabNr[!s:preTabNr.cur] = s:preTabNr[s:preTabNr.cur]
    endif
endfunction

" Specified range code formatting
function! misc#CodeFormat() range
    if !empty(&buftype) || empty(&filetype)
        return
    endif

    let l:pos = getpos('.')
    mark z

    " Determine range
    let l:range = a:firstline == a:lastline ? '%' : a:firstline.','.a:lastline

    " Default format operator list
    let l:formatEx = [l:range.'normal ==', l:range.'s/\s*$//', 'silent! /\v-^']

    " Custom formatting
    if &filetype =~# 'verilog'
        let l:formatEx = [
                    \ l:range.'s/\v[0-9a-zA-Z_)\]]\zs\s*([-+=*/%><|&!?~:^][=><|&~]?)\s*\ze[a-zA-Z_(]/ \1 /ge',
                    \ l:range.'s/\v\(\zs\s*|\s*\ze\)//ge',
                    \ l:range.'s/\v(,|;)\zs\s*\ze\w/ /ge'
                    \ ] + l:formatEx[1:]
    elseif &filetype ==# 'make'
        let l:formatEx = [
                    \ l:range.'s/\v\w\zs\s*(+=|=|:=)\s*/ \1 /ge',
                    \ l:range.'s/\v:\zs\s*\ze(\w|\$)/ /ge'
                    \ ] + l:formatEx

        " Use external tools & Config cmd
        " Tools: clang-format, autopep8, perltidy, shfmt
    elseif index(['c', 'cpp', 'java', 'javascript'], &ft) != -1 && executable('clang-format-7')
        let l:formatEx = l:range."!clang-format-7 -style='{IndentWidth: 4}'"
    elseif &filetype ==# 'python' && executable('yapf') && executable('yapf3')
        let l:formatEx = l:range.(getline(1) =~# 'python3' ? '!yapf3' : '!yapf')
    elseif &filetype ==# 'perl' && executable('perltidy')
        let l:formatEx = l:range.'!perltidy'
    elseif &filetype ==# 'sh' && executable('shfmt')
        let l:formatEx = l:range.'!shfmt -s -i 4'
    endif

    " Format code
    call execute(l:formatEx)
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
            \ 'vim': '"'
            \ }

"  Toggle comment
function! misc#ReverseComment() range
    if has_key(s:commentChar, &ft)
        let l:pos = getpos('.')
        let l:char = s:commentChar[&ft]
        let l:range = a:firstline.','.a:lastline
        silent exe l:range.'s+^+'.l:char.'+e'
        silent exe l:range.'s+^'.l:char.l:char.'++e'
        call setpos('.', l:pos)
    endif
endfunction


" 字符串查找替换
function! misc#StrSubstitute(str)
    if empty(a:str)
        return
    endif

    let l:subs = input('Replace "'.a:str.'" with: ')

    if !empty(l:subs)
        let l:pos = getpos('.')
        exe '%s/'.a:str.'/'.l:subs.'/Ig'
        call setpos('.', l:pos)
    endif
endfunction


" File save
function! misc#SaveFile()
    let l:file = expand('%')

    if !empty(&buftype)
        return
    elseif empty(l:file)
        exe 'file '.input('Set file name: ')
        write
        filetype detect
        call s:UpdateNERTreeView()
    elseif exists('s:DoubleClick_500MSTimer')
        wall
        echo 'Save all'
    else
        if !filereadable(l:file)
            write
            call s:UpdateNERTreeView()
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
    if empty(matchstr(getline(1), '\v^0{8}: \S'))
        :%!xxd
        let b:ale_enabled = 0
    else
        :%!xxd -r
        let b:ale_enabled = 1
    endif
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
        let s:TabLineStart = 0
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
            let l:lable = ' %{misc#TabLabel('.(l:i+1).')} '.l:endSpace.'>'
            let l:last = 1
        elseif s:TabLineStart + s:TabLineChars == l:chars + 2
            " After segmentation symbols (last tab)
            let l:lable = ' %{misc#TabLabel('.(l:i+1).')} '
            let l:lable .= '%#TabLineSeparator#│'.l:endSpace.'%#TabLine#>'
            let l:last = 1
        elseif s:TabLineStart + s:TabLineChars == l:chars
            let l:lable = ' %{misc#TabLabel('.(l:i+1).')}'.l:endSpace
            let l:lable .= l:i != l:num - 1 ? '>' : ' '
            let l:last = 1
        elseif s:TabLineStart + s:TabLineChars < l:chars
            let l:width = strchars(l:tabList[l:i]) - l:chars + s:TabLineStart + s:TabLineChars - 2
            let l:lable = ' %{misc#TabLabel('.(l:i+1).','.l:width.')}'.l:endSpace
            let l:lable .=  '>'
            let l:last = 1
        else
            let l:lable = ' %{misc#TabLabel('.(l:i+1).')} '
        endif

        " select the highlighting & tab page number (for mouse clicks)
        let l:s .= (l:i == l:cur ? '%#TabLineSel#' : '%#TabLine#').
                    \ '%'.(l:i + 1).'T'.l:lable

        " Separator symbols
        if !exists('l:last') && l:i != l:num - 1
            let l:s .= (l:i != l:cur && l:i + 1 != l:cur) ? '%#TabLineSeparator#│' : ' '
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
    let l:lable = gettabvar(a:n, 'tab_lable',
                \ misc#GetWebIcon('filetype', l:name).' '.l:name.' '.l:modFlag)

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
    return ''.(v:foldend - v:foldstart + 1).' '.getline(v:foldstart)
endfunction


" a:1 if exists define the action
" otherwise record the history to w:bufHis
function! s:BufHisRecord()
    if !empty(&buftype) || expand('%') =~# '\v^/|^$'
        return
    endif

    let l:name = expand('%:p')

    if !exists('w:bufHis')
        let w:bufHis = {'list': [l:name], 'init': l:name, 'start': 0, 'chars': -1}
    elseif l:name != get(w:bufHis.list, -1, '')
        " When existing, remove first
        let l:ind = index(w:bufHis.list, l:name)
        if l:ind != -1
            call remove(w:bufHis.list, l:ind)
        endif

        " Put it to last position
        let w:bufHis.list += [l:name]
    endif
endfunction


function! misc#BufHisDel(...)
    if !exists('w:bufHis') || len(w:bufHis.list) < 2
        return
    endif

    let l:cwd = getcwd().'/'
    let l:filter = join(map(copy(a:000), "'".l:cwd."'.bufname(v:val+0)"), '\|')
    call filter(w:bufHis.list, "v:val !~# '".l:filter."'")
endfunction


function! misc#BufHisSwitch(action)
    if !exists('w:bufHis') || len(get(w:bufHis, 'list', [])) < 2
        return
    endif

    if a:action == 'next'
        call add(w:bufHis.list, remove(w:bufHis.list, 0))
    else
        call insert(w:bufHis.list, remove(w:bufHis.list, -1))
    endif

    if bufexists(w:bufHis.list[-1])
        silent update
        silent exe 'buffer '.w:bufHis.list[-1]
        call s:BufHisEcho()
    else
        " Discard invalid item
        if w:bufHis.list[-1] == w:bufHis.init
            let w:bufHis.init = w:bufHis.list[0]
        endif

        call remove(w:bufHis.list, -1)
        call misc#BufHisSwitch(a:action)
    endif
endfunction


function! s:BufHisEcho()
    let l:bufList = map(copy(w:bufHis.list), "' '.bufnr(v:val).'-'.fnamemodify(v:val,':t').' '")

    " Mark out the current item
    let l:bufList[-1] = '['.l:bufList[-1][1:-2].']'

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
            let l:str = '<'.strcharpart(l:str, 1)
        endif

        " Add suffix to tail when not displayed completely
        if w:bufHis.start + w:bufHis.chars < l:allChars
            let l:str = strcharpart(l:str, 0, strchars(l:str) - 1).'>'
        endif
    endif

    echo l:str
endfunction


function! misc#GetWebIcon(type, ...)
    let l:file = a:0 > 0 ? a:1 : expand('%')

    if a:type == 'head'
        if l:file =~ '^!'
            return 'ﲵ'
        elseif getbufvar(l:file, '&bt', '') == 'help'
            return ''
        elseif exists('g:BMBPSign_Projectized')
            return ''
        endif

        return ''
    elseif a:type == 'fileformat'
        if getbufvar(l:file, '&binary', 0)
            return ''
        endif

        return WebDevIconsGetFileFormatSymbol()
    elseif a:type == 'filetype'
        let l:tfile = fnamemodify(l:file, ':t')
        let l:extend = fnamemodify(l:file, ':e')

        if empty(l:extend) && l:tfile !~# '^\.' && bufexists(l:file)
            let l:file .= '.'.getbufvar(l:file, '&filetype')
        elseif getbufvar(l:file, '&buftype') == 'help'
            return ''
        endif

        return WebDevIconsGetFileTypeSymbol(l:file)
    endif
endfunction


" Return linter status & job status
function! misc#StatuslineExtra() abort
    let l:counts = ale#statusline#Count(bufnr(''))
    let l:all_errors = l:counts.error + l:counts.style_error
    let l:all_non_errors = l:counts.total - l:all_errors
    let l:jobs = async#JobRuning()
    let l:list = []

    if l:all_errors > 0
        let l:list +=  [' '.l:all_errors]
    endif

    if l:all_non_errors > 0
        let l:list += [' '.l:all_non_errors]
    endif

    if l:jobs > 0
        let l:list += ['& '.l:jobs]
    endif

    return join(l:list, ' ')
endfunction


function! misc#NextItem(...)
    let l:next = a:0 == 0 || a:1 ==# 'next'

    if empty(&buftype)
        exe l:next ? 'ALENextWrap' : 'ALEPreviousWrap'
    else
        let l:re = get({'qf': '^[^|]', 'tagbar': '^[^ "]', 'nerdtree': '/$'}, &ft, '')

        if empty(l:re)
            return
        endif

        exe "call search('".l:re."','".(l:next ? 'w' : 'wb')."')"
    endif
endfunction


function! misc#Information(act) range
    if a:act ==# 'visual'
        normal gv
    endif

    let l:info = ''
    let l:cwd = fnamemodify(getcwd(), ':~')
    let l:nr = bufnr('%')
    let l:lines = line('$')
    let l:count = wordcount()

    if a:act ==# 'simple'
        if isdirectory('.git')
            let l:info .= ' '.matchstr(system('git branch'), '\v(\* )\zs\w*').'    '
        endif

        let l:time = strftime('%H:%M')
        let l:info .= ' '.l:cwd.'    '.' '.l:nr.': '.l:lines.'L, '.
                    \ l:count.words.'W, '.l:count.chars.'C, '.l:count.bytes.'B'
        echo l:info.repeat(' ', &columns - strdisplaywidth(l:info.l:time) - 1).l:time
    elseif a:act ==# 'detail'
        let l:info .= '  '.strftime('%Y %b %d %A %H:%M')."\n"

        if isdirectory('.git')
            let l:info .= '  '.join(split(system('git branch'), '\v  +|\n'), '  ')."\n"
        endif

        echo l:info.'  '.l:cwd."\n".'  '.l:nr.'-'.expand('%')."\n".
                    \ '  '.l:lines.'L, '.l:count.words.'W, '.l:count.chars.'C, '.l:count.bytes.'B'."\n".
                    \ '  '.matchstr(system('ls -lh '.expand('%:S')), '\v.*\d+:\d+')
    elseif a:act ==# 'visual'
        exe 'normal '.visualmode()
        redraw
        echo 'Lines: '.(a:lastline-a:firstline+1).'/'.l:lines.'   '.
                    \ 'Words: '.l:count.visual_words.'/'.l:count.words.'   '.
                    \ 'Chars: '.l:count.visual_chars.'/'.l:count.chars.'   '.
                    \ 'Bytes: '.l:count.visual_bytes.'/'.l:count.bytes
    endif
endfunction


function! misc#CleanBufferList()
    let l:nrs = []

    for l:tabnr in range(1, tabpagenr('$'))
        for l:winnr in range(1, tabpagewinnr(l:tabnr, '$'))
            let l:var = gettabwinvar(l:tabnr, l:winnr, 'bufHis', {})

            if len(get(l:var, 'list', [])) > 0
                let l:nrs += map(copy(l:var.list), "bufnr(v:val)")
            endif
        endfor
    endfor

    for l:str in split(execute('ls'), "\n")
        let l:nr = matchstr(l:str, '\v^(\s*)\zs\d+\ze(\s+h?\s+")')

        if !empty(l:nr) && (index(l:nrs, l:nr + 0) == -1) && empty(
                    \ matchlist(execute('sign place buffer='.l:nr), '\v\s+\S+\=BMBPSign'))
            exe 'silent bw '.l:nr
        endif
    endfor
endfunction


" Filter :messages output
function! misc#MsgFilter(...)
    let [l:num, l:filter] = [0, '\v^\a+:']

    for l:i in range(len(a:000))
        if a:000[l:i]
            let l:num = abs(a:000[l:i])
        elseif a:000[l:i] !=# '0'
            let l:filter = join(a:000[l:i:], ' ')
            break
        endif
    endfor

    let l:msg = filter(split(execute('messages'), "\n"), "v:val =~? '".l:filter."'")
    echo join(l:num >= len(l:msg) ? l:msg : l:msg[-l:num:], "\n")
endfunction


function! misc#EditFile(file, ...)
    if !filereadable(a:file)
        return
    elseif !bufexists(a:file)
        exe get(a:000, 0, 'edit').' '.a:file
        return
    endif

    let l:file = fnamemodify(a:file, ':p')

    for l:tab in range(1, tabpagenr('$'))
        for l:win in range(1, tabpagewinnr(l:tab, '$'))
            let l:var = gettabwinvar(l:tab, l:win, 'bufHis', {'list': []})

            if index(l:var.list, l:file) != -1
                exe l:tab.'tabnext'
                exe l:win.'wincmd w'
                exe 'buffer '.l:file
                return
            endif
        endfor
    endfor

    exe get(a:000, 0, 'edit').' '.a:file
endfunction

" ############### 窗口相关 ######################################
" 最大化窗口/恢复
function! misc#WinResize()
    if !empty(&buftype)
        return
    endif

    if exists('t:MaxmizeWin')
        let l:winnr = win_id2win(t:MaxmizeWin[2])
        exe l:winnr.'resize '.t:MaxmizeWin[0]
        exe 'vert '.l:winnr.'resize '.t:MaxmizeWin[1]
        if t:MaxmizeWin[2] == win_getid()
            unlet t:MaxmizeWin
            return
        endif
    endif

    let t:MaxmizeWin = [winheight(0), winwidth(0), win_getid()]
    exe 'resize '.max([float2nr(0.8 * &lines), t:MaxmizeWin[0]])
    exe 'vert resize '.max([float2nr(0.8 * &columns), t:MaxmizeWin[1]])
endfunction


" Combine nerdtree & tagbar
" Switch between the two
function! misc#ToggleSidebar(...)
    let l:obj = a:0 > 0 ? a:1 : 'toggle'
    let l:nerd = bufwinnr('NERD_tree') == -1 ? 0 : 1
    let l:tag = bufwinnr('Tagbar') == -1 ? 0 : 2
    let l:statue = l:nerd + l:tag

    if l:obj == 'NERDTree'
        call s:ToggleNERDTree()
    elseif l:obj == 'Tagbar'
        call s:ToggleTagbar()
    elseif l:obj == 'all'
        if l:statue == 0
            NERDTreeToggle
            TagbarOpen
        else
            TagbarClose
            NERDTreeClose
        endif
    elseif g:tagbar_vertical > 0 || (g:tagbar_left != (g:NERDTreeWinPos == 'right'))
        if l:statue == 0
            call s:ToggleTagbar()
        elseif l:statue == 1
            NERDTreeClose
            call s:ToggleTagbar()
        elseif l:statue == 2
            TagbarClose
            NERDTreeToggle
        else
            TagbarClose
        endif
    else
        call s:ToggleTagbar()
    endif
endfunction


" Toggle NERDTree window
function! s:ToggleNERDTree()
    if bufwinnr('NERD_tree') != -1
        NERDTreeClose
    elseif bufwinnr('Tagbar') != -1
        if g:tagbar_vertical > 0 || (g:tagbar_left != (g:NERDTreeWinPos == 'right'))
            TagbarClose
        endif

        NERDTreeToggle

        if g:tagbar_vertical > 0
            TagbarOpen
        endif
    else
        NERDTreeToggle
    endif
endfunction


"  Toggle TagBar window
function! s:ToggleTagbar()
    if bufwinnr('Tagbar') != -1
        TagbarClose
    elseif bufwinnr('NERD_tree') == -1
        if g:tagbar_vertical == 0
            TagbarOpen
        else
            let l:temp = [g:tagbar_vertical, g:tagbar_left]
            let g:tagbar_vertical = 0
            let g:tagbar_left = g:NERDTreeWinPos == 'left'
            TagbarOpen
            let [g:tagbar_vertical, g:tagbar_left] = l:temp
        endif
    elseif g:tagbar_vertical > 0
        let l:id = win_getid()
        exe bufwinnr('NERD_tree').'wincmd w'
        TagbarOpen
        call win_gotoid(l:id)
    else
        if g:tagbar_left != (g:NERDTreeWinPos == 'right')
            NERDTreeClose
        endif
        TagbarOpen
    endif
endfunction


"  Toggle bottom window (quickfix, terminal)
function! misc#ToggleBottombar(winType, ...)
    let l:type = a:0 > 0 ? a:1 : ''

    if a:winType == 'quickfix'
        call async#TermToggle('off')

        if l:type == 'book'
            call BMBPSign#SetQfList('BookMark', 'book')
        elseif l:type == 'break'
            call BMBPSign#SetQfList('BreakPoint', 'break', 'tbreak')
        elseif l:type == 'todo'
            call BMBPSign#SetQfList('TodoList', 'todo')
        elseif getqflist({'winid': 1}).winid == 0
            exe 'copen '.get(g:, 'BottomWinHeight', 15)
        else
            cclose
        endif
    elseif a:winType == 'terminal'
        cclose
        call async#TermToggle('toggle', l:type)
    endif
endfunction
" ####################################################################

function! SwitchXPermission()
    let l:node = g:NERDTreeFileNode.GetSelected().path.str()

    if isdirectory(l:node)
        return
    endif

    let l:perm = getfperm(l:node)
    let l:flag = executable(l:node) ? '-' : 'x'
    call setfperm(l:node, strcharpart(l:perm, 0, 2).l:flag.
                \ strcharpart(l:perm, 3, 2).l:flag.
                \ strcharpart(l:perm, 6, 2).l:flag)

    call b:NERDTree.root.refresh()
    call b:NERDTree.render()
endfunction


function! DebugFile(node)
    call async#GdbStart(a:node.path.str(), BMBPSign#SignRecord('break', 'tbreak'))
endfunction


call NERDTreeAddMenuItem({
            \ 'text': 'Switch file (x) permission',
            \ 'shortcut': 'x',
            \ 'callback': 'SwitchXPermission'
            \ })

call NERDTreeAddKeyMap({
            \ 'key': 'dbg',
            \ 'callback': 'DebugFile',
            \ 'quickhelpText': 'Debug file by gdb tool',
            \ 'scope': 'Node'
            \ })

" vim: foldmethod=marker
