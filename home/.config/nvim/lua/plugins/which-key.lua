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
    icons = {
      group = "", -- Default is "+" (use "" to remove the +, or "+ " to add a space)
    },
    sort = {
      "local",
      "order",
      "group",
      function(node)
        -- Group items with the same action verb together (e.g. "Open Terminal..." together, "Toggle..." together)
        return (node.desc or ""):match("^(%S+)") or ""
      end,
      "alphanum",
      "mod",
    },
  })
end

vim.keymap.set("n", "<leader>?", function()
  require("which-key").show({ global = false })
end, { desc = "Buffer Local Keymaps (which-key)" })
