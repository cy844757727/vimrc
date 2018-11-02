""""""""""""""""""""""""""""""""""""""""""""""""""""
" Name:   HDL_Verilog
" Author: CY <844757727@qq.com>
""""""""""""""""""""""""""""""""""""""""""""""""""""
if getline('.') =~ 'python3'
    let g:ale_python_pylint_executable = 'pylint3'
    let b:ale_echo_msg_format = '[%linter%3] %s [%severity%]'
else
    let b:ale_echo_msg_format = '[%linter%] %s [%severity%]'
    let g:ale_python_pylint_executable = 'pylint'
endif

if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1

" Check Python files with flake8 and pylint.
let b:ale_linters = ['pylint']
" Fix Python files with autopep8 and yapf.
let b:ale_fixers = ['autopep8']

let b:ale_lint_delay = 20
"let b:ale_fix_on_save = 1
