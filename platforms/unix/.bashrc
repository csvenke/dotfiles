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
  git push origin "$(git branch --show-current)" "$@"
}
function git-sync-current-branch() {
  git pull origin "$(git branch --show-current)" "$@"
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
function git-bare-clone() {
  local url="$1"
  local path="${url##*/}"

  mkdir "$path"
  cd "$path" || exit 1
  git clone --bare "$url" .git

  local main_branch
  main_branch=$(git rev-parse --abbrev-ref HEAD)

  git worktree add --lock "$main_branch"
  git worktree add --lock review
}
function git-worktree-remove() {
  local selected_worktree
  selected_worktree=$(git worktree list | fzf)

  if [ -z "$selected_worktree" ]; then
    return 0
  fi

  local worktree_path
  worktree_path=$(echo "$selected_worktree" | awk '{print $1}')

  echo "Removing $worktree_path"
  git worktree remove "$worktree_path"
}
function git-worktree-prune() {
  local branches
  branches=$(git worktree list --porcelain | grep "prunable" -B 1 | grep "branch" | sed "s@branch refs/heads/@@" | xargs -r)

  if [ -z "$branches" ]; then
    echo "No prunable worktrees"
    return 0
  fi

  git worktree prune
  echo "$branches" | xargs git branch -D
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
function is-wsl() {
  [ -n "$WSL_DISTRO_NAME" ]
}

export DOTFILES="$HOME/.dotfiles"
export BASH_SILENCE_DEPRECATION_WARNING=1

alias src="source ~/.bashrc"
alias dot="cd ~/.dotfiles"

source_if_exists "$HOME/.bashrc.work.sh"
source_if_exists "$HOME/.bashrc.machine.sh"

if commands_exist "nix"; then
  alias flake-init="nix flake init -t github:csvenke/devkit"
fi

if commands_exist "git"; then
  alias gfb='git-find-branch'
  alias gpb='git-push-current-branch'
  alias gsb='git-sync-current-branch'
  alias gsm='git-sync-main-branch'
  alias gcm='git-checkout-main-branch'
  alias gcb='git-checkout-branch'
  alias gbc='git-bare-clone'
  alias gwa='git worktree add'
  alias gwr='git-worktree-remove'
  alias gwp='git-worktree-prune'
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

  alias vim="nvim"
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
  if commands_exist "fd"; then
    export FZF_DEFAULT_COMMAND='fd --type file'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  fi
  export FZF_DEFAULT_OPTS='--height 50% --layout=reverse --border'

  eval "$(fzf --bash)"
fi

if is-wsl; then
  export BROWSER='explorer.exe'

  alias start='explorer.exe'
  alias open='explorer.exe'
fi
