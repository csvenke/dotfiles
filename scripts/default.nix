{pkgs ? import <nixpkgs> {}}: let
  home = builtins.getEnv "HOME";

  root = builtins.toString ../.;

  paths = [
    "default.nix"
    ".zshrc"
    ".gitconfig"
    ".config/nix"
    ".config/lazygit"
    ".config/nvim"
    ".config/tmux"
  ];

  envrcPath = "${home}/.envrc";

  checkScript = pkgs.writeShellApplication {
    name = "dotfiles-check";
    runtimeInputs = [
      pkgs.coreutils
    ];
    text = ''
      for path in ${toString paths}; do
        to="${home}/$path"

        if [ ! -L "$to" ]; then
          echo "ERROR $to"
          exit 1
        fi

        echo "OK $to"
      done


      if head -n 5 "${envrcPath}" | grep -q "use nix"; then
        echo "OK ${envrcPath}"
      else
        echo "ERROR ${envrcPath}"
        exit 1
      fi
    '';
  };

  cleanScript = pkgs.writeShellApplication {
    name = "dotfiles-clean";
    runtimeInputs = [
      pkgs.coreutils
    ];
    text = ''
      # unlink paths
      for path in ${toString paths}; do
        to="${home}/$path"

        if [ -L "$to" ]; then
          echo "Unlinking: $to"
          unlink $to
        fi
      done

      # clean envrc
      if [ -e ${envrcPath} ]; then
        rm ${envrcPath}
      fi
    '';
  };

  initScript = pkgs.writeShellApplication {
    name = "dotfiles-init";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.direnv
    ];
    text = ''
      # create .config directory
      if [ ! -e "$HOME/.config" ]; then
        mkdir "$HOME/.config"
      fi

      # symlink paths
      for path in ${toString paths}; do
        from="${root}/$path"
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

      # init .envrc
      if [ ! -e ${envrcPath} ]; then
        echo "Creating .envrc"
        echo "use nix" > ${envrcPath}
      fi
      direnv allow ${envrcPath}
    '';
  };
in
  pkgs.mkShell {
    buildInputs = [
      cleanScript
      initScript
      checkScript
    ];
  }
