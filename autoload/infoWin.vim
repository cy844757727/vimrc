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

    let b:title = get(a:dict, 'title', 'information')
    let b:path = getcwd()
    setlocal nonu nowrap winfixheight buftype=nofile nobuflisted
    setlocal foldcolumn=0 noreadonly modifiable foldmethod=indent
    let l:list = s:DisplayStr(a:dict.content, '')
    let l:mode = get(a:dict, 'mode', 'w')
    exe 'setlocal statusline=\ InfoWin:\ '.b:title.'%=%l/'.len(l:list).'\ '

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
        setlocal statusline=\ InfoWin:\ 
        let s:bufnr = bufnr('%')
    elseif bufwinnr(s:bufnr) != -1
        exe bufwinnr(s:bufnr).'hide'
    else
        exe 'belowright '.get(g:, 'BottomWinHeight', 15).'split +'.s:bufnr.'buffer'
        exe 'setlocal statusline=\ InfoWin:\ '.get(b:, 'title', '').'%=%l/'.line('$').'\ '
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

