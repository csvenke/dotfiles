require("neo-tree").setup({
  source_selector = {
    winbar = true,
    statusLine = true,
  },
  sources = {
    "filesystem",
  },
  filesystem = {
    follow_current_file = {
      enabled = true,
      leave_dirs_open = false,
      use_libuv_file_watcher = true,
    },
    filtered_items = {
      visible = true,
      show_hidden_count = true,
      hide_dotfiles = false,
      hide_gitignored = true,
      never_show = {
        ".git",
      },
    },
  },
  window = {
    mappings = {
      ["<space>"] = "none",
      ["/"] = "none",
      ["L"] = "next_source",
      ["H"] = "prev_source",
    },
  },
})

vim.keymap.set("n", "<leader>e", function()
  require("neo-tree.command").execute({ source = "filesystem", toggle = true })
end, { desc = "file [e]xplorer" })
