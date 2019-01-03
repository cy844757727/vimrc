" Name:         Solarized 8 Flat
" Description:  Precision colors for machines and people
" Author:       Ethan Schoonover
" Maintainer:   Lifepillar <lifepillar@lifepillar.me>
" Website:      https://github.com/lifepillar/vim-solarized8
" License:      OSI approved MIT license
" Last Updated: Sun Aug 26 09:12:59 2018

if !(has('termguicolors') && &termguicolors) && !has('gui_running')
            \ && (!exists('&t_Co') || &t_Co < (get(g:, 'solarized_use16', &t_Co < 256) ? 16 : 256))
    echoerr '[Solarized 8 Flat] There are not enough colors.'
    finish
endif

hi clear
set background=light
if exists('syntax_on')
    syntax reset
endif

let g:colors_name = 'solarizedLight'


augroup Color_statusline
    autocmd!
augroup END
hi default BookMark    ctermbg=253 ctermfg=16 guibg=#FDF6E3 guifg=#CC7832
hi default TodoList    ctermbg=253 ctermfg=16 guibg=#FDF6E3 guifg=#619FC6
hi default BreakPoint  ctermbg=253 ctermfg=16 guibg=#FDF6E3 guifg=#DE3D3B
hi TabLineSeparator guibg=#EEE8D5 guifg=#073642 gui=NONE
" 256-color variant
if !get(g:, 'solarized_use16', &t_Co < 256)
    let g:terminal_ansi_colors = ['#073642', '#dc322f', '#859900', '#b58900', '#268bd2', '#d33682', '#2aa198', '#eee8d5',
                \ '#002b36', '#cb4b16', '#586e75', '#657b83', '#839496', '#6c71c4', '#93a1a1', '#fdf6e3']
    if has('nvim')
        hi! link TermCursor Cursor
        hi TermCursorNC ctermfg=230 ctermbg=247 guifg=#fdf6e3 guibg=#93a1a1 guisp=NONE cterm=NONE gui=NONE
        let g:terminal_color_0='#073642'
        let g:terminal_color_1='#dc322f'
        let g:terminal_color_2='#859900'
        let g:terminal_color_3='#b58900'
        let g:terminal_color_4='#268bd2'
        let g:terminal_color_5='#d33682'
        let g:terminal_color_6='#2aa198'
        let g:terminal_color_7='#eee8d5'
        let g:terminal_color_8='#002b36'
        let g:terminal_color_9='#cb4b16'
        let g:terminal_color_10='#586e75'
        let g:terminal_color_11='#657b83'
        let g:terminal_color_12='#839496'
        let g:terminal_color_13='#6c71c4'
        let g:terminal_color_14='#93a1a1'
        let g:terminal_color_15='#fdf6e3'
    endif
    if !has('gui_running') && get(g:, 'solarized_termtrans', 0)
        hi Normal ctermfg=66 ctermbg=NONE guifg=#657b83 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi Terminal ctermfg=fg ctermbg=NONE guifg=fg guibg=NONE guisp=NONE cterm=NONE gui=NONE
    else
        hi Normal ctermfg=66 ctermbg=230 guifg=#657b83 guibg=#fdf6e3 guisp=NONE cterm=NONE gui=NONE
        hi Terminal ctermfg=fg ctermbg=230 guifg=fg guibg=#fdf6e3 guisp=NONE cterm=NONE gui=NONE
        hi EndOfBuffer guifg=#fdf6e3 guibg=#fdf6e3
    endif
    if get(g:, "solarized_visibility", "") == "high"
        if get(g:, 'solarized_old_cursor_style', 0)
            hi Cursor ctermfg=230 ctermbg=66 guifg=#fdf6e3 guibg=#657b83 guisp=NONE cterm=NONE gui=NONE
        else
            hi Cursor ctermfg=230 ctermbg=160 guifg=#fdf6e3 guibg=#dc322f guisp=NONE cterm=NONE gui=NONE
        endif
        hi CursorLineNr ctermfg=160 ctermbg=NONE guifg=#dc322f guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi MatchParen ctermfg=166 ctermbg=254 guifg=#cb4b16 guibg=#eee8d5 guisp=NONE cterm=NONE,bold,underline gui=NONE,bold,underline
        hi NonText ctermfg=160 ctermbg=NONE guifg=#dc322f guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi SpecialKey ctermfg=160 ctermbg=NONE guifg=#dc322f guibg=NONE guisp=NONE cterm=NONE,reverse gui=NONE,reverse
        hi SpellBad ctermfg=61 ctermbg=254 guifg=#6c71c4 guibg=#eee8d5 guisp=#dc322f cterm=NONE,reverse,underline gui=NONE,reverse,undercurl
        hi SpellCap ctermfg=61 ctermbg=254 guifg=#6c71c4 guibg=#eee8d5 guisp=#dc322f cterm=NONE,reverse,underline gui=NONE,reverse,undercurl
        hi SpellLocal ctermfg=136 ctermbg=254 guifg=#b58900 guibg=#eee8d5 guisp=#cb4b16 cterm=NONE,reverse,underline gui=NONE,reverse,undercurl
        hi SpellRare ctermfg=37 ctermbg=254 guifg=#2aa198 guibg=#eee8d5 guisp=#cb4b16 cterm=NONE,reverse,underline gui=NONE,reverse,undercurl
        hi Title ctermfg=166 ctermbg=NONE guifg=#cb4b16 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    elseif get(g:, "solarized_visibility", "") == "low"
        if get(g:, 'solarized_old_cursor_style', 0)
            hi Cursor ctermfg=230 ctermbg=66 guifg=#fdf6e3 guibg=#657b83 guisp=NONE cterm=NONE gui=NONE
        else
            hi Cursor ctermfg=230 ctermbg=166 guifg=#fdf6e3 guibg=#cb4b16 guisp=NONE cterm=NONE gui=NONE
        endif
        hi CursorLineNr ctermfg=247 ctermbg=NONE guifg=#93a1a1 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi MatchParen ctermfg=166 ctermbg=254 guifg=#cb4b16 guibg=#eee8d5 guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi NonText ctermfg=254 ctermbg=NONE guifg=#eee8d5 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi SpecialKey ctermfg=254 ctermbg=NONE guifg=#eee8d5 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi SpellBad ctermfg=61 ctermbg=NONE guifg=#6c71c4 guibg=NONE guisp=#6c71c4 cterm=NONE,underline gui=NONE,undercurl
        hi SpellCap ctermfg=61 ctermbg=NONE guifg=#6c71c4 guibg=NONE guisp=#6c71c4 cterm=NONE,underline gui=NONE,undercurl
        hi SpellLocal ctermfg=136 ctermbg=NONE guifg=#b58900 guibg=NONE guisp=#b58900 cterm=NONE,underline gui=NONE,undercurl
        hi SpellRare ctermfg=37 ctermbg=NONE guifg=#2aa198 guibg=NONE guisp=#2aa198 cterm=NONE,underline gui=NONE,undercurl
        hi Title ctermfg=247 ctermbg=NONE guifg=#93a1a1 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    else
        if get(g:, 'solarized_old_cursor_style', 0)
            hi Cursor ctermfg=230 ctermbg=66 guifg=#fdf6e3 guibg=#657b83 guisp=NONE cterm=NONE gui=NONE
        else
            hi Cursor ctermfg=230 ctermbg=166 guifg=#fdf6e3 guibg=#cb4b16 guisp=NONE cterm=NONE gui=NONE
        endif
        hi CursorLineNr ctermfg=66 ctermbg=NONE guifg=#657b83 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi MatchParen ctermfg=235 ctermbg=254 guifg=#002b36 guibg=#eee8d5 guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi NonText ctermfg=246 ctermbg=NONE guifg=#839496 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi SpecialKey ctermfg=246 ctermbg=254 guifg=#839496 guibg=#eee8d5 guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi SpellBad ctermfg=61 ctermbg=NONE guifg=#6c71c4 guibg=NONE guisp=#6c71c4 cterm=NONE,underline gui=NONE,undercurl
        hi SpellCap ctermfg=61 ctermbg=NONE guifg=#6c71c4 guibg=NONE guisp=#6c71c4 cterm=NONE,underline gui=NONE,undercurl
        hi SpellLocal ctermfg=136 ctermbg=NONE guifg=#b58900 guibg=NONE guisp=#b58900 cterm=NONE,underline gui=NONE,undercurl
        hi SpellRare ctermfg=37 ctermbg=NONE guifg=#2aa198 guibg=NONE guisp=#2aa198 cterm=NONE,underline gui=NONE,undercurl
        hi Title ctermfg=166 ctermbg=NONE guifg=#cb4b16 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    endif
    hi ColorColumn ctermfg=NONE ctermbg=254 guifg=NONE guibg=#eee8d5 guisp=NONE cterm=NONE gui=NONE
    hi Conceal ctermfg=32 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi CursorColumn ctermfg=NONE ctermbg=254 guifg=NONE guibg=#eee8d5 guisp=NONE cterm=NONE gui=NONE
    hi CursorLine ctermfg=NONE ctermbg=230 guifg=NONE guibg=#EEE8D5 guisp=#93a1a1 cterm=NONE gui=NONE
    hi EndOfBuffer guifg=#FDF6E3
    if get(g:, "solarized_diffmode", "") == "high"
        hi DiffAdd ctermfg=106 ctermbg=NONE guifg=#859900 guibg=NONE guisp=NONE cterm=NONE,reverse gui=NONE,reverse
        hi DiffChange ctermfg=136 ctermbg=NONE guifg=#b58900 guibg=NONE guisp=NONE cterm=NONE,reverse gui=NONE,reverse
        hi DiffDelete ctermfg=160 ctermbg=NONE guifg=#dc322f guibg=NONE guisp=NONE cterm=NONE,reverse gui=NONE,reverse
        hi DiffText ctermfg=32 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE,reverse gui=NONE,reverse
    elseif get(g:, "solarized_diffmode", "") == "low"
        hi DiffAdd ctermfg=106 ctermbg=NONE guifg=#859900 guibg=NONE guisp=#859900 cterm=NONE gui=NONE
        hi DiffChange ctermfg=136 ctermbg=NONE guifg=#b58900 guibg=NONE guisp=#b58900 cterm=NONE gui=NONE
        hi DiffDelete ctermfg=160 ctermbg=NONE guifg=#dc322f guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi DiffText ctermfg=32 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=#268bd2 cterm=NONE gui=NONE
    else
        hi DiffAdd ctermfg=106 ctermbg=254 guifg=#859900 guibg=#eee8d5 guisp=#859900 cterm=NONE gui=NONE
        hi DiffChange ctermfg=136 ctermbg=254 guifg=#b58900 guibg=#eee8d5 guisp=#b58900 cterm=NONE gui=NONE
        hi DiffDelete ctermfg=160 ctermbg=254 guifg=#dc322f guibg=#eee8d5 guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi DiffText ctermfg=32 ctermbg=254 guifg=#268bd2 guibg=#eee8d5 guisp=#268bd2 cterm=NONE gui=NONE
    endif
    hi Directory ctermfg=32 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi EndOfBuffer ctermfg=NONE ctermbg=NONE guifg=#002B36 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi ErrorMsg ctermfg=160 ctermbg=235 guifg=#dc322f guibg=#002b36 guisp=NONE cterm=NONE,reverse gui=NONE,reverse
    hi FoldColumn ctermfg=66 ctermbg=NONE guifg=#657b83 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi Folded ctermfg=66 ctermbg=NONE guifg=#657b83 guibg=NONE guisp=#fdf6e3 cterm=NONE,bold gui=NONE,bold
    hi IncSearch ctermfg=166 ctermbg=NONE guifg=#cb4b16 guibg=NONE guisp=NONE cterm=NONE,standout gui=NONE,standout
    hi LineNr ctermfg=247 ctermbg=NONE guifg=#93a1a1 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi ModeMsg ctermfg=32 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi MoreMsg ctermfg=32 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi Pmenu ctermfg=254 ctermbg=66 guifg=#eee8d5 guibg=#657b83 guisp=NONE cterm=NONE,reverse gui=NONE,reverse
    hi PmenuSbar ctermfg=254 ctermbg=247 guifg=#eee8d5 guibg=#93a1a1 guisp=NONE cterm=NONE,reverse gui=NONE,reverse
    hi PmenuSel ctermfg=247 ctermbg=230 guifg=#93a1a1 guibg=#fdf6e3 guisp=NONE cterm=NONE,reverse gui=NONE,reverse
    hi PmenuThumb ctermfg=246 ctermbg=230 guifg=#839496 guibg=#fdf6e3 guisp=NONE cterm=NONE,reverse gui=NONE,reverse
    hi Question ctermfg=37 ctermbg=NONE guifg=#2aa198 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi! link QuickFixLine Search
    hi Search ctermfg=136 ctermbg=NONE guifg=#b58900 guibg=NONE guisp=NONE cterm=NONE,reverse gui=NONE,reverse
    hi SignColumn ctermfg=66 ctermbg=NONE guifg=#657b83 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    if get(g:, "solarized_statusline", "") == "low"
        hi StatusLine ctermfg=254 ctermbg=242 guifg=#eee8d5 guibg=#586e75 guisp=NONE cterm=NONE,bold,reverse gui=NONE,bold,reverse
        hi StatusLineNC ctermfg=254 ctermbg=247 guifg=#eee8d5 guibg=#93a1a1 guisp=NONE cterm=NONE,reverse gui=NONE,reverse
        hi TabLineSel ctermfg=242 ctermbg=254 guifg=#586e75 guibg=#eee8d5 guisp=NONE cterm=NONE gui=NONE
        hi NormalMode ctermfg=254 ctermbg=242 guifg=#eee8d5 guibg=#586e75 guisp=NONE cterm=NONE,bold,reverse gui=NONE,bold,reverse
    else
        hi StatusLine ctermfg=254 ctermbg=236 guifg=#eee8d5 guibg=#073642 guisp=NONE cterm=NONE,reverse gui=NONE,reverse
        hi StatusLineNC ctermfg=254 ctermbg=242 guifg=#eee8d5 guibg=#586e75 guisp=NONE cterm=NONE,reverse gui=NONE,reverse
        hi TabLineSel ctermfg=236 ctermbg=254 guifg=#073642 guibg=#eee8d5 guisp=NONE cterm=NONE gui=NONE
        hi NormalMode ctermfg=254 ctermbg=236 guifg=#eee8d5 guibg=#073642 guisp=NONE cterm=NONE,reverse gui=NONE,reverse
    endif
    hi TabLine ctermfg=247 ctermbg=254 guifg=#93a1a1 guibg=#eee8d5 guisp=NONE cterm=NONE gui=NONE
    hi TabLineFill ctermfg=247 ctermbg=254 guifg=#93a1a1 guibg=#eee8d5 guisp=NONE cterm=NONE gui=NONE
    hi InsertMode ctermfg=254 ctermbg=37 guifg=#eee8d5 guibg=#2aa198 guisp=NONE cterm=NONE,bold,reverse gui=NONE,bold,reverse
    hi ReplaceMode ctermfg=254 ctermbg=166 guifg=#eee8d5 guibg=#cb4b16 guisp=NONE cterm=NONE,bold,reverse gui=NONE,bold,reverse
    hi VisualMode ctermfg=254 ctermbg=162 guifg=#eee8d5 guibg=#d33682 guisp=NONE cterm=NONE,bold,reverse gui=NONE,bold,reverse
    hi CommandMode ctermfg=254 ctermbg=162 guifg=#eee8d5 guibg=#d33682 guisp=NONE cterm=NONE,bold,reverse gui=NONE,bold,reverse
    hi! link StatusLineTerm StatusLine
    hi! link StatusLineTermNC StatusLineNC
    hi VertSplit ctermfg=247 ctermbg=254 guifg=#FDF6E3 guibg=#FDF6E3 guisp=NONE cterm=NONE gui=NONE
    hi Visual ctermfg=247 ctermbg=230 guifg=#93a1a1 guibg=#fdf6e3 guisp=NONE cterm=NONE,reverse gui=NONE,reverse
    hi VisualNOS ctermfg=NONE ctermbg=254 guifg=NONE guibg=#eee8d5 guisp=NONE cterm=NONE,reverse gui=NONE,reverse
    hi WarningMsg ctermfg=166 ctermbg=NONE guifg=#cb4b16 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi WildMenu ctermfg=247 ctermbg=230 guifg=#93a1a1 guibg=#fdf6e3 guisp=NONE cterm=NONE,reverse gui=NONE,reverse
    hi! link Boolean Constant
    hi! link Character Constant
    hi Comment ctermfg=247 ctermbg=NONE guifg=#93a1a1 guibg=NONE guisp=NONE cterm=NONE gui=NONE,italic
    hi! link Conditional Statement
    hi Constant ctermfg=37 ctermbg=NONE guifg=#2aa198 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi! link Define PreProc
    hi! link Debug Special
    hi! link Delimiter Special
    hi Error ctermfg=160 ctermbg=NONE guifg=#dc322f guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi! link Exception Statement
    hi! link Float Constant
    hi! link Function Identifier
    hi Identifier ctermfg=32 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi Ignore ctermfg=NONE ctermbg=NONE guifg=NONE guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi! link Include PreProc
    hi! link Keyword Statement
    hi! link Label Statement
    hi! link Macro PreProc
    hi! link Number Constant
    hi! link Operator Statement
    hi! link PreCondit PreProc
    hi PreProc ctermfg=166 ctermbg=NONE guifg=#cb4b16 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi! link Repeat Statement
    hi Special ctermfg=166 ctermbg=NONE guifg=#cb4b16 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi! link SpecialChar Special
    hi! link SpecialComment Special
    hi Statement ctermfg=106 ctermbg=NONE guifg=#859900 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi! link StorageClass Type
    hi! link String Constant
    hi! link Structure Type
    hi! link Tag Special
    hi Todo ctermfg=162 ctermbg=NONE guifg=#d33682 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi Type ctermfg=136 ctermbg=NONE guifg=#b58900 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi! link Typedef Type
    hi Underlined ctermfg=61 ctermbg=NONE guifg=#6c71c4 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi! link lCursor Cursor
    hi CursorIM ctermfg=NONE ctermbg=fg guifg=NONE guibg=fg guisp=NONE cterm=NONE gui=NONE
    hi ToolbarLine ctermfg=NONE ctermbg=254 guifg=NONE guibg=#eee8d5 guisp=NONE cterm=NONE gui=NONE
    hi ToolbarButton ctermfg=242 ctermbg=254 guifg=#586e75 guibg=#eee8d5 guisp=NONE cterm=NONE,bold gui=NONE,bold
    if get(g:, 'solarized_extra_hi_groups', 0)
        hi! link vimVar Identifier
        hi! link vimFunc Function
        hi! link vimUserFunc Function
        hi! link helpSpecial Special
        hi! link vimSet Normal
        hi! link vimSetEqual Normal
        hi vimCommentString ctermfg=61 ctermbg=NONE guifg=#6c71c4 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi vimCommand ctermfg=136 ctermbg=NONE guifg=#b58900 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi vimCmdSep ctermfg=32 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi helpExample ctermfg=242 ctermbg=NONE guifg=#586e75 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi helpOption ctermfg=37 ctermbg=NONE guifg=#2aa198 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi helpNote ctermfg=162 ctermbg=NONE guifg=#d33682 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi helpVim ctermfg=162 ctermbg=NONE guifg=#d33682 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi helpHyperTextJump ctermfg=32 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi helpHyperTextEntry ctermfg=106 ctermbg=NONE guifg=#859900 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi vimIsCommand ctermfg=246 ctermbg=NONE guifg=#839496 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi vimSynMtchOpt ctermfg=136 ctermbg=NONE guifg=#b58900 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi vimSynType ctermfg=37 ctermbg=NONE guifg=#2aa198 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi vimHiLink ctermfg=32 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi vimHiGroup ctermfg=32 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi vimGroup ctermfg=32 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi! link diffAdded Statement
        hi! link diffLine Identifier
        hi gitcommitComment ctermfg=247 ctermbg=NONE guifg=#93a1a1 guibg=NONE guisp=NONE cterm=NONE gui=NONE,italic
        hi! link gitcommitUntracked gitcommitComment
        hi! link gitcommitDiscarded gitcommitComment
        hi! link gitcommitSelected gitcommitComment
        hi gitcommitUnmerged ctermfg=106 ctermbg=NONE guifg=#859900 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi gitcommitOnBranch ctermfg=247 ctermbg=NONE guifg=#93a1a1 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi gitcommitBranch ctermfg=162 ctermbg=NONE guifg=#d33682 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi! link gitcommitNoBranch gitcommitBranch
        hi gitcommitdiscardedtype ctermfg=160 ctermbg=NONE guifg=#dc322f guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi gitcommitselectedtype ctermfg=106 ctermbg=NONE guifg=#859900 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi gitcommitHeader ctermfg=247 ctermbg=NONE guifg=#93a1a1 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi gitcommitUntrackedFile ctermfg=37 ctermbg=NONE guifg=#2aa198 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi gitcommitDiscardedFile ctermfg=160 ctermbg=NONE guifg=#dc322f guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi gitcommitSelectedFile ctermfg=106 ctermbg=NONE guifg=#859900 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi gitcommitUnmergedFile ctermfg=136 ctermbg=NONE guifg=#b58900 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi gitcommitFile ctermfg=66 ctermbg=NONE guifg=#657b83 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi! link gitcommitDiscardedArrow gitcommitDiscardedFile
        hi! link gitcommitSelectedArrow gitcommitSelectedFile
        hi! link gitcommitUnmergedArrow gitcommitUnmergedFile
        hi htmlTag ctermfg=247 ctermbg=NONE guifg=#93a1a1 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi htmlEndTag ctermfg=247 ctermbg=NONE guifg=#93a1a1 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi htmlTagN ctermfg=242 ctermbg=NONE guifg=#586e75 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi htmlTagName ctermfg=32 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi htmlSpecialTagName ctermfg=32 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE,italic
        hi htmlArg ctermfg=246 ctermbg=NONE guifg=#839496 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi javaScript ctermfg=136 ctermbg=NONE guifg=#b58900 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi! link jsFuncCall Function
        hi perlHereDoc ctermfg=242 ctermbg=230 guifg=#586e75 guibg=#fdf6e3 guisp=NONE cterm=NONE gui=NONE
        hi perlVarPlain ctermfg=136 ctermbg=230 guifg=#b58900 guibg=#fdf6e3 guisp=NONE cterm=NONE gui=NONE
        hi perlStatementFileDesc ctermfg=37 ctermbg=230 guifg=#2aa198 guibg=#fdf6e3 guisp=NONE cterm=NONE gui=NONE
        hi texstatement ctermfg=37 ctermbg=230 guifg=#2aa198 guibg=#fdf6e3 guisp=NONE cterm=NONE gui=NONE
        hi texmathzonex ctermfg=136 ctermbg=230 guifg=#b58900 guibg=#fdf6e3 guisp=NONE cterm=NONE gui=NONE
        hi texmathmatcher ctermfg=136 ctermbg=230 guifg=#b58900 guibg=#fdf6e3 guisp=NONE cterm=NONE gui=NONE
        hi texreflabel ctermfg=136 ctermbg=230 guifg=#b58900 guibg=#fdf6e3 guisp=NONE cterm=NONE gui=NONE
        hi rubyDefine ctermfg=242 ctermbg=230 guifg=#586e75 guibg=#fdf6e3 guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi! link rubySymbol Type
        hi rubyBoolean ctermfg=162 ctermbg=230 guifg=#d33682 guibg=#fdf6e3 guisp=NONE cterm=NONE gui=NONE
        let hs_highlight_boolean=1
        let hs_highlight_delimiters=1
        hi cPreCondit ctermfg=166 ctermbg=NONE guifg=#cb4b16 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi VarId ctermfg=32 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi ConId ctermfg=136 ctermbg=NONE guifg=#b58900 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi hsImport ctermfg=162 ctermbg=NONE guifg=#d33682 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi hsString ctermfg=246 ctermbg=NONE guifg=#839496 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi hsStructure ctermfg=37 ctermbg=NONE guifg=#2aa198 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi hs_hlFunctionName ctermfg=32 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi hsStatement ctermfg=37 ctermbg=NONE guifg=#2aa198 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi hsImportLabel ctermfg=37 ctermbg=NONE guifg=#2aa198 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi hs_OpFunctionName ctermfg=136 ctermbg=NONE guifg=#b58900 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi hs_DeclareFunction ctermfg=166 ctermbg=NONE guifg=#cb4b16 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi hsVarSym ctermfg=37 ctermbg=NONE guifg=#2aa198 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi hsType ctermfg=136 ctermbg=NONE guifg=#b58900 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi hsTypedef ctermfg=37 ctermbg=NONE guifg=#2aa198 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi hsModuleName ctermfg=106 ctermbg=NONE guifg=#859900 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi! link hsImportParams Delimiter
        hi! link hsDelimTypeExport Delimiter
        hi! link hsModuleStartLabel hsStructure
        hi! link hsModuleWhereLabel hsModuleStartLabel
        hi hsNiceOperator ctermfg=37 ctermbg=NONE guifg=#2aa198 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi hsniceoperator ctermfg=37 ctermbg=NONE guifg=#2aa198 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi pandocTitleBlock ctermfg=32 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi pandocTitleBlockTitle ctermfg=32 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi pandocTitleComment ctermfg=32 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi pandocComment ctermfg=247 ctermbg=NONE guifg=#93a1a1 guibg=NONE guisp=NONE cterm=NONE gui=NONE,italic
        hi pandocVerbatimBlock ctermfg=136 ctermbg=NONE guifg=#b58900 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi! link pandocVerbatimBlockDeep pandocVerbatimBlock
        hi! link pandocCodeBlock pandocVerbatimBlock
        hi! link pandocCodeBlockDelim pandocVerbatimBlock
        hi pandocBlockQuote ctermfg=32 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi pandocBlockQuoteLeader1 ctermfg=32 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi pandocBlockQuoteLeader2 ctermfg=37 ctermbg=NONE guifg=#2aa198 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi pandocBlockQuoteLeader3 ctermfg=136 ctermbg=NONE guifg=#b58900 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi pandocBlockQuoteLeader4 ctermfg=160 ctermbg=NONE guifg=#dc322f guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi pandocBlockQuoteLeader5 ctermfg=66 ctermbg=NONE guifg=#657b83 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi pandocBlockQuoteLeader6 ctermfg=247 ctermbg=NONE guifg=#93a1a1 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi pandocListMarker ctermfg=162 ctermbg=NONE guifg=#d33682 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi pandocListReference ctermfg=162 ctermbg=NONE guifg=#d33682 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi pandocDefinitionBlock ctermfg=61 ctermbg=NONE guifg=#6c71c4 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi pandocDefinitionTerm ctermfg=61 ctermbg=NONE guifg=#6c71c4 guibg=NONE guisp=NONE cterm=NONE,standout gui=NONE,standout
        hi pandocDefinitionIndctr ctermfg=61 ctermbg=NONE guifg=#6c71c4 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi pandocEmphasisDefinition ctermfg=61 ctermbg=NONE guifg=#6c71c4 guibg=NONE guisp=NONE cterm=NONE gui=NONE,italic
        hi pandocEmphasisNestedDefinition ctermfg=61 ctermbg=NONE guifg=#6c71c4 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi pandocStrongEmphasisDefinition ctermfg=61 ctermbg=NONE guifg=#6c71c4 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi pandocStrongEmphasisNestedDefinition ctermfg=61 ctermbg=NONE guifg=#6c71c4 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi pandocStrongEmphasisEmphasisDefinition ctermfg=61 ctermbg=NONE guifg=#6c71c4 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi pandocStrikeoutDefinition ctermfg=61 ctermbg=NONE guifg=#6c71c4 guibg=NONE guisp=NONE cterm=NONE,reverse gui=NONE,reverse
        hi pandocVerbatimInlineDefinition ctermfg=61 ctermbg=NONE guifg=#6c71c4 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi pandocSuperscriptDefinition ctermfg=61 ctermbg=NONE guifg=#6c71c4 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi pandocSubscriptDefinition ctermfg=61 ctermbg=NONE guifg=#6c71c4 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi pandocTable ctermfg=32 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi pandocTableStructure ctermfg=32 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi! link pandocTableStructureTop pandocTableStructre
        hi! link pandocTableStructureEnd pandocTableStructre
        hi pandocTableZebraLight ctermfg=32 ctermbg=230 guifg=#268bd2 guibg=#fdf6e3 guisp=NONE cterm=NONE gui=NONE
        hi pandocTableZebraDark ctermfg=32 ctermbg=254 guifg=#268bd2 guibg=#eee8d5 guisp=NONE cterm=NONE gui=NONE
        hi pandocEmphasisTable ctermfg=32 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE,italic
        hi pandocEmphasisNestedTable ctermfg=32 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi pandocStrongEmphasisTable ctermfg=32 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi pandocStrongEmphasisNestedTable ctermfg=32 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi pandocStrongEmphasisEmphasisTable ctermfg=32 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi pandocStrikeoutTable ctermfg=32 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE,reverse gui=NONE,reverse
        hi pandocVerbatimInlineTable ctermfg=32 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi pandocSuperscriptTable ctermfg=32 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi pandocSubscriptTable ctermfg=32 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi pandocHeading ctermfg=166 ctermbg=NONE guifg=#cb4b16 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi pandocHeadingMarker ctermfg=166 ctermbg=NONE guifg=#cb4b16 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi pandocEmphasisHeading ctermfg=166 ctermbg=NONE guifg=#cb4b16 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi pandocEmphasisNestedHeading ctermfg=166 ctermbg=NONE guifg=#cb4b16 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi pandocStrongEmphasisHeading ctermfg=166 ctermbg=NONE guifg=#cb4b16 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi pandocStrongEmphasisNestedHeading ctermfg=166 ctermbg=NONE guifg=#cb4b16 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi pandocStrongEmphasisEmphasisHeading ctermfg=166 ctermbg=NONE guifg=#cb4b16 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi pandocStrikeoutHeading ctermfg=166 ctermbg=NONE guifg=#cb4b16 guibg=NONE guisp=NONE cterm=NONE,reverse gui=NONE,reverse
        hi pandocVerbatimInlineHeading ctermfg=166 ctermbg=NONE guifg=#cb4b16 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi pandocSuperscriptHeading ctermfg=166 ctermbg=NONE guifg=#cb4b16 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi pandocSubscriptHeading ctermfg=166 ctermbg=NONE guifg=#cb4b16 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi pandocLinkDelim ctermfg=247 ctermbg=NONE guifg=#93a1a1 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi pandocLinkLabel ctermfg=32 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi pandocLinkText ctermfg=32 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi pandocLinkURL ctermfg=246 ctermbg=NONE guifg=#839496 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi pandocLinkTitle ctermfg=246 ctermbg=NONE guifg=#839496 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi pandocLinkTitleDelim ctermfg=247 ctermbg=NONE guifg=#93a1a1 guibg=NONE guisp=#839496 cterm=NONE gui=NONE
        hi pandocLinkDefinition ctermfg=37 ctermbg=NONE guifg=#2aa198 guibg=NONE guisp=#839496 cterm=NONE gui=NONE
        hi pandocLinkDefinitionID ctermfg=32 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi pandocImageCaption ctermfg=61 ctermbg=NONE guifg=#6c71c4 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi pandocFootnoteLink ctermfg=106 ctermbg=NONE guifg=#859900 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi pandocFootnoteDefLink ctermfg=106 ctermbg=NONE guifg=#859900 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi pandocFootnoteInline ctermfg=106 ctermbg=NONE guifg=#859900 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi pandocFootnote ctermfg=106 ctermbg=NONE guifg=#859900 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi pandocCitationDelim ctermfg=162 ctermbg=NONE guifg=#d33682 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi pandocCitation ctermfg=162 ctermbg=NONE guifg=#d33682 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi pandocCitationID ctermfg=162 ctermbg=NONE guifg=#d33682 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi pandocCitationRef ctermfg=162 ctermbg=NONE guifg=#d33682 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi pandocStyleDelim ctermfg=247 ctermbg=NONE guifg=#93a1a1 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi pandocEmphasis ctermfg=66 ctermbg=NONE guifg=#657b83 guibg=NONE guisp=NONE cterm=NONE gui=NONE,italic
        hi pandocEmphasisNested ctermfg=66 ctermbg=NONE guifg=#657b83 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi pandocStrongEmphasis ctermfg=66 ctermbg=NONE guifg=#657b83 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi pandocStrongEmphasisNested ctermfg=66 ctermbg=NONE guifg=#657b83 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi pandocStrongEmphasisEmphasis ctermfg=66 ctermbg=NONE guifg=#657b83 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi pandocStrikeout ctermfg=247 ctermbg=NONE guifg=#93a1a1 guibg=NONE guisp=NONE cterm=NONE,reverse gui=NONE,reverse
        hi pandocVerbatimInline ctermfg=136 ctermbg=NONE guifg=#b58900 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi pandocSuperscript ctermfg=61 ctermbg=NONE guifg=#6c71c4 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi pandocSubscript ctermfg=61 ctermbg=NONE guifg=#6c71c4 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi pandocRule ctermfg=32 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi pandocRuleLine ctermfg=32 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi pandocEscapePair ctermfg=160 ctermbg=NONE guifg=#dc322f guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi pandocCitationRef ctermfg=162 ctermbg=NONE guifg=#d33682 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi pandocNonBreakingSpace ctermfg=160 ctermbg=NONE guifg=#dc322f guibg=NONE guisp=NONE cterm=NONE,reverse gui=NONE,reverse
        hi! link pandocEscapedCharacter pandocEscapePair
        hi! link pandocLineBreak pandocEscapePair
        hi pandocMetadataDelim ctermfg=247 ctermbg=NONE guifg=#93a1a1 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi pandocMetadata ctermfg=32 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi pandocMetadataKey ctermfg=32 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
        hi pandocMetadata ctermfg=32 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
        hi! link pandocMetadataTitle pandocMetadata
    endif
    if get(g:, "solarized_term_italics", 0)
        hi Comment cterm=italic
        hi gitcommitComment cterm=italic
        hi htmlSpecialTagName cterm=italic
        hi pandocComment cterm=italic
        hi pandocEmphasisDefinition cterm=italic
        hi pandocEmphasisTable cterm=italic
        hi pandocEmphasis cterm=italic
    endif
    finish
