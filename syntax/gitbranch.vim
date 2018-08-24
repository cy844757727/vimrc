"
"
"
syn match GITBranchRegin /^Local:\|^Remote:\|^Tag:\|^Stash:/
syn match GITBranchCurrent /\* [a-zA-Z0-9_]\+\s\+[a-zA-Z0-9]\+/

hi def link GITBranchRegin   keyword
hi def link GITBranchCurrent constant
