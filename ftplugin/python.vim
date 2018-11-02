""""""""""""""""""""""""""""""""""""""""""""""""""""
" Name:   HDL_Verilog
" Author: CY <844757727@qq.com>
""""""""""""""""""""""""""""""""""""""""""""""""""""
if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1

" Check Python files with flake8 and pylint.
let b:ale_linters = ['pylint']
" Fix Python files with autopep8 and yapf.
let b:ale_fixers = ['autopep8', 'trim_whitespace']

"let b:ale_fix_on_save = 1
