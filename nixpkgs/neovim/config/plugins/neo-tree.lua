require("neo-tree").setup({
  source_selector = {
    winbar = true,
    statusLine = true,
  },
  sources = {
    "filesystem",
    "git_status",
  },
  filesystem = {
    follow_current_file = {
      enabled = true,
      leave_dirs_open = true,
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

vim.keymap.set("n", "<leader>ge", function()
  require("neo-tree.command").execute({ source = "git_status", toggle = true })
end, { desc = "[g]it status [e]xplorer" })
