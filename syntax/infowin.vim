"
"
"
syn match InfoWinFile /^\S\+$/
syn match InfoWinLineNr /^\s\+\d\+:/
syn match InfoWinColumnNr / \zs\d\+:\ze /
"syn match InfoWinLineMatch /\v-^/

hi link InfoWinFile Directory
hi link InfoWinLineNr Function
hi link InfoWinColumnNr LineNr
hi default InfoWinMatch cterm=NONE
