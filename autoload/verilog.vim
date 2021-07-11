""""""""""""""""""""""""""""""""""""""""""""""
" File: sign.vim
" Author: Cy <844757727@qq.com>
" Description: verilog auto-cmd
""""""""""""""""""""""""""""""""""""""""""""""

if exists('g:loaded_a_verilog')
    finish
endif
let g:loaded_a_verilog = 1


function! verilog#autofmt()
    if getline('.') =~# '\v^\s*$'
        return
    endif
    " Boundary determination
    let l:start = search('\v^\s*$', 'bnW')
    let l:end = search('\v^\s*$', 'nW')
    if l:start <= 0
        let l:start = 1
    else
        let l:start += 1
    endif
    if l:end <= 0
        let l:end = line('$')
    else
        let l:end -= 1
    endif
    if l:start > l:end
        return
    endif
    " Execute automatic call
    let l:content = getline(l:start, l:end)
    for l:item in l:content
        if l:item =~# '\v/\*AUTOSTM'
            call s:autofmt_stm(l:content, l:start, l:end)
            break
        endif
        if l:item =~# '\v/\*AUTOINST\*/'
            call s:autofmt_inst(l:content, l:start, l:end)
            break
        endif
    endfor
endfunction


function s:autofmt_stm(content, start, end)
    let l:tmpfile = tempname()
    call writefile(a:content, l:tmpfile)
    let l:content = systemlist('vgen autofmt '.l:tmpfile.' '.expand('%'))
    let l:start = a:start
    let l:end = a:end
    if len(l:content) > 1
        " Boundary determination
        if l:content[0] =~# '\v^\s*case\('
            norma $
            let l:start = search('\v/\*AUTOSTM', 'bcnW')
            if l:start <= 0 || l:start < a:start
                return
            endif
            normal 0
            let l:end = search('endcase', 'cnW')
            if l:end > a:end
                return
            endif
            if l:end <= 0
                let l:end = search('endcase', 'bnW')
                if l:end > 0
                    return
                endif
                let l:end = line('$')
            endif
            let l:space = matchstr(getline(l:start), '\v^\s*')
            call deletebufline(bufname(), l:start, l:end)
        else
"        elseif l:content[1] =~# '\v^(localparam|wire)'
            let l:space = matchstr(getline(l:start), '\v^\s*')
            call deletebufline(bufname(), l:start, l:end)
"        else
"            return
        endif
        " Execute automatic call
        call map(l:content, '"'.l:space.'"'.'.v:val')
        call append(l:start-1, l:content)
        silent! write
    endif
endfunction


let g:dbg=[]
function s:autofmt_inst(content, start, end)
    let l:tmpfile = tempname()
    call writefile(a:content, l:tmpfile)
    let l:content = systemlist('vgen autofmt '.l:tmpfile.' '.expand('%'))
    if len(l:content) < 4
        return
    endif
    let l:start = a:start
    let l:end = a:end
    " find module start
    while l:start < l:end && getline(l:start) !~# '\v^\s*[A-Za-z_]'
        let l:start += 1
    endwhile
    if l:start == l:end
        return
    endif
    let l:space = matchstr(getline(l:start), '\v^\s*')
    call map(l:content, '"'.l:space.'"'.'.v:val')
    let l:module = split(trim(getline(l:start)))[0]
    " Boundary determination
    let l:ind = search('\v^\s*/\*\s*'.l:module.'\s+AUTO_TEMPLATE', 'bW')
    if l:ind > 0
        let l:ind1 = search('\*/\s*$', 'nW')
        if l:ind1 > 0 && l:ind1+1 <= l:start-1
            if trim(join(getline(l:ind1+1, l:start-1))) !~# '\S'
                let l:start = l:ind
            endif
        endif
    endif
    call deletebufline(bufname(), l:start, l:end)
    " Comments on the first three lines
    if l:content[3] =~# '\v^\s*$'
        call append(l:start-1, l:content[4:])
    else
        call append(l:start-1, l:content[3:])
    endif
    call cursor(l:start, 0)
    silent! write
endfunction


function s:autofmt_tie()
    " code
endfunction


function! verilog#autoinst() range
    let l:content = []
    for l:line in getline(a:firstline, a:lastline)
        let l:space = matchstr(l:line, '\v^\s*')
        let l:module = split(trim(l:line))[0]
        let l:subcontent = systemlist('vgen autoinst '.l:module)
        if len(l:subcontent) > 3
            call map(l:subcontent, '"'.l:space.'"'.'.v:val')
            let l:content += l:subcontent + ['']
        endif
    endfor
    if !empty(l:content)
        call deletebufline(bufname(), a:firstline, a:lastline)
        call append(a:firstline-1, l:content)
        silent! write
    endif
endfunction


function! verilog#autowire()
    let l:start = search('\v^\s*/\*AUTOWIRE\*/', 'n')
    if l:start <= 0
        let l:start = line('.')
    endif
    call cursor(l:start, 0)
    let l:end = search('\v^\s*$', 'nW')
    if l:end <= 0
        return
    endif
    let l:end -= 1
    call deletebufline(bufname(), l:start, l:end)
    silent! write
    let l:content = systemlist('vgen autowire '.expand('%'))
    call append(l:start-1, l:content)
    silent! write
endfunction


function verilog#autoreg()
    let l:start = search('\v^\s*/\*AUTOREG\*/', 'n')
    if l:start <= 0
        let l:start = line('.')
    endif
    call cursor(l:start, 0)
    let l:end = search('\v^\s*$', 'nW')
    if l:end <= 0
        return
    endif
    let l:end -= 1
    call deletebufline(bufname(), l:start, l:end)
    silent! write
    let l:content = systemlist('vgen autoreg '.expand('%'))
    call append(l:start-1, l:content)
    silent! write
endfunction


function verilog#autoarg()
    let l:content = systemlist('vgen autoarg '.expand('%'))
    if len(l:content) > 1
        normal $
        let l:start = search('\v^module \w+', 'bcn')
        if l:start <= 0
            return
        endif
        call cursor(l:start, 0)
        normal 0
        let l:end = search('\v^\s*$', 'cnW')
        if l:end <= 0
            return
        endif
        let l:end -= 1
        call deletebufline(bufname(), l:start, l:end)
        call append(l:start-1, l:content)
        silent! write
    endif
endfunction



