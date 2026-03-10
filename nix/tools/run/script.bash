main() {
  scripts=()
  runners=("npm_runner" "dotnet_runner")

  for runner in "${runners[@]}"; do
    if runner_scripts=$($runner); then
      while IFS= read -r line; do
        scripts+=("$line")
      done <<<"$runner_scripts"
    fi
  done

  if [ ${#scripts[@]} -eq 0 ]; then
    echo "No runnable scripts found. Exiting."
    exit 1
  fi

  selectedScript=$(printf "%s\n" "${scripts[@]}" | fzf)

  if [ -z "$selectedScript" ]; then
    echo "No command selected. Exiting."
    exit 1
  fi

  eval "$selectedScript"
}

npm_runner() {
  if ! command -v npm &>/dev/null; then
    return 1
  fi

  if [ ! -f package.json ]; then
    return 1
  fi

  scriptNames=$(jq -r '.scripts? | keys[]?' package.json 2>/dev/null)

  if [ -z "$scriptNames" ]; then
    return 1
  fi

  while IFS= read -r scriptName; do
    echo "npm run $scriptName"
  done <<<"$scriptNames"
}

dotnet_runner() {
  if ! command -v dotnet &>/dev/null; then
    return 1
  fi

  project_dirs=$(find . -type f -name "*.csproj" -exec dirname {} \; | sort -u | sed 's#^\./##')

  if [ -z "$project_dirs" ]; then
    return 1
  fi

  while IFS= read -r project_dir; do
    echo "dotnet run --project $project_dir"
  done <<<"$project_dirs"

  while IFS= read -r project_dir; do
    echo "dotnet watch --project $project_dir"
  done <<<"$project_dirs"
}

main
