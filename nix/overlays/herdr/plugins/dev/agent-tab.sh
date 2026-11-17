herdr="${HERDR_BIN_PATH:-herdr}"
state="${HERDR_PLUGIN_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/herdr-dev}/agent-tabs"
mkdir -p "$state"

event="${HERDR_PLUGIN_EVENT_JSON:-}"
[ -n "$event" ] || exit 0

marker_for() {
  printf '%s/%s' "$state" "${1//:/_}"
}

if [ "${HERDR_PLUGIN_EVENT:-}" = "tab.closed" ]; then
  tab="$(jq -r '(.data // .).tab_id // empty' <<<"$event")"
  [ -n "$tab" ] && rm -f "$(marker_for "$tab")"
  exit 0
fi

pane="$(jq -r '(.data // .).pane_id // empty' <<<"$event")"
agent="$(jq -r '(.data // .) | if .released then "" else (.agent // "") end' <<<"$event")"
[ -n "$pane" ] || exit 0

tab="$("$herdr" pane get "$pane" | jq -r '.result.pane.tab_id // empty')" || exit 0
[ -n "$tab" ] || exit 0

label="$("$herdr" tab get "$tab" | jq -r '.result.tab.label')"
marker="$(marker_for "$tab")"

if [ -n "$agent" ]; then
  original=""
  if [ -f "$marker" ]; then
    original="$(sed -n 1p "$marker")"
  elif [[ $label =~ ^[0-9]+$ ]]; then
    original="$label"
  fi
  [ -n "$original" ] || exit 0

  "$herdr" tab rename "$tab" "$agent" >/dev/null
  printf '%s\n%s\n' "$original" "$agent" >"$marker.$$"
  mv -f "$marker.$$" "$marker"
elif [ -f "$marker" ]; then
  original="$(sed -n 1p "$marker")"
  if [ -n "$original" ] && [ "$label" = "$(sed -n 2p "$marker")" ]; then
    "$herdr" tab rename "$tab" "$original" >/dev/null
  fi
  rm -f "$marker"
fi
