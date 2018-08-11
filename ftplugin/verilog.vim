""""""""""""""""""""""""""""""""""""""""""""""""""""
" Name:   HDL_Verilog
" Author: CY <844757727@qq.com>
""""""""""""""""""""""""""""""""""""""""""""""""""""
if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1

function s:ModuleName(file)
    let l:name=system("sed -n 's/\\s*module\\s*\\(\\w\\+\\).*/\\1/p' " . a:file)
    let l:name=substitute(l:name, '\n', '', '')
    return l:name
endfunction

function s:ModulePorts(file)
    let l:ports=system("grep '^\\(\\s\\{,4\\}\\|\\t\\)\\(input\\|output\\|inout\\) ' " . a:file )
    let l:ports=substitute(l:ports,'input \|output \|inout \|w\(ire\|and\|or\) \|reg \|signed \|tri\(0\|1\|reg\|and\|or\)\? \|supply\(0\|1\) \|\s*=\s*[^,;]*\|\[.\{-}\]\|//.\{-}\n\|\n\|\s*\|','','g')
    let l:ports=substitute(l:ports,';',',','g')
    let l:ports=substitute(l:ports,',$','','')
    let l:ports=substitute(l:ports,'\(\w\+\)','\n\t\t.\1(\1)','g')
    return l:ports
endfunction

function s:InstanceTemplate(file)
    let l:name=s:ModuleName(a:file)
    let l:ports=s:ModulePorts(a:file)
    return "\n\t" . l:name . " Inst0 (" . l:ports . "\n\t);\n\t"
endfunction

function s:InstVarDef(file)
    let l:varDefIn=system("grep '^\\(\\s\\{,4\\}\\|\\t\\)input ' " . a:file)
    let l:varDefOut=system("grep '^\\(\\s\\{,4\\}\\|\\t\\)output ' " .  a:file)
    let l:varDefInOut=system("grep '^\\(\\s\\{,4\\}\\|\\t\\)inout ' " .  a:file)
    let l:varDefIn=substitute(l:varDefIn,'w\(ire\|and\|or\) \|tri\(0\|1\|reg\|and\|or\)\? \|supply\(0\|1\) \|signed ','','g')
    let l:varDefOut=substitute(l:varDefOut,'reg \|signed \|\s*=\s*[^,;]*','','g')
    let l:varDefInOut=substitute(l:varDefInOut,'w\(ire\|and\|or\) \|tri\(0\|1\|reg\|and\|or\)\? \|supply\(0\|1\) \|signed ',' ','g')
    let l:varDefIn=substitute(l:varDefIn,'input ','reg ','g')
    let l:varDefOut=substitute(l:varDefOut,'output ','wire ','g')
    let l:varDefInOut=substitute(l:varDefInOut,'inout ','wire ','g')
    let l:varDefIn=substitute(l:varDefIn,'[,;]\?\s*//.\{-}\n\|[,;]\?\n',';\n','g')
    let l:varDefOut=substitute(l:varDefOut,'[,;]\?\s*//.\{-}\n\|[,;]\?\n',';\n','g')
    let l:varDefInOut=substitute(l:varDefInOut,'[,;]\?\s*//.\{-}\n\|[,;]\?\n',';\n','g')
    let l:varDefIn=substitute(l:varDefIn,'\([,;]\)',' = 0\1','g')
    return "\n" . l:varDefIn . "\t\n" . l:varDefOut . "\t\n" . l:varDefInOut
endfunction

function s:TestBenchGenerate(file)
    let l:name=s:ModuleName(a:file)
    let l:IODef=s:InstVarDef(a:file)
    let l:inst=s:InstanceTemplate(a:file)
    let @z="`timescale 1ns/100ps\n\nmodule tb_" . l:name . ";"
    let @Z="\n\t// User variable definition\n\t"
    let @Z="\n\t// Instance variable definition" . l:IODef . "\t\n\t// Module instance" . l:inst
    let @Z="\n\t// Clock signal\n\talways #5 clk = ~clk;\n\t"
    let @Z="\n\t// Initialization\n\tinitial begin\n\t\t#10 rst_ <= 0;\n\t\t#10 rst_ <= 1;\n\t\t\n\t\t\n\t\t#10000 $stop;\n\tend\n\t"
    let @Z="\nendmodule\n\n"
    exec "edit " . expand('%:h') . "/tb_" . l:name . ".v"
    normal "zpggdd
    %retab!
