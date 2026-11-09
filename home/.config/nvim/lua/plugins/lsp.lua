-- ============================================================================
-- Native Neovim 0.12 LSP, Mason, Copilot & IntelliSense Keymaps
-- ============================================================================

local map = vim.keymap.set

-- 1. Mason & Tool Installer
local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
if not string.find(vim.env.PATH or "", mason_bin, 1, true) then
  vim.env.PATH = mason_bin .. ":" .. (vim.env.PATH or "")
end

local ok_mason, mason = pcall(require, "mason")
if ok_mason then
  mason.setup({
    ui = { border = "rounded" },
  })
end

local ok_mti, mason_tool_installer = pcall(require, "mason-tool-installer")
if ok_mti then
  mason_tool_installer.setup({
    ensure_installed = {
      "vtsls",
      "biome",
      "lua-language-server",
      "dockerfile-language-server",
      "docker-compose-language-service",
      "html-lsp",
      "css-lsp",
      "json-lsp",
      "yaml-language-server",
      "copilot-language-server",
      "prettier",
      "tree-sitter-cli",
    },
    auto_update = false,
    run_on_start = true,
  })
end

-- 2. Diagnostics (tiny-inline-diagnostic.nvim) & Inline Ghost Text Styling
vim.diagnostic.config({
  virtual_text = false, -- Handled by tiny-inline-diagnostic.nvim
  severity_sort = true,
  float = { border = "rounded", source = "if_many" },
})

local ok_tid, tiny_diag = pcall(require, "tiny-inline-diagnostic")
if ok_tid then
  tiny_diag.setup({
    preset = "modern",
    options = {
      show_source = {
        enabled = true,
        if_many = true,
      },
      multilines = {
        enabled = true,
        always_show = false,
      },
      break_line = {
        enabled = true,
        after = 80,
      },
    },
  })
end

local function set_inline_hint_hl()
  -- Style native inline completion ("editor.inlineSuggest.fontFamily": "'Monaspace Krypton'")
  vim.api.nvim_set_hl(0, "ComplHint", { fg = "#737994", italic = true, default = false })
end
set_inline_hint_hl()
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("LspInlineHintHl", { clear = true }),
  callback = set_inline_hint_hl,
})

-- 3. Native LspAttach (Completion, Inline Copilot, CodeLens, Linked Editing, Inlay Hints)
local copilot_filetypes = {
  typescript = true,
  javascript = true,
  typescriptreact = true,
  javascriptreact = true,
  lua = true,
  html = true,
  css = true,
  scss = true,
  json = true,
  sh = true,
  zsh = true,
  text = true,
  markdown = true,
  yaml = false,
}

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("NativeLspAttach", { clear = true }),
  callback = function(args)
    local bufnr = args.buf
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then
      return
    end

    if client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, bufnr, {
        autotrigger = true,
      })
    end

    if client:supports_method("textDocument/inlineCompletion") then
      local ft = vim.bo[bufnr].filetype
      vim.lsp.inline_completion.enable(copilot_filetypes[ft] == true, {
        client_id = client.id,
        bufnr = bufnr,
      })
    end

    if client:supports_method("textDocument/codeLens") then
      vim.lsp.codelens.enable(true, { bufnr = bufnr })
    end

    if client:supports_method("textDocument/linkedEditingRange") then
      vim.lsp.linked_editing_range.enable(true, { client_id = client.id })
    end

    -- "editor.inlayHints.enabled": "offUnlessPressed" (restored from per-folder state)
    if client:supports_method("textDocument/inlayHint") then
      local saved_inlay = require("core.state").get("inlay_hints", false)
      vim.lsp.inlay_hint.enable(saved_inlay, { bufnr = bufnr })
    end
  end,
})

-- 4. Server Configs (vtsls, lua_ls, jsonls, yamlls, html, cssls, copilot)
vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = {
        checkThirdParty = false,
        library = { vim.env.VIMRUNTIME },
      },
      diagnostics = {
        globals = { "vim" },
      },
    },
  },
})

local ts_settings = {
  implicitProjectConfig = { checkJs = true },
  referencesCodeLens = { enabled = true, showOnAllFunctions = true },
  updateImportsOnFileMove = { enabled = "always" },
  inlayHints = {
    parameterTypes = { enabled = true },
    parameterNames = { enabled = "all" },
    functionLikeReturnTypes = { enabled = true },
  },
}

vim.lsp.config("vtsls", {
  settings = {
    typescript = ts_settings,
    javascript = ts_settings,
    vtsls = { autoUseWorkspaceTsdk = true },
  },
})

