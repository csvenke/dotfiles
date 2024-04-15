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
          pkgs.fzf
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
          direnv-vim

          # Syntax highlighting
          nvim-treesitter.withAllGrammars
          nvim-treesitter-textobjects
          nvim-treesitter-refactor
          nvim-treesitter-context

          # LSP
          fidget-nvim
          neodev-nvim
          neoconf-nvim
          nvim-lspconfig
          omnisharp-extended-lsp-nvim
          nvim-jdtls

          # Formatting
          conform-nvim

          # Autocomplete
          friendly-snippets
          luasnip
          cmp-nvim-lsp
          cmp-buffer
          cmp-path
          cmp-cmdline
          cmp_luasnip
          nvim-cmp

          # Telescope
          telescope-nvim
          telescope-fzf-native-nvim
          telescope-ui-select-nvim

          # Git
          lazygit-nvim
          diffview-nvim

          # Ui
          noice-nvim
          lualine-nvim
          neo-tree-nvim
          nvim-notify
          vim-startuptime
          which-key-nvim
          bufferline-nvim

          # LLMs
          ChatGPT-nvim

          # Utils
          comment-nvim
          mini-nvim
          vim-tmux-navigator

          # Other
          nvim-ts-autotag
          nui-nvim
          plenary-nvim
          nvim-web-devicons
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
                ${builtins.readFile ./lua/plugins/treesitter.lua}
                ${builtins.readFile ./lua/plugins/lsp.lua}
                ${builtins.readFile ./lua/plugins/cmp.lua}
                ${builtins.readFile ./lua/plugins/conform.lua}
                ${builtins.readFile ./lua/plugins/mini.lua}
                ${builtins.readFile ./lua/plugins/lualine.lua}
                ${builtins.readFile ./lua/plugins/bufferline.lua}
                ${builtins.readFile ./lua/plugins/comment.lua}
                ${builtins.readFile ./lua/plugins/neo-tree.lua}
                ${builtins.readFile ./lua/plugins/telescope.lua}
                ${builtins.readFile ./lua/plugins/noice.lua}
                ${builtins.readFile ./lua/plugins/lazygit.lua}
                ${builtins.readFile ./lua/plugins/diffview.lua}
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