endif


" 16-color variant
let g:terminal_ansi_colors = ['#073642', '#dc322f', '#859900', '#b58900', '#268bd2', '#d33682', '#2aa198', '#eee8d5',
            \ '#002b36', '#cb4b16', '#586e75', '#657b83', '#839496', '#6c71c4', '#93a1a1', '#fdf6e3']
if has('nvim')
    hi! link TermCursor Cursor
    hi TermCursorNC ctermfg=15 ctermbg=14 guifg=#fdf6e3 guibg=#93a1a1 guisp=NONE cterm=NONE gui=NONE
    let g:terminal_color_0='#073642'
    let g:terminal_color_1='#dc322f'
    let g:terminal_color_2='#859900'
    let g:terminal_color_3='#b58900'
    let g:terminal_color_4='#268bd2'
    let g:terminal_color_5='#d33682'
    let g:terminal_color_6='#2aa198'
    let g:terminal_color_7='#eee8d5'
    let g:terminal_color_8='#002b36'
    let g:terminal_color_9='#cb4b16'
    let g:terminal_color_10='#586e75'
    let g:terminal_color_11='#657b83'
    let g:terminal_color_12='#839496'
    let g:terminal_color_13='#6c71c4'
    let g:terminal_color_14='#93a1a1'
    let g:terminal_color_15='#fdf6e3'
