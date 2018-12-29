"
"
"
syn match GITBranchRegin /^Local:\|^Remote:\|^Tag:\|^Stash:/
syn match GITBranchCurrent /\* [a-zA-Z0-9_]\+\s\+[a-zA-Z0-9]\+/

hi link GITBranchRegin   Statement
hi link GITBranchCurrent constant
