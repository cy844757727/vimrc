" Vim color file
" Maintainer:	Cy
" Last Change:	2017-05-18

set background=dark
"hi clear
set t_Co=256
let g:colors_name = "cydark"

" Basic highlight
hi Normal ctermfg=230 guifg=#DDDDC0 guibg=#1E1E1E

hi Error ctermfg=256 ctermbg=160 cterm=NONE guifg=#FFFFFF guibg=#DB0000 gui=NONE
hi ErrorMsg ctermfg=256 ctermbg=160 guifg=#FFFFFF guibg=#DB0000
hi WarningMsg ctermfg=13 ctermbg=220 guifg=#FEFEFE guibg=#FE8D00
hi Search ctermfg=232 ctermbg=208 guifg=#080707 guibg=#FE8D00
hi IncSearch ctermfg=232 ctermbg=208 guifg=#080707 guibg=#FE8D00

hi TabLine ctermfg=232 ctermbg=247 cterm=NONE guifg=#BBBBA0 guibg=#555555 gui=NONE
hi TabLinesel ctermfg=232 ctermbg=253 cterm=Bold guifg=#BBBBA0 guibg=#1E1E1E gui=bold
hi TabLineFill ctermfg=NONE ctermbg=NONE cterm=NONE guibg=NONE
hi TabLineSeparator guibg=#555555 guifg=#1E1E1E

" misc
hi Todo cterm=bold guibg=#FFD00A guifg=#000000 gui=bold
hi NonText guifg=#1E1E1E
hi Question guifg=#FEFEFE
hi SignColumn ctermbg=234 guibg=#1E1E1E
hi Directory guifg=#88dcdc
hi Visual ctermfg=232 ctermbg=253 guifg=NONE guibg=#264F78
hi LineNr ctermfg=242 ctermbg=NONE guifg=#5E6165
hi QuickFixLine cterm=bold,italic guifg=NONE guibg=NONE

hi CursorLine ctermfg=NONE ctermbg=235 cterm=NONE guifg=NONE guibg=#232323
hi CursorLineNr ctermfg=242 ctermbg=NONE cterm=NONE guifg=#6E6E6E guibg=NONE
hi VertSplit ctermfg=253 ctermbg=253 guifg=#333333 guibg=#333333
hi StatusLine ctermfg=16 ctermbg=253 cterm=NONE guifg=#FFFFFF guibg=#007ACC
hi StatusLineNC ctermfg=16 ctermbg=252 cterm=bold guifg=#BBBBA0 guibg=#333333

hi DiffAdd ctermfg=230 ctermbg=65 guifg=#FFFFDD guibg=#618A61
hi DiffChange ctermfg=230 ctermbg=24 guifg=#FFFFDD guibg=#00608B
hi DiffDelete ctermfg=230 ctermbg=95 guifg=#FFFFDD guibg=#8B6161
hi DiffText ctermfg=230 ctermbg=239 guifg=#FFFFDD guibg=#4F4F4F

hi PMenu ctermfg=253 ctermbg=237 guifg=#DEDEDE guibg=#3A3A3A
hi PMenuSel ctermfg=232 ctermbg=250 guifg=#080707 guibg=#C0C0C0
hi PMenuSbar ctermfg=NONE ctermbg=239 guifg=NONE guibg=#4A4A4A
hi PMenuThumb ctermfg=NONE ctermbg=250 guifg=NONE guibg=#C0C0C0

hi Folded ctermfg=222 ctermbg=232 guifg=#FDE28C guibg=#090808
hi FoldColumn ctermfg=223 ctermbg=232 guifg=#FDE28C guibg=#090808

" Language highlight
hi PreProc ctermfg=176 guifg=#DD94F3
hi Type ctermfg=75 cterm=NONE guifg=#5FAEEC "#5EAFFF gui=NONE
hi Number ctermfg=208 guifg=#FE8D00
hi Identifier ctermfg=75 cterm=NONE guifg=#5EAFFF gui=NONE
hi Constant ctermfg=208 guifg=#FE8D00
hi Special ctermfg=208 guifg=#FE8D00
hi Comment ctermfg=76 cterm=italic guifg=#44b000 gui=italic
hi Statement ctermfg=220 guifg=#FFE502
hi String ctermfg=215 guifg=#FEB862
hi Character ctermfg=215 guifg=#FEB862
hi Operator ctermfg=230 guifg=#FFFFDD

" BMBPSign
hi NormalSign  ctermbg=253 ctermfg=16 guifg=#FFFFFF guibg=#1E1E1E
" ale.vim
hi ALEErrorSign    ctermfg=9    ctermbg=234 guifg=#FF361E guibg=#1E1E1E
hi ALEWarningSign  ctermfg=215  ctermbg=234 guifg=#FEB862 guibg=#1E1E1E