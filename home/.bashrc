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
  git for-each-ref --format='%(refname:short)' refs/heads/ refs/remotes/ | sed "s@origin/@@" | grep -v "^origin"
}
function git_find_branch() {
  git_all_branches | fzf | xclip -selection clipboard
}
function git_push_current_branch() {
  git push origin "$(git branch --show-current)" "$@"
}
function git_sync_current_branch() {
  git pull origin "$(git branch --show-current)" "$@"
}
function git_sync_main_branch() {
  git pull origin "$(git_main_branch)"
}
function git_checkout_main_branch() {
  git checkout "$(git_main_branch)"
}
function git_checkout_branch() {
  git_all_branches | fzf | xargs git checkout
}
function git_worktree_add() {
  git worktree add "$@"

  local path="${*: -1}"

  if [ -d ".shared" ]; then
    cp -r .shared/. "$path/"
  fi

  if has_cmd "direnv" && [ -f "$path/.envrc" ]; then
    direnv allow "$path"
  fi
}
function git_bare_clone() {
  local url="$1"
  local path="${url##*/}"

  mkdir "$path"
  cd "$path" || return
  git clone --bare "$url" .git || return
  mkdir -p .shared

  git worktree add --lock --orphan nix
  (cd nix && nix flake init -t github:csvenke/devkit && nix flake lock)
  echo 'use flake "../nix"' >.shared/.envrc

  git_worktree_add --lock "$(git_main_branch)"
  git_worktree_add --lock --detach dev
  git_worktree_add --lock --detach review
}
function git_bare_init() {
  local name="$1"
  local main_branch="main"

  mkdir "$name"
  cd "$name" || return
  git init --bare .git -b "$main_branch" || return
  git worktree add --lock --orphan "$main_branch"
  cd "$main_branch" || return
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

alias src="source ~/.bashrc"
alias dot="cd ~/.dotfiles"

if has_cmd "nix"; then
  alias flake-init="nix flake init -t github:csvenke/devkit"
fi

if has_cmd "git"; then
  alias gaa='git add . && git status -s'
  alias gra='git restore --staged . && git status -s'
  alias gfb='git_find_branch'
  alias gpb='git_push_current_branch'
  alias gsb='git_sync_current_branch'
  alias gsm='git_sync_main_branch'
  alias gcm='git_checkout_main_branch'
  alias gcb='git_checkout_branch'
  alias gcB='git checkout -b'
  alias gbc='git_bare_clone'
  alias gbi='git_bare_init'
  alias gwa='git_worktree_add'
  alias gwr='git_worktree_remove'
  alias gwp='git_worktree_prune'
fi

if has_cmd "lazygit"; then
  alias gui='lazygit'
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

  alias vim="nvim"
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

if is_wsl; then
  export BROWSER='explorer.exe'

  alias start='explorer.exe'
  alias open='explorer.exe'
fi

source_if_exists "$HOME/.work/.bashrc"
