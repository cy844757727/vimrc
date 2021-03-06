" ==================================================
" File: misc.vim
" Author: Cy <844757727@qq.com>
" Description: Miscellaneous function
" ==================================================

if exists('g:loaded_a_misc')
    finish
endif
let g:loaded_a_misc = 1
let s:preTabpage = {'before': 1, 'after': 1}


augroup misc
    autocmd!
    autocmd BufEnter *[^0-9] call s:BufHisRecord()
    autocmd TabLeave * let s:preTabpage.before = tabpagenr()
    autocmd TabEnter * let s:preTabpage.after = s:preTabpage.before
    autocmd TabClosed * exec min([s:preTabpage.after, tabpagenr('$')]).'tabnext'
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
" 'global': 'g', 'option': 'o', 'environment': 'e',
" 'command': 'c', 'nnoremap': 'm'
" Do not lock at the beginning, the loading order (event: load viminfo) will affect the results.
" When loading this plugin before loading viminfo file
"lockvar! g:ENV g:ENV_DEFAULT g:ENV_NONE

" Unlock g:ENV... before load viminfo file
function misc#EnvUnlock()
    unlockvar! g:ENV g:ENV_DEFAULT g:ENV_NONE
endfunction

" Environment configure
" Type: [] -> remove all items listed in []
" Type: {} -> add all items (key: val) listed in {}
" Type: analyze string
"       keys and values are linked by '=', and items delimited by ';'.
function! misc#Env(config) abort
    unlockvar! g:ENV g:ENV_DEFAULT g:ENV_NONE
    let l:type = type(a:config)

    if l:type == type('') && !s:EnvParse(a:config)
        let l:print = []

        for l:item in split(a:config, '\v\s*;\s*')
            let l:list = split(l:item, '\v\s*\=\s*')

            if empty(l:list)
                continue
            elseif l:item =~# '\M=$'
                call s:EnvRemove(l:list[0])
            elseif len(l:list) == 1
                let l:print += [l:list[0]]
            elseif len(l:list) == 2
                call s:EnvAdd(l:list[0], l:list[1])
            endif
        endfor

        call s:EnvPrint(l:print)
    elseif l:type == type([])
        for l:key in a:config
            call s:EnvRemove(l:key)
        endfor
    elseif l:type == type({})
        for [l:key, l:Val] in items(a:config)
            call s:EnvAdd(l:key, l:Val)
        endfor
    endif

    lockvar! g:ENV g:ENV_DEFAULT g:ENV_NONE
endfunction


" Set vim global var, option, environment, command
function s:EnvVimSet(key, Val)
    exe
                \ a:key[0:1] ==# 'g:' ? 'let '.a:key.'='.string(a:Val) :
                \ a:key[0] ==# '&'    ? 'let '.a:key.'='.string(a:Val) :
                \ a:key[0] ==# '$'    ? 'let '.a:key.'='.string(a:Val) :
                \ a:key[0] ==# '\'    ? 'nnoremap '.a:key.' '.a:Val.'<CR>' :
                \ a:key[0] ==# ':'    ? 'command! '.a:key[1:].' '.a:Val : ''
endfunction

" Unset vim global var, environment, command
function s:EnvVimUnset(key, Val)
    exe
                \ a:Val ==# 'g' ? 'unlet! '.a:key :
                \ a:Val ==# 'e' ? 'let '.a:key.'=''''' :
                \ a:Val ==# 'm' ? 'nunmap '.a:key :
                \ a:Val ==# 'c' ? 'delcommand '.a:key[1:] : ''
endfunction

