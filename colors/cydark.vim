" Vim color file
" Maintainer:	Cy
" Last Change:	2017-05-18

set background=dark
"hi clear
set t_Co=256
let g:colors_name = "cydark"

" Basic highlight
hi Normal           ctermfg=230
" ctermbg=235  cterm=NONE
hi Error            ctermfg=256  ctermbg=160  cterm=NONE
hi ErrorMsg         ctermfg=256  ctermbg=160  cterm=NONE
hi WarningMsg       ctermfg=13  ctermbg=220  cterm=NONE
hi Search           ctermfg=232  ctermbg=208  cterm=NONE
hi IncSearch        ctermfg=232  ctermbg=208  cterm=NONE

hi TabLine          ctermfg=232  ctermbg=247  cterm=NONE
hi TabLinesel       ctermfg=232  ctermbg=253  cterm=Bold
hi TabLineFill      ctermfg=NONE ctermbg=NONE cterm=NONE

hi SignColumn       ctermbg=234
hi Visual           ctermfg=232  ctermbg=253  cterm=NONE
hi VertSplit        ctermfg=253  ctermbg=253  cterm=NONE
hi LineNr           ctermfg=242  ctermbg=NONE cterm=NONE
hi CursorLine       ctermfg=NONE ctermbg=235  cterm=NONE
hi CursorLineNr     ctermfg=242  ctermbg=235 cterm=NONE
hi StatusLine       ctermfg=16  ctermbg=253  cterm=bold
hi StatusLineNC     ctermfg=16  ctermbg=252  cterm=NONE

hi DiffAdd          ctermfg=230  ctermbg=65   cterm=NONE
hi DiffChange       ctermfg=230  ctermbg=24   cterm=NONE
hi DiffDelete       ctermfg=230  ctermbg=95   cterm=NONE
hi DiffText         ctermfg=230  ctermbg=239  cterm=NONE

hi PMenu            ctermfg=253  ctermbg=237  cterm=NONE
hi PMenuSel         ctermfg=232  ctermbg=250  cterm=NONE
hi PMenuSbar        ctermfg=NONE ctermbg=239  cterm=NONE
hi PMenuThumb       ctermfg=NONE ctermbg=250  cterm=NONE

hi Folded           ctermfg=222  ctermbg=232
hi FoldColumn       ctermfg=223  ctermbg=232

" Language highlight
hi PreProc          ctermfg=176  ctermbg=NONE cterm=NONE
hi Type             ctermfg=75   ctermbg=NONE cterm=NONE
hi Number           ctermfg=208  ctermbg=NONE cterm=NONE
hi Identifier       ctermfg=75  ctermbg=NONE cterm=NONE
hi Constant         ctermfg=208  ctermbg=NONE cterm=NONE
hi Special          ctermfg=208  ctermbg=NONE cterm=NONE
hi Comment          ctermfg=76  ctermbg=NONE cterm=NONE
hi Statement        ctermfg=220  ctermbg=NONE cterm=NONE
hi String           ctermfg=215  ctermbg=NONE cterm=NONE
hi Character        ctermfg=215  ctermbg=NONE cterm=NONE
hi Operator         ctermfg=230  ctermbg=NONE cterm=NONE

" ale.vim
hi ALEErrorSign     ctermfg=9    ctermbg=234
hi ALEWarningSign   ctermfg=220  ctermbg=234

