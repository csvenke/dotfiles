local refactoring = require("refactoring")

refactoring.setup({})

vim.keymap.set({ "n", "x" }, "<leader>rr", function()
  refactoring.select_refactor()
end, { desc = "select [r]efactor" })

vim.keymap.set("x", "<leader>re", function()
  refactoring.refactor("Extract Function")
end, { desc = "[r]efactor [e]xtract function" })

vim.keymap.set("x", "<leader>rf", function()
  refactoring.refactor("Extract Function To File")
end, { desc = "[r]efactor [f]unction to file" })

vim.keymap.set("x", "<leader>rv", function()
  refactoring.refactor("Extract Variable")
end, { desc = "[r]efactor extract [v]ariable" })

vim.keymap.set("n", "<leader>rI", function()
  refactoring.refactor("Inline Function")
end, { desc = "[r]efactor [I]nline function" })

vim.keymap.set({ "n", "x" }, "<leader>ri", function()
  refactoring.refactor("Inline Variable")
end, { desc = "[r]efactor [i]nline variable" })

vim.keymap.set("n", "<leader>rb", function()
  refactoring.refactor("Extract Block")
end, { desc = "[r]efactor extract [b]lock" })

vim.keymap.set("n", "<leader>rbf", function()
  refactoring.refactor("Extract Block To File")
end, { desc = "[r]efactor extract [b]lock to [f]ile" })
