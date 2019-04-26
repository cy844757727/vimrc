"
"
"

let s:fileformat = {'unix': '', 'mac': '', 'dos': ''}
let s:buftype = {'terminal': 'ﲵ', 'help': '', 'quickfix': '', 'nofile': '', 'nowrite': '', 'acwrite': ''}

let s:filetype = extend({
            \ 'awk':    '',     'c':          '',     'conf':          '',
            \ 'cpp':    '',     'css':        '',     'dart':          '',
            \ 'diff':   '',     'dockerfile': '',     'git':           '',
            \ 'go':     '',     'haskell':    '',     'help':          '',
            \ 'html':   '',     'java':       '',     'javascript':    '',
            \ 'json':   '',     'lua':        '',     'markdown':      '',
            \ 'pdf':    '',     'perl':       '',     'php':           '',
            \ 'python': '',     'rar':        '',     'rmd':           '',
            \ 'ruby':   '',     'scala':      '',     'scss':          '',
            \ 'sh':     '',     'sql':        '',     'systemverilog': '',
            \ 'tags':   '',     'tar':        '',     'zip':           '',
            \ 'text':   '',     'verilog':    '',     'vhdl':          '',
            \ 'vim':    ''
            \ }, get(g:, 'iconicFont_filetype', {}))

let s:extension = extend({
            \ '7z':       '',     'aac':      '',     'ai':       '',
            \ 'ape':      '',     'avi':      '',     'awk':      '',
            \ 'bash':     '',     'bat':      '',     'bmp':      '',
            \ 'c':        '',     'c++':      '',     'cc':       '',
            \ 'clj':      '',     'cljc':     '',     'cljs':     '',
            \ 'coffee':   '',     'conf':     '',     'cp':       '',
            \ 'cpp':      '',     'csh':      '',     'css':      '',
            \ 'cxx':      '',     'd':        '',     'dart':     '',
            \ 'db':       '',     'diff':     '',     'doc':      '',
            \ 'docx':     '',     'dump':     '',     'edn':      '',
            \ 'ejs':      '',     'erl':      '',     'f#':       '',
            \ 'fish':     '',     'flac':     '',     'fs':       '',
            \ 'fsi':      '',     'fsscript': '',     'fsx':      '',
            \ 'gif':      '',     'git':      '',     'go':       '',
            \ 'gz':       '',     'gzip':     '',     'h':        '',
            \ 'hbs':      '',     'help':     '',     'hpp':      '',
            \ 'hrl':      '',     'hs':       '',     'htm':      '',
            \ 'html':     '',     'hxx':      '',     'ico':      '',
            \ 'ini':      '',     'iso':      '',     'jar':      '',
            \ 'java':     '',     'jl':       '',     'jpeg':     '',
            \ 'jpg':      '',     'js':       '',     'json':     '',
            \ 'jsx':      '',     'ksh':      '',     'less':     '',
            \ 'lhs':      '',     'lua':      '',     'markdown': '',
            \ 'md':       '',     'mkv':      '',     'mli':      'λ',
            \ 'ml':       'λ',     'mp3':      '',     'mp4':      '',
            \ 'mustache': '',     'ogg':      '',     'pdf':      '',
            \ 'php':      '',     'pl':       '',     'pm':       '',
            \ 'png':      '',     'pp':       '',     'ppt':      '',
            \ 'pptx':     '',     'ps1':      '',     'psb':      '',
            \ 'psd':      '',     'py':       '',     'pyc':      '',
            \ 'pyd':      '',     'pyo':      '',     'rar':      '',
            \ 'rb':       '',     'rlib':     '',     'rmd':      '',
            \ 'rs':       '',     'rss':      '',     'sass':     '',
            \ 'scala':    '',     'scss':     '',     'sh':       '',
            \ 'slim':     '',     'sln':      '',     'sql':      '',
            \ 'styl':     '',     'suo':      '',     'sv':       '',
            \ 'sva':      '',     'svh':      '',     'svi':      '',
            \ 'svp':      '',     't':        '',     'tag':      '',
            \ 'tags':     '',     'tar':      '',     'text':     '',
            \ 'ts':       '',     'tsx':      '',     'twig':     '',
            \ 'v':        '',     'vg':       '',     'vh':       '',
            \ 'vhd':      '',     'vhdl':     '',     'vim':      '',
            \ 'vo':       '',     'vp':       '',     'vt':       '',
            \ 'vue':      '﵂',     'xls':      '',     'xlsx':     '',
            \ 'xul':      '',     'yaml':     '',     'yml':      '',
            \ 'zip':      '',     'zsh':      ''
            \ }, get(g:, 'iconicFont_extension', {}))


function! iconicFont#icon(key, ...)
    if empty(a:key)
        return get(a:000, 0, '')
    endif

    return
                \ get(s:fileformat, a:key,
                \ get(s:buftype, a:key, 
                \ get(s:filetype, a:key, 
                \ get(s:extension, a:key, 
                \ get(a:000, 0, '')))))
endfunction

