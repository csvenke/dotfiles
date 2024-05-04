require("gp").setup({})

vim.keymap.set("n", "<leader>aa", "<cmd>GpNew<cr>", { desc = "quick prompt" })
vim.keymap.set("n", "<leader>aA", "<cmd>GpChatToggle<cr>", { desc = "toggle chat" })

vim.keymap.set("n", "<leader>a|", "<cmd>GpChatNew vsplit<cr>", { desc = "new chat (vertical)" })
vim.keymap.set("n", "<leader>av", "<cmd>GpChatNew vsplit<cr>", { desc = "new chat (vertical)" })
vim.keymap.set("n", "<leader>a-", "<cmd>GpChatNew split<cr>", { desc = "new chat (horizontal)" })
vim.keymap.set("n", "<leader>as", "<cmd>GpChatNew split<cr>", { desc = "new chat (horizontal)" })
vim.keymap.set("n", "<leader>at", "<cmd>GpChatNew tabnew<cr>", { desc = "new chat (tab)" })

vim.keymap.set("v", "<leader>ap", ":'<,'>GpChatPaste split<cr>", { desc = "paste to chat (horizontal)" })
vim.keymap.set("v", "<leader>aP", ":'<,'>GpChatPaste vsplit<cr>", { desc = "paste to chat (vertical)" })

vim.keymap.set("v", "<leader>ae", ":'<,'>GpRewrite<cr>", { desc = "edit selection" })
vim.keymap.set("v", "<leader>ar", ":'<,'>GpRewrite<cr>", { desc = "rewrite selection" })
vim.keymap.set("n", "<leader>ao", "<cmd>GpAppend<cr>", { desc = "insert below" })
vim.keymap.set("n", "<leader>aO", "<cmd>GpPrepend<cr>", { desc = "insert above" })

