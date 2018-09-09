"====================================================
if exists("b:did_ftplugin") || empty(system("grep '" . getcwd() . "' ~/.vim/.projectitem"))
    finish
endif
let b:did_ftplugin = 1

setlocal cindent

augroup c_cpp_project
    autocmd!
    autocmd BufWritePost <buffer> call s:DependencyFile(expand('%'))
augroup END

command! -buffer -nargs=? RMakefile :call s:RefreshAll('<args>')

if exists("*s:GenerateMakeFile()")
    finish
endif

let s:incDirFlag = system("find -maxdepth 2 -type d -iname 'inc*'|sed 's/^/-I/'|tr '\\n' ' '")[:-2]
let s:makeFile = [
            \ '# Basic ############################################',
            \ 'COMPILER := g++',
            \ 'FLAGS := -Wall -O0 -g3',
            \ 'LIBS := ',
            \ 'EXEF := ' . matchstr(getcwd(), '[^/]\+$'),
            \ '',
            \ '####################################################',
            \ 'INCDIR := ' . s:incDirFlag,
            \ 'CC := $(COMPILER) $(INCDIR) $(FLAGS)',
            \ 'LINK := $(COMPILER) -Wall $(LIBS)',
            \ 'ALLTARGET := $(EXEF)',
            \ '',
            \ '# GDB Configure ####################################',
            \ 'DBGFILE := .breakpoint',
            \ 'ifeq ($(DBGFILE), $(wildcard $(DBGFILE)))',
            \ "\tGDBFLAGS := -x \$(DBGFILE)",
            \ 'endif',
            \ '',
            \ '# Main Target ######################################',
            \ 'all: $(ALLTARGET)',
            \ "\t@echo",
            \ "\t@echo '    [ALL DONE]'",
            \ '',
            \ 'include $(wildcard .d/*.d)',
            \ '# Bin Targets:Linking ##############################',
            \ '$(EXEF): $(OBJS)',
            \ "\t@echo",
            \ "\t@echo 'Building target: $@'",
            \ "\t$(LINK) $^ -o $@",
            \ '',
            \ '# Other Targets ####################################',
            \ '.PHONY: all run dbg clean',
            \ '',
            \ 'run: $(ALLTARGET)',
            \ "\tclear;./$(EXEF)",
            \ '',
            \ 'dbg: $(ALLTARGET)',
            \ "\tclear;gdb $(EXEF) $(GDBFLAGS)",
            \ '',
            \ 'clean:',
            \ "\t@rm -f build/*.o",
            \ ''
            \ ]

function s:GenerateMakeFile()
    " 排除主目录
    if getcwd() != system('echo ~')[:-2]
        call writefile(s:makeFile, 'Makefile')
    endif
endfunction

function s:DependencyFile(file)
    if !filereadable('Makefile') && !filereadable('makefile')
        call s:GenerateMakeFile()
    endif
    if !isdirectory('build')
        call mkdir('build')
    endif
    if !isdirectory('.d')
        call mkdir('.d')
    endif
    let l:name = matchstr(a:file, '[^/]\+\ze\.')
    let l:dir = matchstr(a:file, '^.\+\ze/')
    let l:list = ['OBJS += build/' . l:name . '.o']
    if l:dir != ''
        let l:list += ["OBJS_" . substitute(l:dir, '/', '_', 'g') . ' += build/' . l:name . '.o']
    endif
    let l:list += [''] + systemlist("echo -e \"build/`gcc -MM " . s:incDirFlag . ' ' . a:file . "`\"") + ["\t$(CC) -c $< -o $@"]
    call writefile(l:list, '.d/' . l:name . '.d')
endfunction

function s:RefreshAll(arg)
    let s:incDirFlag = system("find -maxdepth 2 -type d -iname 'inc*'|sed 's/^/-I/'|tr '\\n' ' '")[:-2]
    let l:sourceFile = systemlist("find . -type f -iname '*.c*'|sed -n 's+^\./++p'")
    if !empty(l:sourceFile)
        for l:file in l:sourceFile
            call s:DependencyFile(l:file)
        endfor
    endif
    call system("sed -i 's/^INCDIR :=.*/INCDIR := " . s:incDirFlag . "/' Makefile")
endfunction

