#!/usr/bin/env bash

set -euo pipefail

sanitize_name() {
  printf "%s" "$1" | tr -cd '[:alnum:]-_'
}

get_repo_base_path() {
  local pane_path="$1"
  local git_common_dir

  git_common_dir="$(git -C "$pane_path" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)"
  dirname "$git_common_dir"
}

get_repo_name() {
  local pane_path="$1"
  local base_path
  base_path="$(get_repo_base_path "$pane_path")"
  sanitize_name "$(basename "$base_path")"
}

current_session="$(tmux display-message -p '#S')"
pane_path="${1:-$PWD}"

if [[ "$current_session" == workspace-* ]]; then
  prev_session="$(tmux show-option -gqv '@workspace-return-session')"
  if [[ -n "$prev_session" ]]; then
    tmux switch-client -t "$prev_session"
  fi
  exit 0
fi

if ! git -C "$pane_path" rev-parse --git-dir &>/dev/null; then
  repo_name="scratch"
  worktree_root="$pane_path"
else
  repo_name="$(get_repo_name "$pane_path")"
  worktree_root="$(git -C "$pane_path" rev-parse --show-toplevel 2>/dev/null)" || worktree_root="$pane_path"
fi

session_name="workspace-$repo_name"

tmux set-option -g '@workspace-return-session' "$current_session"

if ! tmux has-session -t "$session_name" 2>/dev/null; then
  tmux new-session -d -s "$session_name" -c "$worktree_root" \
    "opencode; tmux switch-client -t \"\$(tmux show-option -gqv '@workspace-return-session')\""
fi

tmux switch-client -t "$session_name"
