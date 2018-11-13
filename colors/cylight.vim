" Vim color file
" Maintainer:	Cy
" Last Change:	2017-05-18

set background=light
"hi clear
set t_Co=256
let g:colors_name = "light"

" Basic highlight
hi Normal           guifg=#000000  guibg=#FBFCFD  gui=none cterm=NONE
hi Error            ctermfg=254  ctermbg=160  cterm=NONE
hi ErrorMsg         ctermfg=254  ctermbg=160  cterm=NONE
hi WarningMsg       ctermfg=254  ctermbg=160  cterm=NONE
hi Search           ctermfg=232  ctermbg=208  cterm=NONE
hi IncSearch        ctermfg=232  ctermbg=208  cterm=NONE

hi TabLine          ctermfg=232  ctermbg=247  cterm=NONE
hi TabLinesel       ctermfg=232  ctermbg=254  cterm=Bold
hi TabLineFill      ctermfg=NONE ctermbg=247  cterm=NONE
hi SignColumn       guibg=#FBFCFD guifg=#FBFCFD
hi Visual           ctermfg=254  ctermbg=242  cterm=NONE
hi VertSplit        guifg=#CCCCCC guibg=#CCCCCC ctermfg=254  ctermbg=254  cterm=NONE
hi CursorLine       guibg=#dbdcdd  ctermfg=NONE ctermbg=252  cterm=NONE
hi LineNr           ctermfg=245  ctermbg=NONE cterm=NONE
hi CursorLineNr     ctermfg=237  ctermbg=NONE cterm=NONE
hi StatusLine       guifg=#9ec6e5 guibg=#000000 ctermfg=232  ctermbg=254  cterm=bold
hi StatusLineNC     guifg=#E9EEF1 guibg=#000000 ctermfg=232  ctermbg=254  cterm=NONE

hi DiffAdd          ctermfg=230  ctermbg=65   cterm=NONE
hi DiffChange       ctermfg=230  ctermbg=24   cterm=NONE
hi DiffDelete       ctermfg=230  ctermbg=95   cterm=NONE
hi DiffText         ctermfg=230  ctermbg=239  cterm=NONE

" Language highlight
hi PreProc          gui=none  ctermfg=176  ctermbg=NONE cterm=NONE
hi Type             guifg=#800000  gui=none  ctermfg=124   ctermbg=NONE cterm=NONE
hi Number           guifg=#104270  gui=none  ctermfg=232  ctermbg=NONE cterm=NONE
hi Identifier       gui=none  ctermfg=254  ctermbg=NONE cterm=NONE
hi Constant         guifg=#b02020  gui=none  ctermfg=208  ctermbg=NONE cterm=NONE
hi Special          guifg=#ba00ba  gui=none  ctermfg=208  ctermbg=NONE cterm=NONE
hi Comment          guifg=#208700  gui=none  ctermfg=28  ctermbg=NONE cterm=NONE
hi Statement        guifg=#1919ec  gui=none  ctermfg=18  ctermbg=NONE cterm=NONE
hi String           guifg=#b02020  gui=none  ctermfg=124  ctermbg=NONE cterm=NONE
hi Character        guifg=#b02020  gui=none  ctermfg=180  ctermbg=NONE cterm=NONE


