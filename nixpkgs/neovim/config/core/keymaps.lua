vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

vim.keymap.set("n", "<leader>qq", "<cmd>wqa<cr>", { desc = "[q]uit" })
vim.keymap.set("n", "<leader>qQ", "<cmd>qa<cr>", { desc = "[q]uit (without saving)" })

vim.keymap.set("n", "<leader>-", "<cmd>split<cr>", { desc = "split horisontal" })
vim.keymap.set("n", "<leader>|", "<cmd>vsplit<cr>", { desc = "split vertical" })

vim.keymap.set("", "<C-s>", "<cmd>w<cr>", { desc = "save" })
vim.keymap.set("n", "<C-q>", "<cmd>q<cr>", { desc = "close" })
