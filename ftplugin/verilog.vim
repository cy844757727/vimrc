""""""""""""""""""""""""""""""""""""""""""""""""""""
" Name:   HDL_Verilog
" Author: CY <844757727@qq.com>
""""""""""""""""""""""""""""""""""""""""""""""""""""
if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1

command! -buffer TBench :call HDLVTestBench()
command! -buffer IInstance :call HDLVInsertInstance()

augroup HDL_Verilog
"    autocmd!
    autocmd BufWritePost <buffer> call HDLVAllFileInclude()
augroup END

if exists('*s:ModuleName')
    finish
endif

function s:ModuleName(file)
    return system("sed -n 's/\\s*module\\s*\\(\\w\\+\\).*/\\1/p' " . a:file)[:-2]
endfunction

function s:ModulePorts(file)
    let l:ports = system("grep '^\\(\\s\\{,4\\}\\|\\t\\)\\(input\\|output\\|inout\\) ' " . a:file )
    let l:ports = split(substitute(l:ports,'\s*//.\{-}\n*\|\n\|\[[0-9:]*\]\s*','','g'), '\s*[,;]\s*')
    for l:i in range(len(l:ports) - 1)
        let l:p = matchstr(l:ports[l:i], '\w*$')
        let l:ports[l:i] = repeat(' ', 8) . '.' . l:p . '(' . l:p . '),'
    endfor
    let l:p = matchstr(l:ports[-1], '\w*$')
    let l:ports[-1] = repeat(' ', 8) . '.' . l:p . '(' . l:p . ')'
    return l:ports
endfunction

function s:InstanceTemplate(file)
    let l:name = s:ModuleName(a:file)
    let l:ports = s:ModulePorts(a:file)
    return ['    ' . l:name . ' Inst0 ('] + l:ports + ['    );']
endfunction

function s:InstVarDef(file)
    let l:varDefIn = systemlist("grep '^\\(\\s\\{,4\\}\\|\\t\\)input ' " . a:file)
    let l:varDefOut = systemlist("grep '^\\(\\s\\{,4\\}\\|\\t\\)output ' " .  a:file)
    let l:varDefInOut = systemlist("grep '^\\(\\s\\{,4\\}\\|\\t\\)inout ' " .  a:file)
    for l:i in range(len(l:varDefIn))
        let l:varDefIn[l:i] = substitute(l:varDefIn[l:i], '^.\{-}\ze\(\s\[\|\s\w\+\[\|\s\w\+\s*[,;]\)\|\s*//.*', '', 'g')
        let l:varDefIn[l:i] = '    reg' . substitute(l:varDefIn[l:i], '[,;]\?$', ';', '')
    endfor
    for l:i in range(len(l:varDefOut))
        let l:varDefOut[l:i] = substitute(l:varDefOut[l:i], '^.\{-}\ze\(\s\[\|\s\w\+\[\|\s\w\+\s*[,;]\)\|\s*//.*', '', 'g')
        let l:varDefOut[l:i] = '    wire' . substitute(l:varDefOut[l:i], '[,;]\?$', ';', '')
    endfor
    for l:i in range(len(l:varDefInOut))
        let l:varDefInOut[l:i] = substitute(l:varDefInOut[l:i], '^.\{-}\ze\(\s\[\|\s\w\+\[\|\s\w\+\s*[,;]\)\|\s*//.*', '', 'g')
        let l:varDefInOut[l:i] = '    wire' . substitute(l:varDefInOut[l:i], '[,;]\?$', ';', '')
    endfor
    return l:varDefIn + [''] + l:varDefOut + [''] + l:varDefInOut
endfunction

function s:TestBenchGenerate(file)
    let l:name = s:ModuleName(a:file)
    let l:IODef = s:InstVarDef(a:file)
    let l:inst = s:InstanceTemplate(a:file)
    let l:templete = [
                \ '`timescale 1ns/100ps',
                \ '',
                \ 'module tb_' . l:name . ';',
                \ '    // Usr variable definition',
                \ '',
                \ '    // Instance variable definition'
                \ ] + l:IODef + [
                \ '',
                \ '    // Module instance'
                \ ] + l:inst + [
                \ '',
                \ '    // Clock signal',
                \ '    always #5 clk = ~clk;',
                \ '',
                \ '    // Initialization',
                \ '    initial begin',
                \ '        clk = 0;',
                \ '        rst_ = 1;',
                \ '        #10 rst_ = 0;',
                \ '        #10 rst_ = 1;',
                \ '        ',
                \ '        ',
                \ '        #10000 $stop;',
                \ '    end',
                \ '',
                \ 'endmodule',
                \ ''
                \ ]
    exec 'edit ' . expand('%:h') . '/tb_' . l:name . '.v'
    call setline(1, l:templete)
endfunction

function s:TestBenchRefresh(file)
    let l:end = search('// Module instance', 'n') - 1
    let l:start = search('// Instance variable definition', 'n') + 1
    if l:end > l:start
        exec l:start . ',' . l:end . 'd'
        let l:var = s:InstVarDef(a:file)
        call append(l:start - 1, l:var + [''])
    endif
    let l:start = search('// Module instance', 'n') + 1
    let l:end = search('// Clock signal', 'n') - 1
    if l:end > l:start
        exec l:start . ',' . l:end . 'd'
        let l:inst = s:InstanceTemplate(a:file)
        call append(l:start - 1, l:inst + [''])
    endif
    write
endfunction
" ==========================================================
" ==========================================================
function HDLVTestBench()
    write
    let l:file = expand('%:p')
    let l:name = s:ModuleName(l:file)
    if l:name !~ '^tb_'
        let l:tbFile = expand('%:h') . "/tb_" . l:name . ".v"
        if filereadable(l:tbFile)
            exec "0vsplit +1 " . l:tbFile 
            call s:TestBenchRefresh(l:file)
            quit
        else
            call s:TestBenchGenerate(l:file)
            call search('^\s*initial begin')
        endif
    else
        let l:name = matchstr(l:name,'^\(tb_\)\zs\w\+')
        let l:file = expand('%:h') . '/' . l:name . '.v'
"        let l:file=system("find . -maxdepth 2 -name '" . l:file . "'")
        call s:TestBenchRefresh(l:file)
    endif
endfunction

function HDLVInsertInstance()
    let l:word = matchstr(getline('.'), '\w\+$')
"    let l:file=system("find . -maxdepth 2 -name '*.v'|xargs -I{} grep -il '^\\s*module\\s\\+" . @z . "' {}")
    let l:file = system("find . -maxdepth 2 -iname '" . l:word . "*.v'|sed -n '1p'")
    if !empty(l:file)
        let l:inst = s:InstanceTemplate(l:file)
        normal dd
        call append(line('.') - 1, l:inst + [''])
        call search(');')
    else
        exec "echo ' Non-existent!!!'" 
    endif
endfunction

function HDLVAllFileInclude()
    call system("find . -maxdepth 2 -name '*.v'|sed '/\\(_bb\\|_inst\\)\\.v/d'|sed 's/^/`include \\\"/'|sed 's/$/\\\"/'>_All.vt")
endfunction

