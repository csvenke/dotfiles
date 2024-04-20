local view_keymaps = {
  { "n", "<leader>gd", "<cmd>DiffviewClose<cr>" },
  { "n", "<leader>gD", "<cmd>DiffviewClose<cr>" },
}

require("diffview").setup({
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

vim.opt.fillchars:append({ diff = " " })

vim.keymap.set("n", "<leader>gg", "<cmd>LazyGit<cr>", { desc = "[g]it [g]ui" })
vim.keymap.set("n", "<leader>gD", "<cmd>DiffviewOpen<cr>", { desc = "[g]it [D]iff view" })
vim.keymap.set("n", "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", { desc = "[g]it [h]istory (current file)" })
vim.keymap.set("n", "<leader>gH", "<cmd>DiffviewFileHistory<cr>", { desc = "[g]it [H]istory" })
vim.keymap.set("n", "<leader>gb", "<cmd>GitBlameToggle<cr>", { desc = "[g]it [b]lame toggle" })
