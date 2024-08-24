require("fidget").setup({})
require("neodev").setup({})
require("neoconf").setup({})

local function make_map_buffer(buffer)
  return function(keys, func, desc)
    vim.keymap.set("n", keys, func, { buffer = buffer, desc = desc })
  end
end

local function default_on_attach(client, buffer)
  local map = make_map_buffer(buffer)
  local telescope = require("telescope.builtin")

  map("gd", telescope.lsp_definitions, "[g]oto [d]efinition(s)")
  map("gD", vim.lsp.buf.declaration, "[g]oto [D]eclaration")
  map("gi", telescope.lsp_implementations, "[g]oto [i]mplementation(s)")
  map("gr", telescope.lsp_references, "[g]oto [r]eference(s)")
  map("K", vim.lsp.buf.hover, "Hover documentation")
  map("<leader>D", telescope.lsp_type_definitions, "type [D]efinition(s)")
  map("<leader>ca", vim.lsp.buf.code_action, "[c]ode [a]ction")
  map("<leader>cr", vim.lsp.buf.rename, "[c]ode [r]ename")
  map("<leader>cd", vim.diagnostic.open_float, "[c]ode [d]iagnostic")

  if client and client.server_capabilities.documentHighlightProvider then
    vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
      buffer = buffer,
      callback = vim.lsp.buf.document_highlight,
    })

    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
      buffer = buffer,
      callback = vim.lsp.buf.clear_references,
    })
  end
end

local function makeCodeAction(name)
  return function()
    vim.lsp.buf.code_action({
      apply = true,
      context = {
        only = { name },
        diagnostics = {},
      },
    })
  end
end

---@diagnostic disable: missing-fields
---@type lspconfig.options
local servers = {
  nil_ls = {},

  bashls = {},

  hls = {},

  jdtls = {
    cmd = { "jdtls" },
  },

  rust_analyzer = {},

  tsserver = {
    init_options = {
      preferences = {
        importModuleSpecifierPreference = "relative",
        importModuleSpecifierEnding = "minimal",
      },
    },
    on_attach = function()
      vim.keymap.set(
        "n",
        "<leader>co",
        makeCodeAction("source.organizeImports.ts"),
        { desc = "[c]ode [o]rganize imports" }
      )
      vim.keymap.set(
        "n",
        "<leader>cR",
        makeCodeAction("source.removeUnused.ts"),
        { desc = "[c]ode [R]emove unused imports" }
      )
    end,
  },

  angularls = {
    cmd = { "angular-language-server", "--stdio", "--tsProbeLocations", "", "--ngProbeLocations", "" },
    on_new_config = function(new_config)
      new_config.cmd = { "angular-language-server", "--stdio", "--tsProbeLocations", "", "--ngProbeLocations", "" }
    end,
  },

  lua_ls = {
    settings = {
      Lua = {
        library = {
          vim.env.VIMRUNTIME,
        },
        completion = {
          callSnippet = "Replace",
        },
      },
    },
  },

  omnisharp = {
    cmd = { "OmniSharp" },
    enable_editorconfig_support = true,
    enable_ms_build_load_projects_on_demand = false,
    enable_roslyn_analyzers = true,
    organize_imports_on_format = false,
    enable_import_completion = true,
    sdk_include_prereleases = true,
    analyze_open_documents_only = false,
    on_attach = function(_, buffer)
      local map = make_map_buffer(buffer)
      local omnisharp = require("omnisharp_extended")

      map("gd", omnisharp.lsp_definition, "[g]oto [d]efinition")
      map("gi", omnisharp.telescope_lsp_implementation, "[g]oto [i]mplementation")
      map("gr", omnisharp.telescope_lsp_references, "[g]oto [r]eferences")
      map("<leader>D", omnisharp.telescope_lsp_type_definition, "type [D]efinition")
    end,
  },

  marksman = {},

  eslint = {},

  pyright = {
    enabled = true,
  },

  ruff_lsp = {
    init_options = {
      settings = {
        args = {},
      },
    },
    on_attach = function(client)
      vim.keymap.set(
        "n",
        "<leader>co",
        makeCodeAction("source.organizeImports"),
        { desc = "[c]ode [o]organize imports" }
      )
      client.server_capabilities.hoverProvider = false
    end,
  },

  yamlls = {
    on_attach = function(client)
      client.server_capabilities.documentFormattingProvider = true
    end,
    on_new_config = function(new_config)
      new_config.settings.yaml.schemas = new_config.settings.yaml.schemas or {}
      vim.list_extend(new_config.settings.yaml.schemas, require("schemastore").yaml.schemas())
    end,
    capabilities = {
      textDocument = {
        foldingRange = {
          dynamicRegistration = false,
          lineFoldingOnly = true,
        },
      },
    },
    settings = {
      redhat = { telemetry = { enabled = false } },
      yaml = {
        keyOrdering = false,
        format = {
          enable = true,
        },
        validate = true,
        schemaStore = {
          enable = false,
          url = "",
        },
      },
    },
  },

  jsonls = {
    on_new_config = function(new_config)
      new_config.settings.json.schemas = new_config.settings.json.schemas or {}
      vim.list_extend(new_config.settings.json.schemas, require("schemastore").json.schemas())
    end,
    settings = {
      json = {
        format = {
          enable = true,
        },
        validate = { enable = true },
      },
    },
  },

  taplo = {},

  gleam = {},
}

local capabilities = vim.tbl_deep_extend(
  "force",
  vim.lsp.protocol.make_client_capabilities(),
  require("cmp_nvim_lsp").default_capabilities()
)

local lspconfig = require("lspconfig")

for server, config in pairs(servers) do
  config.capabilities = vim.tbl_deep_extend("force", {}, capabilities, config.capabilities or {})
  config.on_attach = lspconfig.util.add_hook_after(default_on_attach, config.on_attach or function() end)
  lspconfig[server].setup(config)
end

vim.diagnostic.config({
  underline = false,
})
