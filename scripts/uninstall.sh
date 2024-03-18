#! /usr/bin/env nix-shell
#! nix-shell -i bash -p bash jq

dotfiles="$HOME/.dotfiles"
configFile="$dotfiles/config.json"
paths=$(jq -r '.paths[]' $configFile)

echo "(1/3) Unlink paths"
for path in $paths; do
	to="$HOME/$path"

	if [ -L "$to" ]; then
		echo "Unlinking: $to"
		unlink $to
	fi
done

echo "(2/3) Removing oh-my-bash"
if [ -e "$HOME/.oh-my-bash" ]; then
	rm -rf $HOME/.oh-my-bash
fi

echo "(3/3) Uninstall everything"
nix-env --uninstall '.*'
