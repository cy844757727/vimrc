" Vim color file
" Maintainer:	Cy
" Last Change:	2017-05-18

set background=dark
"hi clear
set t_Co=256
let g:colors_name = "cydark"

" Basic highlight
hi Normal          ctermfg=230  guifg=#F4F4D4 guibg=#232629
" ctermbg=235  cterm=NONE
hi Error ctermfg=256 ctermbg=160 cterm=NONE guifg=#FFFFFF guibg=#DB0000 gui=NONE
hi ErrorMsg ctermfg=256 ctermbg=160 guifg=#FFFFFF guibg=#DB0000
hi WarningMsg ctermfg=13 ctermbg=220 guifg=#FF54FE guibg=#FFD700
hi Search ctermfg=232 ctermbg=208 guifg=#080707 guibg=#FE8D00
hi IncSearch ctermfg=232 ctermbg=208 guifg=#080707 guibg=#FE8D00

hi TabLine ctermfg=232 ctermbg=247 cterm=NONE guifg=#000000 guibg=#A2A2A2 gui=NONE
hi TabLinesel ctermfg=232 ctermbg=253 cterm=Bold guifg=#000000 guibg=#E0E0E0 gui=bold
hi TabLineFill ctermfg=NONE ctermbg=NONE cterm=NONE

hi NonText guifg=#232629
hi Question guifg=#DF7107
hi SignColumn ctermbg=234 guibg=#232629
hi Visual ctermfg=232 ctermbg=253 guifg=#FEFEFE guibg=#2D5C76
hi VertSplit ctermfg=253 ctermbg=253 guifg=#AAAAAA guibg=#AAAAAA
hi LineNr ctermfg=242 ctermbg=NONE guifg=#6E6E6E
hi CursorLine ctermfg=NONE ctermbg=235 cterm=NONE guifg=NONE guibg=#2A2E32 gui=NONE
hi CursorLineNr ctermfg=242 ctermbg=235 guifg=#6E6E6E guibg=#2A2E32
hi StatusLine ctermfg=16 ctermbg=253 cterm=bold guifg=#000000 guibg=#AAAAAA gui=bold
hi StatusLineNC ctermfg=16 ctermbg=252 cterm=NONE guifg=#000000 guibg=#AAAAAA gui=NONE

hi DiffAdd ctermfg=230 ctermbg=65 guifg=#FFFFDD guibg=#618A61
hi DiffChange ctermfg=230 ctermbg=24 guifg=#FFFFDD guibg=#00608B
hi DiffDelete ctermfg=230 ctermbg=95 guifg=#FFFFDD guibg=#8B6161
hi DiffText ctermfg=230 ctermbg=239 guifg=#FFFFDD guibg=#4F4F4F

hi PMenu ctermfg=253 ctermbg=237 guifg=#DEDEDE guibg=#3A3A3A
hi PMenuSel ctermfg=232 ctermbg=250 guifg=#080707 guibg=#C0C0C0
hi PMenuSbar ctermfg=NONE ctermbg=239 guifg=NONE guibg=#4A4A4A
hi PMenuThumb ctermfg=NONE ctermbg=250 guifg=NONE guibg=#C0C0C0

hi Folded ctermfg=222 ctermbg=232 guifg=#FEE38D guibg=#080707
hi FoldColumn ctermfg=223 ctermbg=232 guifg=#FEE3B8 guibg=#080707

" Language highlight
hi PreProc ctermfg=176 guifg=#E58EE5
hi Type ctermfg=75 cterm=NONE guifg=#5EAFFF gui=NONE
hi Number ctermfg=208 guifg=#FE8D00
hi Identifier ctermfg=75 cterm=NONE guifg=#5EAFFF gui=NONE
hi Constant ctermfg=208 guifg=#FE8D00
hi Special ctermfg=208 guifg=#FE8D00
hi Comment ctermfg=76 guifg=#5FDA00
hi Statement ctermfg=220 cterm=NONE guifg=#FFE600
hi String ctermfg=215 guifg=#FFB961
hi Character ctermfg=215 guifg=#FEB862
hi Operator ctermfg=230 guifg=#FFFFDD

" ale.vim
hi ALEErrorSign    ctermfg=9    ctermbg=234 guifg=#FF361E guibg=#232629
hi ALEWarningSign  ctermfg=215  ctermbg=234 guifg=#FEB862 guibg=#232629

