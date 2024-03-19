if ! command -v git >/dev/null; then
	return
fi

alias ggpush='command git push origin "$(git_current_branch)"'
alias ggpull='command git pull origin "$(git_current_branch)"'
