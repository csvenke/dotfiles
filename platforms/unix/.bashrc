source_if_exists() {
  if test -r "$1"; then
    source "$1"
  fi
}
commands_exist() {
  for cmd in "$@"; do
    command -v "$cmd" &>/dev/null || return 1
  done
  return 0
}

export DOTFILES="$HOME/.dotfiles"
export BASH_SILENCE_DEPRECATION_WARNING=1

alias src="source ~/.bashrc"
alias dot="cd ~/.dotfiles"

if commands_exist "nix"; then
  alias flake-init="nix flake init -t github:csvenke/devenv"
  alias dev="nix run github:csvenke/tools#dev"
fi

if commands_exist "direnv"; then
  export DIRENV_LOG_FORMAT=
  export DIRENV_WARN_TIMEOUT=1m

  eval "$(direnv hook bash)"
fi

if commands_exist "starship"; then
  eval "$(starship init bash)"
fi

if commands_exist "nvim"; then
  export EDITOR="nvim --clean"
  export VISUAL="nvim"

  alias chatgpt="nvim -c GpChatNew"
fi

if commands_exist "fzf" "ag"; then
  export FZF_DEFAULT_COMMAND='ag --hidden -l -g ""'
  export FZF_DEFAULT_OPTS='--height 50% --layout=reverse --border'

  eval "$(fzf --bash)"
fi

source_if_exists "$HOME/.bashrc.work.sh"
source_if_exists "$HOME/.bashrc.machine.sh"

if commands_exist "tmux" && [ -n "$PS1" ] && [ -z "$TMUX" ]; then
  tmux new-session -A -s main
fi
