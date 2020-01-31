
"
"
"
syn match GITStatus /^Staged:\|^Untracked:\|^WorkSpace:/
syn match GITBranchCurrentStatue /^##.*/

hi link GITStatus   Statement
hi link GITBranchCurrentStatue constant
