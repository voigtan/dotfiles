-- ============================================================================
-- Flash.nvim (Fast On-Screen Jump & Treesitter Node Selection)
-- ============================================================================

local map = vim.keymap.set

local ok_flash, flash = pcall(require, "flash")
if ok_flash then
  flash.setup({
    labels = "asdfghjklqwertyuiopzxcvbnm",
    search = {
      multi_window = true,
    },
    modes = {
      char = {
        enabled = true, -- Enhances built-in f, F, t, T motions with jump labels
        jump_labels = true,
      },
    },
  })
end

-- Keymaps
map({ "n", "x", "o" }, "s", function()
  require("flash").jump()
end, { desc = "Flash Jump" })

map({ "n", "x", "o" }, "S", function()
  require("flash").treesitter()
end, { desc = "Flash Treesitter Node Select" })

map("o", "r", function()
  require("flash").remote()
end, { desc = "Remote Flash (act on text without moving cursor)" })

map({ "o", "x" }, "R", function()
  require("flash").treesitter_search()
end, { desc = "Flash Treesitter Search" })

map("c", "<C-s>", function()
  require("flash").toggle()
end, { desc = "Toggle Flash Search in / or ?" })