endif
if !has('gui_running') && get(g:, 'solarized_termtrans', 0)
    hi Normal ctermfg=11 ctermbg=NONE guifg=#657b83 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi Terminal ctermfg=fg ctermbg=NONE guifg=fg guibg=NONE guisp=NONE cterm=NONE gui=NONE
else
    hi Normal ctermfg=11 ctermbg=15 guifg=#657b83 guibg=#fdf6e3 guisp=NONE cterm=NONE gui=NONE
    hi Terminal ctermfg=fg ctermbg=15 guifg=fg guibg=#fdf6e3 guisp=NONE cterm=NONE gui=NONE
    hi EndOfBuffer guifg=#fdf6e3 guibg=#fdf6e3
endif
if get(g:, "solarized_visibility", "") == "high"
    if get(g:, 'solarized_old_cursor_style', 0)
        hi Cursor ctermfg=15 ctermbg=11 guifg=#fdf6e3 guibg=#657b83 guisp=NONE cterm=NONE gui=NONE
    else
        hi Cursor ctermfg=15 ctermbg=1 guifg=#fdf6e3 guibg=#dc322f guisp=NONE cterm=NONE gui=NONE
    endif
    hi CursorLineNr ctermfg=1 ctermbg=NONE guifg=#dc322f guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi MatchParen ctermfg=9 ctermbg=7 guifg=#cb4b16 guibg=#eee8d5 guisp=NONE cterm=NONE,bold,underline gui=NONE,bold,underline
    hi NonText ctermfg=1 ctermbg=NONE guifg=#dc322f guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi SpecialKey ctermfg=1 ctermbg=NONE guifg=#dc322f guibg=NONE guisp=NONE cterm=NONE,reverse gui=NONE,reverse
    hi SpellBad ctermfg=13 ctermbg=7 guifg=#6c71c4 guibg=#eee8d5 guisp=#dc322f cterm=NONE,reverse,underline gui=NONE,reverse,undercurl
    hi SpellCap ctermfg=13 ctermbg=7 guifg=#6c71c4 guibg=#eee8d5 guisp=#dc322f cterm=NONE,reverse,underline gui=NONE,reverse,undercurl
    hi SpellLocal ctermfg=3 ctermbg=7 guifg=#b58900 guibg=#eee8d5 guisp=#cb4b16 cterm=NONE,reverse,underline gui=NONE,reverse,undercurl
    hi SpellRare ctermfg=6 ctermbg=7 guifg=#2aa198 guibg=#eee8d5 guisp=#cb4b16 cterm=NONE,reverse,underline gui=NONE,reverse,undercurl
    hi Title ctermfg=9 ctermbg=NONE guifg=#cb4b16 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
