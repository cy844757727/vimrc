""""""""""""""""""""""""""""""""""""""""""""""""""""
" Name:   HDL_Verilog
" Author: CY <844757727@qq.com>
""""""""""""""""""""""""""""""""""""""""""""""""""""
if getline(1) =~ 'python3'
    let b:ale_python_pylint_executable = 'pylint3'
    let b:ale_echo_msg_format = '[%linter%3] %s [%severity%]'
else
    let b:ale_python_pylint_executable = 'pylint'
    let b:ale_echo_msg_format = '[%linter%] %s [%severity%]'
endif

if exists("b:did_ftplugin_")
    finish
endif
let b:did_ftplugin_ = 1

let b:ale_linters = ['pylint', 'pyflakes']
let b:ale_fixers = ['autopep8']

set foldmethod=indent
" 
"let b:ale_lint_on_text_changed = 'always'
