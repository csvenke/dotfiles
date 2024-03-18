#! /usr/bin/env nix-shell
#! nix-shell -i bash -p bash jq

dotfiles="$HOME/.dotfiles"
configFile="$dotfiles/config.json"
paths=$(jq -r '.paths[]' $configFile)

echo "(1/2) Unlink paths"
for path in $paths; do
	to="$HOME/$path"

	if [ -L "$to" ]; then
		echo "Unlinking: $to"
		unlink $to
	fi
done

echo "(2/2) Uninstall everything"
nix-env --uninstall '.*'