local json_schemas = {}
local yaml_schemas = {}
local ok_schemastore, schemastore = pcall(require, "schemastore")
if ok_schemastore then
  json_schemas = schemastore.json.schemas()
  yaml_schemas = schemastore.yaml.schemas()
end

vim.lsp.config("jsonls", {
  settings = {
    json = {
      schemas = json_schemas,
      validate = { enable = true },
    },
  },
})

vim.lsp.config("yamlls", {
  on_attach = function(client, bufnr)
    local filepath = vim.api.nvim_buf_get_name(bufnr)
    if
      filepath:match("/%.github/workflows/.*%.ya?ml$")
      or filepath:match("/%.gitea/workflows/.*%.ya?ml$")
      or filepath:match("/%.forgejo/workflows/.*%.ya?ml$")
    then
      client.settings = vim.tbl_deep_extend("force", client.settings or {}, {
        yaml = {
          schemaStore = { enable = false, url = "" },
          schemas = {},
        },
      })
      client:notify("workspace/didChangeConfiguration", { settings = client.settings })
    end
  end,
  settings = {
    yaml = {
      -- Use b0o/SchemaStore.nvim catalog instead of yamlls's built-in fetcher
      schemaStore = { enable = false, url = "" },
      schemas = yaml_schemas,
      redhat = { telemetry = { enabled = true } },
    },
  },
})

vim.lsp.config("copilot", {
  filetypes = {
    "typescript",
    "javascript",
    "typescriptreact",
    "javascriptreact",
    "lua",
    "html",
    "css",
    "scss",
    "json",
    "sh",
    "zsh",
    "text",
    "markdown",
  },
})

vim.lsp.enable({
  "vtsls",
  "biome",
  "lua_ls",
  "dockerls",
  "docker_compose_language_service",
  "html",
  "cssls",
  "jsonls",
  "yamlls",
  "copilot",
})

-- 5. LSP Action Helpers
local M = {}

function M.on_file_move(old_name, new_name)
  local clients = vim.lsp.get_clients({ name = "vtsls" })
  for _, client in ipairs(clients) do
    if client:supports_method("workspace/willRenameFiles") then
      local resp = client:request_sync("workspace/willRenameFiles", {
        files = {
          {
            oldUri = vim.uri_from_fname(old_name),
            newUri = vim.uri_from_fname(new_name),
          },
        },
      }, 1000, 0)
      if resp and resp.result ~= nil then
        vim.lsp.util.apply_workspace_edit(resp.result, client.offset_encoding)
      end
    end
  end
end

local function toggle_inlay_hints()
  local state = require("core.state")
  local enabled = not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
  vim.lsp.inlay_hint.enable(enabled, { bufnr = 0 })
  state.set("inlay_hints", enabled)
  vim.notify("Inlay Hints: " .. (enabled and "ON" or "OFF") .. " (saved for " .. state.get_project_key() .. ")")
end

-- TypeScript "Go to Source Definition" (jumps past .d.ts to actual .ts/.js source on imports)
local function go_to_source_definition()
  local clients = vim.lsp.get_clients({ bufnr = 0, name = "vtsls" })
  if #clients > 0 then
    local client = clients[1]
    local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
    client:exec_cmd({
      command = "typescript.goToSourceDefinition",
      title = "Go to Source Definition",
      arguments = { params.textDocument.uri, params.position },
    }, { bufnr = 0 }, function(err, result)
      if err or not result or vim.tbl_isempty(result) then
        require("telescope.builtin").lsp_definitions()
        return
      end
      vim.lsp.util.show_document(result[1], client.offset_encoding, { focus = true })
    end)
  else
    require("telescope.builtin").lsp_definitions()
  end
end

-- TypeScript Import Actions (Organize Imports & Add Missing Imports)
local function ts_code_action_by_kind(kind)
  vim.lsp.buf.code_action({
    context = {
      only = { kind },
      diagnostics = vim.diagnostic.get(0),
    },
    apply = true,
  })
end

_G.lsp_go_to_source_def = go_to_source_definition
_G.lsp_organize_imports = function()
  ts_code_action_by_kind("source.organizeImports")
end

-- ============================================================================
-- 6. Keymaps, Which-Key Group & Right-Click Context Menu
-- ============================================================================

local ok_wk, wk = pcall(require, "which-key")
if ok_wk then
  wk.add({
    { "<leader>c", group = "Code / TypeScript LSP" },
  })
end

