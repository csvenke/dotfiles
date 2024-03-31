if [ -f "$HOME/.bashrc" ]; then
	source $HOME/.bashrc
fi

if [ -n "$PS1" ] && [ -z "$TMUX" ]; then
	tmux new-session -A -s main
fi
