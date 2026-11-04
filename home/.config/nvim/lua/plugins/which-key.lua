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

  -- Allow <C-c> as a second chord key inside Which-Key (e.g. <C-k><C-c> to comment lines)
  -- Normally Neovim's `getcharstr()` throws `Vim:Interrupt` on Ctrl+C, causing Which-Key to abort.
  -- local ok_state, wk_state = pcall(require, "which-key.state")
  -- if ok_state then
  --   wk_state.getchar = function()
  --     local ok, char = pcall(vim.fn.getcharstr)
  --     if not ok and tostring(char):find("Interrupt") then
  --       if wk_state.state and wk_state.state.node and wk_state.state.node:find("<C-C>") then
  --         return true, "\x03"
  --       end
  --     end
  --     return ok, char
  --   end
  -- end
end

vim.keymap.set("n", "<leader>?", function()
  require("which-key").show({ global = false })
end, { desc = "Buffer Local Keymaps (which-key)" })
