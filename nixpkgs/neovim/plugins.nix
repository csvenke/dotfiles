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
		trouble-nvim
    lualine-nvim
    neo-tree-nvim
    nvim-notify
    which-key-nvim
    bufferline-nvim
    # LLMs
    ChatGPT-nvim
    # Utils
    comment-nvim
    vim-tmux-navigator
    # Other
    mini-nvim
    vim-startuptime
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
in


plugins ++ extraPlugins