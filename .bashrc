source_if_exists() {
	if test -r "$1"; then
		source "$1"
	fi
}
git_current_branch() {
	git branch --show-current
}
git_main_branch() {
	git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'
}

export DOTFILES="$HOME/.dotfiles"
export DOTFLAKES="$HOME/.dotfiles/devenv"
export DEVENV="$HOME/.dotfiles/devenv"
export EDITOR="vim"
export VISUAL="nvim"
# fzf
export FZF_DEFAULT_COMMAND='ag --hidden -l -g ""'
export FZF_DEFAULT_OPTS='--height 50% --layout=reverse --border'
# direnv
export DIRENV_LOG_FORMAT=
export DIRENV_WARN_TIMEOUT=1m
# macos
export BASH_SILENCE_DEPRECATION_WARNING=1

alias src="source ~/.bashrc"
alias dot="cd ~/.dotfiles"
alias vim="command nvim --clean"
alias ggpush='command git push origin "$(git_current_branch)"'
alias ggpull='command git pull origin "$(git_current_branch)"'
alias ggsync='command git pull origin "$(git_main_branch)"'
alias ls='command eza --icons --colour=auto --sort=type --group-directories-first'
alias la='ls -a'
alias ll='ls -al'
alias cat='command bat --style=plain'

source_if_exists "$HOME/.bashrc.secrets.sh"

eval "$(direnv hook bash)"
eval "$(starship init bash)"
eval "$(fzf --bash)"
