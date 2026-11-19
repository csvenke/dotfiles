herdr="${HERDR_BIN_PATH:-herdr}"

workspaces=""
for _ in $(seq 50); do
  workspaces="$("$herdr" workspace list 2>/dev/null | jq -c '.result.workspaces // []')" || workspaces=""
  if [ -n "$workspaces" ] && [ "$workspaces" != "[]" ]; then
    break
  fi
  sleep 0.2
done
[ -n "$workspaces" ] || exit 0

# A fresh server starts with one untouched shell workspace; replace it.
fresh="$(jq -r 'if length == 1 and .[0].tab_count == 1 and .[0].pane_count == 1
  then .[0].workspace_id else empty end' <<<"$workspaces")"
if [ -n "$fresh" ]; then
  label="$("$herdr" tab list | jq -r --arg ws "$fresh" \
    'first(.result.tabs[] | select(.workspace_id == $ws) | .label) // empty')"
  [[ "$label" =~ ^[0-9]+$ ]] || fresh=""
fi

if [ -n "$fresh" ]; then
  HERDR_DEV_FORCE_NEW=1 herdr-dev-open --home
  "$herdr" workspace close "$fresh" >/dev/null
else
  herdr-dev-open --home
fi
