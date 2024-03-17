#! /usr/bin/env nix-shell
#! nix-shell -i bash -p bash jq

home="$HOME"
root="$HOME/.dotfiles"
configFile="$root/config.json"
paths=$(jq -r '.paths[]' $configFile)
oldPaths=$(jq -r '.oldPaths[]' $configFile)

# Install nix default environment
nix-env -if $root/env.nix

# unlink old paths
for path in $oldPaths; do
	to="$home/$path"

	if [ -L "$to" ]; then
		echo "Unlinking: $to"
		unlink $to
	fi
done

# create .config directory
if [ ! -e "$HOME/.config" ]; then
	mkdir "$HOME/.config"
fi

# symlink paths
for path in $paths; do
	from="$root/$path"
	to="$home/$path"

	if [ -L "$to" ]; then
		echo "Symlink already exists: $to"
		continue
	fi

	if [ -e "$to" ]; then
		echo "Removing existing file or directory: $to"
		rm -rf "$to"
	fi

	echo "Creating symlink: $from -> $to"
	ln -s "$from" "$to"
done

# Install tmux plugins with tpm
tpm-install-plugins
