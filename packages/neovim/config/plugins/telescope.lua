vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("user-vim-enter-telescope", { clear = true }),
  callback = function()
    local trouble = require("trouble.providers.telescope")

    require("telescope").setup({
      defaults = {
        mappings = {
          i = { ["<C-q>"] = trouble.open_with_trouble },
          n = { ["<C-q>"] = trouble.open_with_trouble },
        },
      },
      extensions = {
        ["ui-select"] = {
          require("telescope.themes").get_dropdown(),
        },
      },
    })

    require("telescope").load_extension("notify")
    require("telescope").load_extension("fzf")
    require("telescope").load_extension("ui-select")
    require("telescope").load_extension("lazygit")
    require("telescope").load_extension("noice")

    local builtin = require("telescope.builtin")

    vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "[s]earch [h]elp" })
    vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "[s]earch [k]eymaps" })
    vim.keymap.set("n", "<leader>sf", builtin.find_files, { desc = "[s]earch [f]iles" })
    vim.keymap.set("n", "<leader>sg", builtin.git_files, { desc = "[s]earch [g]it files" })
    vim.keymap.set("n", "<leader>ss", builtin.lsp_document_symbols, { desc = "[s]earch [s]ymbols" })
    vim.keymap.set("n", "<leader>sS", builtin.lsp_workspace_symbols, { desc = "[s]earch [S]ymbols (workspace)" })
    vim.keymap.set("n", "<leader>st", builtin.tagstack, { desc = "[s]earch [t]agstack" })
    vim.keymap.set("n", "<leader>sb", builtin.buffers, { desc = "[s]earch [b]uffers" })
    vim.keymap.set("n", "<leader>sw", builtin.grep_string, { desc = "[s]earch [w]ord" })
    vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "[s]earch [d]iagnostics" })
    vim.keymap.set("n", "<leader>so", builtin.vim_options, { desc = "[s]earch vim [o]ptions" })
    vim.keymap.set("n", "<leader>sn", "<cmd>Telescope notify<cr>", { desc = "[s]earch [n]otifications" })
    vim.keymap.set("n", "<leader>sr", "<cmd>Spectre<cr>", { desc = "[s]earch and [r]eplace" })
    vim.keymap.set("n", "<leader>/", builtin.live_grep, { desc = "Find in files (Grep)" })
    vim.keymap.set("n", "<leader>?", builtin.live_grep, { desc = "Find in files (Grep)" })
    vim.keymap.set("n", "<leader>:", builtin.command_history, { desc = "Command history" })
    vim.keymap.set("n", "<leader><leader>", builtin.find_files, { desc = "[s]earch [f]iles" })
  end,
})
