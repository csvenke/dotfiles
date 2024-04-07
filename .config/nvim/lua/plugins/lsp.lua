return {
  {
    "neovim/nvim-lspconfig",
    event = "VeryLazy",
    opts = {
      diagnostics = {
        underline = false,
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      auto_install = false,
      ensure_installed = { "v", "http", "cuda", "fish", "rust" },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        nix = { "nixfmt" },
      },
      formatters = {
        nixfmt = {
          command = "nixpkgs-fmt",
        },
      },
    },
  },
}
