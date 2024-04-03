{pkgs ? import <nixpkgs-unstable> {}}: let
  configuration = import ./configuration.nix {inherit pkgs;};
  scripts = import ./scripts {inherit pkgs;};
  treesitterParsers = pkgs.symlinkJoin {
    name = "treesitter-parsers";
    paths = pkgs.vimPlugins.nvim-treesitter.withAllGrammars.dependencies;
  };
in
  pkgs.buildEnv {
    name = "Home environment";
    paths = [
      configuration
      scripts

      pkgs.direnv
      pkgs.nix-direnv

      # Rice
      pkgs.starship

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
      pkgs.findutils
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
      (pkgs.neovim.override {
        configure = {
          customRC = /* vim */ ''
            luafile ~/.config/nvim/init.lua
            lua vim.opt.runtimepath:prepend("${treesitterParsers}")
            lua vim.opt.runtimepath:prepend("~/.local/share/nvim/lazy/nvim-treesitter")
          '';
          packages.myPlugins.start = [
            pkgs.vimPlugins.nvim-treesitter.withAllGrammars
          ];
        };
      })

      # tmux
      pkgs.tmux

      # Tools
      pkgs.eza
      pkgs.fzf
      pkgs.bat
      pkgs.silver-searcher
      pkgs.gh
      pkgs.tldr
    ];
  }
