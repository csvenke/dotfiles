vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

vim.keymap.set("n", "<leader>qq", "<cmd>wqa<cr>", { desc = "[q]uit" })
vim.keymap.set("n", "<leader>qQ", "<cmd>qa<cr>", { desc = "[q]uit (without saving)" })

vim.keymap.set("n", "<leader>-", "<cmd>split<cr>", { desc = "split horisontal" })
vim.keymap.set("n", "<leader>|", "<cmd>vsplit<cr>", { desc = "split vertical" })

vim.keymap.set({ "n", "i" }, "<C-s>", "<cmd>w<cr>", { desc = "save" })
vim.keymap.set("n", "<C-q>", "<cmd>q<cr>", { desc = "close" })

vim.keymap.set("i", "<C-j>", "{}<Esc>i", { desc = "{" })
vim.keymap.set("i", "<C-k>", "[]<Esc>i", { desc = "[" })

vim.keymap.set("i", "<C-l>", "<Esc>la", { desc = "Shift right" })
vim.keymap.set("i", "<C-h>", "<Esc>i", { desc = "Shift left" })

vim.keymap.set("i", "<C-c>", "<Esc>")
