return {
  {
    -- "AlexvZyl/nordic.nvim",
    "juniorsundar/nordic.nvim",
    event = "VeryLazy",
    opts = function()
      local C = require("nordic.colors")
      return {
        override = {
          NeoTreeTitleBar = { fg = C.yellow.dim },
          NeoTreeGitUntracked = { fg = C.white0 },
        },
      }
    end,
  },
  {
    "LazyVim/LazyVim",
    event = "VeryLazy",
    opts = {
      colorscheme = "nordic",
    },
  },
}
