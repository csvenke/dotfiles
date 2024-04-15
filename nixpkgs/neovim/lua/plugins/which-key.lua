vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("user-vim-enter-which-key", { clear = true }),
  callback = function()
    require("which-key").setup({})
    require("which-key").register({
      ["<leader>c"] = { name = "[C]ode", _ = "which_key_ignore" },
      ["<leader>d"] = { name = "[D]ocument", _ = "which_key_ignore" },
      ["<leader>b"] = { name = "[B]uffer", _ = "which_key_ignore" },
      ["<leader>r"] = { name = "[R]ename", _ = "which_key_ignore" },
      ["<leader>s"] = { name = "[S]earch", _ = "which_key_ignore" },
      ["<leader>w"] = { name = "[W]orkspace", _ = "which_key_ignore" },
      ["<leader>g"] = { name = "[G]it", _ = "which_key_ignore" },
      ["<leader>q"] = { name = "[Q]uit", _ = "which_key_ignore" },
    })
  end,
})
