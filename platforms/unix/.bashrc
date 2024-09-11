function source_if_exists() {
  if test -r "$1"; then
    source "$1"
  fi
}
function commands_exist() {
  for cmd in "$@"; do
    command -v "$cmd" &>/dev/null || return 1
  done
  return 0
}
function git-main-branch() {
  git remote show origin | grep "HEAD branch:" | sed "s/HEAD branch://" | tr -d " \t\n\r"
}

function git-all-branches() {
  git branch -a -r --format="%(refname:short)" | sed "s@origin/@@" | sed "/^origin/d"
}

function git-find-branch() {
  git-all-branches | fzf | xclip -selection clipboard
}

function git-push-current-branch() {
  git push origin "$(git branch --show-current)"
}

function git-sync-current-branch() {
  git pull origin "$(git branch --show-current)"
}

function git-sync-main-branch() {
  git pull origin "$(git-main-branch)"
}

function git-checkout-main-branch() {
  git checkout "$(git-main-branch)"
}
function git-checkout-branch() {
  git-all-branches | fzf | xargs git checkout
}
function eza-list-files() {
  command eza --icons --colour=auto --sort=type --group-directories-first "$@"
}
function xclip-copy() {
  xclip -selection clipboard
}
function bat-cat() {
  bat --style=plain "$@"
}

export DOTFILES="$HOME/.dotfiles"
export BASH_SILENCE_DEPRECATION_WARNING=1

alias src="source ~/.bashrc"
alias dot="cd ~/.dotfiles"

if commands_exist "nix"; then
  alias flake-init="nix flake init -t github:csvenke/devenv"
fi

if commands_exist "git"; then
  alias gfb='git-find-branch'
  alias gpb='git-push-current-branch'
  alias gsb='git-sync-current-branch'
  alias gsm='git-sync-main-branch'
  alias gcm='git-checkout-main-branch'
  alias gcb='git-checkout-branch'
  alias ggpush='git-push-current-branch'
  alias ggpull='git-sync-current-branch'
fi

if commands_exist "eza"; then
  alias ls='eza-list-files'
  alias la='ls -a'
  alias ll='ls -al'
fi

if commands_exist "xclip"; then
  alias copy='xclip-copy'
fi

if commands_exist "bat"; then
  alias cat='bat-cat'
fi

if commands_exist "nvim"; then
  export EDITOR="nvim --clean"
  export VISUAL="nvim"
fi

if commands_exist "direnv"; then
  export DIRENV_LOG_FORMAT=
  export DIRENV_WARN_TIMEOUT=1m

  eval "$(direnv hook bash)"
fi

if commands_exist "starship"; then
  eval "$(starship init bash)"
fi

if commands_exist "fzf"; then
  if commands_exist "ag"; then
    export FZF_DEFAULT_COMMAND='ag --hidden -l -g ""'
  fi
  export FZF_DEFAULT_OPTS='--height 50% --layout=reverse --border'

  eval "$(fzf --bash)"
fi

source_if_exists "$HOME/.bashrc.work.sh"
source_if_exists "$HOME/.bashrc.machine.sh"

if commands_exist "tmux" && [ -n "$PS1" ] && [ -z "$TMUX" ]; then
  tmux new-session -A -s main
fi
