vim.g.gitblame_display_virtual_text = 0

local gitblame = require("gitblame")
local gitblame_section = { gitblame.get_current_blame_text, cond = gitblame.is_blame_text_available }

require("lualine").setup({
  options = {
    theme = "auto",
    globalstatus = true,
    icons_enabled = vim.g.have_nerd_font,
  },
  sections = {
    lualine_c = {
      gitblame_section,
    },
  },
  extensions = { "neo-tree", "trouble" },
})

