
command! -nargs=+ -complete=file Gadd :echo system('git add ' . '<args>')
command! -nargs=* Gstatus :echo system('git status ' . '<args>')
command! -nargs=* Glog :echo system("git log --oneline --graph --pretty=format:\"%h - 👦%an 📆%ar  💬%s\" " . '<args>')
command! -nargs=* Greflog :echo system('git reflog ' . '<args>')
command! -nargs=+ Gcommit :echo system('git commit ' . "<args>")
command! -nargs=+ -complete=file Greset :echo system('git reset ' . '<args>')
command! -nargs=* Gbranch :echo system('git branch ' . '<args>')
command! -nargs=+ -complete=file Gcheckout :echo system('git checkout ' . '<args>')
command! -nargs=* -complete=file Gtag :echo system('git tag ' . '<args>')
command! -nargs=* Gmerge :echo system('git merge ' . '<args>')
command! -nargs=* Gmergetool :!git mergetool '<args>'
command! -nargs=* Gpush :echo system('git push ' . '<args>')
command! -nargs=* Gpull :echo system('git pull ' . '<args>')
command! -nargs=* Gfetch :echo system('git fetch ' . '<args>')
command! -nargs=* Gremote :echo system('git remote ' . '<args>')
command! -nargs=* Gdiff :echo system('git diff ' . '<args>')
command! -nargs=+ -complete=file Grm :echo system('git rm ' . '<args>')
command! -nargs=+ -complete=file Gmv :echo system('git mv ' . '<args>')
command! -nargs=* Gdifftool :!git difftool '<args>'

