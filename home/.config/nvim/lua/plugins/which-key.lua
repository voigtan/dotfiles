-- ============================================================================
-- Which-Key Popup Guide
-- Note: Group headers and custom icons are colocated in their respective
-- feature files (telescope.lua, git.lua, testing.lua, bufferline.lua, lsp.lua, terminals.lua)
-- ============================================================================

local ok_wk, wk = pcall(require, "which-key")
if ok_wk then
  wk.setup({
    preset = "modern",
    delay = 200,
  })
end

vim.keymap.set("n", "<leader>?", function()
  require("which-key").show({ global = false })
end, { desc = "Buffer Local Keymaps (which-key)" })
