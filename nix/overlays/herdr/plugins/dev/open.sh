herdr="${HERDR_BIN_PATH:-herdr}"

fail() {
  echo "herdr-dev: $*" >&2
  if [ -t 0 ]; then
    read -r -p "Press enter to close" _
  fi
  exit 1
}

project="${1:-}"
if [ "$project" = "--home" ]; then
  project="${HERDR_HOME_PROJECT:-$HOME/.config/dotfiles}"
fi

if [ -z "$project" ]; then
  if ! command -v dev >/dev/null; then
    fail "dev not found in PATH"
  fi

  status=0
  project="$(dev -p)" || status=$?

  if [ -z "$project" ]; then
    if [ "$status" -ge 126 ]; then
      fail "dev -p failed (exit $status)"
    fi
    exit 0
  fi
fi

[ -d "$project" ] || fail "$project is not a directory"
project="$(cd "$project" && pwd -P)"
name="$(basename "$project")"

if [ -z "${HERDR_DEV_FORCE_NEW:-}" ]; then
  existing="$("$herdr" pane list | jq -r --arg cwd "$project" \
    'first(.result.panes[] | select(.cwd == $cwd or (.cwd | startswith($cwd + "/"))) | .workspace_id) // empty')" ||
    fail "could not list panes"

  if [ -n "$existing" ]; then
    "$herdr" workspace focus "$existing" >/dev/null || fail "could not focus workspace"
    exit 0
  fi
fi

created="$("$herdr" workspace create --cwd "$project" --label "$name" --no-focus)" ||
  fail "could not create workspace for $project"

workspace="$(jq -r '.result.workspace.workspace_id' <<<"$created")"
tab="$(jq -r '.result.tab.tab_id' <<<"$created")"
pane="$(jq -r '.result.root_pane.pane_id' <<<"$created")"

"$herdr" tab rename "$tab" neovim >/dev/null
"$herdr" pane run "$pane" nvim >/dev/null
"$herdr" workspace focus "$workspace" >/dev/null
