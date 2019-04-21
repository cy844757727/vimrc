" ==================================================
" File: misc.vim
" Author: Cy <844757727@qq.com>
" Description: Miscellaneous function
" Last Modified: 2019年01月07日 星期一 21时03分39秒
" ==================================================

if exists('g:loaded_a_misc')
    finish
endif
let g:loaded_a_misc = 1


augroup misc
    autocmd!
    autocmd BufEnter *[^0-9] call s:BufHisRecord()
    autocmd TabLeave * call s:TabEvent('leave')
    autocmd TabClosed * call s:TabEvent('close')
    autocmd User WorkSpaceSavePre call s:CleanBufferList()
augroup END


" === Environment variables {{{1
" Dynamic config some behavior or action
" Key with capital initials would creat or reset global variable
" eg: {'Key': val} -> g:Key = val
" Key started with '&' mean vim option
" Key started with '$' mean environment variable
" Could be stored by viminfo
let g:ENV = extend(get(g:, 'ENV', {}), get(g:, 'env', {}), 'keep')
let g:ENV_DEFAULT = get(g:, 'ENV_DEFAULT', {})
let g:ENV_NONE = get(g:, 'ENV_NONE', {})
" none: 'global': 'g', 'option': 'o', 'environment': 'e', 'command': 'c',
" 'nnoremap': 'm'
lockvar! g:ENV g:ENV_DEFAULT g:ENV_NONE


" Environment configure
" Entries are segmented by semicolons,
" keys and values are linked by equal signs.
function! misc#EnvSet(config) abort
    unlockvar! g:ENV g:ENV_DEFAULT g:ENV_NONE
    let l:type = type(a:config)

    if l:type == type('') && !s:EnvParse(a:config)
        let [l:remove, l:add, l:print] = [[], {}, []]

        for l:item in split(a:config, '\v\s*;\s*')
            let l:list = split(l:item, '\v\s*\=\s*')

            if empty(l:list)
                continue
            elseif l:item =~# '\M=$'
                let l:remove += [l:list[0]]
            elseif len(l:list) == 1
                let l:print += [l:list[0]]
            elseif len(l:list) == 2
                let l:add[l:list[0]] = l:list[1]
            endif
        endfor

        call s:EnvRemove(l:remove)
        call s:EnvAdd(l:add)
        call s:EnvPrint(l:print)
    elseif l:type == type([])
        call s:EnvRemove(a:config)
    elseif l:type == type({})
        call s:EnvAdd(a:config)
    endif

    lockvar! g:ENV g:ENV_DEFAULT g:ENV_NONE
endfunction


" Set vim global var, option, environment, command
function s:EnvVimSet(dict)
    for [l:key, l:Val] in items(a:dict)
        exe
                    \ l:key[0] =~# '[A-Z]' ? 'let g:'.l:key.'='.string(l:Val) :
                    \ l:key[0] ==# '&'     ? 'let &g:'.l:key[1:].'='.string(l:Val) :
                    \ l:key[0] ==# '$'     ? 'let '.l:key.'='.string(l:Val) :
                    \ l:key[0] ==# '\'     ? 'nnoremap '.l:key.' '.l:Val :
                    \ l:key[0] ==# ':'     ? 'command! '.l:key[1:].' '.l:Val : ''
    endfor
endfunction

" Delete vim global var, environment, command
function s:EnvVimDelete(dict)
    for [l:key, l:val] in items(g:ENV_NONE)
        exe 
                    \ l:val ==# 'g' ? 'unlet! g:'.l:key :
                    \ l:val ==# 'e' ? 'let '.l:key.'=''''' :
                    \ l:val ==# 'm' ? 'nunmap '.l:key :
                    \ l:val ==# 'c' ? 'delcommand '.l:key[1:] : ''
    endfor
endfunction

