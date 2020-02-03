function! ConvertColorScheme()
    let l:list = split(getline('.'))
    if empty(l:list) || l:list[0][0] ==# '"'
        return
    endif

    call remove(l:list, 0)
    let l:name = remove(l:list, 0)
    let l:fg = ['NONE', 'NONE']
    let l:bg = ['NONE', 'NONE']
    let l:em = 'NONE'

    for l:item in l:list
        let l:color = split(l:item, '=')

        if l:color[0] == 'guifg'
            let l:fg[0] = l:color[1]
        elseif l:color[0] == 'ctermfg'
            let l:fg[1] = l:color[1]
        elseif l:color[0] == 'guibg'
            let l:bg[0] = l:color[1]
        elseif l:color[0] == 'ctermbg'
            let l:bg[1] = l:color[1]
        elseif l:color[0] == 'gui'
            let l:em = l:color[1]
        endif
    endfor

    let l:str = ''
    if l:em != 'NONE'
        let l:str = ", '".l:em."'"
    endif

    let l:tmp = l:bg[0] == 'NONE' ? 's:none' : "['".l:bg[0]."', ".l:bg[1]."]"
    if !empty(l:str) || l:bg[0] != 'NONE'
        let l:str = ", ".l:tmp.l:str
    endif

    let l:tmp = l:fg[0] == 'NONE' ? 's:none' : "['".l:fg[0]."', ".l:fg[1]."]"
    if !empty(l:str) || l:fg[0] != 'NONE'
        let l:str = ", ".l:tmp.l:str
    endif

    let l:str = "call s:HI('".l:name."'".l:str.")"
    call setline('.', l:str)
endfunction
