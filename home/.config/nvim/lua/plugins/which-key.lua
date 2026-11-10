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
    -- Auto-expand small subgroups (<= 2 items) inline so you don't need an extra keypress
    expand = 2,
    win = {
      -- Never shrink the popup to 4 lines when the cursor happens to be near the bottom of the screen
      no_overlap = false,
      width = 0.95,
      height = { min = 6, max = 0.80 },
      padding = { 1, 2 },
      border = "rounded",
      title = true,
      title_pos = "center",
    },
    layout = {
      -- Cap column width so long descriptions don't force a single tall column; fits 3-4 columns side-by-side
      width = { min = 20, max = 38 },
      spacing = 3,
    },
    keys = {
      scroll_down = "<Down>",
      scroll_up = "<Up>",
    },
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

  -- Also allow <C-d>/<C-u> and <PageDown>/<PageUp> to scroll in addition to <Down>/<Up>
  local ok_state, wk_state = pcall(require, "which-key.state")
  local ok_view, wk_view = pcall(require, "which-key.view")
  if ok_state and ok_view then
    local orig_check = wk_state.check
    wk_state.check = function(state, key)
      if wk_view.valid() then
        if key == "<C-D>" or key == "<PageDown>" then
          wk_view.scroll(false)
          return state.node
        elseif key == "<C-U>" or key == "<PageUp>" then
          wk_view.scroll(true)
          return state.node
        end
      end
      return orig_check(state, key)
    end
  end
end

vim.keymap.set("n", "<leader>?", function()
  require("which-key").show({ global = false })
end, { desc = "Buffer Local Keymaps (which-key)" })
