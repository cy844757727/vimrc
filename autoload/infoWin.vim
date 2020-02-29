"
"
"
" Dict: 'title': '', 'content': {'file1': [], ...}, 'hi': '',
"
let s:bufnr = bufnr('^__infoWin__$')
if getbufvar(s:bufnr, '&filetype') !=# 'infowin'
    let s:bufnr = -1
endif

function! infoWin#Set(dict) abort
    if exists('*misc#ToggleBottomBar')
        call misc#ToggleBottomBar('only', 'infowin')
    endif

    if !bufexists(s:bufnr)
        call misc#SwitchToEmptyBuftype()
        exe 'belowright '.get(g:, 'BottomWinHeight', 15).'new __infoWin__'
        let s:bufnr = bufnr('%')
    elseif bufwinnr(s:bufnr) != -1
        exe bufwinnr(s:bufnr).'wincmd w'
    else
        call misc#SwitchToEmptyBuftype()
        exe 'belowright '.get(g:, 'BottomWinHeight', 15).'split +'.s:bufnr.'buffer'
    endif

    if exists('b:infoWin') && has_key(b:infoWin, 'matchId')
        silent! call matchdelete(b:infoWin.matchId)
    endif

    setlocal winfixheight noreadonly modifiable
    let b:infoWin = {'count': [], 'bufnr': s:bufnr, 'files': {}, 'filesnum': 0,
                \ 'indent': get(a:dict, 'indent', 2),
                \ 'filelevel': get(a:dict, 'filelevel', 0),
                \ 'title':   get(a:dict, 'title', '[InfoWin]'),
                \ 'type':    get(a:dict, 'type', ''),
                \ 'path':    get(a:dict, 'path', getcwd()),
                \ 'getline': function('s:GetLine')}
    edit!
    call setline(1, s:DisplayStr(a:dict.content, 0))
    setlocal readonly nomodifiable filetype=infowin
    let b:infoWin.count += [line('$') - s:Sum(b:infoWin.count)]
    exe 'setlocal statusline=\ '.fnameescape(b:infoWin.title).
                \ '%=%{infoWin#Statistic()}'.'%7P\ '

    if has_key(a:dict, 'hi')
        let b:infoWin.matchId = matchadd('InfoWinMatch', a:dict.hi)
        let b:infoWin.hi = a:dict.hi
    endif
endfunction


function! infoWin#Statistic() abort
    if !exists('b:infoWin')
        return ''
    endif

    let l:start = search('^\S', 'bcnW')
    if l:start <= 0
        return ''
    endif
    let [l:ind, l:num] = b:infoWin.files[getline(l:start)]
    return ' '.l:ind.'/'.b:infoWin.count[b:infoWin.filelevel].
                \ '  '.l:num.'/'.b:infoWin.count[b:infoWin.filelevel+1].' '
endfunction


function! s:Sum(list)
    let l:sum = 0
    for l:item in a:list
        let l:sum += l:item
    endfor
    return l:sum ? l:sum : 1
endfunction

function! infoWin#Toggle(act) abort
    if a:act ==# 'off'
        let l:i = winnr('$')

        while l:i > 0
            if getwinvar(l:i, 'infoWinPreview', 0)
                exe l:i.'close'
                break
            endif

            let l:i -= 1
        endwhile
    endif

    if bufwinnr(s:bufnr) != -1
        exe bufwinnr(s:bufnr).(a:act ==# 'on' ? 'wincmd w' : 'hide')
    elseif a:act ==# 'off'
        return
    elseif !bufexists(get(s:, 'bufnr', -1))
        call misc#SwitchToEmptyBuftype()
        exe 'belowright '.get(g:, 'BottomWinHeight', 15).'new __infoWin__'
        setlocal winfixheight readonly nomodifiable filetype=infowin statusline=\ [InfoWin]
        let s:bufnr = bufnr('%')
    else
        call misc#SwitchToEmptyBuftype()
        silent exe 'belowright '.get(g:, 'BottomWinHeight', 15).'split +'.s:bufnr.'buffer'

        if has_key(get(b:, 'infoWin', {}), 'hi')
            let b:infoWin.matchId = matchadd('InfoWinMatch', b:infoWin.hi)
        endif
    endif
endfunction

function infoWin#IsVisible()
    return max([bufwinnr(s:bufnr), 0])
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


function! s:DisplayStr(content, level) abort
    let l:list = []
    let l:prefixKey = repeat(' ', a:level * b:infoWin.indent)
    let l:prefixVal = l:prefixKey. repeat(' ', b:infoWin.indent)

    " Data statistics
    if a:level > len(b:infoWin.count) - 1
        let b:infoWin.count += [len(keys(a:content))]
    else
        let b:infoWin.count[l:level] += len(keys(a:content))
    endif

    for [l:key, l:val] in items(a:content)
        let l:list += [l:prefixKey.l:key]

        if a:level == b:infoWin.filelevel
            let b:infoWin.filesnum += 1
            let b:infoWin.files[l:key] = [b:infoWin.filesnum, len(l:val)]
        endif

        let l:type = type(l:val)
        if l:type == type({})
            let l:list +=  s:DisplayStr(l:val, a:level + 1)
        elseif l:type == type([])
            let l:list += map(l:val, "'".l:prefixVal."'.v:val")
        elseif l:type == type('')
            let l:list += [l:prefixVal.l:val]
        endif
    endfor

    return l:list
endfunction


function s:GetLine()
    let l:line = getline('.')
    let l:indent = indent('.')
    let l:lin = split(matchstr(l:line, '\v^\s+\zs[0-9: ]+\ze:'), '\s*:\s*')

    if empty(l:lin)
        return [-1, -1, -1]
    endif

    let [l:lin, l:col] = len(l:lin) == 1 ? [l:lin[0], -1] : l:lin
    let l:nr = search('\v^\s{,'.(l:indent-1).'}\S', 'bnW')
    let l:file = (!&autochdir && getcwd() ==# b:infoWin.path ? '' : b:infoWin.path.'/').trim(getline(l:nr))

    return l:nr ? [l:file , l:lin, l:col] : [-1, -1, -1]
endfunction

