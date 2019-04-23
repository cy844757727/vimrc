"
"
"
" Dict: 'title': '', 'content': {'file1': [], ...}, 'hi': '',
"
let s:bufnr = bufnr('infoWin')
if getbufvar(s:bufnr, '&filetype') !=# 'infowin'
    let s:bufnr = -1
endif

function! infoWin#Set(dict)
    if type(a:dict) != type({})
        return
    endif

    if exists('*misc#ToggleBottomBar')
        call misc#ToggleBottomBar('only', 'infowin')
    endif

    if !bufexists(s:bufnr)
        call misc#SwitchToEmptyBuftype()
        exe 'belowright '.get(g:, 'BottomWinHeight', 15).'new infoWin'
        let s:bufnr = bufnr('%')
    elseif bufwinnr(s:bufnr) != -1
        exe bufwinnr(s:bufnr).'wincmd w'
    else
        call misc#SwitchToEmptyBuftype()
        exe 'belowright '.get(g:, 'BottomWinHeight', 15).'split +'.s:bufnr.'buffer'
    endif

    setlocal winfixheight noreadonly modifiable
    let s:indent = get(a:dict, 'indent', '  ')
    let b:infoWin = {
                \ 'title': get(a:dict, 'title', '[InfoWin]'),
                \ 'type': get(a:dict, 'type', ''),
                \ 'count': [], 'path': getcwd(), 'bufnr': s:bufnr,
                \ 'getline': get(a:dict, 'getline', function('s:GetLine'))
                \ }
    edit!
    call setline(1, s:DisplayStr(a:dict.content, ''))
    setlocal readonly nomodifiable filetype=infowin
    let b:infoWin.count += [line('$') - s:Sum(b:infoWin.count)]
    exe 'setlocal statusline=\ '.fnameescape(b:infoWin.title).'%=\ %l/'.line('$').
                \ '%4(%)\ '.b:infoWin.count[-2].'\ \ '.b:infoWin.count[-1].'\ '

    if has_key(a:dict, 'hi')
        call clearmatches()
        call matchadd('InfoWinMatch', a:dict.hi)
    endif
endfunction

function! s:Sum(list)
    let l:sum = 0
    for l:item in a:list
        let l:sum += l:item
    endfor
    return l:sum ? l:sum : 1
endfunction

function! infoWin#Toggle(act) abort
    if bufwinnr(s:bufnr) != -1
        exe a:act == 'on' ? bufwinnr(s:bufnr).'wincmd w' : bufwinnr(s:bufnr).'hide'
    elseif a:act ==# 'off'
        return
    elseif !bufexists(get(s:, 'bufnr', -1))
        call misc#SwitchToEmptyBuftype()
        exe 'belowright '.get(g:, 'BottomWinHeight', 15).'new infoWin'
        setlocal winfixheight readonly nomodifiable filetype=infowin statusline=\ [InfoWin]
        let s:bufnr = bufnr('%')
    else
        call misc#SwitchToEmptyBuftype()
        silent exe 'belowright '.get(g:, 'BottomWinHeight', 15).'split +'.s:bufnr.'buffer'
    endif
endfunction

function infoWin#IsVisible()
    return bufwinnr(s:bufnr) != -1
endfunction

function infoWin#GetVal(list)
    if !bufexists(s:bufnr)
        return {}
    endif

    let l:dict = {}
    let l:infoWin = getbufvar(s:bufnr, 'infoWin', {})

    for l:key in a:list
        let l:dict[l:key] = get(l:infoWin, l:key, -1)
    endfor

    return empty(l:dict) ? deepcopy(l:infoWin) : l:dict
endfunction

let s:indent = '  '
function! s:DisplayStr(content, indent) abort
    let l:list = []
    let l:level = strdisplaywidth(a:indent) / strdisplaywidth(s:indent)
    
    " Data statistics
    if l:level > len(b:infoWin.count) - 1
        let b:infoWin.count += [len(keys(a:content))]
    else
        let b:infoWin.count[l:level] += len(keys(a:content))
    endif

    for [l:key, l:val] in items(a:content)
        let l:list += [a:indent.l:key]

        let l:type = type(l:val)
        if l:type == type({})
            let l:list +=  s:DisplayStr(l:val, a:indent.s:indent)
        elseif l:type == type([])
            let l:list += map(l:val, "'".a:indent.s:indent."'.v:val")
        elseif l:type == type('')
            let l:list += [a:indent.s:indent.l:val]
        endif
    endfor

    return l:list
endfunction


function s:GetLine()
    let l:line = getline('.')
    let l:indent = indent('.')
    let l:lin = split(matchstr(l:line, '\v^\s+\zs[0-9,: ]+\ze:'), '\s*[,:]\s*')

    if l:indent == 0 || empty(l:lin)
        return [-1, -1, -1]
    endif

    let [l:lin, l:col] = len(l:lin) == 1 ? [l:lin[0], -1] : l:lin
    let l:nr = search('\v^\s{,'.(l:indent-1).'}\S', 'bnW')

    return l:nr ? [b:infoWin.path.'/'.trim(getline(l:nr)), l:lin, l:col] : [-1, -1, -1]
endfunction

