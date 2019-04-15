"
"
"
" Dict: 'title': '', 'content': {'file1': [], ...}, 'hi': '',
"

function! infoWin#Set(dict)
    if type(a:dict) != type({})
        return
    endif

    if exists('*misc#ToggleBottomBar')
        call misc#ToggleBottomBar('only', 'infowin')
    endif

    if !bufexists(get(s:, 'bufnr', -1))
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
    let l:list = s:DisplayStr(a:dict.content, '')
    let b:infoWin = {'title': get(a:dict, 'title', '[InfoWin]'),
                \ 'type': get(a:dict, 'type', ''),
                \ 'files': len(keys(a:dict.content)),
                \ 'items': len(l:list) - len(keys(a:dict.content)),
                \ 'path': getcwd(), 'bufnr': s:bufnr}
    exe 'setlocal statusline=\ '.fnameescape(b:infoWin.title).
                \ '%=\ %l/'.len(l:list).'%4(%)\ '.b:infoWin.files.'\ \ '.b:infoWin.items.'\ '

    edit!
    call setline(1, l:list)
    setlocal readonly nomodifiable filetype=infowin
    exe 'syn match InfoWinMatch /'.(has_key(a:dict, 'hi') ? a:dict.hi : '\v-^').'/'
endfunction


function! infoWin#Toggle(act) abort
    if bufwinnr(get(s:, 'bufnr', -1)) != -1
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
    return bufwinnr(get(s:, 'bufnr', -1)) != -1
endfunction

function infoWin#GetVal(list)
    if !bufexists(get(s:, 'bufnr', -1))
        return {}
    endif

    let l:dict = {}
    let l:infoWin = getbufvar(s:bufnr, 'infoWin', {})

    for l:key in a:list
        let l:dict[l:key] = get(l:infoWin, l:key, -1)
    endfor

    return l:dict
endfunction

let s:indent = '  '
function! s:DisplayStr(content, indent) abort
    let l:list = []
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