" Parse option:
" -i  initial global variables, options, envirenments
" -c  empty g:ENV            -p  pretty print
" -r  resert to g:env
function s:EnvParse(opt)
    if empty(a:opt)
        echo g:ENV
    elseif a:opt ==# '-d'
        echo 'Default:' g:ENV_DEFAULT "\n---\nNone:" g:ENV_NONE
    elseif a:opt ==# '-i'
        " Initialize environment
        call s:EnvVimSet(g:ENV)
    elseif a:opt ==# '-c'
        " Recovery environment
        call s:EnvVimSet(g:ENV_DEFAULT)
        " Delete environment
        call s:EnvVimDelete(g:ENV_NONE)
        let [g:ENV, g:ENV_DEFAULT, g:ENV_NONE] = [get(g:, 'env', {}), {}, {}]
    elseif a:opt ==# '-p'
        " Pretty print
        let l:str = []
        for [l:key, l:Val] in items(g:ENV)
            let l:str += [l:key.'='.string(l:Val)]
        endfor
        echo join(l:str, "\n")
    elseif a:opt ==# '-r'
        " Resert
        call extend(g:ENV, get(g:, 'env', {}))
    else
        return 0
    endif

    return 1
endfunction


" Remove key (g:ENV)
function s:EnvRemove(keys)
    let [l:default, l:delete] = [{}, {}]

    for l:key in a:keys
        if !has_key(g:ENV, l:key)
            continue
        endif

        " Delete key
        unlet g:ENV[l:key]

        if has_key(g:ENV_DEFAULT, l:key)
            let l:default[l:key] = remove(g:ENV_DEFAULT, l:key)
        elseif has_key(g:ENV_NONE, l:key)
            let l:delete[l:key] = remove(g:ENV_NONE, l:key)
        endif
    endfor

    call s:EnvVimSet(l:default)
    call s:EnvVimDelete(l:delete)
endfunction


" Add or modify item (g:ENV)
function s:EnvAdd(dict)
    for [l:key, l:val] in items(a:dict)
        try
            let l:tmp = {}
            let l:tmp.ENV = eval(l:val)

            if l:key[0] =~# '[A-Z]'
                " Global var
                if !has_key(g:, l:key)
                    let l:tmp.ENV_NONE = 'g'
                elseif !has_key(g:ENV_NONE, l:key) && !has_key(g:ENV_DEFAULT, l:key)
                    let l:tmp.ENV_DEFAULT = g:[l:key]
                endif

                let g:[l:key] = l:tmp.ENV
            elseif l:key[0] ==# '&'
                " vim option
                if !has_key(g:ENV_DEFAULT, l:key)
                    let l:tmp.ENV_DEFAULT = eval(l:key)
                endif

                exe 'let &g:'.l:key[1:].'='.l:val
            elseif l:key[0] ==# '$'
                " Environment var
                if empty(eval(l:key))
                    let l:tmp.ENV_NONE = 'e'
                elseif !has_key(g:ENV_NONE, l:key) && !has_key(g:ENV_DEFAULT, l:key)
                    let l:tmp.ENV_DEFAULT = eval(l:key)
                endif

                exe 'let '.l:key.'='.l:val
            elseif l:key[0] ==# ':'
                " Command
                let l:bang = has_key(g:ENV, l:key) ? '!' : ''
                exe 'command'.l:bang.' '.l:key[1:].' '.l:tmp.ENV
                let l:tmp.ENV_NONE = 'c'
            elseif l:key[0] ==# '\'
                " Maping
                if empty(maparg(l:key, 'n')) || has_key(g:ENV, l:key)
                    exe 'nnoremap '.l:key.' '.l:tmp.ENV
                    let l:tmp.ENV_NONE = 'm'
                else
                    unlet! l:tmp.ENV
                endif
            endif

            for l:item in keys(l:tmp)
                let g:[l:item][l:key] = l:tmp[l:item]
            endfor
        catch
            echohl Error | echo v:exception | echohl None
        endtry
    endfor
endfunction


