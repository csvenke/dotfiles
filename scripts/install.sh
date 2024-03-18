#! /usr/bin/env nix-shell
#! nix-shell -i bash -p bash jq curl

dotfiles="$HOME/.dotfiles"
configFile="$dotfiles/config.json"
paths=$(jq -r '.paths[]' $configFile)
oldPaths=$(jq -r '.oldPaths[]' $configFile)

echo "(1/9) Downloading oh-my-bash"
if [ ! -e "$HOME/.oh-my-bash" ]; then
	bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --unattended
fi

echo "(2/9) Create .config directory if missing"
if [ ! -e "$HOME/.config" ]; then
	echo "Creating .config directory"
	mkdir "$HOME/.config"
fi

echo "(3/9) Install default environment"
nix-env -if $dotfiles/env.nix

echo "(4/9) Remove old paths if exists"
for path in $oldPaths; do
	to="$HOME/$path"

	if [ -e "$to" ]; then
		echo "Deleting $to"
		rm -rf $to
	fi
done

echo "(5/9) Symlink paths if missing"
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

echo "(6/9) Install tmux plugins"
tpm-install-plugins

echo "(7/9) Sync neovim plugins"
nvim --headless "+Lazy! restore" +qa

echo "(8/9) Sync mason packages"
nvim --headless "+TSUpdate all" +qa

echo "(9/9) Source .bashrc"
source $HOME/.bashrc
