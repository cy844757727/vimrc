" Vim color file
" Converted from my Textmate Code School theme using Coloration

set background=dark
highlight clear

if exists("syntax_on")
  syntax reset
endif

set t_Co=256
let g:colors_name = "codeschool"

let s:none  = ['NONE', 'NONE']
let s:white = ['#ffffff', 231]
let s:black = ['#000000',  16]
let s:fg    = ['#e0e0e0', 231]
let s:bg    = ['#252c31',  16]

function! s:HI(group, ...)
    let l:fg = a:0 > 0 ? a:1 : s:none
    let l:bg = a:0 > 1 ? a:2 : s:none
    let l:em = a:0 > 2 ? a:3 : 'NONE'

    exe 'hi '.a:group.
                \ ' guifg='.l:fg[0].' ctermfg='.get(l:fg, 1, 'NONE').
                \ ' guibg='.l:bg[0].' ctermbg='.get(l:bg, 1, 'NONE').
                \ ' gui='.l:em.' cterm='.l:em.
                \ (a:0 > 3 ? ' guisp='.a:4[0] : '')
endfunction

" === Normal text ===
call s:HI('Normal', s:fg, s:bg)

" === Misc highlight ===
call s:HI('SignColumn')
call s:HI('QuickFixLine')
call s:HI('VertSplit', s:bg)
call s:HI('EndOfBuffer', s:bg)
call s:HI('Error', s:white, ['#b53030', 124])
call s:HI('Visual', s:none, ['#3f4b52', 59])

call s:HI('TabLine', s:none, ['#575e61'])
call s:HI('TabLinesel', s:none, s:none, 'bold')
call s:HI('TabLineFill', s:none)
call s:HI('TabLineSeparator', s:bg, ['#575e61'])
call s:HI('WarningMsg', s:white, ['#9a5000', 130])

hi ALEErrorSign guifg=#e44442
hi ALEWarningSign guifg=#da9020
hi ALEWarning guifg=NONE guibg=NONE
hi ALEError guifg=NONE guibg=NONE
hi link TagbarKind Number

call s:HI('CursorLineNr')
call s:HI('FoldColumn', s:bg)
call s:HI('Cursor', ['#182227', 16], ['#9ea7a6', 145])
call s:HI('CursorLine', s:none, ['#2e373b', 23])
call s:HI('CursorColumn', s:none, ['#2e373b', 23])
call s:HI('ColorColumn', s:none, ['#2e373b', 23])
call s:HI('LineNr', ['#84898c', 102], ['#2a343a', 23])
call s:HI('VertSplit', s:bg)
call s:HI('MatchParen', ['#dda790', 180], s:none, 'underline')
call s:HI('StatusLine', ['#f0f0f0', 231], ['#675e71', 59], 'bold')
call s:HI('StatusLineNC', ['#f0f0f0', 231], ['#575e61', 59])
call s:HI('Pmenu', ['#bcdbff', 153])
call s:HI('PmenuSel', s:none, ['#3f4b52', 59])
call s:HI('IncSearch', ['#182227', 16], ['#8bb664', 107])
call s:HI('Search', s:none, s:none, 'underline')
call s:HI('Directory', ['#3c98d9', 68])
call s:HI('Folded', ['#9a9a9a', 247], ['#182227', 16])

