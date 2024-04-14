{
  description = "Neovim flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nixneovimplugins.url = "github:jooooscha/nixpkgs-vim-extra-plugins";
  };

  outputs = { self, nixpkgs, flake-utils, nixneovimplugins }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            nixneovimplugins.overlays.default
          ];
        };

        deps = [
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
          pkgs.xdg-utils
        ];

        lang = [
          # Nix
          pkgs.nil
          pkgs.nixpkgs-fmt

          # Bash
          pkgs.nodePackages.bash-language-server
          pkgs.shfmt

          # Haskell
          pkgs.haskell-language-server
          pkgs.haskellPackages.hoogle
          pkgs.haskellPackages.fast-tags

          # Dotnet
          pkgs.dotnet-sdk
          pkgs.omnisharp-roslyn

          # Java
          pkgs.jdk
          pkgs.jdt-language-server

          # Typescript
          pkgs.nodejs
          pkgs.nodePackages.typescript-language-server

          ## Rust
          pkgs.cargo
          pkgs.rustc
          pkgs.rust-analyzer

          # Lua
          pkgs.lua-language-server
          pkgs.stylua

          # Markdown
          pkgs.markdownlint-cli
          pkgs.marksman

          # Eslint
          pkgs.vscode-extensions.dbaeumer.vscode-eslint

          # Prettier
          pkgs.prettierd

          # Python
          (pkgs.python3.withPackages (ps: [ ps.pip ps.pipx ]))
          pkgs.nodePackages.pyright
          pkgs.ruff

          # Yaml
          pkgs.yaml-language-server

          # TOML
          pkgs.taplo

          # Json, eslint, markdown, css, html
          pkgs.vscode-langservers-extracted

        ];

        plugins = with pkgs.vimPlugins; [
          # Telescope
          telescope-nvim
          telescope-fzf-native-nvim
          telescope-ui-select-nvim

          # Treesitter
          nvim-treesitter.withAllGrammars
          nvim-treesitter-textobjects
          nvim-treesitter-refactor
          nvim-treesitter-context

          # LSP
          nvim-lspconfig
          ## lang specific
          omnisharp-extended-lsp-nvim
          nvim-jdtls

          # CMP
          friendly-snippets
          luasnip
          cmp-nvim-lsp
          cmp-buffer
          cmp-path
          cmp-cmdline
          cmp_luasnip
          nvim-cmp

          # Formatting
          conform-nvim

          # Other
          mini-nvim
          noice-nvim
          nui-nvim
          nvim-notify
          nvim-ts-autotag
          neoconf-nvim
          lazygit-nvim
          nvim-web-devicons
          direnv-vim
          vim-tmux-navigator
          neo-tree-nvim
          fidget-nvim
          neodev-nvim
          vim-sleuth
          comment-nvim
          gitsigns-nvim
          which-key-nvim
          plenary-nvim
        ];

        # https://github.com/NixNeovim/NixNeovimPlugins
        extraPlugins = with pkgs.vimExtraPlugins; [
          # Themes
          nordic-alexczyl
          tokyonight-nvim
        ];

        myNeovim = pkgs.neovim.override {
          configure = {
            customRC = /* vim */ ''
              lua << EOF
                ${builtins.readFile ./lua/config/options.lua}
                ${builtins.readFile ./lua/config/keymaps.lua}
                ${builtins.readFile ./lua/config/autocmds.lua}
                ${builtins.readFile ./lua/plugins/theme.lua}
                ${builtins.readFile ./lua/plugins/cmp.lua}
                ${builtins.readFile ./lua/plugins/comment.lua}
                ${builtins.readFile ./lua/plugins/conform.lua}
                ${builtins.readFile ./lua/plugins/treesitter.lua}
                ${builtins.readFile ./lua/plugins/mini.lua}
                ${builtins.readFile ./lua/plugins/lsp.lua}
                ${builtins.readFile ./lua/plugins/neo-tree.lua}
                ${builtins.readFile ./lua/plugins/telescope.lua}
                ${builtins.readFile ./lua/plugins/noice.lua}
                ${builtins.readFile ./lua/plugins/lazygit.lua}
                ${builtins.readFile ./lua/plugins/which-key.lua}
              EOF
            '';
            packages.myPlugins.start = plugins ++ extraPlugins;
          };
        };
      in
      {
        defaultPackage = pkgs.writeShellApplication {
          name = "nvim";
          runtimeInputs = deps ++ lang;
          text = ''
            ${myNeovim}/bin/nvim "$@"
          '';
        };
      });
}

