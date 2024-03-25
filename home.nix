{pkgs ? import <nixpkgs-unstable> {}}: let
  configuration = import ./configuration.nix {inherit pkgs;};
in
  pkgs.buildEnv {
    name = "My default environment";
    paths = [
      configuration

      pkgs.direnv
      pkgs.nix-direnv

      # Python
      (pkgs.python3.withPackages (ps: [ps.pip]))

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
      pkgs.lazygit
      pkgs.delta
      pkgs.neovim

      # tmux
      pkgs.tmux

      # Tools
      pkgs.fzf
      pkgs.bat
      pkgs.silver-searcher
      pkgs.gh
    ];
  }
