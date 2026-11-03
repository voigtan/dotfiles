-- ============================================================================
-- Formatting (Conform.nvim: Prettier on save for JS/TS/CSS/SCSS, LSP for HTML/JSON)
-- ============================================================================

local ok_conform, conform = pcall(require, "conform")
if ok_conform then
  local format_on_save_ft = {
    javascript = true,
    javascriptreact = true,
    typescript = true,
    typescriptreact = true,
    css = true,
    scss = true,
    html = true,
    -- Note: json has defaultFormatter in VS Code but NOT formatOnSave
  }

  conform.setup({
    formatters_by_ft = {
      javascript = { "prettier" },
      javascriptreact = { "prettier" },
      typescript = { "prettier" },
      typescriptreact = { "prettier" },
      css = { "prettier" },
      scss = { "prettier" },
      html = { lsp_format = "prefer" },
      json = { lsp_format = "prefer" },
    },
    format_on_save = function(bufnr)
      local ft = vim.bo[bufnr].filetype
      if not format_on_save_ft[ft] then
        return nil
      end
      if ft == "html" then
        return { timeout_ms = 2000, lsp_format = "prefer" }
      end
      return { timeout_ms = 2000, lsp_format = "fallback" }
    end,
  })
end

vim.keymap.set({ "n", "v" }, "<leader>f", function()
  if ok_conform then
    conform.format({ async = true, lsp_format = "fallback" })
  else
    vim.lsp.buf.format({ async = true })
  end
end, { desc = "Format buffer / selection" })
