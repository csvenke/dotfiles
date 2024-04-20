require("fidget").setup({})
require("neodev").setup({})
require("neoconf").setup({})

local lspconfig = require("lspconfig")

local capabilities = vim.tbl_deep_extend(
  "force",
  vim.lsp.protocol.make_client_capabilities(),
  require("cmp_nvim_lsp").default_capabilities()
)

lspconfig.nil_ls.setup({
  capabilities = capabilities,
})
---@type lspconfig.options.bashls
lspconfig.bashls.setup({
  capabilities = capabilities,
})
lspconfig.hls.setup({
  capabilities = capabilities,
})
---@type lspconfig.options.jdtls
lspconfig.jdtls.setup({
  capabilities = capabilities,
  settings = {},
})
---@type lspconfig.options.rust_analyzer
lspconfig.rust_analyzer.setup({
  capabilities = capabilities,
  settings = {
    ["rust-analyzer"] = {},
  },
})
---@type lspconfig.options.tsserver
lspconfig.tsserver.setup({
  capabilities = capabilities,
})
---@type lspconfig.options.lua_ls
lspconfig.lua_ls.setup({
  capabilities = capabilities,
  settings = {
    Lua = {
      library = {
        vim.env.VIMRUNTIME,
      },
    },
  },
})
---@type lspconfig.options.omnisharp
lspconfig.omnisharp.setup({
  cmd = { "OmniSharp" },
  capabilities = capabilities,
  settings = {},
  enable_roslyn_analyzers = true,
  organize_imports_on_format = true,
  enable_import_completion = true,
})
lspconfig.marksman.setup({
  capabilities = capabilities,
})
---@type lspconfig.options.eslint
lspconfig.eslint.setup({
  capabilities = capabilities,
})
---@type lspconfig.options.pyright
lspconfig.pyright.setup({
  capabilities = capabilities,
})
lspconfig.ruff.setup({
  capabilities = capabilities,
})
---@type lspconfig.options.yamlls
lspconfig.yamlls.setup({
  capabilities = capabilities,
})
---@type lspconfig.options.jsonls
lspconfig.jsonls.setup({
  capabilities = capabilities,
})
lspconfig.taplo.setup({
  capabilities = capabilities,
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("user-lsp-attach", { clear = true }),
  callback = function(args)
    local map = function(keys, func, desc)
      vim.keymap.set("n", keys, func, { buffer = args.buf, desc = desc })
    end

    local telescope = require("telescope.builtin")
    map("gd", telescope.lsp_definitions, "[g]oto [d]efinition")
    map("gr", telescope.lsp_references, "[g]oto [r]eferences")
    map("gi", telescope.lsp_implementations, "[g]oto [i]mplementation")
    map("<leader>D", telescope.lsp_type_definitions, "type [D]efinition")
    map("gD", vim.lsp.buf.declaration, "[g]oto [D]eclaration")
    map("<leader>ca", vim.lsp.buf.code_action, "[c]ode [a]ction")
    map("<leader>cr", vim.lsp.buf.rename, "[c]ode [r]ename")
    map("K", vim.lsp.buf.hover, "Hover Documentation")

    local client = vim.lsp.get_client_by_id(args.data.client_id)

    if client.name == "omnisharp" then
      local omnisharp = require("omnisharp_extended")
      map("gd", omnisharp.lsp_definition, "[g]oto [d]efinition")
      map("gi", omnisharp.telescope_lsp_implementation, "[g]oto [i]mplementation")
      map("gr", omnisharp.telescope_lsp_references, "[g]oto [r]eferences")
      map("<leader>D", omnisharp.telescope_lsp_type_definition, "type [D]efinition")
    end

    if client and client.server_capabilities.documentHighlightProvider then
      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        buffer = args.buf,
        callback = vim.lsp.buf.document_highlight,
      })

      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        buffer = args.buf,
        callback = vim.lsp.buf.clear_references,
      })
    end
  end,
})

vim.diagnostic.config({
  underline = false,
})
