
"
"
"
syn match GITStatus /^Staged:\|^Untracked:\|^WorkSpace:/
syn match GITBranchCurrent /^## \S\+/

hi link GITStatus   Statement
hi link GITBranchCurrent constant