map("i", "<Tab>", function()
  if not vim.lsp.inline_completion.get() then
    return "<Tab>"
  end
end, { expr = true, replace_keycodes = true, desc = "Accept inline completion (Copilot)" })

map("i", "<M-]>", function()
  vim.lsp.inline_completion.select({ count = 1 })
end, { desc = "Next Copilot inline suggestion" })

map("i", "<M-[>", function()
  vim.lsp.inline_completion.select({ count = -1 })
end, { desc = "Previous Copilot inline suggestion" })

map({ "n", "i", "v" }, "<M-i>", toggle_inlay_hints, { desc = "Toggle Inline Type Hints (Inlay Hints)" })
map("n", "<leader>ci", toggle_inlay_hints, { desc = "Toggle Inline Type Hints (Inlay Hints)" })
map("n", "<leader>ti", toggle_inlay_hints, { desc = "Toggle Inline Type Hints (Inlay Hints)" })

map("i", "<C-Space>", function()
  vim.lsp.completion.get()
end, { desc = "Trigger IntelliSense completion (Ctrl+Space)" })

map("n", "K", function()
  vim.lsp.buf.hover()
end, { desc = "Show Type / Hover Info" })

map({ "n", "i" }, "<C-LeftMouse>", "<LeftMouse><cmd>lua vim.lsp.buf.hover()<CR>", {
  desc = "Show Type / Hover Info at mouse click (Ctrl+Click)",
})
map({ "n", "i" }, "<M-LeftMouse>", "<LeftMouse><cmd>lua require('telescope.builtin').lsp_definitions()<CR>", {
  desc = "Go to Definition / Reference at mouse click (Alt/Option+Click)",
})

map("i", "<C-k>", function()
  vim.lsp.buf.signature_help()
end, { desc = "Show Function Signature Help" })

map("n", "gy", function()
  require("telescope.builtin").lsp_type_definitions()
end, { desc = "Go to Type Definition" })

map("n", "gi", function()
  require("telescope.builtin").lsp_implementations()
end, { desc = "Go to Implementation" })

map("n", "gD", go_to_source_definition, { desc = "Go to Source Definition (skip .d.ts)" })
map("n", "<leader>cs", go_to_source_definition, { desc = "Go to Source Definition (skip .d.ts)" })

map("n", "<leader>co", function()
  ts_code_action_by_kind("source.organizeImports")
end, { desc = "Organize Imports (sort & remove unused)" })

map("n", "<leader>cm", function()
  ts_code_action_by_kind("source.addMissingImports.ts")
end, { desc = "Add All Missing Imports" })

map("n", "<leader>ct", function()
  require("telescope.builtin").lsp_type_definitions()
end, { desc = "Go to Type Definition" })

map({ "n", "v" }, "<leader>ca", function()
  vim.lsp.buf.code_action()
end, { desc = "Code Action / Quick Fix / Auto-Import" })

map("n", "<leader>cr", function()
  vim.lsp.buf.rename()
end, { desc = "Rename Symbol" })

map("n", "<leader>cd", function()
  vim.diagnostic.open_float()
end, { desc = "Show Line Type Error / Diagnostic" })

map("n", "<leader>cl", function()
  vim.lsp.codelens.run()
end, { desc = "Run LSP CodeLens" })

require("core.context-menu").register("editor", {
  { priority = "100.10", label = "Show Type / Hover Info", cmd = "<Cmd>lua vim.lsp.buf.hover()<CR>" },
  { priority = "100.20", label = "Go to Source Definition", cmd = "<Cmd>lua _G.lsp_go_to_source_def()<CR>" },
  { priority = "100.30", label = "Go to Type Definition", cmd = '<Cmd>lua require("telescope.builtin").lsp_type_definitions()<CR>' },
  { priority = "100.40", label = "Go to Implementation", cmd = '<Cmd>lua require("telescope.builtin").lsp_implementations()<CR>' },
  { priority = "100.50", label = "Find All References", cmd = '<Cmd>lua require("telescope.builtin").lsp_references()<CR>' },
  { priority = "100.60", label = "Code Action / Auto-Import", cmd = "<Cmd>lua vim.lsp.buf.code_action()<CR>" },
  { priority = "100.70", label = "Organize Imports", cmd = "<Cmd>lua _G.lsp_organize_imports()<CR>" },
  { priority = "100.80", label = "Rename Symbol", cmd = "<Cmd>lua vim.lsp.buf.rename()<CR>" },
  { priority = "100.99", sep = "-lsp-sep-" },
})

return M
