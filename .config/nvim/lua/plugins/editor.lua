return {
  { "direnv/direnv.vim" },

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

  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      filesystem = {
        filtered_items = {
          visible = true,
          show_hidden_count = true,
          hide_dotfiles = false,
          hide_gitignored = true,
          never_show = {
            ".git",
          },
        },
      },
    },
  },

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
      { "<leader>a", desc = "AI" },
      { "<leader>ap", "<cmd>ChatGPT<cr>", desc = "Prompt" },
      { "<leader>ah", "<cmd>ChatGPTRun explain_code<cr>", desc = "Explain code" },
      { "<leader>ar", "<cmd>ChatGPTRun code_readability_analysis<cr>", desc = "Code readability analysis" },
      { "<leader>ae", "<cmd>ChatGPTEditWithInstruction<cr>", desc = "Edit with instructions", mode = { "n", "v" } },
    },
  },
}
