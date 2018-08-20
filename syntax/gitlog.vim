"
"
"
syn match GITHashKey /\w\{7}/
syn match GITAuthor /👦[^📆]*/
syn match GITTime /📆[^💬]*/
syn match GITMessage /💬.*$/

hi def link GITHashKey type
"hi def link GITAuthor  constant
"hi def link GITTime    constant
hi def link GITMessage string