elseif get(g:, "solarized_visibility", "") == "low"
    if get(g:, 'solarized_old_cursor_style', 0)
        hi Cursor ctermfg=15 ctermbg=11 guifg=#fdf6e3 guibg=#657b83 guisp=NONE cterm=NONE gui=NONE
    else
        hi Cursor ctermfg=15 ctermbg=9 guifg=#fdf6e3 guibg=#cb4b16 guisp=NONE cterm=NONE gui=NONE
    endif
    hi CursorLineNr ctermfg=14 ctermbg=NONE guifg=#93a1a1 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi MatchParen ctermfg=9 ctermbg=7 guifg=#cb4b16 guibg=#eee8d5 guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi NonText ctermfg=7 ctermbg=NONE guifg=#eee8d5 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi SpecialKey ctermfg=7 ctermbg=NONE guifg=#eee8d5 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi SpellBad ctermfg=13 ctermbg=NONE guifg=#6c71c4 guibg=NONE guisp=#6c71c4 cterm=NONE,underline gui=NONE,undercurl
    hi SpellCap ctermfg=13 ctermbg=NONE guifg=#6c71c4 guibg=NONE guisp=#6c71c4 cterm=NONE,underline gui=NONE,undercurl
    hi SpellLocal ctermfg=3 ctermbg=NONE guifg=#b58900 guibg=NONE guisp=#b58900 cterm=NONE,underline gui=NONE,undercurl
    hi SpellRare ctermfg=6 ctermbg=NONE guifg=#2aa198 guibg=NONE guisp=#2aa198 cterm=NONE,underline gui=NONE,undercurl
    hi Title ctermfg=14 ctermbg=NONE guifg=#93a1a1 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
