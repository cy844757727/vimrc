"基本设置======================
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
set noautochdir    "禁用自动切pwd到换文件路径
set diffopt=vertical,filler
set bsdir=buffer 
set ffs=unix,dos,mac  "换行格式集
set mouse=a           "设置鼠标范围
set laststatus=2      "始终显示状态栏
set completeopt=menu,menuone,noinsert,preview,noselect
set errorformat=%f:%l:%c:\ %m,  "gcc/g++
set errorformat+=**\ Error:\ (vlog-%*\\d)\ %f(%l):\ %m, "verilog
set errorformat+=**\ Error:\ (vlog-%*\\d)\ %f(%l.%c):\ %m, "verilog
set errorformat+=**\ Error:\ (suppressible):\ %f(%l.%c):\ %m, "verilog
set errorformat+=**\ Error:\ %f(%l):\ %m,
set errorformat+=**\ Error:\ %f(%l.%c):\ %m,
set errorformat+=**\ at\ %f(%l):\ %m, "verilog
set errorformat+=**\ at\ %f(%l.%c):\ %m "verilog
"set foldmethod=syntax "折叠方式（依据语法）
"set foldcolumn=1     "折叠级别显示
"set foldlevel=1      "折叠级别
colorscheme cydark    "配色方案
set helplang=cn
set langmenu=zh_CN.UTF-8
set enc=utf-8         "显示用的编码
set fencs=utf-8,gb18030,gbk,gb2312,big5,ucs-bom,shift-jis,utf-16,latin1 "检测编码集
set statusline=[%{mode('2')}]\ %f%m%r%h%w%<%=%{ALEGetStatusLine()}\ \ \ \ \ %{''.(&fenc!=''?&fenc:&enc).''}%{(&bomb?\",BOM\":\"\")}\ │\ %{&ff}\ │\ %Y\ \ \ \ \ %-10.(%l:%c%V%)\ %4P\ 

"自定义命令/自动命令=====================
augroup UsrDefCmd
    autocmd!
    autocmd QuickFixCmdPost * copen 10
    autocmd BufRead,BufNewFile *.vt,*.vo,*.vg set filetype=verilog
    autocmd BufRead,BufNewFile *.sv set filetype=systemverilog
    autocmd BufRead,BufNewFile *.d set filetype=make
augroup END

command! -range=% CFormat :<line1>,<line2>call CodeFormat()
command! -range RComment :<line1>,<line2>call ReverseComment()
command! -range=% DBLank :<line1>,<line2>s/\s\+$//ge|<line1>,<line2>s/\(\s*\n\+\)\{3,}/\="\n\n"/ge|silent! /@#$%^&* "删除多余空行，多个空行转一个 && 尾部空白字符
command! Qs call BMBPSign_SaveWorkSpace('') | wqall
command! -nargs=+ -complete=file Async :call job_start('<args>', {'in_io': 'null', 'out_io': 'null', 'err_io': 'null'})

command! -nargs=* Amake :AsyncRun make
command! Actags :call job_start('ctags -R -f .tags', {'in_io': 'null', 'out_io': 'null', 'err_io': 'null'})
command! Avdel :call job_start('vdel -lib work -all', {'in_io': 'null', 'out_io': 'null', 'err_io': 'null'})

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
" 更改PWD到当前文件所在目录
nmap \cd :exec 'cd ' . expand('%:h') . '\|pwd'<CR>

vmap <C-f> yk:exec "/" . getreg("0")<CR><BS>n
nmap <C-f> wbve<C-f>
imap <C-f> <Esc>lwbve<C-f>
vmap <C-h> y:call StrSubstitute(getreg("0"))<CR>
nmap <C-h> wbve<C-h>
imap <C-h> <Esc>lwbve<C-h>

map  <C-a> <Esc>ggvG$
map  <C-w> <Esc>:close<CR>
map  <S-PageUp> <Esc>:wincmd W<CR>
map  <S-pageDown> <Esc>:wincmd w<CR>
map  <C-t> <Esc>:tabnew<CR>
map  <S-t> <Esc>:tabclose<CR>
map  <S-tab> <Esc>:tabnext<CR>
map! <C-a> <Esc><C-a>
map! <C-w> <Esc><C-w>
map! <S-PageUp> <Esc><S-PageUp>
map! <S-PageDown> <Esc><S-PageDown>
map! <C-t> <Esc><C-t>
map! <S-tab> <Esc><S-tab>
"map! <C-o> <Esc>:AsyncRun xdg-open %<CR> "用默认应用打开当前文件
"map  <C-o> <Esc>:AsyncRun xdg-open %<CR>
nmap \od :Async xdg-open .<CR>
nmap \of :Async xdg-open %<CR>
nmap \rf :exec "Async xdg-open " . expand('%:h')<CR>
nmap \h :call HEXCovent()<CR>
nmap <silent> \q :call ReverseComment()<CR>
vmap <silent> \q :call ReverseComment()<CR>
map  \c <Esc>:call CutMouseBehavior()<CR>
" 保存快捷键
map  <f3> <Esc>:call SaveSpecifiedFile(expand('%'))<CR> 
map! <f3> <Esc><f3>
map  <silent> <f4> :call WinResize()<Cr>
map! <f4> <Esc><f4>
" 窗口切换
map  <f7> <Esc>:call GIT_Toggle()<CR>
map  <f8> <Esc>:call ToggleTagbar()<CR>
map  <f9> <Esc>:call ToggleNERDTree()<CR>
map  <f10> <ESC>:call ToggleQuickFix()<CR>
map! <f7> <Esc><f7>
map! <f8> <Esc><f8>
map! <f9> <Esc><f9>
map! <f10> <ESC><f10>
" 编译执行
map  <silent> <f5> <Esc>:call CompileRun()<CR>
map! <silent> <f5> <Esc><f5>
" 断点插入 BMBPSign.vim
map  <silent> <f6> <Esc>:BMBPSignToggleBreakPoint<CR>
map  <silent> \b <Esc>:BMBPSignClearBreakPoint<CR>
map! <silent> <f6> <Esc><f6>
" 书签 BMBPSign.vim
map  <silent> <f12> <Esc>:BMBPSignToggleBookMark<CR>
map  <silent> <C-Down> <Esc>:BMBPSignNextBookMark<CR>
map  <silent> <C-Up> <Esc>:BMBPSignPreviousBookMark<CR>
map  <silent> \m <Esc>:BMBPSignClearBookMark<CR>
map! <silent> <f12> <Esc><f12>
map! <silent> <C-Down> <Esc><C-Down>
map! <silent> <C-Up> <Esc><C-Up>

"插件配置======================
"  Netrw-NERDTree 配置
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
                \ 'callback': 'SwitchXPermission'})

    call NERDTreeAddKeyMap({
                \ 'key': 'dbg',
                \ 'callback': 'DebugFile',
                \ 'quickhelpText': 'Debug file by gdb tool',
                \ 'scope': 'Node'})
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
    call INTERACTIVE_Start(a:node.path.str(), 'dbg')
