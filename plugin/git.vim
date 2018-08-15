
command! -nargs=+ -complete=custom,CompleteGitCommand Git :echo system('git ' . "<args>")[:-2]
command! -nargs=+ -complete=file Gadd :echo system('git add ' . '<args>')[:-2]
command! -nargs=* Gstatus :echo system('git status ' . '<args>')[:-2]
command! -nargs=* Glog :echo OutputGitLog('<args>')
command! -nargs=* Greflog :echo system('git reflog ' . '<args>')[:-2]
command! -nargs=+ Gcommit :echo system('git commit ' . "<args>")[:-2]
command! -nargs=+ -complete=file Greset :echo system('git reset ' . '<args>')[:-2]
command! -nargs=* -complete=custom,CompleteBranchName Gbranch :echo system('git branch ' . '<args>')[:-2]
command! -nargs=+ -complete=file Gcheckout :echo system('git checkout ' . '<args>')[:-2]
command! -nargs=* -complete=file Gtag :echo system('git tag ' . '<args>')[:-2]
command! -nargs=* -complete=custom,CompleteBranchName Gmerge :echo system('git merge ' . '<args>')[:-2]
command! -nargs=* Gmergetool :!git mergetool <args>
command! -nargs=* Gpush :echo system('git push ' . '<args>')[:-2]
command! -nargs=* Gpull :echo system('git pull ' . '<args>')[:-2]
command! -nargs=* Gfetch :echo system('git fetch ' . '<args>')[:-2]
command! -nargs=* Gremote :echo system('git remote ' . '<args>')[:-2]
command! -nargs=* -complete=file Gdiff :echo system('git diff ' . '<args>')[:-2]
command! -nargs=+ -complete=file Grm :echo system('git rm ' . '<args>')[:-2]
command! -nargs=+ -complete=file Gmv :echo system('git mv ' . '<args>')[:-2]
command! -nargs=* -complete=file Gdifftool :!git difftool <args>

" For merge complete
function! CompleteBranchName(A, L, P)
    return system("git branch|grep '^[^*]'|sed -n 's/^ \\+//p'")
endfunction

function! CompleteGitCommand(A, L, P)
    return system("git help|sed -n 's/^  \\+\\(\\w\\+\\) \\+.*/\\1/p'")
endfunction

" Format git log
function! OutputGitLog(str)
    let l:list = systemlist("git log --oneline --graph --pretty=format:\"%h - 👦%an 📆%ar  💬%s\" " . a:str)
    let l:num = 0
    let l:listPost = []
    for l:i in range(len(l:list))
        if l:list[i] =~ '^\*'
            let l:list[i] .= ' |' . l:num
            let l:num += 1
        endif
    endfor
    return join(l:list, "\n")
endfunction

