case $- in
*i*) ;;
*) return ;;
esac

export OSH="$HOME/.oh-my-bash"
export OSH_THEME="robbyrussell"
export OMB_USE_SUDO=true

export DOTFILES="$HOME/.dotfiles"
export DOTFLAKES="$HOME/.dotfiles/flakes"

export DIRENV_LOG_FORMAT=
export DIRENV_WARN_TIMEOUT=1m

export FZF_DEFAULT_COMMAND='ag --hidden --ignore .git -l -g ""'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

source $OSH/oh-my-bash.sh

eval "$(direnv hook bash)"

# fzf fuzzy completions
if command -v fzf-share >/dev/null; then
	source "$(fzf-share)/key-bindings.bash"
	source "$(fzf-share)/completion.bash"
fi

alias src='source ~/.bashrc'
alias ggpush='command git push origin "$(git_current_branch)"'
alias ggpull='command git pull origin "$(git_current_branch)"'
