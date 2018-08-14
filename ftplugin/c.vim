"====================================================
if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1
let b:incDirFlag = system("find -maxdepth 2 -type d -iname 'inc*'|sed 's/^/-I/'|tr '\\n' ' '")[:-2]
setlocal cindent

function s:GenerateMakeFile()
    if getcwd() =~ '^/[^/]\+/[^/]\+$'
        return
    endif
    let l:dir = matchstr(getcwd(), '[^/]\+$')
    let l:makeFile = [
        \ '# Basic ############################################',
        \ 'COMPILER := g++',
        \ 'FLAGS := -Wall -O0 -g3',
        \ 'LIBS := ',
        \ 'EXEF := ' . l:dir,
        \ '',
        \ '####################################################',
        \ 'INCDIR := ' . b:incDirFlag,
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
        \ '']
    call writefile(s:makeFile, 'Makefile')
endfunction

if !filereadable('Makefile') && !filereadable('makefile')
    call s:GenerateMakeFile()
endif

if !exists("*s:DependencyFile")
    function s:DependencyFile(file)
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
        let l:list += [''] + systemlist("echo -e \"build/`gcc -MM " . b:incDirFlag . ' ' . a:file . "`\"") + ["\t$(CC) -c $< -o $@"]
        call writefile(l:list, '.d/' . l:name . '.d')
    endfunction
endif

if !exists("*s:RefreshAll")
    function s:RefreshAll(arg)
        let b:incDirFlag = system("find -maxdepth 2 -type d -iname 'inc*'|sed 's/^/-I/'|tr '\\n' ' '")[:-2]
        let l:sourceFile = systemlist("find . -type f -iname '*.c*'|sed -n 's+^\./++p'")
        if !empty(l:sourceFile)
            for l:file in l:sourceFile
                call s:DependencyFile(l:file)
            endfor
        endif
        if !filereadable('Makefile') && !filereadable('makefile')
            call s:GenerateMakeFile()
        else
            call system("sed -i 's/^INCDIR :=.*/INCDIR := " . b:incDirFlag . "/' Makefile")
        endif
    endfunction
endif

augroup c_cpp_project
    autocmd!
    autocmd BufWritePost *.c,*.cpp call s:DependencyFile(expand('%'))
augroup END

command! -buffer -nargs=? RMakefile :call s:RefreshAll('<args>')

