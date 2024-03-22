if ! command -v fzf >/dev/null; then
	return
fi
if ! command -v fzf-share >/dev/null; then
	return
fi

export FZF_DEFAULT_COMMAND='ag --hidden -l -g ""'
export FZF_DEFAULT_OPTS='--height 50% --layout=reverse --border'

source "$(fzf-share)/key-bindings.bash"
source "$(fzf-share)/completion.bash"