else
    if get(g:, 'solarized_old_cursor_style', 0)
        hi Cursor ctermfg=15 ctermbg=11 guifg=#fdf6e3 guibg=#657b83 guisp=NONE cterm=NONE gui=NONE
    else
        hi Cursor ctermfg=15 ctermbg=9 guifg=#fdf6e3 guibg=#cb4b16 guisp=NONE cterm=NONE gui=NONE
    endif
    hi CursorLineNr ctermfg=11 ctermbg=NONE guifg=#657b83 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi MatchParen ctermfg=8 ctermbg=7 guifg=#002b36 guibg=#eee8d5 guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi NonText ctermfg=12 ctermbg=NONE guifg=#839496 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi SpecialKey ctermfg=12 ctermbg=7 guifg=#839496 guibg=#eee8d5 guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi SpellBad ctermfg=13 ctermbg=NONE guifg=#6c71c4 guibg=NONE guisp=#6c71c4 cterm=NONE,underline gui=NONE,undercurl
    hi SpellCap ctermfg=13 ctermbg=NONE guifg=#6c71c4 guibg=NONE guisp=#6c71c4 cterm=NONE,underline gui=NONE,undercurl
    hi SpellLocal ctermfg=3 ctermbg=NONE guifg=#b58900 guibg=NONE guisp=#b58900 cterm=NONE,underline gui=NONE,undercurl
    hi SpellRare ctermfg=6 ctermbg=NONE guifg=#2aa198 guibg=NONE guisp=#2aa198 cterm=NONE,underline gui=NONE,undercurl
    hi Title ctermfg=9 ctermbg=NONE guifg=#cb4b16 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
endif
hi ColorColumn ctermfg=NONE ctermbg=7 guifg=NONE guibg=#eee8d5 guisp=NONE cterm=NONE gui=NONE
hi Conceal ctermfg=4 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
hi CursorColumn ctermfg=NONE ctermbg=7 guifg=NONE guibg=#eee8d5 guisp=NONE cterm=NONE gui=NONE
hi CursorLine ctermfg=NONE ctermbg=15 guifg=NONE guibg=#09353F guisp=#93a1a1 cterm=NONE gui=NONE
if get(g:, "solarized_diffmode", "") == "high"
    hi DiffAdd ctermfg=2 ctermbg=NONE guifg=#859900 guibg=NONE guisp=NONE cterm=NONE,reverse gui=NONE,reverse
    hi DiffChange ctermfg=3 ctermbg=NONE guifg=#b58900 guibg=NONE guisp=NONE cterm=NONE,reverse gui=NONE,reverse
    hi DiffDelete ctermfg=1 ctermbg=NONE guifg=#dc322f guibg=NONE guisp=NONE cterm=NONE,reverse gui=NONE,reverse
    hi DiffText ctermfg=4 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE,reverse gui=NONE,reverse
