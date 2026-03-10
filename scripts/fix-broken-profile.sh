#!/usr/bin/env bash

set -euo pipefail

DOTFILES_PATH="$HOME/.config/dotfiles"

nix-collect-garbage -d
rm ~/.local/state/nix/profiles/profile*
rm ~/.nix-profile
nix profile add "$DOTFILES_PATH"
nix profile list