endfunction

function s:TestBenchRefresh(file)
    let l:name=s:ModuleName(a:file)
    let l:end=search('// Module instance')
    let l:start=search('// Instance variable definition')
    let l:linCnt=l:end-l:start-1
    if l:linCnt > 0
        let @z=s:InstVarDef(a:file) . "\n"
        exec "normal " . "j" . l:linCnt . "ddk$\"zp"
    endif
    let l:name=match(expand('%:t'), '^tb_\(\w\+\)')
    let l:start=search('^\s*' . l:name[1])
    let l:start=search('[^#](')
    let l:end=search(');')
    let l:linCnt=l:end-l:start-1
    if l:linCnt > 0
        let @z=s:ModulePorts(a:file)
        exec "normal " . l:start . "ggj" . l:linCnt . "ddk$\"zp"
    endif
    %retab!
    write
endfunction
" ==========================================================
" ==========================================================
function HDLVTestBench()
    if &filetype != 'verilog'
        return
    endif
    write
    let l:file=expand('%:p')
    let l:name=s:ModuleName(l:file)
    if match(l:name, "^tb_") == -1
        let l:tbFile=expand('%:h') . "/tb_" . l:name . ".v"
        if empty(findfile(l:tbFile,".;"))
            call s:TestBenchGenerate(l:file)
            call search('^\s*initial begin')
        else
            exec "0vsplit +1 " . l:tbFile 
            call s:TestBenchRefresh(l:file)
            quit
        endif
    else
        let l:name=matchlist(l:name,'^tb_\(\w\+\)')
        let l:file=l:name[1] . '.v'
        let l:file=expand('%:h') . '/' . l:file
"        let l:file=system("find . -maxdepth 2 -name '" . l:file . "'")
        call s:TestBenchRefresh(l:file)
    endif
endfunction

function HDLVInsertInstance()
    if &filetype != 'verilog'
        return
    endif
    normal wbve"zy
"    let l:file=system("find . -maxdepth 2 -name '*.v'|xargs -I{} grep -il '^\\s*module\\s\\+" . @z . "' {}")
    let l:file=system("find . -maxdepth 2 -iname '" . @z . "*.v'|sed -n '1p'")
    if !empty(l:file)
        let @z=s:InstanceTemplate(l:file)
        normal ddk$"zp
        call search(');')
        normal j==
    else
        exec "echo ' Non-existent!!!'" 
    endif
    %retab!
endfunction

function HDLVAllFileInclude()
    call system("find . -maxdepth 2 -name '*.v'|sed '/\\(_bb\\|_inst\\)\\.v/d'|sed 's/^/`include \\\"/'|sed 's/$/\\\"/'>_All.vt")
endfunction

"function HDLVCompileRun()
"    write
"    if empty(finddir('work','.;..'))
"        !vlib work && vmap work work
"    endif
"    AsyncRun vlog -work work %
"endfunction
"
"function HDLVCodeFormat()
"    silent! s/\(\w\|)\|\]\)\s*\([-+=*/%><|&!?~^][=><|&~]\?\)\s*/\1 \2 /ge
"    silent! s/\((\)\s*\|\s*\()\)/\1\2/ge
"    silent! s/\(,\|;\)\s*\(\w\)/\1 \2/ge
"    silent! s/\(\s*\n\+\)\{3,}/\="\n\n"/ge
"    silent! /`!`!`!`!`@#$%^&
"endfunction

" ==========================================================
" ==========================================================
command -buffer TBench :call HDLVTestBench()
command -buffer IInstance :call HDLVInsertInstance()
command -buffer AFInclude :call HDLVAllFileInclude()
"command CompileRun :call HDLVCompileRun()
"command -range=% CFormat :<line1>,<line2>call HDLVCodeFormat()
