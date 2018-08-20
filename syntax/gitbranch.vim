"
"
"
syn match GITBranchRegin /^Local:\|^Remote:\|^Tag:\|^Stash:/
syn match GITBranchCurrent /* \w\+/

hi def link GITBranchRegin   keyword
hi def link GITBranchCurrent constant
