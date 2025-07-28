readonly BLUE='\033[34m'
readonly GRAY='\033[90m'
readonly RESET='\033[0m'
readonly FOLDER_ICON=' '

make_pretty_paths() {
  awk -v blue="$BLUE" -v gray="$GRAY" -v reset="$RESET" -v icon="$FOLDER_ICON" '{
    cmd = "basename " $1; cmd | getline base; close(cmd);
    printf "%s%s%s%s %s%s%s\t%s\n", blue, icon, base, reset, gray, $1, reset, $1
  }'
}

find_search_paths() {
  fd --type d --max-depth 1 --absolute-path . "$HOME" | sed 's@/$@@'
}

find_project_paths() {
  local -r root_files="$1"
  shift
  local -ra search_dirs=("$@")

  fd --max-depth 2 --hidden --follow --regex "$root_files" "${search_dirs[@]}" \
    --exec dirname | sort -u
}

main() {
  local -r search_pattern="(^.git$)"
  local search_paths=("$@")

  if ((${#search_paths[@]} == 0)); then
    mapfile -t search_paths < <(find_search_paths)
  fi

  local project_paths
  project_paths=$(find_project_paths "$search_pattern" "${search_paths[@]}")

  echo "$project_paths" | make_pretty_paths |
    fzf \
      --ansi \
      --multi \
      --tmux \
      --style full \
      --border none \
      --delimiter $'\t' \
      --with-nth 1 \
      --bind "enter:execute-silent(
        for line in {+}; do
          path=\$(cut -f2 <<< \"\$line\")
          tmux new-window -c \"\$path\" nvim
        done
      )+abort"
}

main "$@"