call s:HI('Boolean', ['#3c98d9', 68])
call s:HI('Character', ['#3c98d9', 68])
call s:HI('Comment', ['#9a9a9a', 247], s:none, 'italic')
call s:HI('Conditional', ['#dda790', 180])
call s:HI('Constant', ['#3c98d9', 68])
call s:HI('Define', ['#dda790', 180])
call s:HI('DiffAdd')
call s:HI('DiffDelete', s:none, ['#5a3030', 88])
call s:HI('DiffChange', s:none, ['#304d59', 23])
call s:HI('DiffText', s:none, ['#182227', 24])
call s:HI('ErrorMsg', s:white, ['#b44442', 124])
call s:HI('Float', ['#3c98d9', 68])
call s:HI('Function', ['#bcdbff', 153])
call s:HI('Identifier', ['#99cf50', 113])
call s:HI('Keyword', ['#dda790', 180])
call s:HI('Label', ['#8bb664', 107])
call s:HI('NonText', ['#414e58', 59], ['#232c31', 17])
call s:HI('Number', ['#3c98d9', 68])
call s:HI('Operator', ['#dda790', 180])
call s:HI('PreProc', ['#dda790', 180])
call s:HI('Special', ['#f0f0f0', 231])
call s:HI('SpecialKey', ['#414e58', 59])
call s:HI('Statement', ['#dda790', 180])
call s:HI('StorageClass', ['#99cf50', 113])
call s:HI('String', ['#8bb664', 107])
call s:HI('Tag', ['#bcdbff', 153])
call s:HI('Title', ['#f0f0f0', 231], s:none, 'bold')
call s:HI('Todo', ['#9a9a9a', 247], s:none, 'inverse,bold,italic')
call s:HI('Type', ['#b5d8f6', 153])
call s:HI('Underlined', s:none, s:none, 'underline')
call s:HI('rubyClass', ['#dda790', 180])
call s:HI('rubyFunction', ['#bcdbff', 153])
call s:HI('rubyInterpolationDelimiter')
call s:HI('rubySymbol', ['#3c98d9', 68])
call s:HI('rubyConstant', ['#bfabcb', 146])
call s:HI('rubyStringDelimiter', ['#8bb664', 107])
call s:HI('rubyBlockParameter', ['#68a9eb', 74])
call s:HI('rubyInstanceVariable', ['#68a9eb', 74])
call s:HI('rubyInclude', ['#dda790', 180])
call s:HI('rubyGlobalVariable', ['#68a9eb', 74])
call s:HI('rubyRegexp', ['#e9c062', 179])
call s:HI('rubyRegexpDelimiter', ['#e9c062', 179])
call s:HI('rubyEscape', ['#3c98d9', 68])
call s:HI('rubyControl', ['#dda790', 180])
call s:HI('rubyClassVariable', ['#68a9eb', 74])
call s:HI('rubyOperator', ['#dda790', 180])
call s:HI('rubyException', ['#dda790', 180])
call s:HI('rubyPseudoVariable', ['#68a9eb', 74])
call s:HI('rubyRailsUserClass', ['#bfabcb', 146])
call s:HI('rubyRailsARAssociationMethod', ['#dad085', 186])
call s:HI('rubyRailsARMethod', ['#dad085', 186])
call s:HI('rubyRailsRenderMethod', ['#dad085', 186])
call s:HI('rubyRailsMethod', ['#dad085', 186])
call s:HI('erubyDelimiter')
call s:HI('erubyComment', ['#9a9a9a', 247], s:none, 'italic')
call s:HI('erubyRailsMethod', ['#dad085', 186])
call s:HI('htmlTag', ['#89bdff', 111])
call s:HI('htmlEndTag', ['#89bdff', 111])
call s:HI('htmlTagName', ['#89bdff', 111])
call s:HI('htmlArg', ['#89bdff', 111])
call s:HI('htmlSpecialChar', ['#3c98d9', 68])
call s:HI('javaScriptFunction', ['#99cf50', 113])
call s:HI('javaScriptRailsFunction', ['#dad085', 186])
call s:HI('javaScriptBraces')
call s:HI('yamlKey', ['#bcdbff', 153])
call s:HI('yamlAnchor', ['#68a9eb', 74])
call s:HI('yamlAlias', ['#68a9eb', 74])
call s:HI('yamlDocumentHeader', ['#8bb664', 107])
call s:HI('cssURL', ['#68a9eb', 74])
call s:HI('cssFunctionName', ['#dad085', 186])
call s:HI('cssColor', ['#3c98d9', 68])
call s:HI('cssPseudoClassId', ['#bcdbff', 153])
call s:HI('cssClassName', ['#bcdbff', 153])
call s:HI('cssValueLength', ['#3c98d9', 68])
call s:HI('cssCommonAttr', ['#a7cfa3', 151])
call s:HI('cssBraces')


call s:HI('InfoWinMatch', ['#c9a936'])
call s:HI('InfoWinColumnNr', ['#84898c', 102])
