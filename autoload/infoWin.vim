"
"
"

function! infoWin#Set(dict)
    if type(a:dict) !=# type({})
        return
    endif

    if !bufexists(get(s:, 'bufnr', -1))
        exe 'belowright '.get(g:, 'BottomWinHeight', 15).'new infoWin'
        let s:bufnr = bufnr('%')
    else
        silent exe bufwinnr(s:bufnr) != -1 ?
                    \ bufwinnr(s:bufnr).'wincmd w' :
                    \ 'belowright '.get(g:, 'BottomWinHeight', 15).'new +'.s:bufnr.'buffer'
    endif

    setlocal winfixheight noreadonly modifiable
    let l:list = s:DisplayStr(a:dict.content, '')
    let l:mode = get(a:dict, 'mode', 'w')
    let b:infoWin = {'title': fnameescape(get(a:dict, 'title', '[InfoWin]')),
                \ 'files': len(keys(a:dict.content)),
                \ 'items': len(l:list) - len(keys(a:dict.content)),
                \ 'path': getcwd()}
    exe 'setlocal statusline=\ '.b:infoWin.title.
                \ '%=\ %l/'.len(l:list).'%4(%)\ '.b:infoWin.files.'\ \ '.b:infoWin.items.'\ '

    if l:mode ==# 'w'
        edit!
        call setline(1, l:list)
    elseif l:mode ==# 'a'
        call append(line('$'), l:list)
    endif

    setlocal readonly nomodifiable filetype=infowin

    if has_key(a:dict, 'hi')
        exe 'syn match InfoWinMatch /'.a:dict.hi.'/'
    endif
endfunction


function! infoWin#Toggle(act) abort
    if bufwinnr(get(s:, 'bufnr', -1)) != -1
        exe a:act == 'on' ? bufwinnr(s:bufnr).'wincmd w' : bufwinnr(s:bufnr).'hide'
    elseif a:act ==# 'off'
        return
    elseif !bufexists(get(s:, 'bufnr', -1))
        exe 'belowright '.get(g:, 'BottomWinHeight', 15).'new infoWin'
        setlocal winfixheight readonly nomodifiable filetype=infowin statusline=\ [InfoWin]
        let s:bufnr = bufnr('%')
    else
        silent exe 'belowright '.get(g:, 'BottomWinHeight', 15).'new +'.s:bufnr.'buffer'
    endif
endfunction

function infoWin#IsVisible()
    return bufwinnr(get(s:, 'bufnr', -1)) != -1
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
        else
            let l:list += [a:indent.s:indent.l:val]
        endif
    endfor
    return l:list
endfunction

