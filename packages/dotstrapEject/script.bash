#!/bin/bash

HOME_DIR="$HOME"
SYMLINKS=(
  ".bashrc"
  ".bash_profile"
  ".agignore"
  ".gitconfig"
  ".gitconfig.personal"
  ".gitignore.global"
  ".claude"
  ".config/starship.toml"
  ".config/nixpkgs"
  ".config/wezterm"
  ".config/ghostty"
  ".config/direnv"
  ".config/lazygit"
  ".config/nix"
  ".config/opencode"
  ".machine/.bashrc"
  ".vault/openai-api-key.txt"
  ".vault/anthropic-api-key.txt"
  ".gitconfig.work"
  ".bashrc.machine.sh"
  ".bashrc.work.sh"
  ".work/.bashrc"
  ".work/.gitconfig"
)

for symlink in "${SYMLINKS[@]}"; do
  full_path="$HOME_DIR/$symlink"

  if [ -L "$full_path" ]; then
    echo "UNLINK: $full_path"
    rm "$full_path"
  fi
done
