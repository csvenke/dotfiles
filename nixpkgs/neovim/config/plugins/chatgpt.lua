require("chatgpt").setup({})

vim.keymap.set("n", "<leader>ap", "<Cmd>ChatGPT<CR>", { desc = "[a]i [p]rompt" })
vim.keymap.set("n", "<leader>ae", "<Cmd>ChatGPTEditWithInstruction<CR>", { desc = "[a]i [e]dit" })
