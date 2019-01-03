" Vim color file
" Maintainer:	Cy
" Last Change:	2017-05-18

set background=dark
hi clear
set t_Co=256
let g:colors_name = "OneMonokai"

let s:NormalMode = '#006080'
let s:InsertMode = '#6D0EF2'

augroup Color_statusline
    autocmd!
    autocmd InsertEnter * exe 'hi statusline guibg='.s:InsertMode
    autocmd InsertLeave * exe 'hi statusline guibg='.s:NormalMode
augroup END
" === Basic highlight ===
hi Normal cterm=NONE ctermfg=230 guifg=#abb2bf guibg=#282c34 gui=NONE

" Msg & Tip
hi Error ctermfg=256 ctermbg=160 cterm=NONE guifg=#FFFFFF guibg=#D73130 gui=NONE
hi ErrorMsg ctermfg=256 ctermbg=160 guifg=#FFFFFF guibg=#C24038 gui=NONE
hi WarningMsg ctermfg=13 ctermbg=220 guifg=#FFFFFF guibg=#905510 gui=NONE
hi Question cterm=NONE guifg=#282c34 guibg=#abb2bf
hi MoreMsg cterm=NONE guifg=#60b030 gui=NONE
hi Search ctermfg=232 ctermbg=208 guifg=NONE guibg=#314365 gui=NONE
hi IncSearch ctermfg=232 ctermbg=208 guifg=#101010 guibg=#D96800 gui=NONE
hi Todo cterm=italic guibg=#282c34 guifg=#e06c75 gui=italic

" === TabLine ===
hi TabLine ctermfg=232 ctermbg=247 cterm=NONE guifg=#DDDDCF guibg=#21252B gui=NONE
hi TabLinesel ctermfg=232 ctermbg=253 cterm=Bold guifg=#D5D5CF guibg=#383E4A gui=bold
hi TabLineFill ctermfg=NONE ctermbg=NONE cterm=NONE guibg=NONE
hi TabLineSeparator guibg=#21252B guifg=#383E4A gui=NONE

" === misc ===
hi MatchParen cterm=NONE guifg=#abb2bf guibg=#007FAF gui=NONE
hi SpellBad cterm=underline ctermbg=NONE guibg=NONE
hi NonText guifg=#abb2bf gui=NONE
hi EndOfBuffer guifg=#282c34 gui=NONE
hi SignColumn ctermbg=234 guibg=#282c34 gui=NONE
hi Directory guifg=#60C0D0 gui=NONE
hi Visual ctermfg=232 ctermbg=253 guifg=NONE guibg=#3E4451 gui=NONE
hi LineNr ctermfg=242 ctermbg=NONE guifg=#495162 gui=NONE
hi QuickFixLine cterm=bold,italic gui=bold,italic
hi link TagbarSignature Directory

" === separator ... ===
hi CursorLine ctermfg=NONE ctermbg=235 cterm=NONE guifg=NONE guibg=#383E4A gui=NONE
hi CursorLineNr ctermfg=242 ctermbg=NONE cterm=NONE guifg=#495162 guibg=NONE gui=NONE
hi VertSplit ctermfg=253 ctermbg=253 cterm=NONE guifg=#282C34 guibg=#282c34 gui=NONE
hi StatusLine ctermfg=16 ctermbg=253 cterm=NONE guifg=#FFFFFF guibg=#006080 gui=NONE
hi StatusLineNC ctermfg=16 ctermbg=252 cterm=bold guifg=#abb2bf guibg=#21252B gui=bold
"hi StatusLineTerm
"hi StatusLineTermNC

" === Diff mode ===
hi DiffAdd ctermfg=230 ctermbg=65 guifg=NONE guibg=#2D4C5A gui=NONE
hi DiffChange ctermfg=230 ctermbg=24 guifg=NONE guibg=#2D4C5A gui=NONE
hi DiffDelete ctermfg=230 ctermbg=95 guifg=#53232A guibg=#53232A gui=NONE
hi DiffText ctermfg=230 ctermbg=2392 cterm=NONE guifg=NONE guibg=#20242A gui=NONE

" === Popup menu ui ===
hi PMenu ctermfg=253 ctermbg=237 guifg=#acb2bf guibg=#21252B gui=NONE
hi PMenuSel ctermfg=232 ctermbg=250 cterm=bold guifg=#acb2bf guibg=#2C313A gui=bold
hi PMenuSbar ctermfg=NONE ctermbg=239 guifg=NONE guibg=#21252B gui=NONE
hi PMenuThumb ctermfg=NONE ctermbg=250 guifg=NONE guibg=#2C313A gui=NONE

" === Code folding ===
hi Folded ctermfg=222 ctermbg=232 guifg=#CFB55F guibg=#20242A gui=NONE
hi FoldColumn ctermfg=222 ctermbg=232 guifg=#CFB55F guibg=#202020 gui=NONE

" === Language highlight ===
hi PreProc ctermfg=176 guifg=#c678dd gui=NONE
hi Type ctermfg=75 cterm=NONE guifg=#40BFFF gui=NONE
hi Number ctermfg=208 guifg=#c678dd gui=NONE
hi Identifier ctermfg=75 cterm=NONE guifg=#98c379 gui=NONE
hi Constant ctermfg=208 guifg=#56b6c2 gui=NONE
hi Special ctermfg=208 guifg=#F58440 gui=NONE
hi Comment ctermfg=76 cterm=italic guifg=#676f7d gui=italic
hi String ctermfg=215 guifg=#e5c07b gui=NONE
hi Operator ctermfg=230 cterm=NONE guifg=#e06c75 gui=NONE
hi Title guifg=#e06c75

hi Statement guifg=#56b6c2
hi Function guifg=#d19a66
hi Conditional guifg=#e06c75
hi Keyword guifg=#56b6c2

hi! link Character String
hi! link Title Condition
hi! link Repeat Conditional
hi! link Exception Conditional
hi! link Label Conditional

hi! link pythonDecoratorName Identifier
hi! link pythonBuiltin Identifier
hi! link Label Conditional

hi! link verilogOperator  Normal
hi! link systemverilogOperator Normal

hi! link shOperator Normal
hi! link shQuote String
hi! link shVariable Normal
hi! link shShellVariables Normal
hi! link shOption Normal
hi! link shStatement Identifier
hi! link shLoop Conditional
hi! link shEcho Normal

hi! link NERDTreeDir Directory
hi! link TagbarSignature Directory


hi BookMark    ctermfg=16 guifg=#CC7832
hi TodoList    ctermfg=16 guifg=#619FC6
hi BreakPoint  ctermfg=16 guifg=#DE3D3B
hi AsyncDbgHl  ctermfg=16 guifg=#8BEBFF
" === ale.vim ===
hi ALEError        ctermfg=NONE ctermbg=234 guifg=#EEEED0 guibg=#D73130 gui=NONE
hi ALEErrorSign    ctermfg=9    guifg=#E44442 
hi ALEWarningSign  ctermfg=215  guifg=#CA9010 
hi link ALEWarning Normal
