function findProjectRootDirectories() {
	local search_path="$1"
	local root_files="(.git|shell.nix|flake.nix|.envrc|.env)"
	ag --hidden -g "$root_files" "$search_path" | xargs -I {} dirname {} | sort -u
}

function formatDirectoriesForDisplay() {
	local search_path="$1"
	local directories="$2"
	echo "$directories" |
		sed "s|^$search_path/||" |
		awk -v prefix="$search_path" 'BEGIN {
        gray="\033[90m";
        reset="\033[0m";
    }
    {print $0 " " gray "(" prefix "/" $0 ")" reset}'
}

function selectDirectoryWithUI() {
	local formatted_directories="$1"
	echo "$formatted_directories" | fzf --ansi --border=none | sed 's/.*(\(.*\)).*/\1/'
}

function navigateAndOpenNvim() {
	local target_path="$1"
	if [ -n "$target_path" ]; then
		cd "$target_path" || exit
		nvim .
	fi
}

function runProjectDirectoryNavigator() {
	local dir_to_search="$1"
	root_dirs=$(findProjectRootDirectories "$dir_to_search")
	formatted_dirs=$(formatDirectoriesForDisplay "$dir_to_search" "$root_dirs")
	selected_path=$(selectDirectoryWithUI "$formatted_dirs")
	navigateAndOpenNvim "$selected_path"
}

runProjectDirectoryNavigator "$HOME/projects"
