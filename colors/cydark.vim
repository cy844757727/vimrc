" =================================================
" File: cydark.vim
" Author: Cy <844757727@qq.com>
" Description: dark colorscheme
" Last Modified: 2019年02月17日 星期日 17时49分26秒
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
let g:colors_name = 'cydark'

" palette
let s:none  = ['NONE', 'NONE']
let s:white = ['#ffffff', 231]
let s:black = ['#000000',  16]
let s:fg    = ['#c5c5bf', 251]
let s:bg    = ['#282828', 234]
let s:bg1   = ['#333333', 236]  " Statuslinunc pmenu
let s:gray  = ['#353535', 236]  " search visual
let s:red   = ['#e44442']       " error errorsign


" Different highlight for statusline between insertion mode and others
augroup Color_statusline_cydark
    autocmd!
    autocmd InsertEnter * :hi statusline guibg=#6D0EF2
    autocmd InsertLeave * :hi statusline guibg=#105070
    autocmd ColorScheme * :call s:ClearAutocmd()
augroup END

" Clear autocmd & augroup when switching to other colorscheme
function! s:ClearAutocmd()
    if g:colors_name !=# 'cydark'
        augroup Color_statusline_cydark
            autocmd!
        augroup END

        augroup! Color_statusline_cydark
    endif
endfunction


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
call s:HI('Visual', s:none, s:gray)
call s:HI('Search', s:none, s:gray)
call s:HI('InSearch', s:none, s:none, 'reverse')
call s:HI('QuickFixLine', s:none, s:none, 'bold')
call s:HI('CursorLine', s:none, ['#303030', 235])
call s:HI('StatusLine', s:white, ['#105070', 24])
call s:HI('StatusLineNC', s:none, s:bg1, 'bold')
call s:HI('LineNr', ['#4a4a4a', 239])
call s:HI('Directory', ['#60c0d0'])
call s:HI('WildMenu', s:black, ['#d8dd41'])
call s:HI('Todo', ['#b5d5b5'], s:none, 'italic')
call s:HI('MatchParen', s:fg, ['#006f90'])
call s:HI('Folded', ['#c7ad57'], ['#242323'])
call s:HI('FoldColumn', ['#c7ad57'])

hi! link CursorLineNr LineNr
" === TabLine ===
call s:HI('TabLine', s:none, ['#444444', 238])
call s:HI('TabLinesel', s:none, s:none, 'bold')
call s:HI('TabLineFill', s:none)
call s:HI('TabLineSeparator', s:bg, ['#444444', 238])

" === Diff ===
call s:HI('DiffAdd', s:none, ['#192920'])
call s:HI('DiffChange', s:none, ['#20303a'])
call s:HI('DiffDelete', ['#4f2525'], ['#4f2525'])
call s:HI('DiffText', s:none, ['#202020'])

" === Msg ===
call s:HI('Question', s:black, s:fg)
call s:HI('ErrorMsg', s:white, ['#b53030', 124])
call s:HI('WarningMsg', s:white, ['#9a5000', 130])
call s:HI('ModeMsg', s:none, s:none, 'bold')
call s:HI('MoreMsg', ['#60b030'])

" === Spell ===
call s:HI('SpellBad', s:none, s:none, 'italic')
call s:HI('SpellCap', s:none, s:none, 'bold')
call s:HI('SpellRare', s:none, s:none, 'underline')
call s:HI('SpellLocal', s:none, s:none, 'undercurl')

" === Popup menu ===
call s:HI('PMenu', s:none, s:bg1)
call s:HI('PMenuSel', s:black, s:fg)
call s:HI('PMenuSbar', s:none, s:bg1)
call s:HI('PMenuThumb', s:none, s:gray)

" === Language highlight ===
call s:HI('PreProc', ['#c678dd', 135])
call s:HI('Type', ['#40bfff', 75])
call s:HI('Number', ['#fa8525', 208])
call s:HI('Identifier', ['#56b6c2', 75])
call s:HI('Constant', ['#f58440', 208])
call s:HI('Comment', ['#458520', 76], s:none, 'italic')
call s:HI('Statement', ['#ddb740', 220])
call s:HI('String', ['#e5c07b', 215])
call s:HI('Operator', ['#c5e5f5', 230])
call s:HI('Conditional', ['#f06c75', 220])
call s:HI('Function', ['#d18a66'])

hi! link Special Constant
hi! link Character String
hi! link Repeat Conditional
hi! link Exception Conditional
hi! link Label Statement
hi! link Title Conditional

" === Plugin highlight ===
" BMBPSign.vim
call s:HI('BookMark', ['#cc7832'])
call s:HI('TodoList', ['#619fc6'])
call s:HI('BreakPoint', ['#de3d3b'])

" async.vim
call s:HI('AsyncDbgHl', ['#8bebff'])

" ale.vim
call s:HI('ALEErrorSign', s:red)
call s:HI('ALEWarningSign', ['#da9020'])

hi! link ALEError Error
hi! link ALEWarning Normal
" tagbar.vim
hi! link TagbarAccessPublic Comment
hi! link TagbarAccessProtected Type
hi! link TagbarAccessPrivate Conditional
hi! link TagbarSignature Identifier

" NERDTree.vim
hi! link NERDTreeDir Directory

" === Specific language ===
hi! link pythonFunction Identifier
hi! link pythonBuiltIN Function
hi! link pythonOperator Conditional

hi! link verilogOperator Normal
hi! link systemverilogOperator Normal

hi! link shQuote String
hi! link shOperator Normal
hi! link shVariable Normal
hi! link shShellVariables Normal
hi! link shOption Normal
hi! link shLoop Conditional
hi! link shEcho Normal
hi! link shStatement Statement

