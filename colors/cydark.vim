" Vim color file
" Maintainer:	Cy
" Last Change:	2017-05-18

set background=dark
"hi clear
set t_Co=256
let g:colors_name = "cydark"

" === Basic highlight ===
hi Normal ctermfg=230 guifg=#CCCCB0 guibg=#1E1E1E

hi Error ctermfg=256 ctermbg=160 cterm=NONE guifg=#EEEED0 guibg=#D73130 gui=NONE
hi ErrorMsg ctermfg=256 ctermbg=160 guifg=#EEEED0 guibg=#B02525
hi WarningMsg ctermfg=13 ctermbg=220 guifg=#EEEED0 guibg=#834000
hi Search ctermfg=232 ctermbg=208 guifg=#101010 guibg=#D96800
hi IncSearch ctermfg=232 ctermbg=208 guifg=#101010 guibg=#D96800

" === TabLine ===
hi TabLine ctermfg=232 ctermbg=247 cterm=NONE guifg=#BBBBA0 guibg=#555555 gui=NONE
hi TabLinesel ctermfg=232 ctermbg=253 cterm=Bold guifg=#BBBBA0 guibg=#1E1E1E gui=bold
hi TabLineFill ctermfg=NONE ctermbg=NONE cterm=NONE guibg=NONE
hi TabLineSeparator guibg=#555555 guifg=#1E1E1E
hi TabLineSeparatorPre guibg=#1E1E1E guifg=#555555

" === misc ===
hi SpellBad cterm=underline ctermbg=NONE guibg=NONE
hi Todo cterm=bold guibg=#FFD00A guifg=#000000 gui=bold
hi NonText guifg=#1E1E1E
hi Question cterm=NONE guifg=#000000 guibg=#BBBBA0
"hi MoreMsg cterm=NONE guifg=#000000 guibg=#BBBBA0
hi SignColumn ctermbg=234 guibg=#1E1E1E
hi Directory guifg=#70C7C7
hi Visual ctermfg=232 ctermbg=253 guifg=NONE guibg=#264F78
hi LineNr ctermfg=242 ctermbg=NONE guifg=#5E6165
hi QuickFixLine cterm=bold,italic guifg=NONE guibg=NONE

" === separator ... ===
hi CursorLine ctermfg=NONE ctermbg=235 cterm=NONE guifg=NONE guibg=#232323
hi CursorLineNr ctermfg=242 ctermbg=NONE cterm=NONE guifg=#5E6165 guibg=NONE
hi VertSplit ctermfg=253 ctermbg=253 guifg=#333333 guibg=#333333
hi StatusLine ctermfg=16 ctermbg=253 cterm=NONE guifg=#FFFFFF guibg=#006999
hi StatusLineNormal ctermfg=16 ctermbg=253 cterm=NONE guifg=#FFFFFF guibg=#006999
hi StatusLineInsert ctermfg=16 ctermbg=253 cterm=NONE guifg=#FFFFFF guibg=#6D0EF2
hi StatusLineNC ctermfg=16 ctermbg=252 cterm=bold guifg=#BBBBA0 guibg=#333333

" === Diff mode ===
hi DiffAdd ctermfg=230 ctermbg=65 guifg=NONE guibg=#192920
hi DiffChange ctermfg=230 ctermbg=24 guifg=NONE guibg=#20304F
hi DiffDelete ctermfg=230 ctermbg=95 guifg=#4F2525 guibg=#4F2525
hi DiffText ctermfg=230 ctermbg=239 cterm=NONE guifg=NONE guibg=#161515

" === Popup menu ui ===
hi PMenu ctermfg=253 ctermbg=237 guifg=#CCCCB0 guibg=#333333
hi PMenuSel ctermfg=232 ctermbg=250 cterm=bold guifg=#1E1E1E guibg=#BBBBA0
hi PMenuSbar ctermfg=NONE ctermbg=239 guifg=NONE guibg=#333333
hi PMenuThumb ctermfg=NONE ctermbg=250 guifg=NONE guibg=#BBBBA0

" === Code folding ===
hi Folded ctermfg=222 ctermbg=232 guifg=#CFB55F guibg=#161515
hi FoldColumn ctermfg=223 ctermbg=232 guifg=#CFB55F guibg=#161515

" === Language highlight ===
hi PreProc ctermfg=176 guifg=#C980E0
hi Type ctermfg=75 cterm=NONE guifg=#5FAEEC
hi Number ctermfg=208 guifg=#FE8D00
hi Identifier ctermfg=75 cterm=NONE guifg=#5EAFFF gui=NONE
hi Constant ctermfg=208 guifg=#FE8D00
hi Special ctermfg=208 guifg=#FE8D00
hi Comment ctermfg=76 cterm=italic guifg=#44A000 gui=italic
hi Statement ctermfg=220 guifg=#E0C000
hi String ctermfg=215 guifg=#FEB862
hi Character ctermfg=215 guifg=#FEB862
hi Operator ctermfg=230 guifg=#FFFFDD

" === BMBPSign.vim ===
hi NormalSign  ctermbg=253 ctermfg=16 guibg=#1E1E1E guifg=#CCCCB0
hi BreakPoint  ctermbg=253 ctermfg=16 guibg=#1E1E1E guifg=#D73130

" === ale.vim ===
hi ALEError        ctermfg=NONE ctermbg=234 guifg=NONE    guibg=#D73130
hi ALEErrorSign    ctermfg=9    ctermbg=234 guifg=#D73130 guibg=#1E1E1E
hi link ALEWarning Normal
hi ALEWarningSign  ctermfg=215  ctermbg=234 guifg=#C99C27 guibg=#1E1E1E
