"
"
"

if exists('g:loaded_Async') && v:version >= 800
  finish
endif
let g:loaded_Async = 1


command -nargs=* -complete=shellcmd TTerm :call async#ToggleTerminal('toggle', <f-args>)
command -nargs=+ -complete=shellcmd Term :call async#ToggleTerminal('on', <f-args>)
command -nargs=+ -complete=shellcmd HTerm :call async#ToggleTerminal('off', <f-args>)
command -nargs=+ -complete=shellcmd Async :call async#RunJob(<q-args>)
command -nargs=? SAsync :call async#StopJob(<f-args>)
command LAsync :echo async#ListJob()
command -nargs=+ -complete=file SGdb :call async#GdbStart(<q-args>, BMBPSign#SignRecord('break', 'tbreak'))

