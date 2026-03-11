#!/usr/bin/env bash

set -euo pipefail

sanitize_name() {
  printf "%s" "$1" | tr -cd '[:alnum:]-_'
}

build_session_name() {
  local pane_path="$1"
  local root
  local repo
  local branch
  local hash

  root="$(git -C "$pane_path" rev-parse --show-toplevel 2>/dev/null || printf "%s" "$pane_path")"

  if [[ -f "$root/.git" ]]; then
    repo="$(sanitize_name "$(basename "$(dirname "$root")")")"
  else
    repo="$(sanitize_name "$(basename "$root")")"
  fi

  branch="$(git -C "$root" branch --show-current 2>/dev/null || true)"
  if [[ -z $branch ]]; then
    branch="$(git -C "$root" rev-parse --short HEAD 2>/dev/null || printf "%s" "nogit")"
  fi

  hash="$(printf "%s" "${root}:${branch}" | md5sum | cut -c1-6)"
  printf "popup-%s-%s" "$repo" "$hash"
}

main() {
  local pane_path="${1:-$PWD}"
  local session_name

  session_name="$(build_session_name "$pane_path")"

  tmux popup -w90% -h90% -d "$pane_path" -E "tmux attach -t \"$session_name\" 2>/dev/null || tmux new -s \"$session_name\""
}

main "$@"
