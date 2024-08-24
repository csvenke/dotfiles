require("trouble").setup({})

vim.keymap.set("n", "<leader>dd", "<cmd>Trouble document_diagnostics<cr>", { desc = "[d]iagnostics" })
vim.keymap.set("n", "<leader>dD", "<cmd>Trouble workspace_diagnostics<cr>", { desc = "[D]iagnostics (workspace)" })
