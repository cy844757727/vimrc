"syn match  pythonFunParamter '\h\w*' display contained
"syn region pythonFunArgDef matchgroup=Normal start='(' end=')' contained contains=pythonFunParamter
"syn match  pythonFunction '\h\w*' display contained nextgroup=pythonFunArgDef
syn cluster pythonDS contains=pythonString,pythonRawString,pythonQuotes,pythonbuiltin,
            \ pythonrepeat,pythonOperator,pythonConditional,pythonNumber,pythonEscape
syn cluster pythonBC contains=pythonString,pythonNumber,pythonbuiltin

syn region pythonFuncall  matchgroup=Normal start='\w\zs(' end=')'
            \ contains=@pythonBC,pythonDataSet
syn region pythonDataIndex  matchgroup=Normal start='\(\w\|)\)\zs\[' end=']'
            \ contains=@pythonBC,pythonDataIndex
" Python basic data set type: list tuple dict set
syn region pythonDataSet  matchgroup=Constant start='[^0-9a-zA-Z_)]\zs\[' end=']'
            \ contains=@pythonDS,pythonDataSet,pythonDataIndex
syn region pythonDataSet  matchgroup=Constant start='{' end='}'
            \ contains=@pythonDS,pythonDataSet
syn region pythonDataSet  matchgroup=Constant start='\W\zs(' end=')'
            \ contains=@pythonDS,pythonDataSet,pythonFunCall,

