{ pkgs ? import <nixpkgs> {} }:

let 
  home = builtins.getEnv "HOME";
  cwd = builtins.toString ./.;

  links = [
    { from = "${cwd}/default.nix"; to = "${home}/default.nix"; }
    { from = "${cwd}/.zshrc"; to = "${home}/.zshrc"; }
    { from = "${cwd}/.gitconfig"; to = "${home}/.gitconfig"; }
    { from = "${cwd}/.config/lazygit"; to = "${home}/.config/lazygit"; }
    { from = "${cwd}/.config/nvim"; to = "${home}/.config/nvim"; }
    { from = "${cwd}/.config/tmux"; to = "${home}/.config/tmux"; }
  ];

  createLink = link:
    ''
      if [ ! -L "${link.to}" ]; then
        if [ -e "${link.to}" ]; then
          echo "Removing existing file or directory: ${link.to}"
          rm -rf "${link.to}"
        fi
        echo "Creating symlink: ${link.from} -> ${link.to}"
        ln -s "${link.from}" "${link.to}"
      else
        echo "Symlink already exists: ${link.to}"
      fi
    '';

  script = pkgs.lib.concatMapStrings createLink links;

in 

pkgs.writeShellScriptBin "dotfiles-link" script

