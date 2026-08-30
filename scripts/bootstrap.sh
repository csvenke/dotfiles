#!/usr/bin/env bash

set -euo pipefail

DOTFILES_URL="https://github.com/csvenke/dotfiles.git"
DOTFILES_BRANCH="master"
DOTFILES_PATH="$HOME/.config/dotfiles"

if [ ! -e "$DOTFILES_PATH" ]; then
  git clone --branch "$DOTFILES_BRANCH" --single-branch "$DOTFILES_URL" "$DOTFILES_PATH"
elif git -C "$DOTFILES_PATH" rev-parse --is-inside-work-tree &>/dev/null; then
  git -C "$DOTFILES_PATH" pull --ff-only origin "$DOTFILES_BRANCH"
else
  echo "dotfiles: $DOTFILES_PATH exists but is not a Git checkout" >&2
  exit 1
fi

stow -v --dir="$DOTFILES_PATH/home" --target="$HOME" --restow .

profile_json="$(nix profile list --json)"
if jq -e '.elements | has("dotfiles")' <<<"$profile_json" &>/dev/null; then
  nix profile upgrade dotfiles
else
  nix profile add "$DOTFILES_PATH"
fi

nix profile wipe-history --older-than 3d
