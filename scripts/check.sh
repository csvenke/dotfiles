#!/bin/sh

umask 0022

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
