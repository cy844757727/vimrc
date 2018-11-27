"
"
"

if exists('g:loaded_Async') && v:version >= 800
  finish
endif
let g:loaded_Async = 1


command -nargs=? TTerm :call async#ToggleTerminal('toggle', <q-args>)
command -nargs=+ -complete=file Async :call job_start("<args>", {'in_io': 'null', 'out_io': 'null', 'err_io': 'null'})
command! -nargs=+ -complete=file TermH :call term_start("<args>", {'hidden': 1, 'term_kill': 'kill', 'term_finish': 'close', 'norestore': 1})

