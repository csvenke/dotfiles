#! /usr/bin/env nix-shell
#! nix-shell -i bash -p bash jq

dotfiles="$HOME/.dotfiles"
configFile="$dotfiles/config.json"
paths=$(jq -r '.paths[]' $configFile)
oldPaths=$(jq -r '.oldPaths[]' $configFile)

echo "(1/7) Create .config directory if missing"
if [ ! -e "$HOME/.config" ]; then
	echo "Creating .config directory"
	mkdir "$HOME/.config"
fi

echo "(2/7) Install default environment"
nix-env -if $dotfiles/env.nix

echo "(3/7) Remove old paths if exists"
for path in $oldPaths; do
	to="$HOME/$path"

	if [ -e "$to" ]; then
		echo "Deleting $to"
		rm -rf $to
	fi
done

echo "(4/7) Symlink paths if missing"
for path in $paths; do
	from="$dotfiles/$path"
	to="$HOME/$path"

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

echo "(5/7) Install tmux plugins"
tpm-install-plugins

echo "(6/7) Sync neovim plugins"
nvim --headless "+Lazy! restore" +qa

echo "(7/7) Sync mason packages"
nvim --headless "+TSUpdate all" +qa
