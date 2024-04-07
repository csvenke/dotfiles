{ pkgs ? import <nixpkgs-unstable> { } }:

let
  configuration = import ./configuration.nix { inherit pkgs; };

  scripts = import ./scripts { inherit pkgs; };

  neovimParsers = pkgs.symlinkJoin {
    name = "neovim-parsers";
    paths = pkgs.vimPlugins.nvim-treesitter.withAllGrammars.dependencies;
  };

  neovimInit = pkgs.writeTextFile {
    name = "init.lua";
    text = /* lua */ ''
      require("config.lazy")
      vim.opt.runtimepath:prepend("${neovimParsers}")
      vim.opt.runtimepath:prepend("~/.local/share/nvim/lazy/nvim-treesitter")
      require'lspconfig'.nil_ls.setup{}
      require'lspconfig'.bashls.setup{}
    '';
  };

  neovim = pkgs.buildEnv {
    name = "neovim";
    paths = [
      pkgs.tree-sitter
      pkgs.nil
      pkgs.nixpkgs-fmt
      pkgs.nodePackages.bash-language-server
      (pkgs.neovim.override {
        configure = {
          customRC = /* vim */ ''
            luafile ${neovimInit}
          '';
          packages.myPlugins.start = [
            pkgs.vimPlugins.nvim-treesitter.withAllGrammars
          ];
        };
      })
    ];
  };
in

pkgs.buildEnv {
  name = "Home environment";
  paths = [
    configuration
    scripts

    # Deps
    pkgs.coreutils
    pkgs.direnv
    pkgs.nix-direnv
    pkgs.findutils
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
    pkgs.lazygit
    pkgs.delta

    # Shell
    pkgs.starship
    pkgs.tmux

    # c
    pkgs.gcc

    # Rust
    pkgs.cargo

    # Dotnet
    pkgs.dotnet-sdk

    # Java
    pkgs.jdk

    # Python
    (pkgs.python3.withPackages (ps: [ ps.pip ps.pipx ]))

    # Node
    pkgs.nodejs

    # Editor
    neovim

    # Tools
    pkgs.git
    pkgs.eza
    pkgs.fzf
    pkgs.bat
    pkgs.silver-searcher
    pkgs.gh
    pkgs.tldr
  ];
}
