-- ============================================================================
-- Filetype Associations (mapped from VS Code "files.associations")
-- ============================================================================

vim.filetype.add({
  extension = {
    svg = "html",
    mjs = "javascript",
  },
  pattern = {
    [".*/docker%-compose.*%.ya?ml"] = "yaml.docker-compose",
    [".*/compose.*%.ya?ml"] = "yaml.docker-compose",
  },
})
