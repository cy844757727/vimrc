"
"
if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1

setlocal nonu
setlocal tabstop=1
setlocal statusline=[branch\ status]%=\ \ \ \ \ %-10.(%l:%c%V%)\ %4P\ 

nnoremap <buffer> <C-w> :call GIT_CloseTab()<Cr>
nnoremap <buffer> <S-t> :call GIT_CloseTab()<Cr>
nnoremap <buffer> <f5>  :call GIT_Refresh(0)<Cr>
nnoremap <buffer> <silent> c :call <SID>CheckOutBranch()<Cr>
nnoremap <buffer> <silent> a :call <SID>AddRemote()<Cr>
nnoremap <buffer> n :call <SID>NewBranch()<Cr>
nnoremap <buffer> j :call <SID>JumpCommit()<Cr>

augroup Git_branch
	autocmd!
	autocmd BufWritePost <buffer> call delete('.Git_branch')
augroup END

if !exists('*<SID>CheckOutBranch')
	function <SID>CheckOutBranch()
    	let l:str = split(getline('.'))
    	if len(l:str) > 3 && l:str[0] != '*'
    		let l:msg = system("git checkout " . l:str[0])
    		call GIT_Refresh(0)
    		4wincmd w
    	endif
	endfunction
endif

function! <SID>AddRemote()
	let l:name = input('Enter a name(Default origin)： ')
	if empty(l:name)
		let l:name = 'origin'
	endif
	let l:addr = input('Enter remote URL: ')
	if empty(l:addr)
		echo 'Abort: NO URL'
		return
	endif
	echo system("git remote add " . l:name . ' ' . l:addr)[:-2]
endfunction

function! <SID>NewBranch()
	echo 'none'
endfunction

function! <SID>JumpCommit()
	echo 'none'
endfunction
