"
"
"

if exists('g:loaded_Async') || v:version < 800
  finish
endif
let g:loaded_Async = 1


command -nargs=* -complete=shellcmd TTerm :call async#TermToggle('toggle', <f-args>)
command -nargs=+ -complete=shellcmd Term :call async#TermToggle('on', <f-args>)
command -nargs=+ -complete=shellcmd HTerm :call async#TermToggle('off', <f-args>)
command -nargs=+ -complete=shellcmd Async :call async#JobRun(<q-args>)
command -nargs=+ -complete=shellcmd AsyncQ :call async#JobRun(<q-args>, 'q')
command -nargs=? SAsync :call async#JobStop(<f-args>)
command LAsync :echo async#JobList()
command -nargs=+ -complete=file SGdb :call async#GdbStart(<q-args>, BMBPSign#SignRecord('break', 'tbreak'))

