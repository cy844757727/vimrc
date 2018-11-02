""""""""""""""""""""""""""""""""""""""""""""""""""""
" Name:   HDL_Verilog
" Author: CY <844757727@qq.com>
""""""""""""""""""""""""""""""""""""""""""""""""""""
if getline(1) =~ 'python3'
    let b:ale_linters = ['pylint', 'flake8']
    let b:ale_python_pylint_executable = 'pylint3'
    let b:ale_echo_msg_format = '[%linter%3] %s [%severity%]'
    let b:ale_python_pylint_options = g:ale_python_pylint_options . ' --disable=E'
else
    let b:ale_linters = ['pylint']
    let b:ale_echo_msg_format = '[%linter%] %s [%severity%]'
    let b:ale_python_pylint_executable = 'pylint'
    let b:ale_python_pylint_options = g:ale_python_pylint_options
endif

if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1

" Check Python files with pylint.
"let b:ale_linters = ['pylint']
" Fix Python files with autopep8
let b:ale_fixers = ['autopep8']

"let b:ale_lint_delay = 20
"let b:ale_fix_on_save = 1
