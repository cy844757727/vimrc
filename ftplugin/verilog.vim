""""""""""""""""""""""""""""""""""""""""""""""
" File: sign.vim
" Author: Cy <844757727@qq.com>
" Description: verilog auto-cmd
""""""""""""""""""""""""""""""""""""""""""""""

if exists('b:did_ftplugin')
    finish
endif
let b:did_ftplugin = 1


nnoremap <buffer> <silent> \vf :call verilog#autofmt()<CR>
nnoremap <buffer> <silent> \vi :call verilog#autoinst()<CR>
vnoremap <buffer> <silent> \vi :call verilog#autoinst()<CR>
nnoremap <buffer> <silent> \vw :call verilog#autowire()<CR>
nnoremap <buffer> <silent> \vr :call verilog#autoreg()<CR>
nnoremap <buffer> <silent> \va :call verilog#autoarg()<CR>

