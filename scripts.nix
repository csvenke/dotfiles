{ pkgs ? import <nixpkgs> {}}:

let
  home = builtins.getEnv "HOME";

  cwd = builtins.toString ./.;

  paths = [
    "default.nix"
    ".zshrc"
    ".gitconfig"
    ".config/nix"
    ".config/lazygit"
    ".config/nvim"
    ".config/tmux"
  ];

  linkScript = pkgs.writeShellApplication {
    name = "dotfiles-link";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      for path in ${toString paths}; do
        from="${cwd}/$path"
        to="${home}/$path"

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
    '';
  };

  cleanScript = pkgs.writeShellApplication {
    name = "dotfiles-clean";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      for path in ${toString paths}; do
        to="${home}/$path"

        if [ -L "$to" ]; then
          echo "Removing: $to"
          unlink $to
        fi
      done
    '';
  };
in

[linkScript cleanScript]

