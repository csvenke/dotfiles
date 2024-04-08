function findRoots() {
	local search_dir=$1
	local root_files="(.git|shell.nix|flake.nix|.envrc|.env|.sln|.csproj|pom.xml|settings.gradle|settings.gradke.kts|package.json)"
	ag --hidden -g "$root_files" "$search_dir" |
		xargs -I {} dirname {} |
		sort -u |
		sed "s|^$search_dir/||" |
		awk -v prefix="$search_dir" 'BEGIN { gray="\033[90m"; blue="\033[34m"; reset="\033[0m"; folderIcon=" "; } { print blue folderIcon $0 reset " " gray "(" prefix "/" $0 ")" reset }'
}

function gatherRoots() {
	local directory_paths=""

	for dir in "$@"; do
		if [ -e "$dir" ]; then
			matches=$(findRoots "$dir")
			directory_paths=$(printf "%s\n%s" "$directory_paths" "$matches")
		fi
	done

	echo "$directory_paths"
}

function selectDir() {
	local formatted_directories="$1"
	echo "$formatted_directories" |
		fzf --ansi --border=none |
		sed 's/.*(\(.*\)).*/\1/'
}

function openWithNeovim() {
	local target_path="$1"
	if [ -n "$target_path" ]; then
		cd "$target_path" || exit
		nvim .
	fi
}

function dev() {
	if [ $# -eq 0 ]; then
		return 1
	fi

	project_dirs=$(gatherRoots "$@")
	selected_project_dir=$(selectDir "$project_dirs")
	openWithNeovim "$selected_project_dir"
}

dev "$HOME/projects" "$HOME/repos"
