"
"
"
syn match InfoWinFile /^\S\+$/
syn match InfoWinLineNr /^\s\+[0-9,:]\+:/
"syn match InfoWinLineMatch /\v-^/

hi link InfoWinFile Directory
hi link InfoWinLineNr Function
hi default InfoWinMatch cterm=NONE
