vim.g.gitblame_display_virtual_text = 0

local gitblame = require("gitblame")
local gitblame_section = { gitblame.get_current_blame_text, cond = gitblame.is_blame_text_available }

require("lualine").setup({
  theme = "auto",
  globalstatus = true,
  extensions = { "neo-tree", "trouble" },
  sections = {
    lualine_c = {
      gitblame_section,
    },
  },
})
