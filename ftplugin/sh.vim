if exists("b:did_ftplugin_")
    finish
endif
let b:did_ftplugin_ = 1

syn cluster shDblQuoteList remove=shDerefSimple,shDeref
