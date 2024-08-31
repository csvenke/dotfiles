#!/bin/bash

commands_exist() {
  for cmd in "$@"; do
    command -v "$cmd" &>/dev/null || return 1
  done
  return 0
}

if ! commands_exist "nix" "git"; then
  exit 1
fi

if [ ! -d "$HOME/.dotfiles" ]; then
  git clone https://github.com/csvenke/dotfiles.git ~/.dotfiles
fi

nix-shell ~/.dotfiles/scripts/dotstrap/main.py install

nix profile remove '.*'
nix profile install ~/.dotfiles
nix profile wipe-history --older-than 7d