" Parse option:
" -i  initial global variables, options, envirenments
" -c  empty g:ENV            -p  pretty print
" -r  resert to g:env
function s:EnvParse(opt)
    if empty(a:opt)
        echo filter(deepcopy(g:ENV), 'v:key[0] !=# ''.''')
    elseif a:opt ==# '-h'
        echo filter(deepcopy(g:ENV), 'v:key[0] ==# ''.''')
    elseif a:opt ==# '-d'
        echo 'Default:' g:ENV_DEFAULT "\n---\nNone:" g:ENV_NONE
    elseif a:opt ==# '-i'
        call extend(g:ENV, get(g:, 'env', {}), 'keep')
        for [l:key, l:Val] in items(g:ENV)
            call s:EnvVimSet(l:key, l:Val)
        endfor
    elseif a:opt ==# '-c'
        " Recovery environment
        for [l:key, l:Val] in items(g:ENV_DEFAULT)
            call s:EnvVimSet(l:key, l:Val)
        endfor
        " Delete environment
        for [l:key, l:Val] in items(g:ENV_DEFAULT)
            call s:EnvVimUnset(l:key, l:Val)
        endfor
        call extend(filter(g:ENV, 'v:key[0] ==# ''.'''), get(g:, 'env', {}))
        let [g:ENV_DEFAULT, g:ENV_NONE] = [{}, {}]
    elseif a:opt ==# '-p'
        call s:EnvPrint(filter(keys(g:ENV), 'v:val[0] !=# ''.'''))
    elseif a:opt ==# '-r'
        call extend(g:ENV, get(g:, 'env', {}))
    else
        return 0
    endif

    return 1
endfunction


" Remove key (g:ENV)
function s:EnvRemove(key)
    if !has_key(g:ENV, a:key)
        return
    endif

    " Delete key
    unlet g:ENV[a:key]

    if has_key(g:ENV_DEFAULT, a:key)
        call s:EnvVimSet(a:key, remove(g:ENV_DEFAULT, a:key))
    elseif has_key(g:ENV_NONE, a:key)
        call s:EnvVimUnset(a:key, remove(g:ENV_NONE, a:key))
    endif
endfunction


" Add or modify item (g:ENV)
function s:EnvAdd(key, Val)
    try
        let l:tmp = {'ENV': eval(a:Val)}

        if len(a:key) > 2 && a:key[0:1] ==# 'g:'
            " Global var
            if !exists(a:key)
                let l:tmp.ENV_NONE = 'g'
            elseif !has_key(g:ENV_NONE, a:key) && !has_key(g:ENV_DEFAULT, a:key)
                let l:tmp.ENV_DEFAULT = g:[a:key[2:]]
            endif
        elseif a:key[0] ==# '&'
            " vim option
            if !has_key(g:ENV_DEFAULT, a:key)
                let l:tmp.ENV_DEFAULT = eval(a:key)
            endif
        elseif a:key[0] ==# '$'
            " Environment var
            if empty(eval(a:key))
                let l:tmp.ENV_NONE = 'e'
            elseif !has_key(g:ENV_NONE, a:key) && !has_key(g:ENV_DEFAULT, a:key)
                let l:tmp.ENV_DEFAULT = eval(a:key)
            endif
        elseif a:key[0] ==# ':'
            " Command
            if exists(a:key) == 2 && !has_key(g:ENV, a:key)
                throw 'Error: command exists!'
            endif

            let l:tmp.ENV_NONE = 'c'
        elseif a:key[0] ==# '\'
            " Maping
            if !empty(maparg(a:key, 'n')) && !has_key(g:ENV, a:key)
                throw 'Error: maping exists!'
            endif

            let l:tmp.ENV_NONE = 'm'
        endif

        if len(l:tmp) > 1
            call s:EnvVimSet(a:key, l:tmp.ENV)
        endif

        for [l:key, l:Val] in items(l:tmp)
            let g:[l:key][a:key] = l:Val
        endfor
    catch
        echohl Error | echo v:exception | echohl None
    endtry
endfunction


