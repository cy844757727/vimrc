" Basic configure ======================
" Required external tools 
" Tools: ctags, git pylint, pyflakes, yapf, [ipdb]
" Tools: perltidy, clang-format, bashdb, shfmt
" """"""""""""""""""""""""""""""""""""""""""""
set number         "显示行号
syntax on          "语法高亮
filetype on        "检查文件类型
filetype plugin on
filetype indent on
set tags+=./.tags
set tags+=.tags
set showcmd
set mousetime=1000
"set splitbelow
set splitright
set confirm        "退出保存询问
set ruler          "打开标尺
set completeopt=menu,noinsert,preview
set nocompatible   "关闭兼容模式
set autoread       "设置当文件被改动时自动载入
set nobackup       "禁用备份
set noswapfile
set cursorline     "高亮当前行
set autoindent     "自动缩进
"set cindent        "C系列缩进
set signcolumn=auto
set tabstop=4      "tab键长度
set expandtab      "tab扩展为空格
set shiftwidth=4   "缩进长度
set softtabstop=4  "缩进长度
set smarttab       "智能缩进
set ignorecase     "搜索忽略大小写
set incsearch      "搜索加强
set hlsearch       "搜索高亮
set showmatch      "自动匹配
set matchtime=1    "匹配括号高亮的时间
set viminfo=       "禁用viminfo
set wildmenu       "命令行增强补全显示
set autochdir
set diffopt=vertical,filler,foldcolumn:0,context:3
set bsdir=buffer
set ffs=unix,dos,mac  "换行格式集
set mouse=a           "设置鼠标范围
set laststatus=2      "始终显示状态栏
set completeopt=menu,menuone,noinsert,preview,noselect
" gcc/g++
set errorformat=%f:%l:%c:\ %m
" verilog: modelsim
set errorformat+=**\ Error:\ (vlog-%*\\d)\ %f(%l):\ %m
set errorformat+=**\ Error:\ (vlog-%*\\d)\ %f(%l.%c):\ %m
set errorformat+=**\ Error:\ (suppressible):\ %f(%l.%c):\ %m
set errorformat+=**\ Error:\ %f(%l):\ %m
set errorformat+=**\ Error:\ %f(%l.%c):\ %m
set errorformat+=**\ at\ %f(%l):\ %m
set errorformat+=**\ at\ %f(%l.%c):\ %m
" code folding
"set foldcolumn=1
"set foldmethod=syntax
set foldlevel=99
" Use RGB color scheme in terminal
set termguicolors
colorscheme cydark
" Language & encode set
set helplang=cn
set langmenu=zh_CN.UTF-8
set enc=utf-8
set fencs=utf-8,gb18030,gbk,gb2312,big5,ucs-bom,shift-jis,utf-16,latin1
" TabLine: using t:tab_lable (['glyph', 'name']) variable in tabpage can set custom label
" if Non-existent, using default configure
set tabline=%!misc#TabLine()
set foldtext=misc#FoldText()
" Statusline set
set statusline=\ %{misc#StatuslineIcon()}\ %f%m%r%h%w%<%=
set statusline+=%{LinterStatus()}%3(\ %)
set statusline+=%{misc#GetWebIcon(expand('%'))}\ %Y
set statusline+=\ %{WebDevIconsGetFileFormatSymbol()}\ %{&fenc!=''?&fenc:&enc}\ %3(\ %)
set statusline+=%5(%l%):%-5(%c%V%)\ %4P%(\ %)

"自定义命令/自动命令=====================
augroup UsrDefCmd
    autocmd!
    autocmd QuickFixCmdPost * copen 10
    autocmd BufRead,BufNewFile *.vt,*.vo,*.vg set filetype=verilog
    autocmd BufRead,BufNewFile *.sv set filetype=systemverilog
    autocmd BufRead,BufNewFile *.d set filetype=make
    autocmd BufRead,BufNewFile *.tag,*.tags set filetype=tags
    autocmd InsertEnter * :hi statusline guibg=#6D0EF2
    autocmd InsertLeave * :hi statusline guibg=#006999
augroup END

command! -nargs=? -complete=file T :tabe <args>
command! -range TN :<line1>tabnext
command! -range TP :<line1>tabprevious
command! -range=% CFormat :<line1>,<line2>call misc#CodeFormat()
command! -range RComment :<line1>,<line2>call misc#ReverseComment()
command! -range=% DBlank :<line1>,<line2>s/\s\+$//ge|<line1>,<line2>s/\(\s*\n\+\)\{3,}/\="\n\n"/ge|silent! /@#$%^&*
command! -nargs=* Amake :AsyncRun make
command! Actags :Async ctags -R -f .tags
command! Avdel :Async vdel -lib work -all

"快捷键映射=====================
noremap <silent> <C-left> :call misc#BufHisInAWindow('previous')<CR>
noremap <silent> <C-right> :call misc#BufHisInAWindow('next')<CR>
" 括号引号自动补全
inoremap ( ()<Esc>i
inoremap ) <c-r>=CyClosePair(')')<CR>
inoremap [ []<Esc>i
inoremap ] <c-r>=CyClosePair(']')<CR>
inoremap { {}<Esc>i
inoremap } <c-r>=CyClosePair('}')<CR>
"inoremap ' ''<Esc>i
inoremap " ""<Esc>i

inoremap <C-\> <Esc>o
" External open
nnoremap \cd :exe 'cd ' . expand('%:h') . '\|pwd'<CR>
nnoremap \od :Async xdg-open .<CR>
nnoremap \of :exe 'Async xdg-open ' . expand('%')<CR>
nnoremap \rf :exe 'Async xdg-open ' . expand('%:h')<CR>

vnoremap <silent> \= :call misc#CodeFormat()<CR>
nnoremap <silent> \= :call misc#CodeFormat()<CR>
nnoremap \h  :call misc#HEXCovent()<CR>
nnoremap <silent> \q :call misc#ReverseComment()<CR>
vnoremap <silent> \q :call misc#ReverseComment()<CR>
" ctrl-\ ctrl-n : switch to terminal-normal

" 查找
vnoremap <C-f> yk:exe '/' . getreg('0')<CR><BS>n
nmap <C-f> wbve<C-f>
imap <C-f> <Esc>lwbve<C-f>
" 查找并替换
vnoremap <C-h> y:call misc#StrSubstitute(getreg('0'))<CR>
nmap <C-h> wbve<C-h>
imap <C-h> <Esc>lwbve<C-h>

noremap <silent> <C-l> <Esc>:redraw!<CR>
noremap <silent> <C-a> <Esc>ggvG$
noremap <silent> <C-w> <Esc>:close<CR>
noremap <silent> <S-PageUp> <Esc>:call WindowSwitch('up')<CR>
noremap <silent> <S-pageDown> <Esc>:call WindowSwitch('down')<CR>
noremap <silent> <C-t> <Esc>:tabnew<CR>
noremap <silent> <S-t> <Esc>:try\|tabclose\|catch\|if &diff\|qa\|endif\|endtry<CR>
noremap <silent> <S-tab> <Esc>:tabnext<CR>
map! <C-a> <Esc><C-a>
map! <C-w> <Esc><C-w>
map! <S-PageUp> <Esc><S-PageUp>
map! <S-PageDown> <Esc><S-PageDown>
map! <C-t> <Esc><C-t>
map! <S-tab> <Esc><S-tab>
" 保存快捷键
noremap <silent> <f3> <Esc>:call misc#SaveFile()<CR>
map! <f3> <Esc><f3>
noremap <silent> <f4> :call misc#WinResize()<Cr>
map! <f4> <Esc><f4>
" 窗口切换
noremap <silent> <f9> <Esc>:call git#Toggle()<CR>
noremap <silent> <f8> <Esc>:call misc#ToggleSidebar()<CR>
noremap <silent> <C-S-f8> <Esc>:call misc#ToggleSidebar('off')<CR>
noremap <silent> <C-f8> <Esc>:call misc#ToggleTagbar()<CR>
noremap <silent> <S-f8> <Esc>:call misc#ToggleNERDTree()<CR>
noremap <silent> <f10> <ESC>:call misc#ToggleQuickFix()<CR>
noremap <silent> <C-f10> <ESC>:call misc#ToggleQuickFix('book')<CR>
noremap <silent> <S-f10> <ESC>:call misc#ToggleQuickFix('todo')<CR>
noremap <silent> <C-S-f10> <ESC>:call misc#ToggleQuickFix('break')<CR>
noremap <silent> <f12> :call async#TermToggle()<CR>
noremap <silent> <C-f12> :call async#TermToggle('toggle', 'ipy')<CR>
noremap <silent> <S-f12> :call async#TermToggle('toggle', 'py3')<CR>
noremap <silent> <C-S-f12> :call async#TermToggle('toggle', 'dc')<CR>
map! <f12> <Esc><f12>
map! <C-f12> <Esc><C-f12>
map! <f7> <Esc><f7>
map! <f8> <Esc><f8>
map! <C-f8> <Esc><C-f8>
map! <S-f8> <Esc><S-f8>
map! <C-S-f8> <Esc><C-S-f8>
map! <f9> <Esc><f9>
map! <f10> <ESC><f10>
map! <C-f10> <ESC><C-f10>
map! <S-f10> <ESC><S-f10>
map! <C-S-f10> <ESC><C-S-f10>
" 编译执行
noremap  <silent> <f5> <Esc>:call misc#CompileRun()<CR>
noremap  <silent> <C-f5> <Esc>:call misc#CompileRun('r')<CR>
map! <f5> <Esc><f5>
map! <C-f5> <Esc><C-f5>
" 断点 BMBPSign.vim: breakpoint
noremap  <silent> <f6> <Esc>:call BMBPSign#SignToggle('break')<CR>
noremap  <silent> <C-f6> <Esc>:call BMBPSign#SignToggle('tbreak')<CR>
noremap  <silent> \b <Esc>:call BMBPSign#SignClear('break', 'tbreak')<CR>
map! <C-f6> <Esc><C-f6>
map! <f6> <Esc><f6>
" 书签 BMBPSign.vim: bookmark
noremap <silent> <f7> <Esc>:call BMBPSign#SignToggle('book')<CR>
noremap <silent> <C-f7> <Esc>:call BMBPSign#SignToggle('todo')<CR>
noremap <silent> <C-Down> <Esc>:call BMBPSign#SignJump('book', 'next')<CR>
noremap <silent> <C-Up> <Esc>:call BMBPSign#SignJump('book', 'previous')<CR>
noremap <silent> \m <Esc>:call BMBPSign#SignClear('book')<CR>
map! <f7> <Esc><f7>
map! <C-f7> <Esc><C-f7>
map! <C-Down> <Esc><C-Down>
map! <C-Up> <Esc><C-Up>

" Terminal map
tnoremap <silent> <S-PageUp> <C-w>N:call WindowSwitch('up')<CR>
tnoremap <silent> <S-pageDown> <C-w>N:call WindowSwitch('down')<CR>
tnoremap <silent> <f12> <C-w>N:call async#TermToggle()<CR>
tnoremap <silent> <C-f12> <C-w>N:call async#TermToggle('toggle', 'ipy')<CR>
tnoremap <silent> <S-f12> <C-w>N:call async#TermToggle('toggle', 'py3')<CR>
tnoremap <silent> <C-S-f12> <C-w>N:call async#TermToggle('toggle', 'dc')<CR>
tnoremap <silent> <C-left> <C-w>N:call async#TermSwitch('previous')<CR>
tnoremap <silent> <C-right> <C-w>N:call async#TermSwitch('next')<CR>

" === misc func def === {{{1
" For starting insert mode when switching to terminal 
function! WindowSwitch(action)
    if &bt == 'terminal' && mode() == 'n'
        normal a
    endif

    if a:action == 'down'
        wincmd w
    else
        wincmd W
    endif

    if &bt == 'terminal' && mode() == 'n'
        normal a
    endif
endfunction

"  )]}自动补全相关
function! CyClosePair(char)
    if getline('.')[col('.') - 1] == a:char
        return "\<Right>"
    else
        return a:char
    endif
endfunction

" Termdebug
let g:termdebug_wide = 1
" Plugin Configure======================
" === leaderf.vim === {{{1
let g:Lf_DefaultMode = 'NameOnly'

" === async.vim === {{{1
let g:Async_TerminalType = {
            \ 'dc' : 'dc_shell',
            \ 'py2': 'python',
            \ 'py3': 'python3',
            \ 'ipy': 'ipython3'
            \ }

" === Netrw-NERDTree 配置 === {{{1
let g:netrw_winsize=-25
let g:netrw_dirhistmax=0
let g:netrw_browse_split=4
let g:netrw_altv=1
let g:netrw_banner=0
let g:netrw_liststyle=3
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
"    if empty(matchstr(a:line, '/$')) && (exists('g:WebDevIconsUnicodeDecorateFolderNodes') && g:WebDevIconsUnicodeDecorateFolderNodes == 0)
"        let line = '  ' . a:line
"    else
"        let line = a:line
"    endif
" ===== change a:line to line below ===============================================
" =================================================================================

" Add "call NERDTreeAddKey_Menu_Def()" to ~/.vim/plugin/NERD_tree

function! NERDTreeAddKey_Menu_Def()
    call NERDTreeAddMenuItem({
                \ 'text': 'Switch file (x) permission',
                \ 'shortcut': 'x',
                \ 'callback': 'SwitchXPermission'
                \ })

    call NERDTreeAddKeyMap({
                \ 'key': 'dbg',
                \ 'callback': 'DebugFile',
                \ 'quickhelpText': 'Debug file by gdb tool',
                \ 'scope': 'Node'
                \ })
endfunction

function! SwitchXPermission()
    let l:currentNode = g:NERDTreeFileNode.GetSelected()
    if getfperm(l:currentNode.path.str())[2] == 'x'
        call system("chmod -x '" . l:currentNode.path.str() . "'")
    else
        call system("chmod +x '" . l:currentNode.path.str() . "'")
    endif
    silent call nerdtree#ui_glue#invokeKeyMap('R')
endfunction

function! DebugFile(node)
    call async#GdbStart(a:node.path.str, BMBPSign#SignRecord('break', 'tbreak'))
endfunction

" === TagBar Configure === {{{1
let g:tagbar_width=31
let g:tagbar_vertical=19
let g:tagbar_silent=1
let g:tagbar_left=0
"let g:tagbar_iconchars = ['', '']
let g:tagbar_iconchars = ['▸', '▾']
let g:tagbar_status_func = 'TagbarStatusFunc'

function! TagbarStatusFunc(current, sort, fname, flags, ...) abort
    let l:flagstr = join(a:flags, '')
    if l:flagstr != ''
        let l:flagstr = '[' . l:flagstr . '] '
    endif
    return '  Tagbar: ' . l:flagstr . a:fname
endfunction

"  TagBar 其他语言支持
"    Makefile
let g:tagbar_type_make = {
            \ 'kinds':[
            \ 'm:macros',
            \ 't:targets'
            \ ]
            \}
"    Markdown
let g:tagbar_type_markdown = {
            \ 'ctagstype' : 'markdown',
            \ 'kinds' : [
            \ 'h:Heading_L1',
            \ 'i:Heading_L2',
            \ 'k:Heading_L3'
            \ ]
            \ }

" === Ale Configure === {{{1
" map key to jump
nmap <silent> <C-k> <Plug>(ale_previous_wrap)
nmap <silent> <C-j> <Plug>(ale_next_wrap)
" ** Need to install **
" Tool: flake8 pylint pyflakes(linter), yapf autopep8(fixer) : python
" Tool: clang-format(fixer)     : c/c++/java/javascript
" Tool: shellcheck(linter)      : sh
" Tool: perltidy(fixer)         : perl
" *********************
" Config tool parameter
let g:ale_c_clangformat_executable = 'clang-format-7'
let g:ale_c_clangformat_options = "-style='{IndentWidth: 4}'"
" flake8 msg id
" E22_, E231, E241, E242: missing whitespace
" E26_: comment start          " E501: line too long
" E722: bare except            " E713: test for membership
let g:ale_python_flake8_options = '--ignore=E225,E226,E227,E261,E262,E265,E266,E231,E265,E501,E722,E713'
" pylint msg id
" C0103: invalid-name          " C0112: empty-docstring     " C0303: trailing whitespace
" C0111: missing-docstring     " W0603: global-statement    " W0511: todo ignore
let g:ale_python_pylint_options = '--disable=C0103,C0303,C0111,C0112,W0603,W0511 --jobs=0'

let g:ale_sign_error = '▄'
let g:ale_sign_warning = '▍'
let g:ale_echo_msg_error_str = 'E'
let g:ale_echo_msg_warning_str = 'W'
let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'
let g:ale_sign_column_always = 1
let g:ale_lint_on_insert_leave = 1
"let g:ale_lint_delay = 20
let g:ale_lint_on_text_changed = 'normal'
let g:ale_set_loclist = 0
let g:ale_set_quickfix = 1

" ale statusline
function! LinterStatus() abort
    let l:counts = ale#statusline#Count(bufnr(''))
    let l:all_errors = l:counts.error + l:counts.style_error
    let l:all_non_errors = l:counts.total - l:all_errors
    let l:error = l:all_errors ? printf(' %d', l:all_errors) : ''
    let l:nonError = l:all_non_errors ? printf(' %d', l:all_non_errors) : ''
    if empty(l:error) && !empty(l:nonError)
        return l:nonError
    elseif !empty(l:error) && empty(l:nonError)
        return l:error
    elseif !empty(l:error) && !empty(l:nonError)
        return l:error . ' ' . l:nonError
    else
        return ''
    endif
endfunction

" === BMBPSign configure === {{{1
let g:BMBPSign_SpecialBuf = {
            \ 'NERD_tree': 'bw|NERDTree',
            \ '__Tagbar': 'bw|call Vimrc_Tagbar()'
            \ }

" SpecialBuf hanle
function! Vimrc_Tagbar()
    if bufwinnr('NERD_tree') == -1
        let g:tagbar_vertical=0
        let g:tagbar_left=1
        TagbarOpen
        let g:tagbar_vertical=19
        let g:tagbar_left=0
        wincmd W
    else
        exe bufwinnr('NERD_tree') . 'wincmd w'
        TagbarOpen
        wincmd w
    endif
endfunction

let g:BMBPSign_ProjectType = {
                \ 'c':       '~/Documents/WorkSpace',
                \ 'cpp':     '~/Documents/WorkSpace',
                \ 'fpga':    '~/Documents/Altera',
                \ 'verilog': '~/Documents/Modelsim',
                \ 'altera':  '~/Documents/Altera',
                \ 'xilinx':  '~/Documents/Xilinx',
                \ 'python':  '~/Documents/Python',
                \ 'default': '~/Documents'
                \ }

let g:BMBPSign_PreSaveEventList = [
            \ 'call PreSaveWorkSpace_TabVar()'
            \ ]

let g:BMBPSign_PostLoadEventList = [
            \ 'call PostLoadWorkSpace_TabVar()'
            \ ]

function! PreSaveWorkSpace_TabVar()
    let g:TABVAR_MAXMIZEWIN = {}
    let g:TABVAR_RECORDOFTREE = {}
    let g:WINVAR_BUFHIS = {}

    for l:nr in range(1, tabpagenr('$'))
        " Record win status
        let l:var = gettabvar(l:nr, 'MaxmizeWin', [])
        if !empty(l:var)
            let g:TABVAR_MAXMIZEWIN[l:nr] = l:var
        endif

        " Record nerdtree status
        for l:bufnr in tabpagebuflist(l:nr) + [0]
            if getbufvar(l:bufnr, '&filetype', '') == 'nerdtree'
                break
            endif
        endfor

        let l:var = l:bufnr == 0 ? gettabvar(l:nr, 'RecordOfTree', {}) : misc#RecordOfNERDTree(l:bufnr)

        if !empty(l:var)
            let g:TABVAR_RECORDOFTREE[l:nr] = l:var
        endif

        " Record buf history in every window
        let g:WINVAR_BUFHIS[l:nr] = {}
        for l:winnr in range(1, tabpagewinnr(l:nr, '$'))
            let l:var = gettabwinvar(l:nr, l:winnr, 'bufHis', {})
            if len(get(l:var, 'list', [])) > 1
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

    if empty(g:TABVAR_RECORDOFTREE)
        unlet g:TABVAR_RECORDOFTREE
    endif

    if empty(g:WINVAR_BUFHIS)
        unlet g:WINVAR_BUFHIS
    endif
endfunction

function! PostLoadWorkSpace_TabVar()
    if exists('g:TABVAR_MAXMIZEWIN')
        for [l:nr, l:val] in items(g:TABVAR_MAXMIZEWIN)
            call settabvar(l:nr, 'MaxmizeWin', l:val)
        endfor
        unlet g:TABVAR_MAXMIZEWIN
    endif

    if exists('g:TABVAR_RECORDOFTREE')
        for [l:nr, l:val] in items(g:TABVAR_RECORDOFTREE)
            call settabvar(l:nr, 'RecordOfTree', l:val)
        endfor
        unlet g:TABVAR_RECORDOFTREE
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

" === webdevicons.vim === {{{1
" Extended icon
let g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols = {
            \ 'v'        : '',
            \ 'vhdl'     : '',
            \ 'vhd'      : '',
            \ 'verilog'  : '',
            \ 'systemverilog'  : '',
            \ 'help'     : '',
            \ 'sv'       : '',
            \ 'vt'       : '',
            \ 'vo'       : '',
            \ 'vg'       : '',
            \ 'mp3'      : '',
            \ 'aac'      : '',
            \ 'flac'     : '',
            \ 'ape'      : '',
            \ 'ogg'      : '',
            \ 'jar'      : '',
            \ 'zip'      : '',
            \ 'rar'      : '',
            \ 'gzip'     : '',
            \ 'gz'       : '',
            \ '7z'       : '',
            \ 'tar'      : '',
            \ 'iso'      : '',
            \ 'mp4'      : '',
            \ 'avi'      : '',
            \ 'mkv'      : '',
            \ 'xls'      : '',
            \ 'xlsx'     : '',
            \ 'doc'      : '',
            \ 'docx'     : '',
            \ 'ppt'      : '',
            \ 'pptx'     : '',
            \ 'text'     : '',
            \ 'git'      : '',
            \ 'pdf'      : '',
            \ 'tags'     : '',
            \ 'tag'      : ''
            \ }

let g:WebDevIconsUnicodeDecorateFileNodesExactSymbols = {
            \ '.tags'     : '',
            \ '.tag'      : ''
            \ }
let g:WebDevIconsNerdTreeBeforeGlyphPadding = ''
" ===============================
" set foldmethod=marker
