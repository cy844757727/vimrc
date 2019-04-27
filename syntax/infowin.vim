"
"
"
syn match InfoWinFile /^\S\+$/
syn match InfoWinLineNr /^\s\+\d\+:/ nextgroup=InfoWinColumnNr
syn match InfoWinColumnNr /\s\+\d\+:\ze / contained
"syn match InfoWinLineMatch /\v-^/

hi link InfoWinFile Directory
hi link InfoWinLineNr Function
hi link InfoWinColumnNr LineNr
hi default InfoWinMatch cterm=NONE
