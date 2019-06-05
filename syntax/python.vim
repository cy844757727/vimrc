" File: python.vim
" Author: cy
" Description: extend python syntax

syn cluster pythonDS contains=pythonString,pythonRawString,pythonQuotes,pythonbuiltin,
            \ pythonrepeat,pythonOperator,pythonConditional,pythonNumber,pythonEscape
syn cluster pythonBC contains=pythonString,pythonRawString,pythonQuotes,pythonNumber,
            \ pythonOperator,pythonbuiltin

syn match pythonSystemVariable '\<__\w\+__\>'
syn region pythonFuncall  matchgroup=Normal start='\w\zs(' end=')'
            \ contains=@pythonBC,pythonDataSet
syn region pythonDataIndex  matchgroup=Normal start='\(\w\|)\)\zs\[' end=']'
            \ contains=@pythonBC,pythonDataIndex
" Python basic data set type: list tuple dict set
syn region pythonDataSet  matchgroup=pythonDataBoundary start='[^0-9a-zA-Z_)\]}]\zs\[' end='\]'
            \ contains=@pythonDS,pythonDataSet,pythonDataIndex
syn region pythonDataSet  matchgroup=pythonDataBoundary start='{' end='}'
            \ contains=@pythonDS,pythonDataSet
syn region pythonDataSet  matchgroup=pythonDataBoundary start='\W\zs(' end=')'
            \ contains=@pythonDS,pythonDataSet,pythonFunCall,

hi default link pythonDataBoundary Constant
hi default link pythonSystemVariable pythonBuiltIN

