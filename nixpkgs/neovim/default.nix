{ pkgs }:

let
  deps = [
    # Lazyvim deps
    pkgs.tree-sitter
    pkgs.gcc
    pkgs.libstdcxx5
    pkgs.ripgrep
    pkgs.fd
    pkgs.gnutar
    pkgs.git
    pkgs.lazygit
    pkgs.wget
    pkgs.curl
    pkgs.unzip
    pkgs.gzip
    pkgs.gnumake
    pkgs.gnutar
    pkgs.gnused
    pkgs.gnugrep
    ## Mason rust
    pkgs.cargo
    pkgs.rustc
    ## Mason node
    pkgs.nodejs
    ## Mason dotnet
    pkgs.dotnet-sdk
    ## Mason java
    pkgs.jdk
  ];

  lang = [
    # Nix
    pkgs.nil
    pkgs.nixpkgs-fmt
    # Bash
    pkgs.nodePackages.bash-language-server
    # Haskell
    pkgs.haskell-language-server
    pkgs.haskellPackages.hoogle
    pkgs.haskellPackages.fast-tags
    pkgs.haskellPackages.haskell-debug-adapter
    pkgs.haskellPackages.ghci-dap
  ];

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

  myNeovim = pkgs.neovim.override {
    configure = {
      customRC = /* vim */ ''
        luafile ${neovimInit}
      '';
      packages.myPlugins.start = [
        pkgs.vimPlugins.nvim-treesitter.withAllGrammars
      ];
    };
  };
in

pkgs.writeShellApplication {
  name = "nvim";
  runtimeInputs = deps ++ lang ++ [ ];
  text = ''
    ${myNeovim}/bin/nvim "$@"
  '';
}
