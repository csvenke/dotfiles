#!/usr/bin/env bash

set -euo pipefail

DOTFILES_PATH="$HOME/.config/dotfiles"

if [ ! -d "$DOTFILES_PATH" ]; then
  echo "dotfiles: nothing to eject"
  exit 0
fi

echo "dotfiles: removing packages"
nix profile remove dotfiles

echo "dotfiles: removing symlinks"
stow -v --dir="$DOTFILES_PATH/home" --target="$HOME" --delete .

echo "dotfiles: deleting local checkout"
rm -rf "$DOTFILES_PATH"