elseif get(g:, "solarized_diffmode", "") == "low"
    hi DiffAdd ctermfg=2 ctermbg=NONE guifg=#859900 guibg=NONE guisp=#859900 cterm=NONE gui=NONE
    hi DiffChange ctermfg=3 ctermbg=NONE guifg=#b58900 guibg=NONE guisp=#b58900 cterm=NONE gui=NONE
    hi DiffDelete ctermfg=1 ctermbg=NONE guifg=#dc322f guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi DiffText ctermfg=4 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=#268bd2 cterm=NONE gui=NONE
else
    hi DiffAdd ctermfg=2 ctermbg=7 guifg=#859900 guibg=#eee8d5 guisp=#859900 cterm=NONE gui=NONE
    hi DiffChange ctermfg=3 ctermbg=7 guifg=#b58900 guibg=#eee8d5 guisp=#b58900 cterm=NONE gui=NONE
    hi DiffDelete ctermfg=1 ctermbg=7 guifg=#dc322f guibg=#eee8d5 guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi DiffText ctermfg=4 ctermbg=7 guifg=#268bd2 guibg=#eee8d5 guisp=#268bd2 cterm=NONE gui=NONE
endif
hi Directory ctermfg=4 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
hi EndOfBuffer ctermfg=NONE ctermbg=NONE guifg=#002B36 guibg=NONE guisp=NONE cterm=NONE gui=NONE
hi ErrorMsg ctermfg=1 ctermbg=8 guifg=#dc322f guibg=#002b36 guisp=NONE cterm=NONE,reverse gui=NONE,reverse
hi FoldColumn ctermfg=11 ctermbg=NONE guifg=#657b83 guibg=NONE guisp=NONE cterm=NONE gui=NONE
hi Folded ctermfg=11 ctermbg=NONE guifg=#657b83 guibg=NONE guisp=#fdf6e3 cterm=NONE,bold gui=NONE,bold
hi IncSearch ctermfg=9 ctermbg=NONE guifg=#cb4b16 guibg=NONE guisp=NONE cterm=NONE,standout gui=NONE,standout
hi LineNr ctermfg=14 ctermbg=NONE guifg=#93a1a1 guibg=NONE guisp=NONE cterm=NONE gui=NONE
hi ModeMsg ctermfg=4 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
hi MoreMsg ctermfg=4 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
hi Pmenu ctermfg=7 ctermbg=11 guifg=#eee8d5 guibg=#657b83 guisp=NONE cterm=NONE,reverse gui=NONE,reverse
hi PmenuSbar ctermfg=7 ctermbg=14 guifg=#eee8d5 guibg=#93a1a1 guisp=NONE cterm=NONE,reverse gui=NONE,reverse
hi PmenuSel ctermfg=14 ctermbg=15 guifg=#93a1a1 guibg=#fdf6e3 guisp=NONE cterm=NONE,reverse gui=NONE,reverse
hi PmenuThumb ctermfg=12 ctermbg=15 guifg=#839496 guibg=#fdf6e3 guisp=NONE cterm=NONE,reverse gui=NONE,reverse
hi Question ctermfg=6 ctermbg=NONE guifg=#2aa198 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
hi! link QuickFixLine Search
hi Search ctermfg=3 ctermbg=NONE guifg=#b58900 guibg=NONE guisp=NONE cterm=NONE,reverse gui=NONE,reverse
hi SignColumn ctermfg=11 ctermbg=NONE guifg=#657b83 guibg=NONE guisp=NONE cterm=NONE gui=NONE
if get(g:, "solarized_statusline", "") == "low"
    hi StatusLine ctermfg=7 ctermbg=10 guifg=#eee8d5 guibg=#586e75 guisp=NONE cterm=NONE,bold,reverse gui=NONE,bold,reverse
    hi StatusLineNC ctermfg=7 ctermbg=14 guifg=#eee8d5 guibg=#93a1a1 guisp=NONE cterm=NONE,reverse gui=NONE,reverse
    hi TabLineSel ctermfg=10 ctermbg=7 guifg=#586e75 guibg=#eee8d5 guisp=NONE cterm=NONE gui=NONE
    hi NormalMode ctermfg=7 ctermbg=10 guifg=#eee8d5 guibg=#586e75 guisp=NONE cterm=NONE,bold,reverse gui=NONE,bold,reverse
else
    hi StatusLine ctermfg=7 ctermbg=0 guifg=#eee8d5 guibg=#073642 guisp=NONE cterm=NONE,reverse gui=NONE,reverse
    hi StatusLineNC ctermfg=7 ctermbg=10 guifg=#eee8d5 guibg=#586e75 guisp=NONE cterm=NONE,reverse gui=NONE,reverse
    hi TabLineSel ctermfg=0 ctermbg=7 guifg=#073642 guibg=#eee8d5 guisp=NONE cterm=NONE gui=NONE
    hi NormalMode ctermfg=7 ctermbg=0 guifg=#eee8d5 guibg=#073642 guisp=NONE cterm=NONE,reverse gui=NONE,reverse
