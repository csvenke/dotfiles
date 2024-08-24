local actions = require("diffview.actions")

local default_keymaps = {
  { "n", "<leader>gd", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
  { "n", "<leader>gD", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
  { "n", "<C-q>", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
  { "n", "<tab>", actions.select_next_entry, { desc = "Select next entry" } },
  { "n", "<s-tab>", actions.select_prev_entry, { desc = "Select previous entry" } },
}

local file_panel = {
  { "n", "<leader>gd", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
  { "n", "<leader>gD", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
  { "n", "<C-q>", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
  { "n", "<tab>", actions.select_next_entry, { desc = "Select next entry" } },
  { "n", "<s-tab>", actions.select_prev_entry, { desc = "Select previous entry" } },
  { "n", "j", actions.next_entry, { desc = "Next" } },
  { "n", "k", actions.prev_entry, { desc = "Previous" } },
  { "n", "<cr>", actions.select_entry, { desc = "Select entry" } },
  { "n", "s", actions.toggle_stage_entry, { desc = "Toggle stage entry" } },
  { "n", "S", actions.stage_all, { desc = "Stage all entries" } },
  { "n", "u", actions.unstage_all, { desc = "Unstage all entries" } },
  { "n", "d", actions.restore_entry, { desc = "Restore entry" } },
}

require("diffview").setup({
  keymaps = {
    disable_defaults = true,
    view = default_keymaps,
    diff1 = default_keymaps,
    diff2 = default_keymaps,
    diff3 = default_keymaps,
    diff4 = default_keymaps,
    file_panel = file_panel,
    file_history_panel = default_keymaps,
    option_panel = default_keymaps,
    help_panel = default_keymaps,
  },
  view = {
    merge_tool = {
      layout = "diff3_mixed"
    }
  },
  hooks = {
    diff_buf_read = function()
      vim.opt_local.foldenable = false
      vim.cmd("set diffopt+=context:99999")
    end,
  },
})

vim.opt.culopt = "number"
vim.opt.fillchars:append({ diff = " " })

vim.keymap.set("n", "<leader>gg", "<cmd>LazyGit<cr>", { desc = "[g]it [g]ui" })
vim.keymap.set("n", "<leader>gd", "<cmd>DiffviewOpen<cr>", { desc = "[g]it [d]iff view" })
vim.keymap.set("n", "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", { desc = "[g]it [h]istory (current file)" })
vim.keymap.set("n", "<leader>gH", "<cmd>DiffviewFileHistory<cr>", { desc = "[g]it [H]istory" })
vim.keymap.set("n", "<leader>gb", "<cmd>GitBlameToggle<cr>", { desc = "[g]it [b]lame toggle" })
