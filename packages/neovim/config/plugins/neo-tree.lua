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
    use_libuv_file_watcher = true,
    follow_current_file = { enabled = true },
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
      ["l"] = "open",
      ["h"] = "close_node",
      ["L"] = "next_source",
      ["H"] = "prev_source",
      ["s"] = "open_split",
      ["v"] = "open_vsplit",
    },
  },
})

vim.keymap.set("n", "<leader>e", function()
  require("neo-tree.command").execute({ source = "filesystem", toggle = true })
end, { desc = "file [e]xplorer" })

vim.keymap.set("n", "<leader>E", function()
  require("neo-tree.command").execute({ source = "filesystem" })
end, { desc = "goto [E]xplorer" })

vim.keymap.set("n", "<leader>ge", function()
  require("neo-tree.command").execute({ source = "git_status", toggle = true })
end, { desc = "[g]it status [e]xplorer" })
