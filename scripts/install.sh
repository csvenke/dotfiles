#! /usr/bin/env nix-shell
#! nix-shell -i bash -p bash jq

home="$HOME"
root="$HOME/.dotfiles"
configFile="$root/config.json"
paths=$(jq -r '.paths[]' $configFile)
oldPaths=$(jq -r '.oldPaths[]' $configFile)

# Install default environment
nix-env -if $root/env.nix

# Setup node with fnm
eval "$(fnm env --use-on-cd)"
fnm use --install-if-missing --silent-if-unchanged 20

# Unlink old paths if exists
for path in $oldPaths; do
	to="$home/$path"

	if [ -L "$to" ]; then
		echo "Unlinking: $to"
		unlink $to
	fi
done

# Create .config directory if missing
if [ ! -e "$HOME/.config" ]; then
	mkdir "$HOME/.config"
fi

# Symlink paths if missing
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

# Install neovim plugins from lockfile
nvim --headless "+Lazy! restore" +qa
