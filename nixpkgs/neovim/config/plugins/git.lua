require("diffview").setup({
  keymaps = {
    view = {
      { "n", "<leader>gd", "<cmd>DiffviewClose<cr>" },
      { "n", "<leader>gD", "<cmd>DiffviewClose<cr>" },
    },
    diff2 = {
      { "n", "<leader>gd", "<cmd>DiffviewClose<cr>" },
      { "n", "<leader>gD", "<cmd>DiffviewClose<cr>" },
    },
    file_panel = {
      { "n", "<leader>gd", "<cmd>DiffviewClose<cr>" },
      { "n", "<leader>gD", "<cmd>DiffviewClose<cr>" },
    },
  },
})

vim.keymap.set("n", "<leader>gg", "<cmd>LazyGit<cr>", { desc = "[g]it [g]ui" })
vim.keymap.set("n", "<leader>gD", "<cmd>DiffviewOpen<cr>", { desc = "[g]it [D]iff view" })
