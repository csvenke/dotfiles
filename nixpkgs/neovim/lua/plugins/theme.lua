local C = require("nordic.colors")

require("nordic").setup({
  override = {
    NeoTreeTitleBar = { fg = C.yellow.dim },
    NeoTreeGitUntracked = { fg = C.white0 },
  },
})

vim.cmd.colorscheme("nordic")
