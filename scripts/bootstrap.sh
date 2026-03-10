#!/usr/bin/env -S nix shell nixpkgs#bash nixpkgs#git nixpkgs#stow -c bash

set -euo pipefail

DOTFILES_URL="https://github.com/csvenke/dotfiles.git"
DOTFILES_BRANCH="master"
DOTFILES_PATH="$HOME/.config/dotfiles"

if [ ! -d "$DOTFILES_PATH" ]; then
  git clone "$DOTFILES_URL" "$DOTFILES_PATH"
else
  git -C "$DOTFILES_PATH" pull origin "$DOTFILES_BRANCH"
fi

stow -v --dir="$DOTFILES_PATH/home" --target="$HOME" --adopt --restow .
nix profile add "$DOTFILES_PATH"
nix profile upgrade dotfiles
nix profile wipe-history --older-than 7d
