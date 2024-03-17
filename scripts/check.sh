#! /usr/bin/env nix-shell
#! nix-shell -i bash -p bash jq

home="$HOME"
root="$HOME/.dotfiles"
configFile="$root/config.json"
paths=$(jq -r '.paths[]' $configFile)

for path in $paths; do
	to="$home/$path"

	if [ ! -L "$to" ]; then
		echo "ERROR $to"
		exit 1
	fi

	echo "OK $to"
done
