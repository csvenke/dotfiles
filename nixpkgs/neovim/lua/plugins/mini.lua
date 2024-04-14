require("mini.ai").setup({ n_lines = 500 })

require("mini.surround").setup()

local statusline = require("mini.statusline")
statusline.setup({ use_icons = vim.g.have_nerd_font })
statusline.section_location = function()
  return "%2l:%-2v"
end

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

vim.keymap.set("n", "<leader>go", function()
  require("mini.diff").toggle_overlay(0)
end, { desc = "Toggle diff" })

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

vim.keymap.set("n", "<leader>bd", deleteBuffer, { desc = "Delete buffer" })
vim.keymap.set("n", "<leader>bD", deleteBufferForce, { desc = "Delete buffer (force)" })
