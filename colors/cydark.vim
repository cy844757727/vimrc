" Vim color file
" Maintainer:	Cy
" Last Change:	2017-05-18

set background=dark
"hi clear
set t_Co=256
let g:colors_name = "cydark"

let g:colors_NormalMode = '#105070'
let g:colors_InsertMode = '#6D0EF2'

" === Basic highlight ===
hi Normal cterm=NONE ctermfg=230 guifg=#C0C0BA guibg=#202020 gui=NONE

" Msg & Tip
hi Error ctermfg=256 ctermbg=160 cterm=NONE guifg=#FFFFFF guibg=#D73130 gui=NONE
hi ErrorMsg ctermfg=256 ctermbg=160 guifg=#FFFFFF guibg=#B53030 gui=NONE
hi WarningMsg ctermfg=13 ctermbg=220 guifg=#FFFFFF guibg=#905510 gui=NONE
hi Question cterm=NONE guifg=#202020 guibg=#C0C0BA gui=NONE
hi MoreMsg cterm=NONE guifg=#60b030 gui=NONE
hi Search ctermfg=232 ctermbg=208 guifg=NONE guibg=#303030 gui=NONE
hi IncSearch ctermfg=232 ctermbg=208 guifg=#101010 guibg=#D96800 gui=NONE
hi Todo cterm=italic guibg=#202020 guifg=#B5D5B5 gui=italic

" === TabLine ===
hi TabLine ctermfg=232 ctermbg=247 cterm=NONE guifg=#C5C5BF guibg=#444444 gui=NONE
hi TabLinesel ctermfg=232 ctermbg=253 cterm=Bold guifg=#D5D5CF guibg=#202020 gui=bold
hi TabLineFill ctermfg=NONE ctermbg=NONE cterm=NONE guibg=NONE
hi TabLineSeparator guibg=#444444 guifg=#202020 gui=NONE
hi TabLineSeparatorPre guibg=#202020 guifg=#444444 gui=NONE

" === misc ===
hi MatchParen cterm=NONE guifg=#CCCCB5 guibg=#007FAF gui=NONE
hi SpellBad cterm=underline ctermbg=NONE guibg=NONE
hi NonText guifg=#CCCCB5 gui=NONE
hi EndOfBuffer guifg=#202020 gui=NONE
hi SignColumn ctermbg=234 guibg=#202020 gui=NONE
hi Directory guifg=#60C0D0 gui=NONE
hi Visual ctermfg=232 ctermbg=253 guifg=NONE guibg=#353535 gui=NONE
hi LineNr ctermfg=242 ctermbg=NONE guifg=#4A4A4A gui=NONE
hi QuickFixLine cterm=bold,italic gui=bold,italic

" === separator ... ===
hi CursorLine ctermfg=NONE ctermbg=235 cterm=NONE guifg=NONE guibg=#252525 gui=NONE
hi CursorLineNr ctermfg=242 ctermbg=NONE cterm=NONE guifg=#4A4A4A guibg=NONE gui=NONE
hi VertSplit ctermfg=253 ctermbg=253 cterm=NONE guifg=#202020 guibg=#202020 gui=NONE
hi StatusLine ctermfg=16 ctermbg=253 cterm=NONE guifg=#CCCCBF guibg=#105070 gui=NONE
hi StatusLineNC ctermfg=16 ctermbg=252 cterm=bold guifg=#C5C5BF guibg=#292929 gui=bold

" === Diff mode ===
hi DiffAdd ctermfg=230 ctermbg=65 guifg=NONE guibg=#192920 gui=NONE
hi DiffChange ctermfg=230 ctermbg=24 guifg=NONE guibg=#203045 gui=NONE
hi DiffDelete ctermfg=230 ctermbg=95 guifg=#4F2525 guibg=#4F2525 gui=NONE
hi DiffText ctermfg=230 ctermbg=2392 cterm=NONE guifg=NONE guibg=#1D1C1C gui=NONE

" === Popup menu ui ===
hi PMenu ctermfg=253 ctermbg=237 guifg=#CCCCB5 guibg=#333333 gui=NONE
hi PMenuSel ctermfg=232 ctermbg=250 cterm=bold guifg=#202020 guibg=#CCCCB5 gui=bold
hi PMenuSbar ctermfg=NONE ctermbg=239 guifg=NONE guibg=#333333 gui=NONE
hi PMenuThumb ctermfg=NONE ctermbg=250 guifg=NONE guibg=#AAAA95 gui=NONE

" === Code folding ===
hi Folded ctermfg=222 ctermbg=232 guifg=#BFA54F guibg=#191818 gui=NONE
hi FoldColumn ctermfg=222 ctermbg=232 guifg=#CFB55F guibg=#202020 gui=NONE

" === Language highlight ===
hi PreProc ctermfg=176 guifg=#c678dd gui=NONE
hi Type ctermfg=75 cterm=NONE guifg=#40BFFF gui=NONE
hi Number ctermfg=208 guifg=#FA8525 gui=NONE
hi Identifier ctermfg=75 cterm=NONE guifg=#56b6c2 gui=NONE
hi Constant ctermfg=208 guifg=#F58440 gui=NONE
hi Special ctermfg=208 guifg=#F58440 gui=NONE
hi Comment ctermfg=76 cterm=italic guifg=#458520 gui=italic
hi Statement ctermfg=220 guifg=#DDB740 gui=NONE
hi String ctermfg=215 guifg=#E5C07B gui=NONE
hi Operator ctermfg=230 cterm=NONE guifg=#C5E5F5 gui=NONE
hi Conditional ctermfg=220 guifg=#e06c75 gui=NONE
hi Function guifg=#d18a66
hi Structure guifg=#56b6c2

hi link Character String
hi link Repeat Conditional
hi link Exception Conditional

hi link pythonFunction   Identifier
hi link pythonBuiltIN    Function
hi link pythonOperator   Conditional

hi link verilogOperator  Normal
hi link systemverilogOperator Normal

hi link shOperator String

" === Tagbar.vim ===
hi link TagbarSignature Directory

" === BMBPSign.vim ===
hi BookMark    ctermbg=253 ctermfg=16 guibg=#202020 guifg=#CC7832 gui=NONE
hi TodoList    ctermbg=253 ctermfg=16 guibg=#202020 guifg=#619FC6 gui=NONE
hi BreakPoint  ctermbg=253 ctermfg=16 guibg=#202020 guifg=#D73130 gui=NONE

" === async.vim ===
hi AsyncDbgHl  ctermbg=253 ctermfg=16 guibg=#202020 guifg=#8BEBFF gui=NONE

" === ale.vim ===
hi ALEError        ctermfg=NONE ctermbg=234 guifg=#EEEED0 guibg=#D73130 gui=NONE
hi ALEErrorSign    ctermfg=9    ctermbg=234 guifg=#E44442 guibg=#202020 gui=NONE
hi ALEWarningSign  ctermfg=215  ctermbg=234 guifg=#DAA010 guibg=#202020 gui=NONE
hi link ALEWarning Normal
