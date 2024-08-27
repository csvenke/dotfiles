{ pkgs }:

let
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
    refactoring-nvim
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
    git-blame-nvim
    # Ui
    noice-nvim
    trouble-nvim
    lualine-nvim
    neo-tree-nvim
    nvim-notify
    which-key-nvim
    bufferline-nvim
    nvim-spectre
    # Utils
    comment-nvim
    smart-splits-nvim
    # Other
    SchemaStore-nvim
    mini-nvim
    vim-startuptime
    nvim-ts-autotag
    nui-nvim
    plenary-nvim
    vim-sleuth
    # Icons
    lspkind-nvim
    nvim-web-devicons
  ];

  # https://github.com/NixNeovim/NixNeovimPlugins
  extraPlugins = with pkgs.vimExtraPlugins; [
    # Themes
    nordic-alexczyl
    # LLMs
    gp-nvim
  ];
in

plugins ++ extraPlugins
