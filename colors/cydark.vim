" Vim color file
" Maintainer:	Cy
" Last Change:	2017-05-18

set background=dark
"hi clear
set t_Co=256
let g:colors_name = "cydark"

" === Basic highlight ===
hi Normal ctermfg=230 guifg=#D5D5CA guibg=#1E1E1E

" Msg & Tip
hi Error ctermfg=256 ctermbg=160 cterm=NONE guifg=#EEEED0 guibg=#D73130 gui=NONE
hi ErrorMsg ctermfg=256 ctermbg=160 guifg=#FFFFFF guibg=#B53030
hi WarningMsg ctermfg=13 ctermbg=220 guifg=#FFFFFF guibg=#905510
hi Question cterm=NONE guifg=#000000 guibg=#D5D5CA
hi MoreMsg cterm=NONE guifg=#60b030
hi Search ctermfg=232 ctermbg=208 guifg=#1E1E1E guibg=#D97820
hi IncSearch ctermfg=232 ctermbg=208 guifg=#101010 guibg=#D96800
hi Todo cterm=bold guibg=#DDD000 guifg=#000000 gui=bold

" === TabLine ===
hi TabLine ctermfg=232 ctermbg=247 cterm=NONE guifg=#D0D0C0 guibg=#555555 gui=NONE
hi TabLinesel ctermfg=232 ctermbg=253 cterm=Bold guifg=#C5C5BA guibg=#1E1E1E gui=bold
hi TabLineFill ctermfg=NONE ctermbg=NONE cterm=NONE guibg=NONE
hi TabLineSeparator guibg=#555555 guifg=#1E1E1E
hi TabLineSeparatorPre guibg=#1E1E1E guifg=#555555

" === misc ===
hi MatchParen cterm=NONE guifg=#CCCCB5 guibg=#007FAF
hi SpellBad cterm=underline ctermbg=NONE guibg=NONE
hi NonText guifg=#CCCCB5
hi EndOfBuffer guifg=#1E1E1E
hi SignColumn ctermbg=234 guibg=#1E1E1E
hi Directory guifg=#70D0D0
hi Visual ctermfg=232 ctermbg=253 guifg=NONE guibg=#264F78
hi LineNr ctermfg=242 ctermbg=NONE guifg=#5E6165
hi QuickFixLine cterm=bold,italic guifg=NONE guibg=NONE

" === separator ... ===
hi CursorLine ctermfg=NONE ctermbg=23509ABA5 cterm=NONE guifg=NONE guibg=#232323
hi CursorLineNr ctermfg=242 ctermbg=NONE cterm=NONE guifg=#5E6165 guibg=NONE
hi VertSplit ctermfg=253 ctermbg=253 guifg=#333333 guibg=#333333
hi StatusLine ctermfg=16 ctermbg=253 cterm=NONE guifg=#FFFFFF guibg=#006999
hi StatusLineInsert ctermfg=16 ctermbg=253 cterm=NONE guifg=#FFFFFF guibg=#6D0EF2
hi StatusLineNC ctermfg=16 ctermbg=252 cterm=bold guifg=#D5D5CF guibg=#333333
"hi StatusLineTerm
"hi StatusLineTermNC

" === Diff mode ===
hi DiffAdd ctermfg=230 ctermbg=65 guifg=NONE guibg=#192920
hi DiffChange ctermfg=230 ctermbg=24 guifg=NONE guibg=#203045
hi DiffDelete ctermfg=230 ctermbg=95 guifg=#4F2525 guibg=#4F2525
hi DiffText ctermfg=230 ctermbg=2392 cterm=NONE guifg=NONE guibg=#1A1919

" === Popup menu ui ===
hi PMenu ctermfg=253 ctermbg=237 guifg=#CCCCB5 guibg=#333333
hi PMenuSel ctermfg=232 ctermbg=250 cterm=bold guifg=#1E1E1E guibg=#CCCCB5
hi PMenuSbar ctermfg=NONE ctermbg=239 guifg=NONE guibg=#333333
hi PMenuThumb ctermfg=NONE ctermbg=250 guifg=NONE guibg=#AAAA95

" === Code folding ===
hi Folded ctermfg=222 ctermbg=232 guifg=#CFB55F guibg=#161515
hi FoldColumn ctermfg=223 ctermbg=232 guifg=#CFB55F guibg=#161515

" === Language highlight ===
hi PreProc ctermfg=176 guifg=#EF96FF
hi Type ctermfg=75 cterm=NONE guifg=#40BFFF
hi Number ctermfg=208 guifg=#F58440
hi Identifier ctermfg=75 cterm=NONE guifg=#6AC5FF gui=NONE
hi Constant ctermfg=208 guifg=#F58440
hi Special ctermfg=208 guifg=#F58440
hi Comment ctermfg=76 cterm=italic guifg=#60B030 gui=italic
hi Statement ctermfg=220 guifg=#F0C03A
hi String ctermfg=215 guifg=#FAC070
hi link Character String
hi Operator ctermfg=230 cterm=bold guifg=#D0F0D0

" === BMBPSign.vim ===
hi NormalSign  ctermbg=253 ctermfg=16 guibg=#1E1E1E guifg=#CCCCB0
hi BreakPoint  ctermbg=253 ctermfg=16 guibg=#1E1E1E guifg=#D73130

" === ale.vim ===
hi ALEError        ctermfg=NONE ctermbg=234 guifg=#1E1E1E guibg=#E44442
hi ALEErrorSign    ctermfg=9    ctermbg=234 guifg=#E44442 guibg=#1E1E1E
hi ALEWarningSign  ctermfg=215  ctermbg=234 guifg=#CEB107 guibg=#1E1E1E
hi link ALEWarning Normal