if [ -f "$HOME/.bashrc" ]; then
  source "$HOME/.bashrc"
fi

if command -v tmux >/dev/null && [ -n "$PS1" ] && [ -z "$TMUX" ]; then
  tmux new -A -s main
fi
