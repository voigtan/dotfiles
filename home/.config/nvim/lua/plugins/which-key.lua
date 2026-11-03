-- ============================================================================
-- Which-Key Popup Guide
-- ============================================================================

local ok_wk, wk = pcall(require, "which-key")
if ok_wk then
  wk.setup({
    preset = "modern",
    delay = 200,
    spec = {
      { "<leader>b", group = "Buffers / File Tabs" },
      { "<leader>f", group = "Find / Format" },
      { "<leader>g", group = "Git / Inline Diffs" },
      { "<leader>t", group = "Terminal / Toggles" },
      { "<leader>c", group = "Code / TypeScript LSP" },

      -- Yellow search icon for Telescope grep / all-files / symbol searches
      { "<leader>fF", icon = { icon = " ", color = "yellow" } },
      { "<leader>fg", icon = { icon = " ", color = "yellow" } },
      { "<leader>fG", icon = { icon = " ", color = "yellow" } },
      { "<leader>fs", icon = { icon = " ", color = "yellow" } },
    },
  })
end

vim.keymap.set("n", "<leader>?", function()
  require("which-key").show({ global = false })
end, { desc = "Buffer Local Keymaps (which-key)" })
