#!/usr/bin/env bash
# End-to-end smoke test: drives the real wrapped pi binary in tmux and
# verifies the chess overlay opens during an agent run, closes when the run
# settles, and that /chess opens/closes it manually.
#
# Requires: tmux, network (lichess.org — otherwise bundled puzzles kick in,
# which is also fine for this test), and working pi model auth.
# Not part of `npm test`; run via `npm run test:e2e`.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
SESSION="pi-chess-e2e-$$"
WORK="$(mktemp -d /tmp/pi-chess-e2e.XXXXXX)"
MODEL="${PI_CHESS_E2E_MODEL:-github-copilot/gpt-5-mini}"

log() { printf '[e2e] %s\n' "$*"; }

cleanup() {
  tmux kill-session -t "$SESSION" 2>/dev/null || true
  rm -rf "$WORK"
}
trap cleanup EXIT

capture() {
  tmux capture-pane -p -t "$SESSION"
}

# wait_for <pattern> <timeout> [present|absent]
wait_for() {
  local pattern="$1" timeout="$2" mode="${3:-present}"
  local deadline=$((SECONDS + timeout))
  while ((SECONDS < deadline)); do
    local cap
    cap="$(capture)"
    if [[ $mode == present ]] && grep -q -- "$pattern" <<<"$cap"; then
      return 0
    fi
    if [[ $mode == absent ]] && ! grep -q -- "$pattern" <<<"$cap"; then
      return 0
    fi
    sleep 1
  done
  log "TIMEOUT waiting for '$pattern' ($mode). Last capture:"
  capture | tail -40 >&2
  return 1
}

log "building dotfiles (cached after first run)…"
cd "$REPO_ROOT"
nix build .#default

PI="$REPO_ROOT/result/bin/pi"
[[ -x $PI ]] || {
  echo "pi binary missing at $PI" >&2
  exit 1
}

log "starting pi ($MODEL) in tmux session $SESSION"
tmux new-session -d -s "$SESSION" -x 200 -y 50 -c "$WORK" \
  "TERM=xterm-256color '$PI' --model '$MODEL'"

# TUI ready when anything renders; give the event loop a moment too.
wait_for '[a-zA-Z]' 30
sleep 3

log "sending a prompt that takes a few seconds"
tmux send-keys -t "$SESSION" -l -- 'Write exactly three sentences about the history of chess.'
tmux send-keys -t "$SESSION" Enter

log "waiting for the chess overlay to open during the run"
wait_for 'CHESS' 90

log "waiting for the overlay to close when the run settles"
wait_for 'CHESS' 240 absent

log "testing manual /chess open"
tmux send-keys -t "$SESSION" -l -- '/chess'
tmux send-keys -t "$SESSION" Enter
wait_for 'CHESS' 30

log "testing escape close"
tmux send-keys -t "$SESSION" Escape
wait_for 'CHESS' 15 absent

log "PASS"
