
if exists('g:loaded_verilog')
    finish
endif
let g:loaded_verilog = 1


command! -range -nargs=? Waive :<line1>,<line2>call verilog#waive(0, <q-args>)
command! -range -nargs=? Waives :<line1>,<line2>call verilog#waive(1, <q-args>)

