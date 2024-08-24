vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("user-vim-enter-which-key", { clear = true }),
  callback = function()
    require("which-key").setup({})
    require("which-key").register({
      ["<leader>a"] = { name = "[a]i", _ = "which_key_ignore" },
      ["<leader>b"] = { name = "[b]uffer", _ = "which_key_ignore" },
      ["<leader>c"] = { name = "[c]ode", _ = "which_key_ignore" },
      ["<leader>d"] = { name = "[d]iagnostics", _ = "which_key_ignore" },
      ["<leader>f"] = { name = "[f]ormat", _ = "which_key_ignore" },
      ["<leader>g"] = { name = "[g]it", _ = "which_key_ignore" },
      ["<leader>q"] = { name = "[q]uit", _ = "which_key_ignore" },
      ["<leader>s"] = { name = "[s]earch", _ = "which_key_ignore" },
      ["<leader>r"] = { name = "[r]efactor", _ = "which_key_ignore" },
    })
  end,
})
