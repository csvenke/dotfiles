#!/usr/bin/env -S nix shell nixpkgs#bash nixpkgs#git nixpkgs#stow -c bash

set -euo pipefail

eject_v1() {
  local path="$HOME/.dotfiles"

  if [ ! -d "$path" ]; then
    echo "Eject v1: Nothing to do. Exiting..."
    return
  fi

  echo "Eject v1: Removing symlinks"
  stow -v --dir="$path/home" --target="$HOME" --delete .

  echo "Eject v1: Removing dotfiles packages"
  nix profile remove --all

  echo "Eject v1: Deleting local repo"
  rm -rf "$path"
}

eject_v2() {
  local path="$HOME/.config/dotfiles"

  if [ ! -d "$path" ]; then
    echo "Eject v2: Nothing to do. Exiting..."
    return
  fi

  echo "Eject v2: Removing symlinks"
  stow -v --dir="$path/home" --target="$HOME" --delete .

  echo "Eject v2: Removing dotfiles packages"
  nix profile remove dotfiles

  echo "Eject v2: Deleting local repo"
  rm -rf "$path"
}

eject_v1
eject_v2
