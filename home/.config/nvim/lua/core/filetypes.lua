-- ============================================================================
-- Filetype Associations (mapped from VS Code "files.associations")
-- ============================================================================

vim.filetype.add({
  extension = {
    svg = "html",
    mjs = "javascript",
  },
  pattern = {
    [".*/www/.*%.js"] = { "text", { priority = 10 } },
    [".*/www/.*%.ts"] = { "text", { priority = 10 } },
  },
})
