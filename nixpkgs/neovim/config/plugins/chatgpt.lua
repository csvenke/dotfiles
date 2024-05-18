require("gp").setup({
  openai_api_key = { "cat", os.getenv("HOME") .. "/.vault/openai-api-key.txt" },
  agents = {
    {
      name = "ChatGPT",
      chat = true,
      command = false,
      model = { model = "gpt-4o", temperature = 1.1, top_p = 1 },
      system_prompt = "You are a general AI assistant.\n\n"
        .. "The user provided the additional info about how they would like you to respond:\n\n"
        .. "- If you're unsure don't guess and say you don't know instead.\n"
        .. "- Ask question if you need clarification to provide better answer.\n"
        .. "- Think deeply and carefully from first principles step by step.\n"
        .. "- Zoom out first to see the big picture and then zoom in to details.\n"
        .. "- Use Socratic method to improve your thinking and coding skills.\n"
        .. "- Don't elide any code from your output if the answer requires coding.\n"
        .. "- Take a deep breath; You've got this!\n",
    },
    {
      name = "CodeGPT",
      chat = false,
      command = true,
      model = { model = "gpt-4o", temperature = 0.8, top_p = 1 },
      system_prompt = "You are an AI working as a code editor.\n\n"
        .. "Please AVOID COMMENTARY OUTSIDE OF THE SNIPPET RESPONSE.\n"
        .. "START AND END YOUR ANSWER WITH:\n\n```",
    },
  },
})

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
