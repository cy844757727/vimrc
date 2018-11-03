""""""""""""""""""""""""""""""""""""""""""""""""""""
" Name:   HDL_Verilog
" Author: CY <844757727@qq.com>
""""""""""""""""""""""""""""""""""""""""""""""""""""
if getline(1) =~ 'python3'
    let b:ale_python_pylint_executable = 'pylint3'
    let b:ale_echo_msg_format = '[%linter%3] %s [%severity%]'
else
    let b:ale_echo_msg_format = '[%linter%] %s [%severity%]'
    let b:ale_python_pylint_executable = 'pylint'
endif

if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1

" Fix Python files with autopep8
let b:ale_fixers = ['autopep8']

