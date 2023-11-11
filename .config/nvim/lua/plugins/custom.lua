return {
  -- Themes
  {
    "AlexvZyl/nordic.nvim",
    event = "VeryLazy",
    opts = function()
      local colors = require("nordic.colors")
      return {
        override = {
          NeoTreeTitleBar = {
            fg = colors.yellow.dim,
          },
          NeoTreeGitUntracked = {
            fg = colors.white0,
          },
        },
      }
    end,
  },
  {
    "LazyVim/LazyVim",
    event = "VeryLazy",
    opts = {
      colorscheme = "nordic",
    },
  },

  -- LSP
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
    "ThePrimeagen/refactoring.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("refactoring").setup({})
    end,
  },
  {
    "nvimtools/none-ls.nvim",
    event = "VeryLazy",
    opts = function(_, opts)
      local builtins = require("null-ls").builtins
      local utils = require("null-ls.utils")
      opts.root_dir = opts.root_dir or utils.root_pattern(".null-ls-root", ".neoconf.json", "Makefile", ".git")
      opts.sources = vim.list_extend(opts.sources or {}, {
        builtins.formatting.stylua,
        builtins.formatting.shfmt,
        builtins.formatting.prettier,
        builtins.formatting.alejandra,
        builtins.code_actions.refactoring,
      })
    end,
  },

  -- Editor
  {
    "christoomey/vim-tmux-navigator",
    event = "VeryLazy",
    keys = {
      { "<C-H>", "<cmd>TmuxNavigateLeft<cr>", desc = "window left" },
      { "<C-L>", "<cmd>TmuxNavigateRight<cr>", desc = "window right" },
      { "<C-J>", "<cmd>TmuxNavigateDown<cr>", desc = "window down" },
      { "<C-K>", "<cmd>TmuxNavigateUp<cr>", desc = "window up" },
    },
  },

  -- Diffview
  {
    "sindrets/diffview.nvim",
    event = "VeryLazy",
    opts = {
      show_help_hints = false,
      keymaps = {
        view = {
          { "n", "<leader>gd", "<cmd>DiffviewClose<cr>" },
        },
        diff2 = {
          { "n", "<leader>gd", "<cmd>DiffviewClose<cr>" },
        },
        file_panel = {
          { "n", "<leader>gd", "<cmd>DiffviewClose<cr>" },
        },
      },
    },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "diff" },
    },
  },

  -- ChatGPT
  {
    "jackMort/ChatGPT.nvim",
    event = "VeryLazy",
    enabled = function()
      return vim.fn.getenv("OPENAI_API_KEY") ~= nil
    end,
    config = function()
      require("chatgpt").setup()
    end,
    dependencies = {
      "MunifTanjim/nui.nvim",
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
    },
    keys = {
      { "<leader>cc", "<cmd>ChatGPT<cr>", desc = "AI Prompt" },
      { "<leader>ce", "<cmd>ChatGPTEditWithInstruction<cr>", desc = "AI Edit", mode = { "n", "v" } },
    },
  },
}
