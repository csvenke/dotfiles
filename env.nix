let
  pkgs = import <nixpkgs> {};

  tpmRepo = pkgs.stdenv.mkDerivation {
    name = "tmux plugin manager";
    src = builtins.fetchGit {
      url = "https://github.com/tmux-plugins/tpm";
      ref = "master";
      rev = "99469c4a9b1ccf77fade25842dc7bafbc8ce9946";
    };
    installPhase = ''
      mkdir -p $out
      cp -r ./* $out/
    '';
  };
  tpmWrapper = pkgs.writeShellScriptBin "tmux-plugin-manager" ''
    echo ${tpmRepo}
  '';
  tpmInstallWrapper = pkgs.writeShellScriptBin "tmux-plugin-manager-install" ''
    bash ${tpmRepo}/scripts/install_plugins.sh
  '';

  ohMyBashRepo = pkgs.stdenv.mkDerivation {
    name = "oh my bash";
    src = builtins.fetchGit {
      url = "https://github.com/ohmybash/oh-my-bash";
      ref = "master";
      rev = "4c2afd012ae56a735f18a5f313a49da29b616998";
    };
    installPhase = ''
      mkdir -p $out
      cp -r ./* $out/
    '';
  };
  ohMyBashWrapper = pkgs.writeShellScriptBin "oh-my-bash" ''
    echo ${ohMyBashRepo}
  '';

  python3 = pkgs.python3.withPackages (ps: [
    ps.pip
    ps.pipx
  ]);
in
  pkgs.buildEnv {
    name = "My default environment";
    paths = [
      pkgs.direnv
      pkgs.nix-direnv

      # Python3
      python3

      # Node
      pkgs.nodejs
      pkgs.bun
      pkgs.yarn
      pkgs.nodePackages.pnpm

      # Rust
      pkgs.cargo
      pkgs.rustc

      # Neovim
      pkgs.coreutils
      pkgs.tree-sitter
      pkgs.alejandra
      pkgs.gcc
      pkgs.gnumake
      pkgs.gnutar
      pkgs.gnused
      pkgs.gnugrep
      pkgs.unzip
      pkgs.gzip
      pkgs.fd
      pkgs.ripgrep
      pkgs.curl
      pkgs.wget
      pkgs.git
      pkgs.gh
      pkgs.lazygit
      pkgs.delta
      pkgs.neovim

      # tmux
      pkgs.tmux
      tpmWrapper
      tpmInstallWrapper

      # oh my bash
      ohMyBashWrapper

      # Tools
      pkgs.fzf
      pkgs.bat
      pkgs.silver-searcher
    ];
  }
