local function deleteBuffer()
  local bd = require("mini.bufremove").delete
  if vim.bo.modified then
    local choice = vim.fn.confirm(("Save changes to %q?"):format(vim.fn.bufname()), "&Yes\n&No\n&Cancel")
    if choice == 1 then -- Yes
      vim.cmd.write()
      bd(0)
    elseif choice == 2 then -- No
      bd(0, true)
    end
  else
    bd(0)
  end
end

local function deleteBufferForce()
  require("mini.bufremove").delete(0, true)
end

require("mini.ai").setup({
  n_lines = 500,
})

require("mini.surround").setup()

require("mini.pairs").setup()

require("mini.diff").setup({
  view = {
    style = "sign",
    signs = {
      add = "▎",
      change = "▎",
      delete = "",
    },
  },
})

vim.keymap.set("n", "<leader>bd", deleteBuffer, { desc = "[b]uffer [d]elete" })
vim.keymap.set("n", "<leader>bD", deleteBufferForce, { desc = "[b]uffer [D]elete (force)" })