" Pretty print, format string
function s:EnvPrint(keys)
    let l:str = []
    for l:key in a:keys
        let l:val = has_key(g:ENV, l:key) ? string(g:ENV[l:key]) :
                    \ has_key(g:, l:key) ? string(g:[l:key]) : 
                    \ l:key[0] =~# '[&$]' && exists(l:key) ? string(eval(l:key)) : ''
        let l:str += [l:key.'='.l:val]
    endfor

    if !empty(l:str)
        echo join(l:str, "\n")
    endif
endfunction


function misc#CompleteEnv(L, C, P)
    if a:C[:a:P] =~# '\v\=\s*$'
        " Get value
        let l:key = matchstr(a:C[:a:P], '\v\S+\ze(\s*\=\s*)$')
        let l:val = has_key(g:ENV, l:key) ? string(g:ENV[l:key]) :
                    \ has_key(g:, l:key) ? string(g:[l:key]) :
                    \ l:key[0] ==# '\' ? string(maparg(l:key, 'n')) :
                    \ l:key[0] =~# '[&$]' && exists(l:key) ? string(eval(l:key)) : ''
        return a:L.l:val
    endif

    " Match key, global var
    if a:C[:a:P] =~# '\v[^= ]\s+\w*$'
        return join(['-i', '-c', '-p'] + keys(g:ENV) + 
                    \ filter(keys(g:), "v:val[0] =~# '[A-Z]'"), "\n")
    endif

    " Match option
    if a:L =~# '^[&]'
        return join(map(getcompletion('', 'option'), '''&''.v:val'), "\n")
    endif

    " Match environment var
    if a:L =~# '^[$]'
        return join(map(getcompletion('', 'environment'), '''$''.v:val'), "\n")
    endif

    " Match specific var
    if a:L =~# '^[bwtg]:'
        return join(map(keys(eval(a:L[:1])), ''''.a:L[:1].'''.v:val'), "\n")
    endif

    " Match function
    return join(getcompletion('', 'function'), "\n")
endfunction


" Special variables in g:ENV (task_queue)
function! misc#EnvTaskQueue(task) abort
    unlockvar! g:ENV
    let l:type = type(a:task)

    if !has_key(g:ENV, 'task_queue')
        let g:ENV.task_queue = {}
    endif

    if l:type == type('') && !s:TaskQueueParse(a:task)
        for l:item in split(a:task, '\v\s*;\s*')
            let l:list = split(l:item, '\v\s*\=\s*')

            if empty(l:list)
                continue
            elseif l:item =~# '\M=$'
                unlet! g:ENV.task_queue[l:list[0]]
            elseif len(l:list) == 1 && has_key(g:ENV.task_queue, l:list[0])
                let l:Task = g:ENV.task_queue[l:list[0]]
                let l:type = type(l:Task)

                if l:type == type(function('add'))
                    call l:Task()
                elseif l:type == type('') || l:type == type([])
                    call execute(l:Task, '')
                endif
            elseif len(l:list) == 2
                let g:ENV.task_queue[l:list[0]] = eval(l:list[1])
            endif
        endfor
    elseif l:type == type({})
        call extend(g:ENV.task_queue, a:task)
    endif

    lockvar! g:ENV
endfunction


function s:TaskQueueParse(opt)
    if empty(a:opt)
        echo g:ENV.task_queue
    elseif a:opt ==# '-s'
        call s:TaskQueueSelect()
    elseif a:opt ==# '-c'
        unlet! g:ENV.task_queue
    else
        return 0
    endif

    return 1
endfunction


function s:TaskQueueSelect()
    let [l:i, l:prompt, l:menu] = [1, 'Select one ...', {}]
    for [l:key, l:Val] in items(get(g:ENV, 'task_queue', {}))
        let l:prompt .= "\n".printf('  %2d:  %-15s  %s', l:i, l:key, string(l:Val))
        let l:menu[l:i] = l:Val
        let l:i += 1
    endfor

    if empty(l:menu)
        echo 'Task queue is empty!'
        return
    endif

    let l:Task = get(l:menu, input(l:prompt."\n!?: "), 0)
    let l:type = type(l:Task)

    if l:type == type('') || l:type == type([])
        call execute(l:Task, '')
    elseif l:type == type(function('add'))
        call l:Task()
    endif
endfunction


function misc#CompleteTask(L, C, P)
    if a:C[:a:P] =~# '\v\=\s*$'
        let l:key = matchstr(a:C[:a:P], '\v\S+\ze(\s*\=\s*)$')
        let l:val = has_key(get(g:ENV, 'task_queue', {}), l:key) ? string(g:ENV.task_queue[l:key]) : ''
        return a:L.l:val
    endif

    return join(['-s'] + keys(get(g:ENV, 'task_queue', {})), "\n")
endfunction



" === Multifunctional F5 key {{{1
" Dict function
" {'task', 'run', 'debug', 'visual'}
let s:F5Function = {}

" diffupdate in diffmode
" Compile c/cpp/verilog, Run  & debug script language ...
" Type: task, task_queue, run, debug, visual ...
function! misc#F5Function(type) range abort
    if a:type =~# 'task' && has_key(s:F5Function, a:type)
        call s:F5Function[a:type]()
    elseif &diff
        diffupdate
    elseif exists('t:git_tabpageManager')
        call git#Refresh()
    elseif misc#SwitchToEmptyBuftype() && has_key(s:F5Function, a:type)
        call s:F5Function[a:type]()
    endif
endfunction

let s:F5Function.task_queue = function('s:TaskQueueSelect')

" Task
function s:F5Function.task()
    let l:Task = exists('b:task') ? b:task :
                \ exists('w:task') ? w:task :
                \ exists('t:task') ? t:task :
                \ exists('g:task') ? g:task :
                \ get(g:ENV, 'task', '')
    let l:type = type(l:Task)

    if l:type == type(function('add'))
        call l:Task()
    elseif l:type == type('') || l:type == type([])
        call execute(l:Task, '')
    endif
endfunction

" Run
function s:F5Function.run()
    update

    if &filetype =~# 'verilog' && executable('vlib')
        let l:ex = isdirectory('work') ? 'Asyncrun vlog -work work %' :
                    \ 'Asyncrun vlib work && vmap work work && vlog -work work %'
    elseif index(['sh', 'python', 'perl', 'tcl', 'ruby', 'awk'], &ft) != -1
        call misc#ToggleBottomBar('only', 'terminal')
        call async#ScriptRun(expand('%'))
    elseif !empty(glob('[mM]ake[fF]ile'))
        let l:ex = 'Asyncrun! make'
    elseif &ft ==# 'c'
        let l:ex = 'Asyncrun! gcc -Wall -O0 -g3 % -o %<'
    elseif &ft ==# 'cpp'
        let l:ex = 'Asyncrun! g++ -Wall -O0 -g3 % -o %<'
    elseif &filetype ==# 'vim'
        source %
    endif

    if exists('l:ex')
        call misc#ToggleBottomBar('only', 'quickfix')
        exe l:ex
    endif
endfunction

" Debug
function s:F5Function.debug()
    update
    let l:breakPoint = BMBPSign#SignRecord('break', 'tbreak')

    if index(['sh', 'python', 'perl'], &ft) != -1
        call async#ScriptDbg(expand('%'), l:breakPoint)
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
endfunction

" Visual
function s:F5Function.visual()
    if index(['sh', 'python', 'ruby'], &ft) != -1
        call misc#ToggleBottomBar('only', 'terminal')
        call async#ScriptRun('visual')
    elseif &filetype ==# 'vim'
        let l:tempFile = tempname()
        silent exe line('''<').','.line('''>').'write! '.l:tempFile
        exe 'source '.l:tempFile
    endif
endfunction

function misc#CompleteF5(L, C, P)
    return join(keys(s:F5Function), "\n")
endfunction


" === ag tool: vim script implementation {{{1
" Ag: silver-search tool
let s:AgFileFilter = {
            \ 'vim': '\\.vim$|vimrc|gvimrc',
            \ 'python': '\\.py$',
            \ 'c': '\\.(c|cpp|h|hpp)$|^c[^.]+$',
            \ 'cpp': '\\.(c|cpp|h|hpp)$|^c\\w+$',
            \ 'perl': '\\.(pl|pm)$',
            \ 'verilog': '\\.(v|vh|vp|vt|vo|vg|sv|svi|svh|svg|sva)$',
            \ 'systemverilog': '\\.(v|vh|vp|vt|vo|vg|sv|svi|svh|svg|sva)$'
            \ }

function! misc#Ag(str, word) abort
    if a:str !~ '\S'
        if exists('g:Infowin_output')
            call infoWin#Toggle('toggle')
        endif

        return
    endif

    let l:type = a:str =~# '\v -?-\S+' ? 'none' : &filetype
    " file filter and search string
    let l:cmd = 'ag --column --nocolor --nogroup '.(
                \ has_key(s:AgFileFilter, l:type) ?
                \ '-G '.s:AgFileFilter[l:type].' ' : ''
                \ ).(a:word ? '\\b'.a:str.'\\b' : a:str)

    if get(g:, 'Infowin_output', 0)
        let s:refDict = {'title': ' '.a:str, 'content': {},
                    \ 'hi': '\v'.substitute(a:str, '\\\\', '\', 'g'), 'type': l:type}
        call async#JobRun('!', l:cmd, {
                    \ 'out_io': 'pipe', 'out_mode': 'nl',
                    \ 'out_cb': function('s:AgOnOut'),
                    \ 'exit_cb': function('s:AgOnExit')
                    \ }, {'flag': '[infowin]'})
    else
        call async#JobRunOut('!', l:cmd, {'title': ' '.a:str, 'efm': '%f:%l:%c:%m'})
    endif
endfunction

function s:AgOnExit(...)
    call infoWin#Set(s:refDict)
endfunction

function! s:AgOnOut(job, msg) abort
    let l:list = matchlist(a:msg, '\v^([^:]+):(\d+):(\d+):(.*)$')
    let l:file = fnamemodify(l:list[1], ':.')

    " Skip comment string
    if has_key(s:commentChar, s:refDict.type)
        let l:ind = matchstrpos(l:list[4], s:commentChar[s:refDict.type])[2]

        if l:ind == 1 || (l:ind != -1 && l:ind < l:list[3] && s:refDict.type !=# 'vim')
            return
        endif
    endif

    if !has_key(s:refDict.content, l:file)
        let s:refDict.content[l:file] = []
    endif

    let s:refDict.content[l:file] += [printf('%-10s %s', l:list[2].':'.l:list[3].':', trim(l:list[4]))]
endfunction


" === Auto record file history in a window {{{1
" BufEnter enent trigger (w:bufHis)
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
    let [w:bufHis.start, w:bufHis.chars, l:endSpace] = s:AdaptOneLineDisplay(
                \ l:bufList, len(l:bufList)-l:ind-1, w:bufHis.start, w:bufHis.chars, &columns-1)

    " Cut out a section of l:str
    let l:str = join(l:bufList)
    let l:allChars = strchars(l:str)
    let l:str = strcharpart(l:str, w:bufHis.start, w:bufHis.chars).l:endSpace

    " Add prefix to head when not displayed completely
    if w:bufHis.start > 0
        let l:str = '<'.strcharpart(l:str, 1)
    endif

    " Add suffix to tail when not displayed completely
    if w:bufHis.start + w:bufHis.chars < l:allChars
        let l:str = strcharpart(l:str, 0, strchars(l:str) - 1).'>'
    endif

    echo l:str
endfunction

" === misc function implementation {{{1
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


" Switch to buffer with empty buftype
function misc#SwitchToEmptyBuftype()
    let l:ex = (index(['qf', 'infowin'], &ft) != -1 || bufname('%') =~# '\v^!Term') ?
                \ 'wincmd W' : 'wincmd w'

    let l:num = winnr('$')
    while (!empty(&buftype) || exists('w:buftype')) && l:num > 0
        exe l:ex
        let l:num -= 1
    endwhile

    return empty(&buftype)
endfunction

" tableave, tabclose event handle
let s:preTabNr = {'0': 1, '1': 1, 'cur': 0}
function s:TabEvent(act)
    if a:act == 'leave'
        let s:preTabNr[s:preTabNr.cur] = tabpagenr()
        let s:preTabNr.cur = !s:preTabNr.cur
    elseif a:act == 'close'
        exe s:preTabNr[s:preTabNr.cur] > tabpagenr('$') ? '$tabnext' :
                    \ s:preTabNr[s:preTabNr.cur].'tabnext'
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
        call timer_start(500, function('s:TimerHandle500MS'))
    endif
endfunction
" ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑
function! s:TimerHandle500MS(id)
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


function s:AdaptOneLineDisplay(list, cur, start, chars, width)
    let l:str = join(a:list)
    if strdisplaywidth(l:str) > a:width
        let [l:start, l:chars] = [a:start, a:chars]
        let l:B = strchars(join(a:list[:a:cur])) - 1
        let l:A = l:B - strchars(a:list[a:cur]) + 1

        if  l:A < l:start
            let l:start = max([0, l:A - 1])
            let l:chars = a:width

            while strdisplaywidth(strcharpart(l:str, l:start, l:chars)) > a:width
                let l:chars -= 1
            endwhile
        elseif strdisplaywidth(strcharpart(l:str, l:start, l:B - l:start + 1)) > a:width
            let l:start = max([0, l:B - a:width + 1])
            let l:chars = a:width

            while strdisplaywidth(strcharpart(l:str, l:start, l:chars)) > a:width
                let l:chars -= 1
                let l:start += 1
            endwhile
        endif

        let l:endSpace = repeat(' ', a:width - strdisplaywidth(
                    \ strcharpart(l:str, l:start, l:chars)) - 1)

        return [l:start, l:chars, l:endSpace]
    endif

    return [0, a:width, '']
endfunction

" Customize tabline
let s:TabLineStart = 0
let s:TabLineChars = &columns
function! misc#TabLine()
    let [l:s, l:cur, l:num] = ['', tabpagenr()-1, tabpagenr('$')]
    let l:tabList = map(range(l:num), "' '.misc#TabLabel(v:val+1).' '")
    let [s:TabLineStart, s:TabLineChars, l:endSpace] = s:AdaptOneLineDisplay(
                \ l:tabList, l:cur, s:TabLineStart, s:TabLineChars, &columns - 3)

    for l:i in range(l:num)
        let l:chars = strchars(join(l:tabList[:l:i]))

        if s:TabLineStart >= l:chars
            continue
        endif

        " the label is made by misc#TabLabel()
        if empty(l:s)
            " The first lable
            let l:width = s:TabLineStart - l:chars + 1
            let l:lable = (s:TabLineStart > 0 ? '<' : ' ').
                        \  '%{misc#TabLabel('.(l:i+1).','.l:width.')} '
        elseif s:TabLineStart + s:TabLineChars > l:chars + 2
            " Middle lable
            let l:lable = ' %{misc#TabLabel('.(l:i+1).')} '
        else
            " Last lable
            let l:extra = s:TabLineStart + s:TabLineChars - l:chars
            let l:width = strchars(l:tabList[l:i]) + l:extra - 2
            let l:lable = ' %{misc#TabLabel('.(l:i+1).(l:extra < 0 ? ','.l:width : '').')}'.l:endSpace.
                        \ repeat(' ', l:extra).(l:i == l:num -1 && !l:extra ? ' ' : '>')
            let l:last = 1
        endif

        " select the highlighting & tab page number (for mouse clicks)
        let l:s .= (l:i == l:cur ? '%#TabLineSel#' : '%#TabLine#').
                    \ '%'.(l:i + 1).'T'.l:lable

        if exists('l:last') || l:i == l:num - 1
            break
        endif

        " Separator symbols
        let l:s .= (l:i != l:cur && l:i + 1 != l:cur) ? '%#TabLineSeparator#│' : ' '
    endfor

    return l:s.'%#TabLineFill#%T'.(tabpagenr('$') > 1 ? '%=%#TabLine#%999X ✘ ' : '')
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
    return 
                \ a:0 == 0 ? l:lable :
                \ a:1 >= 0 ? strcharpart(l:lable, 0, a:1) :
                \ strcharpart(l:lable, a:1)
endfunction


" Custom format instead of default
function! misc#FoldText()
    return ''.(v:foldend - v:foldstart + 1).' '.getline(v:foldstart)
endfunction



function! misc#GetWebIcon(type, ...)
    let l:file = a:0 > 0 ? a:1 : expand('%')

    if a:type == 'head'
        return
                    \ l:file =~ '^!'                      ? 'ﲵ' :
                    \ getbufvar(l:file, '&bt') ==# 'help' ? '' :
                    \ exists('g:BMBPSign_Projectized')    ? '' : ''
    elseif !empty(getbufvar(l:file, '&bt'))
        return ''
    elseif a:type == 'fileformat'
        return getbufvar(l:file, '&binary') ? '' :
                    \ WebDevIconsGetFileFormatSymbol()
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

    return ''
endfunction


" Return linter status & job status
function! misc#StatuslineExtra() abort
    if !empty(&buftype)
        return ''
    endif

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


function! s:CleanBufferList()
    let l:nrs = []
    for l:tabnr in range(1, tabpagenr('$'))
        for l:winnr in range(1, tabpagewinnr(l:tabnr, '$'))
            let l:var = gettabwinvar(l:tabnr, l:winnr, 'bufHis', {})

            if len(get(l:var, 'list', [])) > 0
                let l:nrs += map(copy(l:var.list), "bufnr(v:val)")
            endif
        endfor
    endfor

    let l:bws = []
    for l:str in filter(split(execute('ls'), "\n"), 'v:val =~ ''\v^\s*\d+\s+"''')
        let l:nr = matchstr(l:str, '\v\d+')

        if (index(l:nrs, l:nr + 0) == -1) && empty(matchlist(
                    \ execute('sign place buffer='.l:nr), '\v\=BMBPSign'))
            let l:bws += [l:nr]
        endif
    endfor

    if !empty(l:bws)
        silent! exe 'bw '.join(l:bws)
    endif
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


function! misc#EditFile(file, way)
    if !filereadable(a:file)
        return
    elseif !bufexists(a:file)
        exe a:way.' '.a:file
        return
    endif

    let l:file = fnamemodify(a:file, ':p')

    for l:tab in range(1, tabpagenr('$'))
        for l:win in range(1, tabpagewinnr(l:tab, '$'))
            let l:var = gettabwinvar(l:tab, l:win, 'bufHis', {'list': []})

            if index(l:var.list, l:file) != -1
                exe l:tab.'tabnext'
                exe l:win.'wincmd w'

                if bufnr('%') != bufnr(l:file)
                    exe 'buffer '.matchstr(a:way, '\v\S\zs .*$').' '.l:file
                endif

                return
            endif
        endfor
    endfor

    if bufnr('%') != bufnr(l:file)
        exe a:way.' '.a:file
    endif
endfunction


" === Window resize or sidebar, bottombar toggle {{{1
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
function! misc#ToggleSideBar(...)
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
            call s:ToggleNERDTree()
            call s:ToggleTagbar()
        else
            TagbarClose
            NERDTreeClose
        endif
    elseif l:statue == 3
        TagbarClose
    elseif l:statue == 2
        TagbarClose
        call s:ToggleNERDTree()
    elseif l:statue == 1
        NERDTreeClose
        call s:ToggleTagbar()
    else
        call s:ToggleTagbar()
    endif
endfunction


" Toggle NERDTree window
function! s:ToggleNERDTree()
    let l:mode = get(g:, 'SideWinMode', 1)
    let g:NERDTreeWinPos = l:mode > 2 ? 'right' : 'left'
    let g:NERDTreeWinSize = get(g:, 'SideWinWidth', 31)

    if bufwinnr('NERD_tree') != -1
        NERDTreeClose
    elseif bufwinnr('Tagbar') == -1 || l:mode == 2 || l:mode == 3
        NERDTreeToggle
    else
        TagbarClose
        NERDTreeToggle
        let g:tagbar_vertical = &lines/2 - 2
        let g:tagbar_left = 0
        TagbarOpen
    endif
endfunction


"  Toggle TagBar window
function! s:ToggleTagbar()
    let l:mode = get(g:, 'SideWinMode', 1)
    let g:tagbar_width = get(g:, 'SideWinWidth', 31)

    if bufwinnr('Tagbar') != -1
        TagbarClose
    elseif bufwinnr('NERD_tree') == -1 || l:mode == 2 || l:mode == 3
        let g:tagbar_vertical = 0
        let g:tagbar_left = l:mode % 2
        TagbarOpen
    else
        let g:tagbar_vertical = &lines/2 - 2
        let g:tagbar_left = 0
        let l:id = win_getid()
        exe bufwinnr('NERD_tree').'wincmd w'
        TagbarOpen
        call win_gotoid(l:id)
    endif
endfunction

function misc#CompleteSide(...)
    return "Tagbar\nNERDTree\nall"
endfunction

"  Toggle bottom window (quickfix, terminal)
let s:bottomBar = {
            \ 'terminal': function('async#TermToggle', ['off', '']),
            \ 'infowin':  function('infoWin#Toggle', ['off']),
            \ 'quickfix': 'cclose'
            \ }

function! misc#ToggleBottomBar(winType, type)
    if a:winType ==# 'only'
        for [l:key, l:Val] in items(s:bottomBar)
            if l:key ==# a:type
                continue
            elseif type(l:Val) == type(function('add'))
                call l:Val()
            else
                call execute(l:Val)
            endif
        endfor
    elseif a:winType == 'quickfix'
        call async#TermToggle('off', '')

        if a:type == 'book'
            call BMBPSign#SetQfList(' BookMark', 'book')
        elseif a:type == 'break'
            call BMBPSign#SetQfList('ךּ BreakPoint', 'break', 'tbreak')
        elseif a:type == 'todo'
            call BMBPSign#SetQfList(' TodoList', 'todo')
        elseif getqflist({'winid': 1}).winid != 0
            cclose
        elseif infoWin#IsVisible()
            call infoWin#Toggle('off')
        else
            exe 'copen '.get(g:, 'BottomWinHeight', 15)
        endif
    elseif a:winType == 'terminal'
        call misc#ToggleBottomBar('only', 'terminal')
        call async#TermToggle('toggle', a:type)
    endif
endfunction

" radix {{{1
function s:Num2Radix(list, radix, map, prefix) abort
    let l:out = []
    for l:num in type(a:list) == type([]) ? a:list : [a:list]
        let l:str = ''

        while l:num
            let l:tmp = l:num % a:radix
            let l:str = get(a:map, l:tmp, l:tmp).l:str
            let l:num = l:num / a:radix
        endwhile

        let l:out += [a:prefix.l:str]
    endfor

    return type(a:list) == type([]) ? l:out : l:out[0]
endfunction

function misc#Hex(list, ...)
    return s:Num2Radix(a:list, 16,
                \ {'10': 'a', '11': 'b', '12': 'c', '13': 'd', '14': 'e', '15': 'f'}, get(a:000, 0, ''))
endfunction

function misc#Bin(list, ...)
    return s:Num2Radix(a:list, 2, {}, get(a:000, 0, ''))
endfunction

function misc#Oct(list, ...)
    return s:Num2Radix(a:list, 8, {}, get(a:000, 0, ''))
endfunction

" #################################################################### {{{1
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
