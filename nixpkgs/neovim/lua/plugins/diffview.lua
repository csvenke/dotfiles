require("diffview").setup({
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
})

vim.keymap.set("n", "<leader>gd", "<cmd>DiffviewOpen<cr>", { desc = "Open diff view" })
