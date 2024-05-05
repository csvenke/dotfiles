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
    show_buffer_close_icons = false,
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

vim.keymap.set("n", "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", { desc = "[b]uffer [p]in" })
vim.keymap.set("n", "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", { desc = "[b]uffer close un-[P]inned" })
vim.keymap.set("n", "<leader>bo", "<Cmd>BufferLineCloseOthers<CR>", { desc = "[b]uffer close [o]thers" })
vim.keymap.set("n", "<S-h>", "<Cmd>BufferLineCyclePrev<CR>", { desc = "Previous buffer" })
vim.keymap.set("n", "<S-l>", "<Cmd>BufferLineCycleNext<CR>", { desc = "Next buffer" })
