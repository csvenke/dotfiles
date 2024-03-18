#! /usr/bin/env nix-shell
#! nix-shell -i bash -p bash jq

dotfiles="$HOME/.dotfiles"
configFile="$dotfiles/config.json"
paths=$(jq -r '.paths[]' $configFile)
oldPaths=$(jq -r '.oldPaths[]' $configFile)

echo "(1/2) Check if paths are linked"
for path in $paths; do
	to="$HOME/$path"

	if [ ! -L "$to" ]; then
		echo "ERROR $to"
		exit 1
	fi

	echo "OK $to"
done

echo "(2/2) Check if old paths exist"
for path in $oldPaths; do
	to="$HOME/$path"

	if [ -e "$to" ]; then
		echo "ERROR $to"
		exit 1
	fi
done
