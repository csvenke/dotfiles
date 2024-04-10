function getEnvOrDefault() {
	local value="$1"
	local defaultValue="$2"
	echo "${!value:-$defaultValue}"
}

SEARCH_DIRS=$(getEnvOrDefault "DEV_SEARCH_DIRS" "$HOME/repos")
ROOT_FILE_PATTERN=$(getEnvOrDefault "DEV_ROOT_FILE_PATTERN" "(.git|.envrc|.env|shell.nix|flake.nix|package.json|.sln|.csproj)")

findRoots() {
	local search_dir=$1
	local root_files="$ROOT_FILE_PATTERN"
	ag --hidden -g "$root_files" "$search_dir" |
		xargs -I {} dirname {} |
		sort -u |
		sed "s|^$search_dir/||" |
		awk -v prefix="$search_dir" 'BEGIN { gray="\033[90m"; blue="\033[34m"; reset="\033[0m"; folderIcon=" "; } { print blue folderIcon $0 reset " " gray "(" prefix "/" $0 ")" reset }'
}

gatherRoots() {
	local directory_paths=""

	for dir in "$@"; do
		if [ -e "$dir" ]; then
			matches=$(findRoots "$dir")
			directory_paths=$(printf "%s\n%s" "$directory_paths" "$matches")
		fi
	done

	echo "$directory_paths"
}

selectDir() {
	local formatted_directories="$1"
	echo "$formatted_directories" |
		fzf --ansi --border=none |
		sed 's/.*(\(.*\)).*/\1/'
}

openWithEditor() {
	local target_path="$1"
	if [ -n "$target_path" ]; then
		cd "$target_path" || exit
		$VISUAL .
	fi
}

dev() {
	if [ $# -eq 0 ]; then
		return 1
	fi

	project_dirs=$(gatherRoots "$@")
	selected_project_dir=$(selectDir "$project_dirs")
	openWithEditor "$selected_project_dir"
}

read -ra search_dir_args <<<"$SEARCH_DIRS"
dev "${search_dir_args[@]}"
