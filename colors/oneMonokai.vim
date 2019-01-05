" Vim color file
" Maintainer:	Cy
" Last Change:	2017-05-18

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
let g:colors_name = "oneMonokai"

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
    if g:colors_name != 'oneMonokai'
        augroup Color_statusline_oneMonokai
            autocmd!
        augroup END

        augroup! Color_statusline_oneMonokai
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

    execute join(l:hiString, ' ')
endfunction


" === Normal text ===
call s:HL('Normal', s:fg, s:bg)

" === Misc highlight ===
call s:HL('NonText')
call s:HL('SignColumn')
call s:HL('VertSplit', s:bg)
call s:HL('EndOfBuffer', s:bg)
call s:HL('Error', s:white, s:red)
call s:HL('Visual', s:none, ['#3e4451'])
call s:HL('Search', s:none, ['#314365'])
call s:HL('InSearch', s:none, s:none, 'reverse')
call s:HL('QuickFixLine', s:none, s:none, 'bold')
call s:HL('CursorLine', s:none, ['#383e4a'])
call s:HL('StatusLine', s:white, ['#006080'])
call s:HL('StatusLineNC', s:none, s:bg1, 'bold')
call s:HL('WildMenu', s:black, ['#e8ed51'])
call s:HL('Todo', ['#e06c75'], s:none, 'italic')
call s:HL('MatchParen', s:fg, ['#007faf'])
call s:HL('LineNr', ['#495162'])
call s:HL('Directory', ['#60c0d0'])
call s:HL('Folded', ['#cfb55f'], ['#20242a'])
call s:HL('FoldColumn', ['#cfb55f'])

hi! link CursorLineNr LineNr
" === TabLine ===
call s:HL('TabLine', ['#ddddcf'], s:bg1)
call s:HL('TabLinesel', ['#d5d5cf'], s:none, 'bold')
call s:HL('TabLineFill')
call s:HL('TabLineSeparator', ['#383e4a'], s:bg1)

" === Diff mode ===
call s:HL('DiffAdd', s:none, ['#2d4c5a'])
call s:HL('DiffChange', s:none, ['#2d4c5a'])
call s:HL('DiffDelete', ['#53232a'], ['#53232a'])
call s:HL('DiffText', s:none)

" === Msg ===
call s:HL('Question', s:bg, s:fg)
call s:HL('ErrorMsg', s:white, ['#c24038'])
call s:HL('WarningMsg', s:white, ['#905510'])
call s:HL('ModeMsg', s:none, s:none, 'bold')
call s:HL('MoreMsg', ['#60b030'])

" === Spell ===
call s:HL('SpellBad', s:none, s:none, 'underline')
call s:HL('SpellCap', s:none, s:none, 'bold')
call s:HL('SpellRare', s:none, s:none, 'italic')
call s:HL('SpellLocal', s:none, s:none, 'undercurl')

" === Popup menu ui ===
call s:HL('PMenu', s:none, s:bg1)
call s:HL('PMenuSel', s:bg1, s:fg)
call s:HL('PMenuSbar', s:none, s:bg1)
call s:HL('PMenuThumb', s:none, ['#383e4a'])

" === Language highlight ===
call s:HL('PreProc', ['#c678dd'])
call s:HL('Type', ['#40bfff'])
call s:HL('Number', ['#c678dd'])
call s:HL('Identifier', ['#98c379'])
call s:HL('Constant', ['#56b6c2'])
call s:HL('Comment', ['#676f7d'], s:none, 'italic')
call s:HL('Statement', ['#56b6c2'])
call s:HL('String', ['#e5c07b'])
call s:HL('Operator', ['#e06c75'])
call s:HL('Conditional', ['#e06c75'])
call s:HL('Function', ['#d19a66'])
call s:HL('Structure', ['#56b6c2'])
call s:HL('Special', ['#f58440'])
call s:HL('Keyword', ['#56b6c2'])

hi! link Character String
hi! link Title Condition
hi! link Repeat Conditional
hi! link Exception Conditional
hi! link Label Conditional

" === Plugin highlight ===
" BMBPSign.vim
call s:HL('BookMark', ['#cc7832'])
call s:HL('TodoList', ['#619fc6'])
call s:HL('BreakPoint', ['#de3d3b'])

" async.vim
call s:HL('AsyncDbgHl', ['#8bebff'])

" ale.vim
call s:HL('ALEErrorSign', s:red)
call s:HL('ALEWarningSign', ['#ca9010'])

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