" Pretty print, format string
function s:EnvPrint(keys)
    let l:str = []
    for l:key in a:keys
        let l:val = has_key(g:ENV, l:key) ? string(g:ENV[l:key]) :
                    \ has_key(g:, l:key)  ? string(g:[l:key]) :
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
                    \ has_key(g:, l:key)  ? string(g:[l:key]) :
                    \ l:key[0] ==# '\'    ? string(maparg(l:key, 'n')) :
                    \ l:key[0] =~# '[&$]' && exists(l:key) ? string(eval(l:key)) : ''
        return a:L.l:val
    endif

    " Match option
    if a:L =~# '^[&]'
        return join(map(getcompletion('', 'option'), '''&''.v:val'), "\n")
    endif

    " Match environment var
    if a:L =~# '^[$]'
        return join(map(getcompletion('', 'environment'), '''$''.v:val'), "\n")
    endif

    " Match key, global var
    if a:C[:a:P] =~# '\v(^\w+|;)\zs\s+[^=;]*$'
        return join(['-i', '-c', '-p'] + filter(keys(g:ENV), 'v:val[0] !=# ''.''') +
                    \ filter(keys(g:), "v:val[0] =~# '[A-Z]'"), "\n")
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

    if !has_key(g:ENV, '.task_queue')
        let g:ENV['.task_queue'] = {}
    endif

    if l:type == type('') && !s:TaskQueueParse(a:task)
        for l:item in split(a:task, '\v\s*;\s*')
            let l:list = split(l:item, '\v\s*\=\s*')

            if empty(l:list)
                continue
            elseif l:item =~# '\M=$'
                unlet! g:ENV['.task_queue'][l:list[0]]
            elseif len(l:list) == 1 && has_key(g:ENV['.task_queue'], l:list[0])
                let l:Task = g:ENV['.task_queue'][l:list[0]]
                let l:type = type(l:Task)

                if l:type == type(function('add'))
                    call l:Task()
                elseif l:type == type('') || l:type == type([])
                    call execute(l:Task, '')
                endif
            elseif len(l:list) == 2
                let g:ENV['.task_queue'][l:list[0]] = eval(l:list[1])
            endif
        endfor
    elseif l:type == type({})
        call extend(g:ENV['.task_queue'], a:task)
    endif

    lockvar! g:ENV
endfunction


function s:TaskQueueParse(opt)
    if empty(a:opt)
        echo g:ENV['.task_queue']
    elseif a:opt ==# '-s'
        call s:TaskQueueSelect()
    elseif a:opt ==# '-c'
        unlet! g:ENV['.task_queue']
    else
        return 0
    endif

    return 1
endfunction


let s:task_queue_index = 0
function s:TaskQueueSelect()
    let l:queue = get(g:ENV, '.task_queue', {})
    if empty(l:queue)
        echo 'Task queue is empty'
        return
    endif

    let [l:i, l:prompt, l:menu, l:content] = [0, 'Select one ...', {}, []]
    if exists('g:quickui#style#border')
        for [l:key, l:Val] in items(l:queue)
            let l:content += [l:key . "\t \t" .l:Val]
            let l:menu[l:i] = l:Val
            let l:i += 1
        endfor
        let l:sel = quickui#listbox#inputlist(l:content, 
                    \ {'title': 'Task Queue', 'w': 60, 'h': 10, 'index': s:task_queue_index})
        if l:sel != -1
            let s:task_queue_index = l:sel
        endif
    else
        let [l:i, l:prompt, l:menu] = [1, 'Select one ...', {}]
        for [l:key, l:Val] in items(l:queue)
            let l:prompt .= "\n".printf('  %2d:  %-15s  %s', l:i, l:key, string(l:Val))
            let l:menu[l:i] = l:Val
            let l:i += 1
        endfor
        let l:sel = input(l:promt."\n?!:")
    end


    let l:Task = get(l:menu, l:sel)
    let l:type = type(l:Task)

    if l:type == type('') || l:type == type([])
        call execute(l:Task, '')
    elseif l:type == type(function('add'))
        call l:Task()
    endif
endfunction


function misc#CompleteTask(L, C, P)
    let l:task_queue = get(g:ENV, '.task_queue', {})

    if a:C[:a:P] =~# '\v\=\s*$'
        let l:key = matchstr(a:C[:a:P], '\v\S+\ze(\s*\=\s*)$')
        return a:L.(has_key(l:task_queue, l:key) ? string(l:task_queue[l:key]) : '')
    endif

    " Match key
    if a:C[:a:P] =~# '\v(^\w+|;)\zs\s+[^=;]*$'
        return join(['-s'] + keys(l:task_queue), "\n")
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

    return join(getcompletion('', 'command'), "\n")
endfunction



" === Multifunctional F5 key {{{1
" Dict function
" 'task', 'run', 'debug', 'visual', 'task_queue', 'task_visual'
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
        call git#Refresh('all')
    elseif has_key(s:F5Function, a:type) && misc#SwitchToEmptyBuftype()
        call s:F5Function[a:type]()
    endif
endfunction


" F5Function.task(): Run task define by local enironment task, bind to Ctrl-F5 {{{2
function s:F5Function.task(...)
    let l:Task = exists('b:task') ? b:task :
                \ exists('w:task') ? w:task :
                \ exists('t:task') ? t:task :
                \ exists('g:task') ? g:task :
                \ get(g:ENV, 'task', '')
    let l:type = type(l:Task)

    if a:0 > 0 && a:1 ==# 'visual'
        normal gv
    endif

    if l:type == type(function('add'))
        call l:Task()
    elseif l:type == type('') || l:type == type([])
        call execute(l:Task, '')
    endif

    normal \<Esc>
endfunction

let s:F5Function.task_queue = function('s:TaskQueueSelect')
let s:F5Function.task_visual = function(s:F5Function.task, ['visual'])

" F5Function.run(): Run script or make, bind to F5 in normal mode{{{2
function s:F5Function.run()
    update

    if index(['sh', 'python', 'bash', 'perl', 'tcl', 'ruby', 'awk'], &ft) != -1
        # run script in internal terminal
        call misc#ToggleBottomBar('only', 'terminal')
        call async#ScriptRun(expand('%'))
    elseif &filetype ==# 'vim'
        # source vim-script
        source %
    elseif misc#MakeTool('')
        # try to execute make
        return
    elseif &ft ==# 'c'
        # compile single c code
        call misc#ToggleBottomBar('only', 'quickfix')
        Asyncrun! gcc -Wall -O0 -g3 % -o %<
    elseif &ft ==# 'cpp'
        # compile single cpp code
        call misc#ToggleBottomBar('only', 'quickfix')
        Asyncrun! g++ -Wall -O0 -g3 % -o %<
    endif

endfunction

" Debug {{{2
function s:F5Function.debug()
    update
    let l:breakPoint = sign#Record('break', 'tbreak')

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

" F5Function.visual(): Run the selected code fragment, bind to F5 in visual mode{{{2
function s:F5Function.visual()
    if index(['sh', 'python', 'ruby', 'bash'], &ft) != -1
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
        if exists('g:InfoWin_output')
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

    if get(g:, 'InfoWin_output', 0)
        let s:infoDict = {'title': ' '.a:str, 'content': {}, 'path': getcwd(), 'number': 1,
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
    if !empty(s:infoDict.content)
        call infoWin#Set(s:infoDict)
    endif
endfunction

function! s:AgOnOut(job, msg) abort
    let l:list = matchlist(a:msg, '\v^([^:]+):(\d+):(\d+):(.*)$')
    let l:file = fnamemodify(l:list[1], ':.')

    " Skip line comment string
    if has_key(s:commentChar, s:infoDict.type)
        let l:ind = matchstrpos(l:list[4], s:commentChar[s:infoDict.type])[1] + 1

        if l:ind > 0 && l:ind < l:list[3] && s:infoDict.type !=# 'vim'
            return
        endif
    endif

    if !has_key(s:infoDict.content, l:file)
        let s:infoDict.content[l:file] = []
    endif

    let s:infoDict.content[l:file] += [printf('%-5s %3s  %s', l:list[2].':', l:list[3].':', trim(l:list[4]))]
endfunction

function misc#MakeTool(opt)
    let l:makefile = findfile('makefile', '**')
    if empty(l:makefile)
        return 0
    endif
    let l:root = fnamemodify(l:makefile, ':h')
    exec 'Asyncrun! make '.get(g:, 'MakeOpt', '').' -C '.l:root.' '.a:opt
    return 1
endfunction

" === Auto record file history in a window {{{1
" BufEnter enent trigger (w:bufHis)
function! s:BufHisRecord()
    " Use relative path %:. , dont record outer (cwd) file
    if !empty(&buftype) || expand('%:.') =~# '\v^/|^$' || exists('w:buftype')
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
        if filereadable(w:bufHis.list[-1])
            silent update
        endif
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
function misc#VerticalFind(flag)
    let l:pos = getpos('.')
    let l:posP = getpos('''''')
    let l:str = ''
    let l:cur = []
    normal j

    while 1
        let l:char = getchar()

        if nr2char(l:char) ==# "\<CR>"
            break
        elseif nr2char(l:char) ==# "\<Esc>"
            call setpos('.', l:pos)
            call setpos('''''', l:posP)
            return
        elseif l:char ==# "\<BS>"
            let l:str = l:str[:-2]
            silent! call setpos('.', remove(l:cur, -1))
        else
            if nr2char(l:char) !=# ';'
                let l:str .= nr2char(l:char)
            endif

            let l:cur += [getpos('.')]
            call search(l:str, a:flag.'W')
        endif

        redraw
        echo l:str
    endwhile

    call setpos('''''', l:pos)
endfunction


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
    if winnr() == 0 && &buftype ==# 'terminal'
        return
    endif

    let l:ex = (index(['qf', 'infowin'], &ft) != -1 || bufname('%') =~# '\v^!Term') ?
                \ 'wincmd W' : 'wincmd w'

    let l:num = winnr('$')
    while (!empty(&buftype) || exists('w:buftype')) && l:num > 0
        exe l:ex
        let l:num -= 1
    endwhile

    return empty(&buftype)
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
    elseif index(['c', 'cpp', 'java', 'javascript'], &ft) != -1 && executable('clang-format')
        let l:formatEx = l:range."!clang-format -style='{IndentWidth: 4}'"
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
            \ 'awk': '#', 'ruby': '#', 'r': '#', 'python3': '#', 'csh': '#', 'conf': '#', 'sdc': '#',
            \ 'tex': '%', 'latex': '%', 'postscript': '%', 'matlab': '%',
            \ 'vhdl': '--', 'haskell': '--', 'lua': '--', 'sql': '--', 'openscript': '--',
            \ 'ada': '--',
            \ 'lisp': ';', 'scheme': ';',
            \ 'vim': '"'
            \ }

" Toggle comment
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
    let l:ft = getbufvar(l:buflist[l:winnr], '&ft')

    " Append the glyph & modify name
    let l:lable = gettabvar(a:n, 'tab_lable', iconicFont#icon(empty(l:ft) ?
                \ matchstr(l:name, '\v\w*$') : l:ft).' '.l:name.' '.l:modFlag)

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

    if l:jobs > 0 && !exists('w:buftype')
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
                    \ execute('sign place buffer='.l:nr), '\v\=sign'))
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
                let l:op = matchstr(a:way, '\v\+.*$')

                if bufnr('%') != bufnr(l:file) || !empty(l:op)
                    exe 'edit '.l:op.' '.l:file
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
    if &filetype ==# 'tagbar'
        normal x
    elseif &filetype ==# 'nerdtree'
        normal A
    elseif &buftype ==# 'terminal'
        let l:height = get(g:, 'BottomWinHeight', 15)
        exe 'resize '.(winheight(0) != l:height ? l:height : '')
    elseif exists('b:WinResize')
        if type(b:WinResize) == type(function('add'))
            call b:WinResize()
        else
            call execute(b:WinResize)
        endif
    elseif empty(&buftype)
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
    endif
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
    elseif a:winType == 'quickfix' && !(winnr() == 0 && &buftype ==# 'terminal')
        call async#TermToggle('off', '')

        if a:type == 'book'
            call sign#SetQfList(' BookMark', ['book'])
        elseif a:type == 'break'
            call sign#SetQfList('ךּ BreakPoint', ['break', 'tbreak'])
        elseif a:type == 'todo'
            call sign#SetQfList(' TodoList', ['todo'])
        elseif get(getqflist({'winid': 1}), 'winid', 0) != 0
            cclose
        elseif infoWin#IsVisible()
            call infoWin#Toggle('off')
        else
            exe 'copen '.get(g:, 'BottomWinHeight', 15)
        endif
    elseif a:winType == 'terminal'
        if a:type !=# 'popup' && !(winnr() == 0 && &buftype ==# 'terminal')
            call misc#ToggleBottomBar('only', 'terminal')
        endif
        call async#TermToggle('toggle', a:type)
    endif
endfunction

" radix {{{1
function s:NumBaseConvert(list, radix, map, prefix) abort
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
    return s:NumBaseConvert(a:list, 16, {'10': 'a', '11': 'b', '12': 'c',
                \ '13': 'd', '14': 'e', '15': 'f'}, get(a:000, 0, '0x'))
endfunction

function misc#Bin(list, ...)
    return s:NumBaseConvert(a:list, 2, {}, get(a:000, 0, '0b'))
endfunction

function misc#Oct(list, ...)
    return s:NumBaseConvert(a:list, 8, {}, get(a:000, 0, '0'))
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
    call async#GdbStart(a:node.path.str(), sign#Record('break', 'tbreak'))
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
            \ 'scope': 'FileNode'
            \ })

" vim: foldmethod=marker
