" =================================================
" File: oneMonokai.vim
" Author: Cy <844757727@qq.com>
" Description: dark colorscheme reference from One Monokai Theme (Joshua Azemoh)
"              https://marketplace.visualstudio.com/items?itemName=azemoh.theme-onedark
" =================================================

if !has('gui_running') && (!has('termguicolors') || !&termguicolors)
    finish
endif

if version > 580
    hi clear
    if exists("syntax_on")
        syntax reset
    endif
endif

set t_Co=256
set background=dark
let g:colors_name = 'oneMonokai'

" palette
let s:none  = ['NONE', 'NONE']
let s:white = ['#ffffff']
let s:black = ['#000000']
let s:fg    = ['#abb2bf']
let s:bg    = ['#282c34']
let s:bg1   = ['#21252b']  " statuslinenc pmenu
let s:red   = ['#e44442']  " error errorsign


" Different highlight for statusline between insertion mode and others
augroup Color_statusline_oneMonokai
    autocmd!
    autocmd InsertEnter * :hi statusline guibg=#6d0ef2
    autocmd InsertLeave * :hi statusline guibg=#006080
    autocmd ColorScheme * :call s:ClearAutocmd()
augroup END

" Clear autocmd & augroup when switching to other colorscheme
function! s:ClearAutocmd()
    if g:colors_name !=# 'oneMonokai'
        augroup Color_statusline_oneMonokai
            autocmd!
        augroup END

        augroup! Color_statusline_oneMonokai
    endif
endfunction

" Config terminal color
"let g:terminal_ansi_colors = []

" Highlighting Function
" Args: group, fg, bg, gui/cterm, guisp
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
call s:HI('NonText')
call s:HI('SignColumn')
call s:HI('VertSplit', s:bg)
call s:HI('EndOfBuffer', s:bg)
call s:HI('Error', s:white, s:red)
call s:HI('Visual', s:none, ['#3e4451'])
call s:HI('Search', s:none, ['#314365'])
call s:HI('InSearch', s:none, s:none, 'reverse')
call s:HI('QuickFixLine', s:none, s:none, 'bold')
call s:HI('CursorLine', s:none, ['#383e4a'])
call s:HI('StatusLine', s:white, ['#006080'])
call s:HI('StatusLineNC', s:none, s:bg1, 'bold')
call s:HI('WildMenu', s:black, ['#e8ed51'])
call s:HI('Todo', ['#e06c75'], s:none, 'italic')
call s:HI('MatchParen', s:fg, ['#007faf'])
call s:HI('LineNr', ['#495162'])
call s:HI('Directory', ['#60c0d0'])
call s:HI('Folded', ['#cfb55f'], ['#20242a'])
call s:HI('FoldColumn', ['#cfb55f'])

hi! link CursorLineNr LineNr
hi! link qfLineNr Function
" === TabLine ===
call s:HI('TabLine', s:none, s:bg1)
call s:HI('TabLinesel', s:none, ['#383e4a'], 'bold')
call s:HI('TabLineFill')
call s:HI('TabLineSeparator', ['#383e4a'], s:bg1)

" === Diff mode ===
call s:HI('DiffAdd', s:none, ['#2d4c5a'])
call s:HI('DiffChange', s:none, ['#2d4c5a'])
call s:HI('DiffDelete', ['#53232a'], ['#53232a'])
call s:HI('DiffText', s:none)

" === Msg ===
call s:HI('Question', s:bg, s:fg)
call s:HI('ErrorMsg', s:white, ['#c24038'])
call s:HI('WarningMsg', s:white, ['#905510'])
call s:HI('ModeMsg', s:none, s:none, 'bold')
call s:HI('MoreMsg', ['#60b030'])

" === Spell ===
call s:HI('SpellBad', s:none, s:none, 'italic')
call s:HI('SpellCap', s:none, s:none, 'bold')
call s:HI('SpellRare', s:none, s:none, 'underline')
call s:HI('SpellLocal', s:none, s:none, 'undercurl')

" === Popup menu ui ===
call s:HI('PMenu', s:none, s:bg1)
call s:HI('PMenuSel', s:bg1, s:fg)
call s:HI('PMenuSbar', s:none, s:bg1)
call s:HI('PMenuThumb', s:none, ['#383e4a'])

" === Language highlight ===
call s:HI('PreProc', ['#c678dd'])
call s:HI('Type', ['#40bfff'])
call s:HI('Number', ['#c678dd'])
call s:HI('Identifier', ['#98c379'])
call s:HI('Constant', ['#56b6c2'])
call s:HI('Comment', ['#676f7d'], s:none, 'italic')
call s:HI('Statement', ['#56b6c2'])
call s:HI('String', ['#e5c07b'])
call s:HI('Operator', ['#e06c75'])
call s:HI('Conditional', ['#e06c75'])
call s:HI('Function', ['#d19a66'])
call s:HI('Structure', ['#56b6c2'])
call s:HI('Special', ['#f58440'])
call s:HI('Keyword', ['#56b6c2'])

hi! link Character String
hi! link Title Condition
hi! link Repeat Conditional
hi! link Exception Conditional
hi! link Label Conditional

" === Plugin highlight ===
" infoWin.vim
hi! link InfoWinMatch Search

" sign.vim
call s:HI('BookMark', ['#cc7832'])
call s:HI('TodoList', ['#619fc6'])
call s:HI('BreakPoint', ['#de3d3b'])

" async.vim
call s:HI('AsyncDbgHl', ['#8bebff'])

" ale.vim
call s:HI('ALEErrorSign', s:red)
call s:HI('ALEWarningSign', ['#ca9010'])

hi! link ALEError Error
hi! link ALEWarning Normal
" tagbar.vim
hi! link TagbarAccessPublic Comment
hi! link TagbarAccessProtected Type
hi! link TagbarAccessPrivate Conditional
hi! link TagbarSignature Directory

" NERDTree.vim
hi! link NERDTreeDir Directory

" === Link ===
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

