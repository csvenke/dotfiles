{ pkgs }:

pkgs.writeShellScriptBin "bashrc" /* bash */ ''
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
  export EDITOR="nvim --clean"
  export VISUAL="nvim"
  export FZF_DEFAULT_COMMAND='ag --hidden -l -g ""'
  export FZF_DEFAULT_OPTS='--height 50% --layout=reverse --border'
  export DIRENV_LOG_FORMAT=
  export DIRENV_WARN_TIMEOUT=1m
  export BASH_SILENCE_DEPRECATION_WARNING=1

  alias src="source ~/.bashrc"
  alias dot="cd ~/.dotfiles"
  alias gpb='command git push origin "$(git_current_branch)"'
  alias gsb='command git pull origin "$(git_current_branch)"'
  alias gsm='command git pull origin "$(git_main_branch)"'
  alias gcm='command git checkout "$(git_main_branch)"'
  alias ggpush='gpb'
  alias ggpull='gsb'
  alias ggsync='gsm'
  alias ls='command eza --icons --colour=auto --sort=type --group-directories-first'
  alias la='ls -a'
  alias ll='ls -al'
  alias cat='command bat --style=plain'
  alias flake-init="nix flake init -t github:csvenke/devenv"

  source_if_exists "$HOME/.bashrc.work.sh"
  source_if_exists "$HOME/.bashrc.machine.sh"

  eval "$(direnv hook bash)"
  eval "$(starship init bash)"
  eval "$(fzf --bash)"

  if [ -n "$PS1" ] && [ -z "$TMUX" ]; then
    tmux new-session -A -s main
  fi
''
