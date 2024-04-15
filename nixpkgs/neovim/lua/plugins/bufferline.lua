require("bufferline").setup({
  options = {
    close_command = function(n)
      require("mini.bufremove").delete(n, false)
    end,
    right_mouse_command = function(n)
      require("mini.bufremove").delete(n, false)
    end,
    diagnostics = "nvim_lsp",
    always_show_bufferline = false,
    offsets = {
      {
        filetype = "neo-tree",
        text = "Explorer",
        highlight = "Directory",
        text_align = "left",
      },
    },
  },
})

vim.keymap.set("n", "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", { desc = "[B]uffer [P]in" })
vim.keymap.set("n", "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", { desc = "[B]uffer delte un-[P]inned" })
vim.keymap.set("n", "<leader>bo", "<Cmd>BufferLineCloseOthers<CR>", { desc = "[B]uffer close [O]thers" })
vim.keymap.set("n", "<S-h>", "<Cmd>BufferLineCyclePrev<CR>", { desc = "Previous buffer" })
vim.keymap.set("n", "<S-l>", "<Cmd>BufferLineCycleNext<CR>", { desc = "Next buffer" })
