local conform = require("conform")

conform.setup({
  notify_on_error = false,
  format_on_save = function(bufnr)
    local disable_filetypes = { c = true, cpp = true }
    return {
      timeout_ms = 500,
      lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
    }
  end,
  formatters_by_ft = {
    lua = { "stylua" },
    nix = { "nixfmt" },
    bash = { "shfmt" },
    sh = { "shfmt" },
    cs = {},
    cshtml = {},
    py = { "ruff" },
    ["javascript"] = { "prettier" },
    ["javascriptreact"] = { "prettier" },
    ["typescript"] = { "prettier" },
    ["typescriptreact"] = { "prettier" },
    ["vue"] = { "prettier" },
    ["css"] = { "prettier" },
    ["scss"] = { "prettier" },
    ["less"] = { "prettier" },
    ["html"] = { "prettier" },
    ["json"] = { "prettier" },
    ["jsonc"] = { "prettier" },
    ["yaml"] = { "prettier" },
    ["markdown"] = { "prettier" },
    ["markdown.mdx"] = { "prettier" },
    ["graphql"] = { "prettier" },
    ["handlebars"] = { "prettier" },
  },
  formatters = {
    ruff = {
      command = "ruff",
    },
    stylua = {
      command = "stylua",
      cwd = require("conform.util").root_file({
        ".stylua.toml",
        "stylua.toml",
        ".editorconfig",
      }),
      require_cwd = true,
    },
    nixfmt = {
      command = "nixpkgs-fmt",
    },
    shfmt = {
      command = "shfmt",
      prepend_args = { "-i", "2" },
    },
    csharpier = {
      command = "dotnet-csharpier",
      args = { "--write-stdout" },
      cwd = require("conform.util").root_file({
        ".csharpierrc",
        ".csharpierrc.json",
        ".csharpierrc.yaml",
        ".editorconfig",
      }),
      require_cwd = true,
    },
    prettier = {
      command = "prettierd",
      cwd = require("conform.util").root_file({
        ".prettierrc",
        ".prettierrc.json",
        ".prettierrc.yml",
        ".prettierrc.yaml",
        ".prettierrc.json5",
        ".prettierrc.js",
        "prettier.config.js",
        ".editorconfig",
      }),
      require_cwd = true,
    },
  },
})

local function formatBuffer()
  require("conform").format({ async = true, lsp_fallback = true })
end

vim.keymap.set("n", "<leader>f", formatBuffer, { desc = "[F]ormat buffer" })
