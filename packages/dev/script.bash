function main() {
  local search_pattern="(^.git$)"
  local search_paths_array=("$@")

  if [ "${#search_paths_array[@]}" -eq 0 ]; then
    mapfile -t search_paths_array < <(find_search_paths)
  fi

  local project_paths
  project_paths=$(find_project_paths "$search_pattern" "${search_paths_array[@]}")

  local selected_path
  selected_path=$(select_path "$project_paths")

  open_path "$selected_path"
}

function find_search_paths() {
  fd --type d --max-depth 1 --absolute-path . "$HOME" | sed 's@/$@@'
}

function find_project_paths() {
  local root_files="$1"
  shift
  local search_dir=("$@")
  fd --max-depth 2 --hidden --follow --regex "$root_files" "${search_dir[@]}" -x dirname | sort -u
}

function select_path() {
  local project_paths="$1"
  local pretty_project_paths
  pretty_project_paths=$(make_pretty_paths "$project_paths")

  echo "$pretty_project_paths" | fzf --ansi --border=none --info=inline | unmake_pretty_path
}

function make_pretty_paths() {
  echo "$1" |
    awk '{ cmd = "basename " $1; cmd | getline base; close(cmd); printf "%s (%s)\n", base, $1 }' |
    awk 'BEGIN { gray="\033[90m"; blue="\033[34m"; reset="\033[0m"; folderIcon=" "; } { print blue folderIcon $1 reset " " gray ""$2"" reset }'
}

function unmake_pretty_path() {
  sed -n 's/.*(\(.*\)).*/\1/p'
}

function open_path() {
  local path="$1"

  if [[ -z "$path" ]]; then
    return
  fi

  cd "$path" || return 1

  if [ -n "$VISUAL" ]; then
    exec "$VISUAL"
  elif [ -n "$EDITOR" ]; then
    exec "$EDITOR"
  fi
}

main "$@"
