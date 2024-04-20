local view_keymaps = {
  { "n", "<leader>gd", "<cmd>DiffviewClose<cr>" },
  { "n", "<leader>gD", "<cmd>DiffviewClose<cr>" },
}

require("diffview").setup({
  enhanced_diff_hl = true,
  keymaps = {
    view = view_keymaps,
    diff1 = view_keymaps,
    diff2 = view_keymaps,
    diff3 = view_keymaps,
    diff4 = view_keymaps,
    file_panel = view_keymaps,
    file_history_panel = view_keymaps,
    option_panel = view_keymaps,
    help_panel = view_keymaps,
  },
})

vim.keymap.set("n", "<leader>gg", "<cmd>LazyGit<cr>", { desc = "[g]it [g]ui" })
vim.keymap.set("n", "<leader>gD", "<cmd>DiffviewOpen<cr>", { desc = "[g]it [D]iff view" })
