function select_project_dir() {
	ag -g "(.sln|.csproj|package.json)" "$1" |
		xargs -I {} dirname {} |
		sort -u |
		sed "s|^$1/||" |
		fzf --border=none --color "hl:-1:underline,hl+:-1:underline:reverse"
}

function main() {
	projects_directory="$HOME/projects"
	target_dir=$(select_project_dir "$projects_directory")
	full_path="$projects_directory/$target_dir"

	if [ -n "$full_path" ]; then
		cd "$full_path" && nvim .
	fi
}

main