endif
hi TabLine ctermfg=14 ctermbg=7 guifg=#93a1a1 guibg=#eee8d5 guisp=NONE cterm=NONE gui=NONE
hi TabLineFill ctermfg=14 ctermbg=7 guifg=#93a1a1 guibg=#eee8d5 guisp=NONE cterm=NONE gui=NONE
hi InsertMode ctermfg=7 ctermbg=6 guifg=#eee8d5 guibg=#2aa198 guisp=NONE cterm=NONE,bold,reverse gui=NONE,bold,reverse
hi ReplaceMode ctermfg=7 ctermbg=9 guifg=#eee8d5 guibg=#cb4b16 guisp=NONE cterm=NONE,bold,reverse gui=NONE,bold,reverse
hi VisualMode ctermfg=7 ctermbg=5 guifg=#eee8d5 guibg=#d33682 guisp=NONE cterm=NONE,bold,reverse gui=NONE,bold,reverse
hi CommandMode ctermfg=7 ctermbg=5 guifg=#eee8d5 guibg=#d33682 guisp=NONE cterm=NONE,bold,reverse gui=NONE,bold,reverse
hi! link StatusLineTerm StatusLine
hi! link StatusLineTermNC StatusLineNC
hi VertSplit ctermfg=14 ctermbg=7 guifg=#FDF6E3 guibg=#FDF6E3 guisp=NONE cterm=NONE gui=NONE
hi Visual ctermfg=14 ctermbg=15 guifg=#93a1a1 guibg=#fdf6e3 guisp=NONE cterm=NONE,reverse gui=NONE,reverse
hi VisualNOS ctermfg=NONE ctermbg=7 guifg=NONE guibg=#eee8d5 guisp=NONE cterm=NONE,reverse gui=NONE,reverse
hi WarningMsg ctermfg=9 ctermbg=NONE guifg=#cb4b16 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
hi WildMenu ctermfg=14 ctermbg=15 guifg=#93a1a1 guibg=#fdf6e3 guisp=NONE cterm=NONE,reverse gui=NONE,reverse
hi! link Boolean Constant
hi! link Character Constant
hi Comment ctermfg=14 ctermbg=NONE guifg=#93a1a1 guibg=NONE guisp=NONE cterm=NONE gui=NONE,italic
hi! link Conditional Statement
hi Constant ctermfg=6 ctermbg=NONE guifg=#2aa198 guibg=NONE guisp=NONE cterm=NONE gui=NONE
hi! link Define PreProc
hi! link Debug Special
hi! link Delimiter Special
hi Error ctermfg=1 ctermbg=NONE guifg=#dc322f guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
hi! link Exception Statement
hi! link Float Constant
hi! link Function Identifier
hi Identifier ctermfg=4 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
hi Ignore ctermfg=NONE ctermbg=NONE guifg=NONE guibg=NONE guisp=NONE cterm=NONE gui=NONE
hi! link Include PreProc
hi! link Keyword Statement
hi! link Label Statement
hi! link Macro PreProc
hi! link Number Constant
hi! link Operator Statement
hi! link PreCondit PreProc
hi PreProc ctermfg=9 ctermbg=NONE guifg=#cb4b16 guibg=NONE guisp=NONE cterm=NONE gui=NONE
hi! link Repeat Statement
hi Special ctermfg=9 ctermbg=NONE guifg=#cb4b16 guibg=NONE guisp=NONE cterm=NONE gui=NONE
hi! link SpecialChar Special
hi! link SpecialComment Special
hi Statement ctermfg=2 ctermbg=NONE guifg=#859900 guibg=NONE guisp=NONE cterm=NONE gui=NONE
hi! link StorageClass Type
hi! link String Constant
hi! link Structure Type
hi! link Tag Special
hi Todo ctermfg=5 ctermbg=NONE guifg=#d33682 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
hi Type ctermfg=3 ctermbg=NONE guifg=#b58900 guibg=NONE guisp=NONE cterm=NONE gui=NONE
hi! link Typedef Type
hi Underlined ctermfg=13 ctermbg=NONE guifg=#6c71c4 guibg=NONE guisp=NONE cterm=NONE gui=NONE
hi! link lCursor Cursor
hi CursorIM ctermfg=NONE ctermbg=fg guifg=NONE guibg=fg guisp=NONE cterm=NONE gui=NONE
hi ToolbarLine ctermfg=NONE ctermbg=7 guifg=NONE guibg=#eee8d5 guisp=NONE cterm=NONE gui=NONE
hi ToolbarButton ctermfg=10 ctermbg=7 guifg=#586e75 guibg=#eee8d5 guisp=NONE cterm=NONE,bold gui=NONE,bold
if get(g:, 'solarized_extra_hi_groups', 0)
    hi! link vimVar Identifier
    hi! link vimFunc Function
    hi! link vimUserFunc Function
    hi! link helpSpecial Special
    hi! link vimSet Normal
    hi! link vimSetEqual Normal
    hi vimCommentString ctermfg=13 ctermbg=NONE guifg=#6c71c4 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi vimCommand ctermfg=3 ctermbg=NONE guifg=#b58900 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi vimCmdSep ctermfg=4 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi helpExample ctermfg=10 ctermbg=NONE guifg=#586e75 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi helpOption ctermfg=6 ctermbg=NONE guifg=#2aa198 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi helpNote ctermfg=5 ctermbg=NONE guifg=#d33682 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi helpVim ctermfg=5 ctermbg=NONE guifg=#d33682 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi helpHyperTextJump ctermfg=4 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi helpHyperTextEntry ctermfg=2 ctermbg=NONE guifg=#859900 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi vimIsCommand ctermfg=12 ctermbg=NONE guifg=#839496 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi vimSynMtchOpt ctermfg=3 ctermbg=NONE guifg=#b58900 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi vimSynType ctermfg=6 ctermbg=NONE guifg=#2aa198 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi vimHiLink ctermfg=4 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi vimHiGroup ctermfg=4 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi vimGroup ctermfg=4 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi! link diffAdded Statement
    hi! link diffLine Identifier
    hi gitcommitComment ctermfg=14 ctermbg=NONE guifg=#93a1a1 guibg=NONE guisp=NONE cterm=NONE gui=NONE,italic
    hi! link gitcommitUntracked gitcommitComment
    hi! link gitcommitDiscarded gitcommitComment
    hi! link gitcommitSelected gitcommitComment
    hi gitcommitUnmerged ctermfg=2 ctermbg=NONE guifg=#859900 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi gitcommitOnBranch ctermfg=14 ctermbg=NONE guifg=#93a1a1 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi gitcommitBranch ctermfg=5 ctermbg=NONE guifg=#d33682 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi! link gitcommitNoBranch gitcommitBranch
    hi gitcommitdiscardedtype ctermfg=1 ctermbg=NONE guifg=#dc322f guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi gitcommitselectedtype ctermfg=2 ctermbg=NONE guifg=#859900 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi gitcommitHeader ctermfg=14 ctermbg=NONE guifg=#93a1a1 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi gitcommitUntrackedFile ctermfg=6 ctermbg=NONE guifg=#2aa198 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi gitcommitDiscardedFile ctermfg=1 ctermbg=NONE guifg=#dc322f guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi gitcommitSelectedFile ctermfg=2 ctermbg=NONE guifg=#859900 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi gitcommitUnmergedFile ctermfg=3 ctermbg=NONE guifg=#b58900 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi gitcommitFile ctermfg=11 ctermbg=NONE guifg=#657b83 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi! link gitcommitDiscardedArrow gitcommitDiscardedFile
    hi! link gitcommitSelectedArrow gitcommitSelectedFile
    hi! link gitcommitUnmergedArrow gitcommitUnmergedFile
    hi htmlTag ctermfg=14 ctermbg=NONE guifg=#93a1a1 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi htmlEndTag ctermfg=14 ctermbg=NONE guifg=#93a1a1 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi htmlTagN ctermfg=10 ctermbg=NONE guifg=#586e75 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi htmlTagName ctermfg=4 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi htmlSpecialTagName ctermfg=4 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE,italic
    hi htmlArg ctermfg=12 ctermbg=NONE guifg=#839496 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi javaScript ctermfg=3 ctermbg=NONE guifg=#b58900 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi! link jsFuncCall Function
    hi perlHereDoc ctermfg=10 ctermbg=15 guifg=#586e75 guibg=#fdf6e3 guisp=NONE cterm=NONE gui=NONE
    hi perlVarPlain ctermfg=3 ctermbg=15 guifg=#b58900 guibg=#fdf6e3 guisp=NONE cterm=NONE gui=NONE
    hi perlStatementFileDesc ctermfg=6 ctermbg=15 guifg=#2aa198 guibg=#fdf6e3 guisp=NONE cterm=NONE gui=NONE
    hi texstatement ctermfg=6 ctermbg=15 guifg=#2aa198 guibg=#fdf6e3 guisp=NONE cterm=NONE gui=NONE
    hi texmathzonex ctermfg=3 ctermbg=15 guifg=#b58900 guibg=#fdf6e3 guisp=NONE cterm=NONE gui=NONE
    hi texmathmatcher ctermfg=3 ctermbg=15 guifg=#b58900 guibg=#fdf6e3 guisp=NONE cterm=NONE gui=NONE
    hi texreflabel ctermfg=3 ctermbg=15 guifg=#b58900 guibg=#fdf6e3 guisp=NONE cterm=NONE gui=NONE
    hi rubyDefine ctermfg=10 ctermbg=15 guifg=#586e75 guibg=#fdf6e3 guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi! link rubySymbol Type
    hi rubyBoolean ctermfg=5 ctermbg=15 guifg=#d33682 guibg=#fdf6e3 guisp=NONE cterm=NONE gui=NONE
    let hs_highlight_boolean=1
    let hs_highlight_delimiters=1
    hi cPreCondit ctermfg=9 ctermbg=NONE guifg=#cb4b16 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi VarId ctermfg=4 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi ConId ctermfg=3 ctermbg=NONE guifg=#b58900 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi hsImport ctermfg=5 ctermbg=NONE guifg=#d33682 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi hsString ctermfg=12 ctermbg=NONE guifg=#839496 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi hsStructure ctermfg=6 ctermbg=NONE guifg=#2aa198 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi hs_hlFunctionName ctermfg=4 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi hsStatement ctermfg=6 ctermbg=NONE guifg=#2aa198 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi hsImportLabel ctermfg=6 ctermbg=NONE guifg=#2aa198 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi hs_OpFunctionName ctermfg=3 ctermbg=NONE guifg=#b58900 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi hs_DeclareFunction ctermfg=9 ctermbg=NONE guifg=#cb4b16 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi hsVarSym ctermfg=6 ctermbg=NONE guifg=#2aa198 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi hsType ctermfg=3 ctermbg=NONE guifg=#b58900 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi hsTypedef ctermfg=6 ctermbg=NONE guifg=#2aa198 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi hsModuleName ctermfg=2 ctermbg=NONE guifg=#859900 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi! link hsImportParams Delimiter
    hi! link hsDelimTypeExport Delimiter
    hi! link hsModuleStartLabel hsStructure
    hi! link hsModuleWhereLabel hsModuleStartLabel
    hi hsNiceOperator ctermfg=6 ctermbg=NONE guifg=#2aa198 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi hsniceoperator ctermfg=6 ctermbg=NONE guifg=#2aa198 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi pandocTitleBlock ctermfg=4 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi pandocTitleBlockTitle ctermfg=4 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi pandocTitleComment ctermfg=4 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi pandocComment ctermfg=14 ctermbg=NONE guifg=#93a1a1 guibg=NONE guisp=NONE cterm=NONE gui=NONE,italic
    hi pandocVerbatimBlock ctermfg=3 ctermbg=NONE guifg=#b58900 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi! link pandocVerbatimBlockDeep pandocVerbatimBlock
    hi! link pandocCodeBlock pandocVerbatimBlock
    hi! link pandocCodeBlockDelim pandocVerbatimBlock
    hi pandocBlockQuote ctermfg=4 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi pandocBlockQuoteLeader1 ctermfg=4 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi pandocBlockQuoteLeader2 ctermfg=6 ctermbg=NONE guifg=#2aa198 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi pandocBlockQuoteLeader3 ctermfg=3 ctermbg=NONE guifg=#b58900 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi pandocBlockQuoteLeader4 ctermfg=1 ctermbg=NONE guifg=#dc322f guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi pandocBlockQuoteLeader5 ctermfg=11 ctermbg=NONE guifg=#657b83 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi pandocBlockQuoteLeader6 ctermfg=14 ctermbg=NONE guifg=#93a1a1 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi pandocListMarker ctermfg=5 ctermbg=NONE guifg=#d33682 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi pandocListReference ctermfg=5 ctermbg=NONE guifg=#d33682 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi pandocDefinitionBlock ctermfg=13 ctermbg=NONE guifg=#6c71c4 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi pandocDefinitionTerm ctermfg=13 ctermbg=NONE guifg=#6c71c4 guibg=NONE guisp=NONE cterm=NONE,standout gui=NONE,standout
    hi pandocDefinitionIndctr ctermfg=13 ctermbg=NONE guifg=#6c71c4 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi pandocEmphasisDefinition ctermfg=13 ctermbg=NONE guifg=#6c71c4 guibg=NONE guisp=NONE cterm=NONE gui=NONE,italic
    hi pandocEmphasisNestedDefinition ctermfg=13 ctermbg=NONE guifg=#6c71c4 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi pandocStrongEmphasisDefinition ctermfg=13 ctermbg=NONE guifg=#6c71c4 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi pandocStrongEmphasisNestedDefinition ctermfg=13 ctermbg=NONE guifg=#6c71c4 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi pandocStrongEmphasisEmphasisDefinition ctermfg=13 ctermbg=NONE guifg=#6c71c4 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi pandocStrikeoutDefinition ctermfg=13 ctermbg=NONE guifg=#6c71c4 guibg=NONE guisp=NONE cterm=NONE,reverse gui=NONE,reverse
    hi pandocVerbatimInlineDefinition ctermfg=13 ctermbg=NONE guifg=#6c71c4 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi pandocSuperscriptDefinition ctermfg=13 ctermbg=NONE guifg=#6c71c4 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi pandocSubscriptDefinition ctermfg=13 ctermbg=NONE guifg=#6c71c4 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi pandocTable ctermfg=4 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi pandocTableStructure ctermfg=4 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi! link pandocTableStructureTop pandocTableStructre
    hi! link pandocTableStructureEnd pandocTableStructre
    hi pandocTableZebraLight ctermfg=4 ctermbg=15 guifg=#268bd2 guibg=#fdf6e3 guisp=NONE cterm=NONE gui=NONE
    hi pandocTableZebraDark ctermfg=4 ctermbg=7 guifg=#268bd2 guibg=#eee8d5 guisp=NONE cterm=NONE gui=NONE
    hi pandocEmphasisTable ctermfg=4 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE,italic
    hi pandocEmphasisNestedTable ctermfg=4 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi pandocStrongEmphasisTable ctermfg=4 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi pandocStrongEmphasisNestedTable ctermfg=4 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi pandocStrongEmphasisEmphasisTable ctermfg=4 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi pandocStrikeoutTable ctermfg=4 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE,reverse gui=NONE,reverse
    hi pandocVerbatimInlineTable ctermfg=4 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi pandocSuperscriptTable ctermfg=4 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi pandocSubscriptTable ctermfg=4 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi pandocHeading ctermfg=9 ctermbg=NONE guifg=#cb4b16 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi pandocHeadingMarker ctermfg=9 ctermbg=NONE guifg=#cb4b16 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi pandocEmphasisHeading ctermfg=9 ctermbg=NONE guifg=#cb4b16 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi pandocEmphasisNestedHeading ctermfg=9 ctermbg=NONE guifg=#cb4b16 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi pandocStrongEmphasisHeading ctermfg=9 ctermbg=NONE guifg=#cb4b16 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi pandocStrongEmphasisNestedHeading ctermfg=9 ctermbg=NONE guifg=#cb4b16 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi pandocStrongEmphasisEmphasisHeading ctermfg=9 ctermbg=NONE guifg=#cb4b16 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi pandocStrikeoutHeading ctermfg=9 ctermbg=NONE guifg=#cb4b16 guibg=NONE guisp=NONE cterm=NONE,reverse gui=NONE,reverse
    hi pandocVerbatimInlineHeading ctermfg=9 ctermbg=NONE guifg=#cb4b16 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi pandocSuperscriptHeading ctermfg=9 ctermbg=NONE guifg=#cb4b16 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi pandocSubscriptHeading ctermfg=9 ctermbg=NONE guifg=#cb4b16 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi pandocLinkDelim ctermfg=14 ctermbg=NONE guifg=#93a1a1 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi pandocLinkLabel ctermfg=4 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi pandocLinkText ctermfg=4 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi pandocLinkURL ctermfg=12 ctermbg=NONE guifg=#839496 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi pandocLinkTitle ctermfg=12 ctermbg=NONE guifg=#839496 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi pandocLinkTitleDelim ctermfg=14 ctermbg=NONE guifg=#93a1a1 guibg=NONE guisp=#839496 cterm=NONE gui=NONE
    hi pandocLinkDefinition ctermfg=6 ctermbg=NONE guifg=#2aa198 guibg=NONE guisp=#839496 cterm=NONE gui=NONE
    hi pandocLinkDefinitionID ctermfg=4 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi pandocImageCaption ctermfg=13 ctermbg=NONE guifg=#6c71c4 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi pandocFootnoteLink ctermfg=2 ctermbg=NONE guifg=#859900 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi pandocFootnoteDefLink ctermfg=2 ctermbg=NONE guifg=#859900 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi pandocFootnoteInline ctermfg=2 ctermbg=NONE guifg=#859900 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi pandocFootnote ctermfg=2 ctermbg=NONE guifg=#859900 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi pandocCitationDelim ctermfg=5 ctermbg=NONE guifg=#d33682 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi pandocCitation ctermfg=5 ctermbg=NONE guifg=#d33682 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi pandocCitationID ctermfg=5 ctermbg=NONE guifg=#d33682 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi pandocCitationRef ctermfg=5 ctermbg=NONE guifg=#d33682 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi pandocStyleDelim ctermfg=14 ctermbg=NONE guifg=#93a1a1 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi pandocEmphasis ctermfg=11 ctermbg=NONE guifg=#657b83 guibg=NONE guisp=NONE cterm=NONE gui=NONE,italic
    hi pandocEmphasisNested ctermfg=11 ctermbg=NONE guifg=#657b83 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi pandocStrongEmphasis ctermfg=11 ctermbg=NONE guifg=#657b83 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi pandocStrongEmphasisNested ctermfg=11 ctermbg=NONE guifg=#657b83 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi pandocStrongEmphasisEmphasis ctermfg=11 ctermbg=NONE guifg=#657b83 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi pandocStrikeout ctermfg=14 ctermbg=NONE guifg=#93a1a1 guibg=NONE guisp=NONE cterm=NONE,reverse gui=NONE,reverse
    hi pandocVerbatimInline ctermfg=3 ctermbg=NONE guifg=#b58900 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi pandocSuperscript ctermfg=13 ctermbg=NONE guifg=#6c71c4 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi pandocSubscript ctermfg=13 ctermbg=NONE guifg=#6c71c4 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi pandocRule ctermfg=4 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi pandocRuleLine ctermfg=4 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi pandocEscapePair ctermfg=1 ctermbg=NONE guifg=#dc322f guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi pandocCitationRef ctermfg=5 ctermbg=NONE guifg=#d33682 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi pandocNonBreakingSpace ctermfg=1 ctermbg=NONE guifg=#dc322f guibg=NONE guisp=NONE cterm=NONE,reverse gui=NONE,reverse
    hi! link pandocEscapedCharacter pandocEscapePair
    hi! link pandocLineBreak pandocEscapePair
    hi pandocMetadataDelim ctermfg=14 ctermbg=NONE guifg=#93a1a1 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi pandocMetadata ctermfg=4 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi pandocMetadataKey ctermfg=4 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE gui=NONE
    hi pandocMetadata ctermfg=4 ctermbg=NONE guifg=#268bd2 guibg=NONE guisp=NONE cterm=NONE,bold gui=NONE,bold
    hi! link pandocMetadataTitle pandocMetadata
endif
if get(g:, "solarized_term_italics", 0)
    hi Comment cterm=italic
    hi gitcommitComment cterm=italic
    hi htmlSpecialTagName cterm=italic
    hi pandocComment cterm=italic
    hi pandocEmphasisDefinition cterm=italic
    hi pandocEmphasisTable cterm=italic
    hi pandocEmphasis cterm=italic
endif
finish


