"
"
if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1

setlocal nonu
setlocal statusline=[file\ status]%=\ \ \ \ \ %-10.(%l:%c%V%)\ %4P\ 

nnoremap <buffer> <C-w> :call GIT_CloseTab()<Cr>
nnoremap <buffer> <S-t> :call GIT_CloseTab()<Cr>
nnoremap <buffer> <f5>  :call GIT_Refresh(0)<Cr>
nnoremap <buffer> <silent> d :call <SID>FileDiff()<Cr>
nnoremap <buffer> <silent> r :call <SID>CancelStaged(0)<Cr>
nnoremap <buffer> <silent> a :call <SID>AddFile(0)<Cr>
nnoremap <buffer> <silent> R :call <SID>CancelStaged(1)<Cr>
nnoremap <buffer> <silent> A :call <SID>AddFile(1)<Cr>
nnoremap <buffer> <silent> \co :call <SID>CheckOutFile()<Cr>

augroup Git_status
	autocmd!
	autocmd BufWritePost <buffer> call delete('.Git_status')
augroup END

if !exists('*<SID>Refresh')
    function <SID>Refresh(lin)
        silent edit!
        call setline(1, GIT_FormatStatus())
        call cursor(a:lin, 1)
        set filetype=gitstatue
    endfunction
endif

if !exists('*<SID>FileDiff')
    function <SID>FileDiff()
        let l:str = split(getline('.'))
        if len(l:str) == 2
        	let [l:sign, l:file] = split(system("git status -s -- " . l:str[1]))
        	if l:sign =~ 'M' "&& l:sign !～ 'A'
            	let l:lin = search('^尚未暂存以备提交的变更\|^Changes not staged for commit', 'n')
            	if l:lin == 0 || line('.') < l:lin
            		let l:flag = ' -y --cached '
                else
                    let l:flag = ' -y '
            	endif
                exec '!git difftool' . l:flag . l:file
        	endif
        endif
    endfunction
endif

if !exists('*<SID>CancelStaged')
    function <SID>CancelStaged(arg)
        if a:arg == 1
            let l:msg = system('git reset HEAD')
            call <SID>Refresh(line('.'))
        else
            let l:str = split(getline('.'))
            let l:lin = search('^尚未暂存以备提交的变更\|Changes not staged for commit', 'n')
            if len(l:str) == 2 && (l:lin == 0 || line('.') < l:lin)
                let l:msg = system("git reset HEAD -- " . l:str[1])
                call <SID>Refresh(line('.'))
            endif
        endif
    endfunction
endif

if !exists('*<SID>AddFile')
    function <SID>AddFile(arg)
        let l:curL = line('.')
        if a:arg == 1
            let l:msg = system('git add .')
            call <SID>Refresh(l:curL)
        else
            let l:lin = search('^未跟踪的文件\|^Untracked files', 'n')
            if l:lin != 0 && l:curL > l:lin
                call system('git add -- ' . getline('.'))
            else
                let l:lin = search('^尚未暂存以备提交的变更\|Changes not staged for commit', 'n')
                let l:str = split(getline('.'))
                if l:lin != 0 && l:curL > l:lin && len(l:str) == 2
                    let l:msg = system('git add -- ' . l:str[1])
                    call <SID>Refresh(l:curL)
                endif
            endif
        endif
    endfunction
endif

if !exists('*<SID>CheckOutFile')
	function <SID>CheckOutFile()
    	let l:str = split(getline('.'))
    	if len(l:str) == 2
    		let l:msg = system('git checkout HEAD -- ' . l:str[1])
    		call <SID>Refresh(line('.'))
    	endif
	endfunction
endif

