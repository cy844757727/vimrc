" Basic configure ======================
" """"""""""""""""""""""""""""""""""""""""""""
" The following four lines are placed at the front
" so that there is no flash at startup
set nocompatible
set shell=/usr/bin/env\ bash
syntax on
set termguicolors
colorscheme codeschool
filetype plugin indent on
" set default options
set tw=0
set number noshowcmd splitright wildmenu ruler wrap smartindent
set autoread autoindent autochdir noswapfile nobackup confirm
set hlsearch ignorecase incsearch cursorline smarttab nospell
set expandtab tabstop=4 shiftwidth=4 softtabstop=4
set foldcolumn=0 foldminlines=10 foldlevel=99 foldnestmax=3
set foldtext=misc#FoldText() tabline=%!misc#TabLine()
set shortmess=aoOtTcF mousetime=1000 signcolumn=auto
set tags+=./.tags,.tags bsdir=buffer mouse=a viminfo=
set title titlestring=\ Vim winminheight=1 winminwidth=1
set fillchars=fold:\ ,diff:\ ,vert:│
set completeopt=menu,menuone,noinsert,noselect
set diffopt=vertical,filler,foldcolumn:0,context:5
" gcc/g++
set errorformat=%E%f:%l:%c:\ error:\ %m
set errorformat+=%W%f:%l:%c:\ warning:\ %m
" verilog: modelsim
"set errorformat+=**\ Error:\ (vlog-%*\\d)\ %f(%l):\ %m
"set errorformat+=**\ Error:\ (vlog-%*\\d)\ %f(%l.%c):\ %m
"set errorformat+=**\ Error:\ (suppressible):\ %f(%l.%c):\ %m
"set errorformat+=**\ Error:\ %f(%l):\ %m
"set errorformat+=**\ Error:\ %f(%l.%c):\ %m
"set errorformat+=**\ at\ %f(%l):\ %m
"set errorformat+=**\ at\ %f(%l.%c):\ %m
" Language & encode config
set encoding=utf-8 fileformats=unix,dos,mac
set fileencodings=utf-8,gb18030,gbk,gb2312,big5,ucs-bom,shift-jis,utf-16,latin1
" Statusline config
set laststatus=2
set statusline=\ %{iconicFont#icon(&bt,get(g:,'Sign_projectized',0)?'':empty(&key)?'':'')}
set statusline+=\ %f%m%r%h%w%<%=%{misc#StatuslineExtra()}%3(%)
set statusline+=%{iconicFont#icon(empty(&ft)?expand('%:e'):&ft,'')}\ %Y
set statusline+=\ %{&binary?'':iconicFont#icon(&ff)}\ %{&fenc}
set statusline+=\ %3(%)%5(%l%):%-5(%c%V%)\ %4P%(\ %)

" Global enviroment config
let g:BottomWinHeight = 15
let g:SideWinWidth = 31
let g:SideWinMode = 1
let g:env = {'&autochdir': 0}

" Autocmd & command ===================== {{{1
augroup vimrc
    autocmd!
    autocmd BufRead,BufNewFile *.v,*.vh,*.vp,*.vt,*.vo,*.vg set filetype=verilog
    autocmd BufRead,BufNewFile *.sv,*.svi,*.svh,*.svp,*.sva set filetype=systemverilog
    autocmd BufRead,BufNewFile *.d set filetype=make
    autocmd BufRead,BufNewFile *.tag,*.tags set filetype=tags
    autocmd BufRead,BufNewFile *.edf set filetype=none
    autocmd BufRead ?* if &fenc=='latin1'|edit ++bin|endif
	autocmd VimEnter * set nocp
    autocmd User WorkSpaceSavePre call PreSaveWorkSpace_Var()
    autocmd User WorkSpaceLoadPre call async#JobRun('!', 'ctags -R -f .tags', {}, {'flag': '[I]'})
    autocmd User VimInfoLoadPre call misc#EnvUnlock()
    autocmd User VimInfoLoadPost call misc#Env('-i')
    autocmd User WorkSpaceLoadPost call PostLoadWorkSpace_Var()
augroup END


command! Info :call misc#Information('detail')
command! ATags :Async! ctags -R -f .tags
command! -nargs=? -complete=custom,misc#CompleteSide ToggleSideWin :call misc#ToggleSideBar(<q-args>)
command! -nargs=? -complete=custom,misc#CompleteEnv Env :call misc#Env(<q-args>)
command! -nargs=? -complete=custom,misc#CompleteTask Task :call misc#EnvTaskQueue(<q-args>)
command! -nargs=? -complete=custom,misc#CompleteF5 F5 :call misc#F5Function(<q-args>)
command! -nargs=* -count=15 Msg :call misc#MsgFilter(<count>, <f-args>)
command! -nargs=* -bang -range -complete=file Open :Async<bang> xdg-open <args>
command! -nargs=? VResize :vertical resize <args>
command! -nargs=* -range -addr=tabs -complete=file T :<line1>tabedit <args>
command! TClose tabclose
command! TQuit TClose
command! -nargs=+ DBufHis :call misc#BufHisDel(<f-args>)
command! Avdel :Async vdel -lib work -all
command! -nargs=? -complete=tag Ag :call misc#Ag(<q-args>, 0)
command! -nargs=* Amake :Asyncrun make <args>

"快捷键映射===================== {{{1
" 括号引号自动补全
inoremap ( ()<Esc>i
inoremap ) <C-r>=Vimrc_ClosePair(')')<CR>
inoremap [ []<Esc>i
inoremap ] <C-r>=Vimrc_ClosePair(']')<CR>
inoremap { {}<Esc>i
inoremap } <C-r>=Vimrc_ClosePair('}')<CR>
inoremap " ""<Esc>i

function! Vimrc_ClosePair(char)
    return getline('.')[col('.') - 1] == a:char ? "\<Right>" : a:char
endfunction

noremap <silent> \| :call Async_run()<CR><BS>
"nnoremap \|\| <Esc>:Asyncrun 
noremap <silent> <C-j> :call misc#NextItem('next')<CR>
noremap <silent> <C-k> :call misc#NextItem('previous')<CR>
map! <C-j> <Esc><C-j>
map! <C-k> <Esc><C-k>

inoremap <C-\> <Esc>o
nnoremap <silent> <C-g> :call misc#Information('simple')<CR>
map! <C-g> <Esc><C-g>
vnoremap <silent> <C-g> :call misc#Information('visual')<CR>
" External open
nnoremap <silent> \cd :exe 'cd '.fnameescape(expand('%:h')).'\|pwd'<CR>
nnoremap <silent> \od :Open! .<CR>
nnoremap <silent> \of :exe 'Open! '.fnameescape(expand('%'))<CR>
nnoremap <silent> \rf :exe 'Open! '.fnameescape(expand('%:h'))<CR>
vnoremap <silent> \op <Esc>:exe 'Async xdg-open '.getreg('*')<CR>
nnoremap <silent> \op :exe 'Async xdg-open '.expand('<cWORD>')<CR>
" ctrlp
"nnoremap <silent> \t :CtrlPBufTag<CR>
"nnoremap <silent> \T :CtrlpTag<CR>
"nnoremap <silent> \l :CtrlpLine %<CR>
"nnoremap <silent> \L :CtrlpLine<CR>
"nnoremap <silent> \F :CtrlpBuffer<CR>
"nnoremap <silent> \f :CtrlP<CR>
" Leaderf.vim maping
nnoremap <silent> \t :call Vimrc_leader('LeaderfBufTag')<CR>
vnoremap <silent> \t :call Vimrc_leader('LeaderfBufTagPattern '.getreg('*'))<CR>
nnoremap <silent> \T :LeaderfTag<CR>
vnoremap <silent> \T <Esc>:exe 'LeaderfTagPattern '.getreg('*')<CR>
nnoremap <silent> \l :call Vimrc_leader('LeaderfLine')<CR>
vnoremap <silent> \l :call Vimrc_leader('LeaderfLinePattern '.getreg('*'))<CR>
nnoremap <silent> \L :call Vimrc_leader('LeaderfLineAll')<CR>
vnoremap <silent> \L :call Vimrc_leader('LeaderfLineAllPattern '.getreg('*'))<CR>
nnoremap <silent> \b :LeaderfBuffer<CR>
nnoremap <silent> \F :LeaderfFile %:h<CR>
nnoremap <silent> \f :LeaderfFile<CR>

function! Vimrc_leader(cmd) range
    let l:save_pos = getpos('.')
    exe a:cmd
    call setpos("''", l:save_pos)
endfunction

nnoremap <silent> \ag :call misc#Ag(expand('<cword>'), 1)<CR>
vnoremap <silent> \ag :call misc#Ag(getreg('*'), 0)<CR>
nnoremap <silent> \=  :call misc#CodeFormat()<CR>
vnoremap <silent> \=  :call misc#CodeFormat()<CR>
nnoremap <silent> \q  :call misc#ReverseComment()<CR>
vnoremap <silent> \q  :call misc#ReverseComment()<CR>
nnoremap <silent> \h  :call misc#HEXCovent()<CR>
" ctrl-\ ctrl-n : switch to terminal-normal

nnoremap <C-@> :Ydc<CR>
nnoremap <C-t> :echo<CR>
" find / replace
vnoremap <C-f> <Esc>k:exe '/'.getreg('*')<CR>
nnoremap <C-f> viw<Esc>k:exe '/\<'.getreg('*').'\>'<CR>kn
vnoremap <C-h> <Esc>:call misc#StrSubstitute(getreg('*'))<CR>
nnoremap <C-h> :call misc#StrSubstitute('\<'.expand('<cword>').'\>')<CR>
imap <C-f> <Esc><C-f>
imap <C-h> <Esc><C-h>

" Save & winresize & f5 function
noremap <silent> <f3>     :call misc#SaveFile()<CR>
noremap <silent> <f4>     :call misc#WinResize()<CR>
nnoremap <silent> <f5>    :call misc#F5Function('run')<CR>
vnoremap <silent> <f5>    :call misc#F5Function('visual')<CR>
noremap <silent> <C-f5>   :call misc#F5Function('task')<CR>
nnoremap <silent> <S-f5>  :call misc#F5Function('task')<CR>
vnoremap <silent> <S-f5>  :call misc#F5Function('task_visual')<CR>
noremap <silent> <C-S-f5> :call misc#F5Function('task_queue')<CR>
map! <f3> <Esc><f3>
map! <f4> <Esc><f4>
imap <f5> <Esc><f5>
map! <C-f5> <Esc><C-f5>
imap <S-f5> <Esc><S-f5>
map! <C-S-f5> <Esc><C-S-f5>
" sign.vim: bookmark, breakpoint
noremap <silent> <f6>     :call sign#Toggle('break')<CR>
noremap <silent> <C-f6>   :call sign#Toggle('tbreak')<CR>
noremap <silent> <f7>     :call sign#Toggle('book')<CR>
noremap <silent> <C-f7>   :call sign#Toggle('todo')<CR>
noremap <silent> <C-Down> :call sign#Jump('book', 'next')<CR>
noremap <silent> <C-Up>   :call sign#Jump('book', 'previous')<CR>
map! <f6> <Esc><f6>
map! <C-f6> <Esc><C-f6>
map! <f7> <Esc><f7>
map! <C-f7> <Esc><C-f7>
map! <C-Down> <Esc><C-Down>
map! <C-Up> <Esc><C-Up>
" Window & tabpage toggle
noremap <silent> <f8>      :call misc#ToggleSideBar()<CR>
noremap <silent> <C-f8>    :call misc#ToggleSideBar('Tagbar')<CR>
noremap <silent> <S-f8>    :call misc#ToggleSideBar('NERDTree')<CR>
noremap <silent> <C-S-f8>  :call misc#ToggleSideBar('all')<CR>
noremap <silent> <f9>      :call git#Toggle()<CR>
noremap <silent> <f10>     :call misc#ToggleBottomBar('quickfix', '')<CR>
noremap <silent> <C-f10>   :call misc#ToggleBottomBar('quickfix', 'book')<CR>
noremap <silent> <S-f10>   :call misc#ToggleBottomBar('quickfix', 'todo')<CR>
noremap <silent> <C-S-f10> :call misc#ToggleBottomBar('quickfix', 'break')<CR>
noremap <silent> <f12>     :call misc#ToggleBottomBar('terminal', '')<CR>
noremap <silent> <C-f12>   :call misc#ToggleBottomBar('terminal', 'ipython3')<CR>
noremap <silent> <S-f12>   :call misc#ToggleBottomBar('terminal', 'python3')<CR>
noremap <silent> <C-S-f12> :call misc#ToggleBottomBar('terminal', 'popup')<CR>
map! <f8> <Esc><f8>
map! <C-f8> <Esc><C-f8>
map! <S-f8> <Esc><S-f8>
map! <C-S-f8> <Esc><C-S-f8>
map! <f9> <Esc><f9>
map! <f10> <ESC><f10>
map! <C-f10> <ESC><C-f10>
map! <S-f10> <ESC><S-f10>
map! <C-S-f10> <ESC><C-S-f10>
map! <f12> <Esc><f12>
map! <C-f12> <Esc><C-f12>
map! <S-f12> <Esc><S-f12>
map! <C-S-f12> <Esc><C-S-f12>
" Terminal map
tnoremap <silent> <f4> <C-w>N:call execute(['norm a', 'call misc#WinResize()'])<CR>
tnoremap <silent> <f10> <C-w>N:call execute(['norm a', "call misc#ToggleBottomBar('quickfix', '')"])<CR>
tnoremap <silent> <C-f10> <C-w>N:call execute(['norm a', "call misc#ToggleBottomBar('quickfix','book')"])<CR>
tnoremap <silent> <S-f10> <C-w>N:call execute(['norm a', "call misc#ToggleBottomBar('quickfix','todo')"])<CR>
tnoremap <silent> <C-S-f10> <C-w>N:call execute(['norm a', "call misc#ToggleBottomBar('quickfix','break')"])<CR>
tnoremap <silent> <f12> <C-w>N:call execute(['norm a', "call misc#ToggleBottomBar('terminal', '')"])<CR>
tnoremap <silent> <C-f12> <C-w>N:call execute(['norm a', "call misc#ToggleBottomBar('terminal','ipython3')"])<CR>
tnoremap <silent> <S-f12> <C-w>N:call execute(['norm a', "call misc#ToggleBottomBar('terminal','python3')"])<CR>
tnoremap <silent> <C-S-f12> <C-w>N:call execute(['norm a',"call misc#ToggleBottomBar('terminal','popup')"])<CR>

noremap <silent> <C-HOME> :1tabnext<CR>
noremap <silent> <C-END> :$tabnext<CR>
map! <silent> <Esc><C-HOME> :1tabnext<CR>
map! <silent> <Esc><C-END> :$tabnext<CR>
" Window & tab switch
tnoremap <silent> <C-PageUp>   <C-w>N:call execute(['normal a', 'tabnext'])<CR>
tnoremap <silent> <C-PageDown> <C-w>N:call execute(['normal a', 'tabprevious'])<CR>
tnoremap <silent> <C-HOME>   <C-w>N:call execute(['normal a', '1tabnext'])<CR>
tnoremap <silent> <C-END> <C-w>N:call execute(['normal a', '$tabnext'])<CR>
tnoremap <silent> <C-Up>   <C-w>N:call execute(['normal a', 'wincmd W'])<CR>
tnoremap <silent> <C-Down> <C-w>N:call execute(['normal a', 'wincmd w'])<CR>
noremap  <silent> <C-Up>   :wincmd W<CR>
noremap  <silent> <C-Down> :wincmd w<CR>
map! <C-Up> <Esc><C-Up>
map! <C-Down> <Esc><C-Down>

tnoremap <silent> <f5>   <C-w>N:call execute(['normal a', "call misc#F5Function('run')"])<CR>
tnoremap <silent> <C-f5> <C-w>N:call execute(['normal a', "call misc#F5Function('debug')"])<CR>
tnoremap <silent> <S-f5> <C-w>N:call execute(['normal a', "call misc#F5Function('task')"])<CR>

tnoremap <silent> <PageDown> <C-w>N
tnoremap <silent> <PageUp> <C-w>N
tnoremap <silent> <C-e> <C-w>N
tnoremap <silent> <C-y> <C-w>N
" Buffer switch
tnoremap <silent> <C-left>  <C-w>N:call execute(['normal a', "call async#TermSwitch('previous')"], '')<CR>
tnoremap <silent> <C-right> <C-w>N:call execute(['normal a', "call async#TermSwitch('next')"], '')<CR>
noremap  <silent> <C-left>  :call misc#BufHisSwitch('previous')<CR>
noremap  <silent> <C-right> :call misc#BufHisSwitch('next')<CR>
map! <C-left> <Esc><C-left>
map! <C-right> <Esc><C-right>

"let Git_GuiDiffTool = 1
" Termdebug
let g:termdebug_wide = 1
" Plugin Configure ======================
" === async.vim === {{{1
let g:async_termType = [
            \ 'python3',  'python2',  'python',
            \ 'ipython3', 'ipython2', 'ipython',
            \ 'jupyter-console', 'csh'
            \ ]

" === CtrlP ============ {{{1
let g:ctrlp_by_filename = 1
let g:ctrlp_show_hidden = 0
let g:ctrlp_extensions = ['tag', 'buffertag', 'dir', 'line']
let g:ctrlp_match_window = 'bottom,order:ttb,min:15,max:15,results:30'
let g:ctrlp_working_path_mode = 'rw'
let g:ctrlp_root_markers = ['.svn', '.git']
let g:ctrlp_custom_ignore = {
            \ 'dir': '\v[\/].(git|hg|svn)$',
            \ 'file': '\v\.(session|viminfo|tags|signrecord)',
            \ 'link': 'SOME_BAD_SYMBOLIC_LINKS'
            \ }

" === Leaderf =========={{{1
let g:Lf_DefaultMode = 'NameOnly'
let g:Lf_WildIgnore = {
            \ 'dir': ['.svn', '.git', '.hg'],
            \ 'file': ['*.bak', '*.o', '*.so', '*.py[co]']
            \ }
let g:Lf_PreviewResult = {
        \ 'File': 0,
        \ 'Buffer': 0,
        \ 'Mru': 0,
        \ 'Tag': 0,
        \ 'BufTag': 1,
        \ 'Function': 1,
        \ 'Line': 0,
        \ 'Colorscheme': 0
        \}
let g:Lf_WorkingDirectoryMode = 'Ac'
let g:Lf_RootMarkers = ['.git', '.svn', '.hg']
" === Netrw-NERDTree === {{{1
let g:netrw_dirhistmax=0
let g:netrw_browse_split=4
let g:netrw_altv=1
let g:netrw_banner=0
let g:netrw_liststyle=3
let g:NERDTreeWinPos ='left'
let g:NERDTreeWinSize=get(g:, 'SideWinWidth', 31)
let g:NERDTreeStatusline=' פּ NERDTree'
let g:NERDTreeAutoDeleteBuffer=1
let g:NERDTreeMouseMode=2
let g:NERDTreeDirArrowExpandable = ''
let g:NERDTreeDirArrowCollapsible = ''
" Do not use fold decoration from webicons (use above set instead)
let g:WebDevIconsUnicodeDecorateFolderNodes = 0
" When g:WebDevIconsUnicodeDecorateFolderNodes set to 1: use below set
"let g:NERDTreeDirArrowExpandable = '▸'
"let g:NERDTreeDirArrowCollapsible = '▾'

" =================================================================================
" ===== Modify NERDtree plugin: ~/.vim/lib/nerdtree/tree_file_node.vim  line:347 ====
" ===== To reduce excess whitespace for align (file, fold) ========================
"     if !self.path.isDirectory && (!exists('g:WebDevIconsUnicodeDecorateFolderNodes') || g:WebDevIconsUnicodeDecorateFolderNodes != 0)
"
" ===== Modify NERDtree plugin: ~/.vim/lib/nerdtree/ui.vim  line:277 ================
" ===== To add extra indent for normal file (cause reduce whitespace: above)=======
"    let l:line = empty(matchstr(a:line, '/$')) && (exists('g:WebDevIconsUnicodeDecorateFolderNodes') 
"                \ && g:WebDevIconsUnicodeDecorateFolderNodes == 0) ? '  '.a:line : a:line
" ===== change a:line to line below ===============================================
" =================================================================================

" snippets.vim
let g:snips_author = 'Cy <844757727@qq.com>'
" === tagBar.vim === {{{1
let g:tagbar_width=get(g:, 'SideWinWidth', 31)
let g:tagbar_vertical=&lines/2 - 2
let g:tagbar_silent=1
let g:tagbar_left=0
"let g:tagbar_iconchars = ['●', '○']
let g:tagbar_iconchars = ['▸', '▾']
let g:tagbar_status_func = 'TagbarStatusFunc'

function! TagbarStatusFunc(current, sort, fname, flags, ...) abort
    let l:flagstr = join(a:flags, '')

    if l:flagstr != ''
        let l:flagstr = '['.l:flagstr.'] '
    endif

    return '  Tagbar: '.l:flagstr.a:fname
endfunction

"  TagBar 其他语言支持
"    Makefile
let g:tagbar_type_make = {
            \ 'kinds': [
            \ 'm:macros',
            \ 't:targets'
            \ ]
            \ }
"    Markdown
let g:tagbar_type_markdown = {
            \ 'ctagstype': 'markdown',
            \ 'kinds': [
            \ 'h:Heading_L1',
            \ 'i:Heading_L2',
            \ 'k:Heading_L3'
            \ ]
            \ }

" === Ale.vim === {{{1
" ** Need to install **
" Tool: flake8 pylint pyflakes(linter), yapf autopep8(fixer) : python
" Tool: clang-format(fixer)     : c/c++/java/javascript
" Tool: shellcheck(linter)      : sh
" Tool: perltidy(fixer)         : perl
" *********************
" flake8 msg id
" E22_, E231, E241, E242: missing whitespace
" E26_: comment start          " E501: line too long
" E722: bare except            " E713: test for membership
let g:ale_python_flake8_options = '--ignore=E225,E226,E227,E261,E262,E265,E266,E231,E265,E501,E722,E713'
" pylint msg id
" C0103: invalid-name          " C0112: empty-docstring     " C0303: trailing whitespace
" C0111: missing-docstring     " W0603: global-statement    " W0511: todo ignore
let g:ale_python_pylint_options = '--disable=C0103,C0303,C0111,C0112,W0603,W0511 --jobs=0'
" Verilator option

let g:ale_verilog_verilator_options = '-I.. -I. -sv'
if filereadable('work/verilator.syntax')
    let g:ale_verilog_verilator_options = '-I.. -I. -sv'
endif

let g:ale_sign_error = '▄'
let g:ale_sign_warning = '▎'
let g:ale_echo_msg_error_str = 'E'
let g:ale_echo_msg_warning_str = 'W'
let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'
let g:ale_sign_column_always = 1
let g:ale_lint_on_insert_leave = 1
"let g:ale_lint_delay = 20
let g:ale_lint_on_text_changed = 'normal'
let g:ale_set_loclist = 1
let g:ale_set_quickfix = 0

" === infowin.vim === {{{1
let g:InfoWin_output = 1

" === sign.vim === {{{1
let g:sign_specialBuf = {
            \ 'NERD_tree': 'bw|call Vimrc_Nerd()',
            \ '__Tagbar': 'bw|call Vimrc_Tagbar()'
            \ }

" SpecialBuf hanle
function! Vimrc_Tagbar()
    let l:mode = get(g:, 'SideWinMode', 1)

    if bufwinnr('NERD_tree') == -1 || l:mode == 2 || l:mode == 3
        let g:tagbar_vertical = 0
        let g:tagbar_left = l:mode % 2
        TagbarOpen
        exe 'wincmd '.(g:tagbar_left ? 'W' : 'w')
    else
        let g:tagbar_vertical = &lines % 2 -2
        let g:tagbar_left = 0
        exe bufwinnr('NERD_tree').'wincmd w'
        TagbarOpen
        wincmd w
    endif
endfunction

function! Vimrc_Nerd()
    let g:NERDTreeWinPos = get(g:, 'SideWinMode', 1) > 2 ? 'right' : 'left'
    NERDTree
endfunction

let g:sign_projectType = {
                \ 'c':       '~/Documents/WorkSpace',
                \ 'cpp':     '~/Documents/WorkSpace',
                \ 'fpga':    '~/Documents/Altera',
                \ 'verilog': '~/Documents/Modelsim',
                \ 'altera':  '~/Documents/Altera',
                \ 'xilinx':  '~/Documents/Xilinx',
                \ 'python':  '~/Documents/Python',
                \ 'default': '~/Documents'
                \ }

function! PreSaveWorkSpace_Var()
    let g:TABVAR_MAXMIZEWIN = {}
    let g:WINVAR_BUFHIS = {}

    for l:nr in range(1, tabpagenr('$'))
        " Record win status
        let l:var = gettabvar(l:nr, 'MaxmizeWin', [])
        if !empty(l:var)
            let g:TABVAR_MAXMIZEWIN[l:nr] = l:var
        endif

        " Record buf history in every window
        let g:WINVAR_BUFHIS[l:nr] = {}
        for l:winnr in range(1, tabpagewinnr(l:nr, '$'))
            let l:var = gettabwinvar(l:nr, l:winnr, 'bufHis', {'list': []})
            if len(l:var.list) > 1
                let g:WINVAR_BUFHIS[l:nr][l:winnr] = l:var
            endif
        endfor

        if empty(g:WINVAR_BUFHIS[l:nr])
            unlet g:WINVAR_BUFHIS[l:nr]
        endif
    endfor

    if empty(g:TABVAR_MAXMIZEWIN)
        unlet g:TABVAR_MAXMIZEWIN
    endif

    if empty(g:WINVAR_BUFHIS)
        unlet g:WINVAR_BUFHIS
    endif
endfunction

function! PostLoadWorkSpace_Var()
    if exists('g:TABVAR_MAXMIZEWIN')
        for [l:nr, l:val] in items(g:TABVAR_MAXMIZEWIN)
            call settabvar(l:nr, 'MaxmizeWin', l:val)
        endfor
        unlet g:TABVAR_MAXMIZEWIN
    endif

    if exists('g:WINVAR_BUFHIS')
        for [l:nr, l:dict] in items(g:WINVAR_BUFHIS)
            for [l:winnr, l:val] in items(l:dict)
                call settabwinvar(l:nr, l:winnr, 'bufHis', l:val)
            endfor
        endfor
        unlet g:WINVAR_BUFHIS
    endif
endfunction
"
" === quickui.vim === {{{1
let g:quickui_border_style=2
let g:quickui_color_scheme = 'papercol'
"let g:quickui_color_scheme = 'gruvbox'
"let g:quickui_color_scheme = 'solarized'
"let g:quickui_color_scheme = 'papercol-light'
" === webdevicons.vim === {{{1
" Extended icon
let g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols = {
            \ 'v':    '', 'vh':   '', 'vp':   '', 'vt':   '',
            \ 'vg':   '', 'vo':   '', 'vhdl': '', 'vhd':  '',
            \ 'sv':   '', 'svi':  '', 'svh':  '', 'svp':  '',
            \ 'sva':  '',
            \ 'mp3':  '', 'aac':  '', 'flac': '', 'ape':  '',
            \ 'ogg':  '', 'mp4':  '', 'avi':  '', 'mkv':  '',
            \ 'jar':  '', 'zip':  '', 'rar':  '', 'gzip': '',
            \ 'gz':   '', '7z':   '', 'tar':  '',
            \ 'xls':  '', 'xlsx': '', 'doc':  '', 'docx': '',
            \ 'ppt':  '', 'pptx': '', 'text': '', 'pdf':  '',
            \ 'iso':  '', 'git':  '', 'help': '',
            \ 'tags': '', 'tag':  ''
            \ }

let g:WebDevIconsUnicodeDecorateFileNodesExactSymbols = {
            \ '.tags': '', '.tag': ''
            \ }

let g:WebDevIconsNerdTreeBeforeGlyphPadding = ''

set tw=10000000
set backspace=2
" vim:foldmethod=marker
