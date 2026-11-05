-- ============================================================================
-- Treesitter & Sticky Scroll ("editor.stickyScroll.enabled": true)
-- Compatible with Neovim 0.12 & nvim-treesitter (main branch)
-- ============================================================================

local desired_parsers = {
  "javascript",
  "typescript",
  "tsx",
  "dockerfile",
  "html",
  "css",
  "scss",
  "json",
  "yaml",
  "php",
}

local ok_ts, ts = pcall(require, "nvim-treesitter")
if ok_ts and type(ts.get_installed) == "function" then
  local installed = {}
  for _, lang in ipairs(ts.get_installed()) do
    installed[lang] = true
  end
  local missing = {}
  for _, lang in ipairs(desired_parsers) do
    if not installed[lang] then
      table.insert(missing, lang)
    end
  end
  if #missing > 0 and vim.fn.executable("tree-sitter") == 1 then
    ts.install(missing)
  end
end

-- Enable native Neovim 0.12 treesitter highlighting on every buffer with a parser
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("NativeTreesitterStart", { clear = true }),
  callback = function(args)
    pcall(vim.treesitter.start, args.buf)
  end,
})

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
