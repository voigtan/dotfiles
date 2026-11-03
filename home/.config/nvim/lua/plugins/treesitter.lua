-- ============================================================================
-- Treesitter & Sticky Scroll ("editor.stickyScroll.enabled": true)
-- ============================================================================

local ok_ts, ts_configs = pcall(require, "nvim-treesitter.configs")
if ok_ts then
  ts_configs.setup({
    ensure_installed = {
      "javascript",
      "typescript",
      "tsx",
      "html",
      "css",
      "scss",
      "json",
      "yaml",
      "php",
      "markdown",
      "markdown_inline",
      "bash",
      "lua",
      "vim",
      "vimdoc",
    },
    auto_install = true,
    highlight = { enable = true },
    indent = { enable = true },
  })
else
  vim.api.nvim_create_autocmd("FileType", {
    callback = function(args)
      pcall(vim.treesitter.start, args.buf)
    end,
  })
end

local ok_ctx, ts_context = pcall(require, "treesitter-context")
if ok_ctx then
  ts_context.setup({
    enable = true,
    max_lines = 4,
    min_window_height = 0,
    line_numbers = true,
    multiline_threshold = 20,
    trim_scope = "outer",
    mode = "cursor",
  })
end