endfunction

"  TagBar 配置
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

" ale
let g:ale_sign_error = '👽'
let g:ale_sign_warning = '💡'
let g:ale_echo_msg_error_str = 'E'
let g:ale_echo_msg_warning_str = 'W'
let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'
let g:ale_statusline_format = ['⨉ %d', '⚠ %d', '⬥ ok']
let g:ale_sign_column_always = 1
"let g:ale_lint_delay = 1000
let g:ale_lint_on_text_changed = 'normal'
let g:ale_set_loclist = 0
let g:ale_set_quickfix = 1
"================================
" BMBPSign configure =================
let g:BMBPSign_SpecialBuf = {
            \ 'NERD_tree': 'call ToggleNERDTree()',
            \ '__Tagbar': 'call ToggleTagbar()|wincmd W'
            \ }

let g:BMBPSign_ProjectType = {
                \ 'c':       '~/Documents/WorkSpace',
                \ 'cpp':     '~/Documents/WorkSpace',
                \ 'fpga':    '~/Documents/Altera',
                \ 'verilog': '~/Documents/Modelsim',
                \ 'altera':  '~/Documents/Altera',
                \ 'xilinx':  '~/Documents/Xilinx',
                \ 'default': '~/Documents'
                \ }

"################### 自定义函数 #############################
"	编译运行: F5
function! CompileRun()
    if &filetype == 'nerdtree'
        silent call nerdtree#ui_glue#invokeKeyMap('R')
        echo 'Refresh Done!'
        return
    endif
    wall
    if filereadable('makefile') || filereadable('Makefile')
        AsyncRun make
    elseif &filetype == 'c' || &filetype == 'cpp'
        AsyncRun g++ -Wall -O0 -g3 % -o binFile
    elseif &filetype == 'verilog'
        let l:cmd = 'vlog -work work %'
        if !isdirectory('work')
            let l:cmd = 'vlib work && vmap work work && ' . l:cmd
        endif
        exec 'AsyncRun ' . l:cmd
    else
        return
    endif
    copen 10
