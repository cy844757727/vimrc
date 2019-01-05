" Vim color file
" Maintainer:	Cy
" Last Change: 2019年01月05日 星期六 17时40分06秒

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
let g:colors_name = "cydark"

" palette
let s:none  = ['NONE', 'NONE']
let s:white = ['#ffffff', 231]
let s:black = ['#000000', 16]
let s:fg    = ['#c5c5bf', 251]
let s:bg    = ['#202020', 234]
let s:bg1   = ['#292929', 236]  " Statuslinunc pmenu
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
    if g:colors_name != 'cydark'
        augroup Color_statusline_cydark
            autocmd!
        augroup END

        silent augroup! Color_statusline_cydark
    endif
endfunction


" Highlighting Function
" Arguments: group, fg, bg, gui/cterm, guisp
function! s:HL(group, ...)
    let l:fg = a:0 > 0 ? a:1 : s:none
    let l:bg = a:0 > 1 ? a:2 : s:none
    let l:em = a:0 > 2 ? a:3 : 'NONE'

    let l:hiString = [
                \ 'hi', a:group,
                \ 'guifg=' . fg[0], 'ctermfg=' . get(l:fg, 1, 'NONE'),
                \ 'guibg=' . bg[0], 'ctermbg=' . get(l:bg, 1, 'NONE'),
                \ 'gui=' . l:em, 'cterm=' . l:em
                \ ]

    " special
    if a:0 > 3
        call add(l:hiString, 'guisp=' . a:4[0])
    endif

    exe join(l:hiString, ' ')
endfunction


" === Normal text ===
call s:HL('Normal', s:fg, s:bg)

" === Misc highlight ===
call s:HL('NonText')
call s:HL('SignColumn')
call s:HL('VertSplit', s:bg)
call s:HL('EndOfBuffer', s:bg)
call s:HL('Error', s:white, s:red)
call s:HL('Visual', s:none, s:gray)
call s:HL('Search', s:none, s:gray)
call s:HL('InSearch', s:none, s:none, 'reverse')
call s:HL('QuickFixLine', s:none, s:none, 'bold')
call s:HL('CursorLine', s:none, ['#252525', 235])
call s:HL('StatusLine', s:white, ['#105070', 24])
call s:HL('StatusLineNC', s:none, s:bg1, 'bold')
call s:HL('LineNr', ['#4a4a4a', 239])
call s:HL('Directory', ['#60c0d0'])
call s:HL('WildMenu', s:black, ['#d8dd41'])
call s:HL('Todo', ['#b5d5b5'], s:none, 'italic')
call s:HL('MatchParen', s:fg, ['#007fa0'])
call s:HL('Folded', ['#bfa54f'], ['#1b1a1a'])
call s:HL('FoldColumn', ['#bfa54f'])

hi! link CursorLineNr LineNr
" === TabLine ===
call s:HL('TabLine', s:none, ['#444444', 238])
call s:HL('TabLinesel', s:none, s:none, 'bold')
call s:HL('TabLineFill', s:none)
call s:HL('TabLineSeparator', s:bg, ['#444444', 238])

" === Diff ===
call s:HL('DiffAdd', s:none, ['#192920'])
call s:HL('DiffChange', s:none, ['#203045'])
call s:HL('DiffDelete', ['#4f2525'], ['#4f2525'])
call s:HL('DiffText', s:none)

" === Msg ===
call s:HL('Question', s:black, s:fg)
call s:HL('ErrorMsg', s:white, ['#b53030', 124])
call s:HL('WarningMsg', s:white, ['#8a5005', 130])
call s:HL('ModeMsg', s:none, s:none, 'bold')
call s:HL('MoreMsg', ['#60b030'])

" === Spell ===
call s:HL('SpellBad', s:none, s:none, 'underline')
call s:HL('SpellCap', s:none, s:none, 'bold')
call s:HL('SpellRare', s:none, s:none, 'italic')
call s:HL('SpellLocal', s:none, s:none, 'undercurl')

" === Popup menu ===
call s:HL('PMenu', s:none, s:bg1)
call s:HL('PMenuSel', s:black, s:fg)
call s:HL('PMenuSbar', s:none, s:bg1)
call s:HL('PMenuThumb', s:none, s:gray)

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

hi! link Special Constant
hi! link Character String
hi! link Repeat Conditional
hi! link Exception Conditional
hi! link Label Statement
hi! link Title Conditional

" === Plugin highlight ===
" BMBPSign.vim
call s:HL('BookMark', ['#cc7832'])
call s:HL('TodoList', ['#619fc6'])
call s:HL('BreakPoint', ['#de3d3b'])

" async.vim
call s:HL('AsyncDbgHl', ['#8bebff'])

" ale.vim
call s:HL('ALEErrorSign', s:red)
call s:HL('ALEWarningSign', ['#ca8010'])

hi! link ALEError Error
hi! link ALEWarning Normal
" tagbar.vim
hi! link TagbarAccessPublic Comment
hi! link TagbarAccessProtected Type
hi! link TagbarAccessPrivate Conditional
hi! link TagbarSignature Directory

" NERDTree.vim
hi! link NERDTreeDir Directory

" === Specific language ===
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

