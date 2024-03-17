#! /usr/bin/env nix-shell
#! nix-shell -i bash -p bash jq

home="$HOME"
root="$HOME/.dotfiles"
configFile="$root/config.json"
paths=$(jq -r '.paths[]' $configFile)

# unlink paths
for path in $paths; do
	to="$home/$path"

	if [ -L "$to" ]; then
		echo "Unlinking: $to"
		unlink $to
	fi
done

# Uninstall everything
nix-env --uninstall '.*'
