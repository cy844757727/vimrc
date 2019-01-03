" Vim color file
" Maintainer:	Cy
" Last Change:	2019年 01月 03日 星期四 20:36:09 CST2017-05-18

if !has('gui_running') && (!has('termguicolors') || !&termguicolors)
    finish
endif

set background=dark
hi clear
set t_Co=256
let g:colors_name = "cydark"

let s:none  = ['NONE', 'NONE']
let s:white = ['#ffffff', 231]
let s:black = ['#000000', 16]
let s:fg    = ['#c5c5bf', 251]
let s:bg    = ['#202020', 234]


" Arguments: group, fg, bg, gui/cterm, guisp
function! s:HL(group, ...)
  let l:fg = a:0 > 0 ? a:1 : s:fg
  let l:bg = a:0 > 1 ? a:2 : s:none
  let l:em = a:0 > 2 ? a:3 : 'NONE'

  let l:histring = [
              \ 'hi', a:group,
              \ 'guifg=' . fg[0], 'ctermfg=' . get(l:fg, 1, 'NONE'),
              \ 'guibg=' . bg[0], 'ctermbg=' . get(l:bg, 1, 'NONE'),
              \ 'gui=' . l:em, 'cterm=' . l:em
              \ ]

  " special
  if a:0 > 3
    call add(l:histring, 'guisp=' . a:4[0])
  endif

  execute join(l:histring, ' ')
endfunction


let s:NormalMode = '#105070'
let s:InsertMode = '#6D0EF2'

augroup Color_statusline
    autocmd!
    autocmd InsertEnter * exe 'hi statusline guibg='.s:InsertMode
    autocmd InsertLeave * exe 'hi statusline guibg='.s:NormalMode
augroup END


" === Basic highlight ===
call s:HL('Normal', s:fg, s:bg)
call s:HL('LineNr', ['#4a4a4a', 239])
call s:HL('NonText')
call s:HL('EndOfBuffer', s:bg)
call s:HL('SignColumn', s:none)
call s:HL('VertSplit', s:bg)
call s:HL('CursorLine', s:none, ['#252525', 235])
call s:HL('CursorLineNr', ['#4a4a4a', 239])
call s:HL('StatusLine', ['#ddddcf', 253], ['#105070', 24])
call s:HL('StatusLineNC', ['#c0c0ba', 251], ['#292929', 236], 'bold')
call s:HL('Error', s:white, ['#d73130', 160])
call s:HL('ErrorMsg', s:white, ['#b53030', 124])
call s:HL('WarningMsg', s:white, ['#905510', 130])
call s:HL('Question', s:bg, s:fg)
call s:HL('MoreMsg', ['#60b030'])
call s:HL('Search', s:none, ['#303030'])
call s:HL('Todo', ['#b5d5b5'], s:bg, 'italic')
call s:HL('MatchParen', s:fg, ['#007faf'])
call s:HL('SpellBad', s:none, s:none, 'underline')
call s:HL('Directory', ['#60c0d0'])
call s:HL('Visual', s:none, ['#353535', 236])
call s:HL('QuickFixLine', s:none, s:none, 'bold,italic')

" === TabLine ===
call s:HL('TabLine', ['#c5c5bf', 251], ['#444444', 238])
call s:HL('TabLinesel', ['#d5d5cf', 253], s:none, 'bold')
call s:HL('TabLineFill', s:none)
call s:HL('TabLineSeparator', s:bg, ['#444444', 238])

" === Diff mode ===
call s:HL('DiffAdd', s:none, ['#192920'])
call s:HL('DiffChange', s:none, ['#203045'])
call s:HL('DiffDelete', ['#4f2525'], ['#4f2525'])
call s:HL('DiffText', s:none)

" === Popup menu ui ===
call s:HL('PMenu', ['#ccccb5'], ['#333333', 236])
call s:HL('PMenuSel', s:bg, ['#ccccb5'])
call s:HL('PMenuSbar', s:none, ['#333333', 236])
call s:HL('PMenuThumb', s:none, ['#aaaa95'])

" === Code folding ===
call s:HL('Folded', ['#bfa54f'], ['#191818'])
call s:HL('FoldColumn', ['#cfb55f'])

" === Language highlight ===
call s:HL('PreProc', ['#c678dd', 135])
call s:HL('Type', ['#40bfff', 75])
call s:HL('Number', ['#fa8525', 208])
call s:HL('Identifier', ['#56b6c2', 75])
call s:HL('Constant', ['#f58440', 208])
call s:HL('Comment', ['#458520', 76], s:none, 'italic')
call s:HL('Statement', ['#ddb740', 220])
call s:HL('String', ['#e5c07b', 215])
call s:HL('Operator', ['#c5e5f5', 230])
call s:HL('Conditional', ['#e06c75', 220])
call s:HL('Function', ['#d18a66'])
call s:HL('Structure', ['#56b6c2'])
call s:HL('Title', ['#e06c75'])

" === Plugin highlight ===
" BMBPSign.vim
call s:HL('BookMark', ['#cc7832'])
call s:HL('TodoList', ['#619fc6'])
call s:HL('BreakPoint', ['#de3d3b'])

" async.vim
call s:HL('AsyncDbgHl', ['#8bebff'])

" ale.vim
call s:HL('ALEError', ['#eeeed0'], ['#d73130'])
call s:HL('ALEErrorSign', ['#e44442'])
call s:HL('ALEWarningSign', ['#ca8010'])

hi! link ALEWarning Normal
hi! link TagbarSignature Directory
hi! link NERDTreeDir Directory

" === Link ===
hi! link Special Constant
hi! link Character String
hi! link Repeat Conditional
hi! link Exception Conditional
hi! link Label Statement

hi! link pythonFunction   Identifier
hi! link pythonBuiltIN    Function
hi! link pythonOperator   Conditional

hi! link verilogOperator  Normal
hi! link systemverilogOperator Normal

hi! link shQuote String
hi! link shOperator Normal
hi! link shVariable Normal
hi! link shShellVariables Normal
hi! link shOption Normal
hi! link shLoop Conditional
hi! link shEcho Normal
hi! link shStatement Statement

