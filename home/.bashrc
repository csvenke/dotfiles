function source_if_exists() {
  if test -r "$1"; then
    source "$1"
  fi
}

function has_cmd() {
  command -v "$1" &>/dev/null || return 1
  return 0
}

function git_main_branch() {
  git remote show origin | grep "HEAD branch:" | sed "s/HEAD branch://" | tr -d " \t\n\r"
}

function git_all_branches() {
  git fetch origin
  git for-each-ref --format='%(refname:short)' refs/heads/ refs/remotes/ | sed "s@origin/@@" | grep -v "^origin"
}

function git_find_branch() {
  git_all_branches | fzf | xclip -selection clipboard
}

function git_push_current_branch() {
  git push origin "$(git branch --show-current)" "$@"
}

function git_push_force_current_branch() {
  git_push_current_branch --force-with-lease "$@"
}

function git_sync_current_branch() {
  git pull origin "$(git branch --show-current)" "$@"
}

function git_sync_main_branch() {
  git pull origin "$(git_main_branch)"
}

function git_checkout_main_branch() {
  git switch "$(git_main_branch)"
}

function git_rebase_branch() {
  git rebase -i "$(git merge-base HEAD "$(git_main_branch)")"
}

function git_add_all() {
  git add . && git status -s
}

function git_unstage_all() {
  git restore --staged . && git status -s
}

function git_checkout_local_branch() {
  local branch_name="$1"

  if [ -z "$branch_name" ]; then
    return 1
  fi

  git fetch origin
  git switch --create "$branch_name"
}

function git_checkout_remote_branch() {
  local branch_name="$1"

  if [ -z "$branch_name" ]; then
    return 1
  fi

  git fetch origin
  git switch "$branch_name"
}

function setup_shared_dir() {
  mkdir -p .shared

  if has_cmd "nix"; then
    git worktree add --lock --orphan nix
    (cd nix && nix flake init -t github:csvenke/devkit && nix flake lock)
    echo 'use flake "../nix"' >.shared/.envrc
  fi
}

function setup_worktree() {
  local path="$1"

  if [ -d ".shared" ]; then
    cp -r .shared/. "$path/"
  fi

  if has_cmd "direnv" && [ -f "$path/.envrc" ]; then
    direnv allow "$path"
  fi
}

function git_worktree_add() {
  git worktree add "$@"

  local path="${*: -1}"
  setup_worktree "$path"
}

function git_worktree_clone() {
  local url="$1"
  local path="${url##*/}"
  local original_dir="$PWD"

  mkdir "$path"
  cd "$path" || return
  git clone --bare "$url" .git || return

  setup_shared_dir

  local main_branch
  main_branch="$(git_main_branch)"

  git_worktree_add --lock "$main_branch"
  (cd "$main_branch" && git push -u origin "$main_branch")

  git_worktree_add --lock --detach dev
  git_worktree_add --lock --detach review

  cd "$original_dir" || return
}

function git_worktree_init() {
  local name="$1"
  local main_branch="main"

  mkdir "$name"
  cd "$name" || return

  git init --bare .git -b "$main_branch" || return
  git worktree add --orphan --lock "$main_branch"
  (cd "$main_branch" && touch README.md && git add . && git commit -m "genesis")

  setup_shared_dir
  setup_worktree "$main_branch"
  git_worktree_add --lock --detach dev
  git_worktree_add --lock --detach review
}

function git_worktree_remove() {
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

function git_worktree_switch() {
  local selected_worktree
  selected_worktree=$(git worktree list | fzf | awk '{print $1}')

  if [ -z "$selected_worktree" ]; then
    return 0
  fi

  cd "$selected_worktree" || return 1
}

function git_worktree_prune() {
  local branches
  branches=$(git worktree list --porcelain | grep "prunable" -B 1 | grep "branch" | sed "s@branch refs/heads/@@" | xargs -r)

  if [ -z "$branches" ]; then
    echo "No prunable worktrees"
    return 0
  fi

  git worktree prune
  echo "$branches" | xargs git branch -D
}

function eza_list_files() {
  command eza --icons --colour=auto --sort=type --group-directories-first "$@"
}

function xclip_copy() {
  xclip -selection clipboard
}

function bat_cat() {
  bat --style=plain "$@"
}

function is_wsl() {
  [ -n "$WSL_DISTRO_NAME" ]
}

export DOTFILES="$HOME/.dotfiles"
export XDG_CONFIG_HOME="$HOME/.config"
export BASH_SILENCE_DEPRECATION_WARNING=1

alias which="command -v"

if [ -d "$HOME/.dotfiles" ]; then
  export DOTFILES="$HOME/.dotfiles"

  alias update-dotfiles="(cd ~/.dotfiles && git checkout HEAD -- flake.lock && nix flake update && nix run .#install)"
  alias src="source ~/.bashrc"
  alias dot="cd ~/.dotfiles"
fi

if has_cmd "nix"; then
  alias flake-init="nix flake init -t github:csvenke/devkit"
fi

if has_cmd "git"; then
  alias gfb='git_find_branch'
  alias gcm='git_checkout_main_branch'
  alias gcb='git_checkout_local_branch'
  alias gcB='git_checkout_remote_branch'
  alias gca='git commit --amend'
  alias gcA='git commit --amend --no-edit'
  alias gaa='git_add_all'
  alias gua='git_unstage_all'
  alias gpb='git_push_current_branch'
  alias gpB='git_push_force_current_branch'
  alias gsb='git_sync_current_branch'
  alias gsm='git_sync_main_branch'
  alias grb='git_rebase_branch'
  alias gwi='git_worktree_init'
  alias gwc='git_worktree_clone'
  alias gws='git_worktree_switch'
  alias gwa='git_worktree_add'
  alias gwr='git_worktree_remove'
  alias gwp='git_worktree_prune'
fi

if has_cmd "lazygit"; then
  alias lg='lazygit'
fi

if has_cmd "eza"; then
  alias ls='eza_list_files'
  alias la='ls -a'
  alias ll='ls -al'
fi

if has_cmd "xclip"; then
  alias copy='xclip_copy'
fi

if has_cmd "bat"; then
  alias cat='bat_cat'
fi

if has_cmd "nvim"; then
  export EDITOR="nvim --clean"
  export VISUAL="nvim"

  alias vim="nvim --clean"
fi

if has_cmd "direnv"; then
  export DIRENV_LOG_FORMAT=
  export DIRENV_WARN_TIMEOUT=1m

  eval "$(direnv hook bash)"
fi

if has_cmd "starship"; then
  eval "$(starship init bash)"
fi

if has_cmd "fzf"; then
  if has_cmd "fd"; then
    export FZF_DEFAULT_COMMAND='fd --type file'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  fi
  export FZF_DEFAULT_OPTS='--height 50% --layout=reverse --border'

  eval "$(fzf --bash)"
fi

if has_cmd "pacman"; then
  alias update-system='sudo pacman -Syu'
fi

if has_cmd "apt"; then
  alias update-system='sudo apt update && sudo apt upgrade'
fi

if is_wsl; then
  export BROWSER='explorer.exe'

  alias start='explorer.exe'
  alias open='explorer.exe'
fi

source_if_exists "$HOME/.machine/.bashrc"
