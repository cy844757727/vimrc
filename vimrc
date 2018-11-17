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
set diffopt=vertical,filler
set bsdir=buffer
set ffs=unix,dos,mac  "换行格式集
set mouse=a           "设置鼠标范围
set laststatus=2      "始终显示状态栏
set completeopt=menu,menuone,noinsert,preview,noselect
" gcc/g++
set errorformat=%f:%l:%c:\ %m
" verilog
set errorformat+=**\ Error:\ (vlog-%*\\d)\ %f(%l):\ %m
set errorformat+=**\ Error:\ (vlog-%*\\d)\ %f(%l.%c):\ %m
set errorformat+=**\ Error:\ (suppressible):\ %f(%l.%c):\ %m
set errorformat+=**\ Error:\ %f(%l):\ %m
set errorformat+=**\ Error:\ %f(%l.%c):\ %m
set errorformat+=**\ at\ %f(%l):\ %m
set errorformat+=**\ at\ %f(%l.%c):\ %m
"set foldmethod=syntax "折叠方式（依据语法）
"set foldcolumn=1     "折叠级别显示
"set foldlevel=1      "折叠级别
set termguicolors
"colorscheme desert
colorscheme cydark
set helplang=cn
set langmenu=zh_CN.UTF-8
set enc=utf-8
set fencs=utf-8,gb18030,gbk,gb2312,big5,ucs-bom,shift-jis,utf-16,latin1
set statusline=[%{mode('2')}]\ %f%m%r%h%w%<%=
set statusline+=%{LinterStatus()}%5(\ %)
set statusline+=%{''.(&fenc!=''?&fenc:&enc).''}%{(&bomb?\",BOM\":\"\")}\ │\ %{&ff}\ │\ %Y%5(\ %)
set statusline+=%-10.(%l:%c%V%)\ %4P%(\ %)

"自定义命令/自动命令=====================
augroup UsrDefCmd
    autocmd!
    autocmd QuickFixCmdPost * copen 10
    autocmd BufRead,BufNewFile *.vt,*.vo,*.vg set filetype=verilog
    autocmd BufRead,BufNewFile *.sv set filetype=systemverilog
    autocmd BufRead,BufNewFile *.d set filetype=make
augroup END

command! -nargs=? -complete=file T :tabe <args>
command! -range TB :<line1>tabnext
command! -range TP :<line1>tabprevious
command! -range=% CFormat :<line1>,<line2>call misc#CodeFormat()
command! -range RComment :<line1>,<line2>call misc#ReverseComment()
command! -range=% DBlank :<line1>,<line2>s/\s\+$//ge|<line1>,<line2>s/\(\s*\n\+\)\{3,}/\="\n\n"/ge|silent! /@#$%^&*
command! -nargs=+ -complete=file Async :call job_start("<args>", {'in_io': 'null', 'out_io': 'null', 'err_io': 'null'})
command! -nargs=+ -complete=file TermH :call term_start("<args>", {'hidden': 1, 'term_kill': 'kill', 'term_finish': 'close', 'norestore': 1})
command! Qs :call BMBPSign#WorkSpaceSave('') | wall | qall
command! -nargs=* -complete=file Debug :call misc#Debug("<args>")
command! -nargs=* Amake :AsyncRun make
command! Actags :Async ctags -R -f .tags
command! Avdel :Async vdel -lib work -all

"快捷键映射=====================
" 括号引号自动补全
inoremap ( ()<Esc>i
inoremap ) <c-r>=ClosePair(')')<CR>
inoremap [ []<Esc>i
inoremap ] <c-r>=ClosePair(']')<CR>
inoremap { {}<Esc>i
inoremap } <c-r>=ClosePair('}')<CR>
"inoremap ' ''<Esc>i
inoremap " ""<Esc>i

inoremap <C-\> <Esc>o
" External open
nnoremap \cd :exe 'cd ' . expand('%:h') . '\|pwd'<CR>
nnoremap \od :Async xdg-open .<CR>
nnoremap \of :Async xdg-open %<CR>
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

noremap <C-a> <Esc>ggvG$
noremap <C-w> <Esc>:close<CR>
noremap <S-PageUp> <Esc>:wincmd W<CR>
noremap <S-pageDown> <Esc>:wincmd w<CR>
noremap <C-t> <Esc>:tabnew<CR>
noremap <silent> <S-t> <Esc>:try\|tabclose\|catch\|if &diff\|qa\|endif\|endtry<CR>
noremap  <S-tab> <Esc>:tabnext<CR>
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
noremap <silent> <f7> <Esc>:call git#Toggle()<CR>
noremap <silent> <f8> <Esc>:call misc#ToggleTagbar()<CR>
noremap <silent> <f9> <Esc>:call misc#ToggleNERDTree()<CR>
noremap <silent> <f10> <ESC>:call misc#ToggleQuickFix()<CR>
noremap <silent> <C-f10> <ESC>:call misc#ToggleQuickFix('book')<CR>
noremap <silent> <S-f10> <ESC>:call misc#ToggleQuickFix('break')<CR>
noremap <silent> <C-x> :call misc#ToggleEmbeddedTerminal()<CR>
map! <C-x> <Esc><C-x>
map! <f7> <Esc><f7>
map! <f8> <Esc><f8>
map! <f9> <Esc><f9>
map! <f10> <ESC><f10>
map! <C-f10> <ESC><C-f10>
map! <S-f10> <ESC><S-f10>
map! <C-S-f10> <ESC><C-S-f10>
" 编译执行
noremap  <silent> <f5> <Esc>:call misc#CompileRun()<CR>
map! <silent> <f5> <Esc><f5>
" 断点 BMBPSign.vim
noremap  <silent> <f6> <Esc>:BMBPSignToggleBreakPoint<CR>
noremap  <silent> <C-f6> <Esc>:BMBPSignToggleBreakPoint tbreak<CR>
noremap  <silent> \b <Esc>:BMBPSignClearBreakPoint<CR>
map! <C-f6> <Esc><C-f6>
map! <f6> <Esc><f6>
" 书签 BMBPSign.vim
noremap <silent> <f12> <Esc>:BMBPSignToggleBookMark<CR>
noremap <silent> <C-f12> <Esc>:BMBPSignToggleBookMark todo<CR>
noremap <silent> <C-Down> <Esc>:BMBPSignNextBookMark<CR>
noremap <silent> <C-Up> <Esc>:BMBPSignPreviousBookMark<CR>
noremap <silent> \m <Esc>:BMBPSignClearBookMark<CR>
map! <f12> <Esc><f12>
map! <C-f12> <Esc><C-f12>
map! <C-Down> <Esc><C-Down>
map! <C-Up> <Esc><C-Up>

let g:termdebug_wide = 1
"插件配置======================
" == Netrw-NERDTree 配置 ==
let g:netrw_winsize=-25
let g:netrw_dirhistmax=0
let g:netrw_browse_split=4
let g:netrw_altv=1
let g:netrw_banner=0
let g:netrw_liststyle=3

let g:NERDTreeStatusline='[NERDTree]'
let g:NERDTreeAutoDeleteBuffer=1
let g:NERDTreeMouseMode=2

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
    call misc#Debug(a:node.path.str())
endfunction

" == TagBar Configure ==
let g:tagbar_width=31
let g:tagbar_vertical=19
let g:tagbar_silent=1
let g:tagbar_left=0
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

" == Ale Configure ==
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
" C0111: missing-docstring     " W0603: global-statement
let g:ale_python_pylint_options = '--disable=C0103,C0303,C0111,C0112,W0603 --jobs=0'

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

" clear warning highlight
hi link ALEWarning Normal

" ale statusline
function! LinterStatus() abort
    let l:counts = ale#statusline#Count(bufnr(''))
    let l:all_errors = l:counts.error + l:counts.style_error
    let l:all_non_errors = l:counts.total - l:all_errors
    let l:error = l:all_errors ? printf('✘ %d', l:all_errors) : ''
    let l:nonError = l:all_non_errors ? printf('! %d', l:all_non_errors) : ''
    if empty(l:error) && !empty(l:nonError)
        return l:nonError
    elseif !empty(l:error) && empty(l:nonError)
        return l:error
    elseif !empty(l:error) && !empty(l:nonError)
        return l:error . '  ' . l:nonError
    else
        return ''
    endif
endfunction

" == BMBPSign configure ==
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
    let g:TABVAR_MAXMIZEWIN = []
    for l:nr in range(1, tabpagenr('$') + 1)
        let l:var = gettabvar(l:nr, 'MAXMIZEWIN')
        if !empty(l:var)
            let g:TABVAR_MAXMIZEWIN += [[l:nr] + l:var]
        endif
    endfor
    if empty(g:TABVAR_MAXMIZEWIN)
        unlet g:TABVAR_MAXMIZEWIN
    endif
endfunction

function! PostLoadWorkSpace_TabVar()
    if exists('g:TABVAR_MAXMIZEWIN')
        for l:item in g:TABVAR_MAXMIZEWIN
            call settabvar(l:item[0], 'MAXMIZEWIN', l:item[1:])
        endfor
        unlet g:TABVAR_MAXMIZEWIN
    endif
endfunction
" ===============================
"  )]}自动补全相关
function! ClosePair(char)
    if getline('.')[col('.') - 1] == a:char
        return "\<Right>"
    else
        return a:char
    endif
endfunction

" Customize tabline
set tabline=%!CYMyTabLine()
function! CYMyTabLine()
    let s = ''
    for i in range(tabpagenr('$'))
        " select the highlighting
        if i + 1 == tabpagenr()
            let s .= '%#TabLineSel#'
        else
            let s .= '%#TabLine#'
        endif

        " set the tab page number (for mouse clicks)
        let s .= '%' . (i + 1) . 'T'

        " the label is made by MyTabLabel()
        let s .= ' %{CYMyTabLabel(' . (i + 1) . ')} '

        " Separator
        if i + 1 != tabpagenr() && i + 2 != tabpagenr() && i + 1 != tabpagenr('$')
            let s .= '│'
        else
            let s .= ' '
        endif
    endfor

    " after the last tab fill with TabLineFill and reset tab page nr
    let s .= '%#TabLineFill#%T'

    " right-align the label to close the current tab page
    if tabpagenr('$') > 1
        let s .= '%=%#TabLine#%999X ✘ '
    endif

    return s
endfunction

function! CYMyTabLabel(n)
    let l:buflist = tabpagebuflist(a:n)
    let l:winnr = tabpagewinnr(a:n) - 1
    " Extend buflist
    let l:buflist = l:buflist + l:buflist[0:l:winnr]

    " Display filename which buftype is empty
    while !empty(getbufvar(l:buflist[l:winnr], '&buftype')) && l:winnr < len(l:buflist) - 1
        let l:winnr += 1
    endwhile

    " Add '+' if current buf is modified
    if getbufvar(l:buflist[l:winnr], '&modified')
        let l:label = '+'
    else
        let l:label = ' '
    endif

    " Append the buffer name
    let l:bufname = matchstr(bufname(l:buflist[l:winnr]), '[^/]*$')

    " Unnamed file
    if empty(l:bufname)
        let l:bufname = '#'
    endif
    
    return l:label . l:bufname
endfunction

