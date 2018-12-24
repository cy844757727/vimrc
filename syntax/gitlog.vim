"
"
"
syn match GITHashKey /\w\{7}/
syn match GITAuthor /[^ﲊ]*/
syn match GITTime /ﲊ[^(]*/
syn match GITMessage /.*$/
syn match GITBranch /([^]*)/

hi def link GITHashKey type
"hi def link GITAuthor  constant
"hi def link GITTime    constant
hi def link GITMessage string
"hi def link GITBranch keyword