endfunction

"	转换鼠标范围（a，v）: \c
function! CutMouseBehavior()
    if &mouse == 'a'
        set nonumber
        set mouse=v
    else
        set number
        set mouse=a
    endif
endfunction

"  )]}自动补全相关
function! ClosePair(char)
    if getline('.')[col('.') - 1] == a:char
        return "\<Right>"
    else
        return a:char
    endif
endfunction

"	指定范围代码格式化: :CFormat
function! CodeFormat()
    if &filetype == 'c' || &filetype == 'cpp'
        silent! s/\(\w\|)\|\]\)\s*\([-+=*/%><|&:!?^][-+=/><|&:]\?=\?\)\s*/\1 \2 /ge
        silent! s/\s*\(++\|--\|::\)\s*/\1/ge
        silent! s/\s*\(<\)\s*\(.\+\w\+\)\s*\(>\)\s*/ \1\2\3 /ge
        silent! s/\((\)\s*\|\s*\()\)/\1\2/ge
        silent! s/\(,\|;\)\s*\(\w\)/\1 \2/ge
        silent! s/\(\s*\n*\s*\)*{/ {/ge
        silent! s/\(\s*\n\+\)\{3,}/\="\n\n"/ge
        normal ==
    elseif &filetype == 'matlab'
        silent! s/\(\w\|)\)\s*\(\.\?[-+=*/><~|&^][=&|]\?\)\s*/\1 \2 /ge
        silent! s/\((\)\s*\|\s*\()\)/\1\2/ge
        silent! s/\(;\)\s*\(\w\)/\1 \2/ge
        silent! s/\(\s*\n\+\)\{3,}/\="\n\n"/ge
        normal ==
    elseif &filetype == 'make'
        silent! s/\(\w\)\s*\(+=\|=\|:=\)\s*/\1 \2 /ge
        silent! s/\(:\)\s*\(\w\|\$\)/\1 \2/ge
        silent! s/\(\s*\n\+\)\{3,}/\="\n\n"/ge
        normal ==
    elseif &filetype == 'python'
        silent! s/\(\w\|)\|\]\|}\)\s*\([-+=*/%><|&~!^][=*/><]\?=\?\)\s*/\1 \2 /ge
        silent! s/\((\|\[\|{\)\s*\|\s*\()\|\]\|}\)/\1\2/ge
        silent! s/\(,\|;\)\s*\(\w\)/\1 \2/ge
        silent! s/\(\s*\n\+\)\{3,}/\="\n\n"/ge
        normal ==
    elseif &filetype == 'verilog' || &filetype == 'systemverilog'
        silent! s/\(\w\|)\|\]\)\s*\([-+=*/%><|&!?~^][=><|&~]\?\)\s*/\1 \2 /ge
        silent! s/\((\)\s*\|\s*\()\)/\1\2/ge
        silent! s/\(,\|;\)\s*\(\w\)/\1 \2/ge
        silent! s/\(\s*\n\+\)\{3,}/\="\n\n"/ge
    endif
    silent! /`!`!`!`!`@#$%^&
endfunction

"   切换注释状态: \q
function! ReverseComment()
    if &filetype == 'c' || &filetype == 'cpp' || &filetype == 'verilog' || &filetype == 'systemverilog'
        let l:char='//'
    elseif &filetype == 'matlab'
        let l:char='%'
    elseif &filetype == 'sh' || &filetype == 'make' || &filetype == 'python'
        let l:char='#'
    elseif &filetype == 'vim'
        let l:char="\""
    else
        let l:char=''
    endif
    if !empty(l:char)
        exec 's+^+' . l:char . '+e'
        exec 's+^' . l:char . l:char . '++e'
    endif
endfunction

"  刷新目录树
function! UpdateNERTreeView()
    let l:nrOfNerd_tree=bufwinnr('NERD_tree')
    if l:nrOfNerd_tree != -1
        let l:id=win_getid()
        exec l:nrOfNerd_tree . 'wincmd w'
        silent call nerdtree#ui_glue#invokeKeyMap('R')
        call win_gotoid(l:id)
    endif
endfunction

" 字符串查找替换: ctrl+h
function! StrSubstitute(str)
    let l:pos = getpos('.')
    let l:subs=input('Replace ' . "\"" . a:str . "\"" . ' with: ')
    if l:subs != ''
        exec '%s/' . a:str . '/' . l:subs . '/Ig'
        call cursor(l:pos[1], l:pos[2])
    else
        echo 'Do Nothing!'
    endif
endfunction

let g:DoubleClick_500MSTimer = 0
" 文件保存及后期处理: F3
function! SaveSpecifiedFile(file)
    if g:DoubleClick_500MSTimer == 1
        wall
        echo 'Save all'
    elseif filereadable(a:file)
        let g:DoubleClick_500MSTimer = 1
        let l:id = timer_start(500, 'TimerHandle500MS')
        write
    elseif empty(a:file)
        exec 'file ' . input('Set file name')
        filetype detect
        write
        if &filetype == 'verilog'
            AFInclude
        endif
        call UpdateNERTreeView()
    endif
endfunction

function! TimerHandle500MS(id)
    let g:DoubleClick_500MSTimer = !g:DoubleClick_500MSTimer
    call timer_stop(a:id)
endfunction
" 切换16进制显示: \h
function! HEXCovent()
    if empty(matchstr(getline(1), '^00000000: \S'))
        :%!xxd
        ALEDisable
    else
        :%!xxd -r
        ALEEnable
    endif
endfunction

let g:MaxmizeWindow = []
function! WinResize()
    let l:winId = win_getid()
    if g:MaxmizeWindow == []
        let g:MaxmizeWindow = [winheight(0), winwidth(0), l:winId]
        exec 'resize ' . max([float2nr(0.8 * &lines), g:MaxmizeWindow[0]])
        exec 'vert resize ' . max([float2nr(0.8 * &columns), g:MaxmizeWindow[1]])
    elseif g:MaxmizeWindow[2] == l:winId
        exec 'resize ' . g:MaxmizeWindow[0]
        exec 'vert resize ' . g:MaxmizeWindow[1]
        let g:MaxmizeWindow = []
    else
        if win_gotoid(g:MaxmizeWindow[2]) == 1
            exec 'resize ' . g:MaxmizeWindow[0]
            exec 'vert resize ' . g:MaxmizeWindow[1]
            call win_gotoid(l:winId)
        endif
        let g:MaxmizeWindow = [winheight(0), winwidth(0), l:winId]
        exec 'resize ' . max([float2nr(0.8 * &lines), g:MaxmizeWindow[0]])
        exec 'vert resize ' . max([float2nr(0.8 * &columns), g:MaxmizeWindow[1]])
    endif
endfunction

" ############### 窗口相关 ######################################
"  切换NERDTree窗口: F9
function! ToggleNERDTree()
    if bufwinnr('NERD_tree') != -1
        NERDTreeClose
    elseif bufwinnr('Tagbar') != -1
        TagbarClose
        NERDTree
        TagbarOpen
    else
        NERDTree
    endif
endfunction

"  切换TagBar窗口: F8
function! ToggleTagbar()
    let l:id=win_getid()
    if bufwinnr('Tagbar') != -1
        TagbarClose
    elseif bufwinnr('NERD_tree') == -1
        let g:tagbar_vertical=0
        let g:tagbar_left=1
        TagbarOpen
        let g:tagbar_vertical=19
        let g:tagbar_left=0
        call win_gotoid(l:id)
    else
        exec bufwinnr('NERD_tree') . 'wincmd w'
        TagbarOpen
        call win_gotoid(l:id)
    endif
endfunction

"  切换QuickFix窗口: F10
function! ToggleQuickFix()
    let l:id=win_getid()
    exec tabpagewinnr(tabpagenr(),'$') . 'wincmd w'
    if &ft == 'qf'
        cclose
    else
        copen 10
        call win_gotoid(l:id)
    endif
endfunction
"#####################################################################

