""""""""""""""""""""""""""""""""""""""""""""""""""""
" Name:   
" Author: CY <844757727@qq.com>
""""""""""""""""""""""""""""""""""""""""""""""""""""
if exists('b:did_ftplugin_')
    finish
endif

let b:did_ftplugin_ = 1

if getline(1) =~ 'python3'
    let b:ale_python_pylint_executable = 'pylint3'
    let b:ale_echo_msg_format = '[%linter%3] %s [%severity%]'
else
    let b:ale_python_pylint_executable = 'pylint'
    let b:ale_echo_msg_format = '[%linter%] %s [%severity%]'
endif

let b:ale_linters = ['pylint', 'pyflakes']
let b:ale_fixers = ['autopep8']

setlocal foldmethod=indent

function! s:ScriptRun()
    if exists('t:dbg')
        call t:dbg.sendCmd('q', '')
        return
    endif

    if empty(visualmode())
        return
    endif

    if executable('jupyter-console')
        let l:cmd = 'jupyter-console'
    elseif executable('ipython3')
        let l:cmd = 'ipython3'
    else
        return
    endif

    let l:lines = filter(getline(line('''<'), line('''>')), "v:val =~ '\\S'")
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
" 
"let b:ale_lint_on_text_changed = 'always'
