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
lspconfig.bashls.setup({
  capabilities = capabilities,
})
lspconfig.hls.setup({
  capabilities = capabilities,
})
lspconfig.jdtls.setup({
  capabilities = capabilities,
})
lspconfig.rust_analyzer.setup({
  capabilities = capabilities,
  settings = {
    ["rust-analyzer"] = {},
  },
})
lspconfig.tsserver.setup({
  capabilities = capabilities,
})
lspconfig.lua_ls.setup({
  capabilities = capabilities,
  settings = {
    Lua = {
      completion = "Replace",
      diagnostics = {
        globals = { "vim" },
      },
    },
  },
})
lspconfig.omnisharp.setup({
  cmd = { "OmniSharp" },
  capabilities = capabilities,
  enable_roslyn_analyzers = true,
  organize_imports_on_format = true,
  enable_import_completion = true,
})
lspconfig.marksman.setup({
  capabilities = capabilities,
})
lspconfig.eslint.setup({
  capabilities = capabilities,
})
lspconfig.pyright.setup({
  capabilities = capabilities,
})
lspconfig.ruff.setup({
  capabilities = capabilities,
})
lspconfig.yamlls.setup({
  capabilities = capabilities,
})
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

    map("gd", require("telescope.builtin").lsp_definitions, "[g]oto [d]efinition")
    map("gD", vim.lsp.buf.declaration, "[g]oto [D]eclaration")
    map("gr", require("telescope.builtin").lsp_references, "[g]oto [r]eferences")
    map("gi", require("telescope.builtin").lsp_implementations, "[g]oto [i]mplementation")
    map("<leader>ca", vim.lsp.buf.code_action, "[c]ode [a]ction")
    map("<leader>cr", vim.lsp.buf.code_action, "[c]ode [r]ename")
    map("K", vim.lsp.buf.hover, "Hover Documentation")
    map("<leader>D", require("telescope.builtin").lsp_type_definitions, "type [D]efinition")

    local client = vim.lsp.get_client_by_id(args.data.client_id)

    if client.name == "omnisharp" then
      map("gd", require("omnisharp_extended").lsp_definition, "[g]oto [d]efinition")
      map("gi", require("omnisharp_extended").telescope_lsp_implementation, "[g]oto [i]mplementation")
      map("gr", require("omnisharp_extended").telescope_lsp_references, "[g]oto [r]eferences")
      map("<leader>D", require("omnisharp_extended").telescope_lsp_type_definition, "type [D]efinition")
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