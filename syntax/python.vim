"syn match  pythonFunParamter '\h\w*' display contained
"syn region pythonFunArgDef matchgroup=Normal start='(' end=')' contained contains=pythonFunParamter
"syn match  pythonFunction '\h\w*' display contained nextgroup=pythonFunArgDef
syn region pythonFuncall  matchgroup=Normal start='\w\zs(' end=')' contains=pythonString,pythonNumber,pythonDataSet
syn region pythonDataIndex  matchgroup=Normal start='\(\w\|)\)\zs\[' end=']' contains=pythonString,pythonNumber,pythonDataIndex

" Python basic data set type: list tuple dict set
syn region pythonDataSet  matchgroup=Constant start='[^0-9a-zA-Z_)]\zs\[' end=']'
            \ contains=pythonDataSet,pythonString,pythonRawString,pythonQuotes,pythonbuiltin,pythonrepeat,pythonOperator,
            \ pythonConditional,pythonNumber,pythonEscape,pythonDataIndex
syn region pythonDataSet  matchgroup=Constant start='{' end='}'
            \ contains=pythonDataSet,pythonString,pythonRawString,pythonQuotes,pythonbuiltin,pythonrepeat,pythonOperator,
            \ pythonConditional,pythonNumber,pythonEscape
syn region pythonDataSet  matchgroup=Constant start='\W\zs(' end=')'
            \ contains=pythonDataSet,pythonString,pythonRawString,pythonQuotes,ythonbuiltin,pythonrepeat,pythonOperator,
            \ pythonConditional,pythonNumber,pythonEscape,pythonFunCall,

