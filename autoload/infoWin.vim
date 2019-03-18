"
"
"

function! s:Set(dict)
    if exists('s:bufnr') && bufwinnr(s:bufnr) != -1
        exe bufwinnr(s:bufnr).'wincmd w'
    else
        exe 'belowright '.get(g:, 'BottomWinHeight', 15).'split infoWin'
        let s:bufnr = bufnr('%')
    endif

    setlocal nonu nowrap winfixheight buftype=nofile nobuflisted
    setlocal foldcolumn=0 noreadonly modifiable foldmethod=indent
    let l:list = s:DisplayStr(a:dict.content, '')
    let l:mode = get(a:dict, 'mode', 'w')
    let b:infoWin = {'title': fnameescape(get(a:dict, 'title', '[InfoWin]')),
                \ 'files': len(keys(a:dict.content)),
                \ 'items': len(l:list) - len(keys(a:dict.content)),
                \ 'path': getcwd()}
    exe 'setlocal statusline=\ '.b:infoWin.title.
                \ '%=%l/'.len(l:list).'\ \ \ \ '.b:infoWin.files.'\ \ '.b:infoWin.items.'\ '

    if l:mode ==# 'w'
        edit!
        call setline(1, l:list)
    elseif l:mode ==# 'a'
        call append(line('$'), l:list)
    endif

    setlocal readonly nomodifiable filetype=infowin
endfunction


function! infoWin#Toggle(...)
    if a:0 > 0
        call s:Set(a:1)
    elseif !exists('s:bufnr')
        exe 'belowright '.get(g:, 'BottomWinHeight', 15).'split infoWin'
        setlocal nonu nowrap winfixheight buftype=nofile filetype=infowin nobuflisted
        setlocal foldcolumn=0 noreadonly modifiable foldmethod=indent
        setlocal statusline=\ [InfoWin]
        let s:bufnr = bufnr('%')
    elseif bufwinnr(s:bufnr) != -1
        exe bufwinnr(s:bufnr).'hide'
    else
        exe 'belowright '.get(g:, 'BottomWinHeight', 15).'split +'.s:bufnr.'buffer'
        exe 'setlocal statusline=\ '.b:infoWin.title.
                    \ '%=%l/'.len(l:list).'\ \ \ \ '.b:infoWin.files.'\ \ '.b:infoWin.items.'\ '
    endif
endfunction


let s:indent = '   '
function! s:DisplayStr(content, indent)
    let l:list = []
    for [l:key, l:val] in items(a:content)
        let l:list += [a:indent.l:key]

        let l:type = type(l:val)
        if l:type == type({})
            let l:list +=  s:DisplayStr(l:val, a:indent.s:indent)
        elseif l:type == type([])
            let l:list += map(l:val, "'".a:indent.s:indent."'.v:val")
        else
            let l:list += a:indent.s:indent.l:val
        endif
    endfor
    return l:list
endfunction

