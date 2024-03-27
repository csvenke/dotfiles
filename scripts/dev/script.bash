function select_project_dir() {
	local projects_dir=$1
	ag -g "(.sln|.csproj|package.json)" "$projects_dir" |
		xargs -I {} dirname {} |
		sort -u |
		sed "s|^$projects_dir/||" |
		fzf --color "hl:-1:underline,hl+:-1:underline:reverse"
}

function main() {
	local PROJECTS_DIRECTORY="$HOME/projects"
	TARGET_DIR=$(select_project_dir "$PROJECTS_DIRECTORY")
	FULL_PATH="$PROJECTS_DIRECTORY/$TARGET_DIR"

	if [ -n "$FULL_PATH" ]; then
		cd "$FULL_PATH" && nvim .
	fi
}

main
