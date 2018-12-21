" Vim color file
" Maintainer:	Cy
" Last Change:	2017-05-18

set background=dark
"hi clear
set t_Co=256
let g:colors_name = "cydark"

" === Basic highlight ===
hi Normal cterm=NONE ctermfg=230 guifg=#DADACF guibg=#1E1E1E gui=NONE

" Msg & Tip
hi Error ctermfg=256 ctermbg=160 cterm=NONE guifg=#FFFFFF guibg=#D73130 gui=NONE
hi ErrorMsg ctermfg=256 ctermbg=160 guifg=#FFFFFF guibg=#B53030 gui=NONE
hi WarningMsg ctermfg=13 ctermbg=220 guifg=#FFFFFF guibg=#905510 gui=NONE
hi Question cterm=NONE guifg=#000000 guibg=#D5D5CA gui=NONE
hi MoreMsg cterm=NONE guifg=#60b030 gui=NONE
hi Search ctermfg=232 ctermbg=208 guifg=#1E1E1E guibg=#D97820 gui=NONE
hi IncSearch ctermfg=232 ctermbg=208 guifg=#101010 guibg=#D96800 gui=NONE
hi Todo cterm=bold guibg=#DDD000 guifg=#000000 gui=bold

" === TabLine ===
hi TabLine ctermfg=232 ctermbg=247 cterm=NONE guifg=#DDDDCF guibg=#444444 gui=NONE
hi TabLinesel ctermfg=232 ctermbg=253 cterm=Bold guifg=#D5D5CF guibg=#1E1E1E gui=bold
hi TabLineFill ctermfg=NONE ctermbg=NONE cterm=NONE guibg=NONE
hi TabLineSeparator guibg=#444444 guifg=#1E1E1E gui=NONE
hi TabLineSeparatorPre guibg=#1E1E1E guifg=#444444 gui=NONE

" === misc ===
hi MatchParen cterm=NONE guifg=#CCCCB5 guibg=#007FAF gui=NONE
hi SpellBad cterm=underline ctermbg=NONE guibg=NONE
hi NonText guifg=#CCCCB5 gui=NONE
hi EndOfBuffer guifg=#1E1E1E gui=NONE
hi SignColumn ctermbg=234 guibg=#1E1E1E gui=NONE
hi Directory guifg=#6ADADA gui=NONE
hi Visual ctermfg=232 ctermbg=253 guifg=NONE guibg=#353535 gui=NONE
hi LineNr ctermfg=242 ctermbg=NONE guifg=#5E6165 gui=NONE
hi QuickFixLine cterm=bold,italic gui=bold,italic

hi link TagbarSignature Directory

" === separator ... ===
hi CursorLine ctermfg=NONE ctermbg=23509ABA5 cterm=NONE guifg=NONE guibg=#232323 gui=NONE
hi CursorLineNr ctermfg=242 ctermbg=NONE cterm=NONE guifg=#5E6165 guibg=NONE gui=NONE
hi VertSplit ctermfg=253 ctermbg=253 guifg=#333333 guibg=#333333 gui=NONE
hi StatusLine ctermfg=16 ctermbg=253 cterm=NONE guifg=#FFFFFF guibg=#006999 gui=NONE
hi StatusLineInsert ctermfg=16 ctermbg=253 cterm=NONE guifg=#FFFFFF guibg=#6D0EF2 gui=NONE
hi StatusLineNC ctermfg=16 ctermbg=252 cterm=bold guifg=#D5D5CF guibg=#333333 gui=bold
"hi StatusLineTerm
"hi StatusLineTermNC

" === Diff mode ===
hi DiffAdd ctermfg=230 ctermbg=65 guifg=NONE guibg=#192920 gui=NONE
hi DiffChange ctermfg=230 ctermbg=24 guifg=NONE guibg=#203045 gui=NONE
hi DiffDelete ctermfg=230 ctermbg=95 guifg=#4F2525 guibg=#4F2525 gui=NONE
hi DiffText ctermfg=230 ctermbg=2392 cterm=NONE guifg=NONE guibg=#1A1919 gui=NONE

" === Popup menu ui ===
hi PMenu ctermfg=253 ctermbg=237 guifg=#CCCCB5 guibg=#333333 gui=NONE
hi PMenuSel ctermfg=232 ctermbg=250 cterm=bold guifg=#1E1E1E guibg=#CCCCB5 gui=bold
hi PMenuSbar ctermfg=NONE ctermbg=239 guifg=NONE guibg=#333333 gui=NONE
hi PMenuThumb ctermfg=NONE ctermbg=250 guifg=NONE guibg=#AAAA95 gui=NONE

" === Code folding ===
hi Folded ctermfg=222 ctermbg=232 guifg=#CFB55F guibg=#161515 gui=NONE
hi FoldColumn ctermfg=223 ctermbg=232 guifg=#CFB55F guibg=#161515 gui=NONE

" === Language highlight ===
hi PreProc ctermfg=176 guifg=#EE95F5 gui=NONE
hi Type ctermfg=75 cterm=NONE guifg=#40BFFF gui=NONE
hi Number ctermfg=208 guifg=#FA8525 gui=NONE
hi Identifier ctermfg=75 cterm=NONE guifg=#5DBDFC gui=NONE
hi Constant ctermfg=208 guifg=#F58440 gui=NONE
hi Special ctermfg=208 guifg=#F58440 gui=NONE
hi Comment ctermfg=76 cterm=italic guifg=#458520 gui=italic
hi Statement ctermfg=220 guifg=#F2C732 gui=NONE
hi String ctermfg=215 guifg=#F6BB6B gui=NONE
hi link Character String
hi Operator ctermfg=230 cterm=bold guifg=#D0F0D0 gui=bold

" === BMBPSign.vim ===
hi NormalSign  ctermbg=253 ctermfg=16 guibg=#1E1E1E guifg=#CCCCB0 gui=NONE
hi BreakPoint  ctermbg=253 ctermfg=16 guibg=#1E1E1E guifg=#D73130 gui=NONE

" === ale.vim ===
hi ALEError        ctermfg=NONE ctermbg=234 guifg=#EEEED0 guibg=#D73130 gui=NONE
hi ALEErrorSign    ctermfg=9    ctermbg=234 guifg=#E44442 guibg=#1E1E1E gui=NONE
hi ALEWarningSign  ctermfg=215  ctermbg=234 guifg=#CEB107 guibg=#1E1E1E gui=NONE
hi link ALEWarning Normal
