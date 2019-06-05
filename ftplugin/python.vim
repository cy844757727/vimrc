""""""""""""""""""""""""""""""""""""""""""""""""""""
" Name:   
" Author: CY <844757727@qq.com>
""""""""""""""""""""""""""""""""""""""""""""""""""""
let s:line = getline(1)
if s:line =~# 'python3' || (s:line !~# '\v^#!'
            \ && get(get(g:, 'ENV', get(g:, 'env', {})), 'python', '') =~# 'python3')
    let b:ale_python_pylint_executable = 'pylint3'
    let b:ale_echo_msg_format = '[%linter%3] %s [%severity%]'
else
    let b:ale_python_pylint_executable = 'pylint'
    let b:ale_echo_msg_format = '[%linter%] %s [%severity%]'
endif

if exists('b:did_ftplugin_')
    finish
endif
let b:did_ftplugin_ = 1

let b:ale_linters = ['pylint', 'pyflakes']
let b:ale_fixers = ['autopep8']

setlocal tabstop=4
setlocal foldmethod=expr
setlocal foldexpr=PythonFoldLevel(v:lnum)

nnoremap <silent> <buffer> \] :call <SID>python_jump_end('normal', ']]', 'bW')<CR>
xnoremap <silent> <buffer> \] <Esc>:call <SID>python_jump_end('visual', ']]', 'bW')<CR>
nnoremap <silent> <buffer> \[ :call <SID>python_jump_end('normal', '[[', 'bW')<CR>
xnoremap <silent> <buffer> \[ <Esc>:call <SID>python_jump_end('visual', '[[', 'bW')<CR>


function! <SID>python_jump_end(mode, ex, flag)
    let l:lin = line('.')

    if a:mode ==# 'visual'
        normal! gv
    endif

    exe 'normal '.a:ex
    let l:indent = indent('.') + 1
    let l:linN = search('\v^\s{'.l:indent.',}\S', a:flag.'n')

    if l:lin == l:linN
        exe 'normal '.a:ex
        let l:indent = indent('.') + 1
        call search('\v^\s{'.l:indent.',}\S', a:flag)
    else
        exe 'normal '.l:linN.'gg'
    endif
endfunction


function! PythonFoldLevel(lnum)
    let l:lnum = a:lnum
    let l:line = getline(a:lnum)
    let l:extra = l:line =~# '\v^[^#]*:\s*(#.*)?$'

    while l:line !~ '\S' && l:lnum < line('$')
        let l:lnum += 1
        let l:line = getline(l:lnum)
    endwhile

    return indent(l:lnum) / 4 + l:extra
endfunction


function! s:ScriptRun()
    if exists('t:dbg')
        call t:dbg.sendCmd('q', '')
        return
    endif

    if executable('jupyter-console')
        let l:cmd = 'jupyter-console'
    elseif executable('ipython3')
        let l:cmd = 'ipython3'
    else
        return
    endif

    let [l:lin1, l:lin2] = mode() =~? '\vv|'."\<C-v>" ?
                \ [line('''<'), line('''>')] :
                \ [search('^#%%', 'bnW'), search('^#%%', 'nW')]

    if !l:lin2
        let l:lin2 = line('$')
    endif

    let l:lines = filter(getline(l:lin1, l:lin2), "v:val =~ '\\S'")
    let l:postCmd = join(['%%capture vim'] + l:lines + ['', ''], "\n")

    if l:lines[-1] =~# '^\s'
        let l:postCmd .= "\n"
    endif

    if exists('*misc#ToggleBottomBar')
        call misc#ToggleBottomBar('only', 'terminal')
    endif

    call term_sendkeys(async#TermToggle('on', l:cmd), l:postCmd."\n")
endfunction

let b:task = function('s:ScriptRun')
 
"let b:ale_lint_on_text_changed = 'always'
