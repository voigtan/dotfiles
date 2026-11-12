-- ============================================================================
-- VS Code / macOS Keybindings Mode (Cmd+D Multi-Cursor, Shift+Arrow Selection,
-- Option+Arrow Word Jump, Option+j/k Line Move, Cmd+S/W/C/X/V/Z/A + Toggle)
-- ============================================================================

local state = require("core.state")
local map = vim.keymap.set

local ok_mc, mc = pcall(require, "multicursor-nvim")
if ok_mc then
  mc.setup()

  -- When multiple cursors are active, <Esc> clears extra cursors; otherwise clears search highlights
  mc.addKeymapLayer(function(layerSet)
    layerSet({ "n", "x" }, "<left>", mc.prevCursor)
    layerSet({ "n", "x" }, "<right>", mc.nextCursor)
    layerSet({ "n", "x" }, "<leader>x", mc.deleteCursor)
    layerSet("n", "<Esc>", function()
      if not mc.cursorsEnabled() then
        mc.enableCursors()
      else
        mc.clearCursors()
      end
    end)
  end)
end

local function close_current_tab()
  if _G.close_buffer_tab then
    _G.close_buffer_tab(0, false)
  else
    vim.cmd("bdelete")
  end
end

local function match_add_cursor(direction)
  if ok_mc then
    mc.matchAddCursor(direction)
  else
    -- Native fallback: select word under cursor / next search match
    vim.cmd("normal! *Ngn")
  end
end

local function match_skip_cursor(direction)
  if ok_mc then
    mc.matchSkipCursor(direction)
  end
end

-- All keybindings managed by :ToggleVSCodeKeys
local vscode_bindings = {
  -- 1. Save & Close (Cmd+S, Cmd+W)
  { { "n", "x" }, "<D-s>", "<Cmd>write<CR>", { desc = "Save file (VS Code)" } },
  { "i", "<D-s>", "<Cmd>write<CR>", { desc = "Save file (VS Code)" } },
  { { "n", "x" }, "<D-w>", close_current_tab, { desc = "Close file tab (VS Code)" } },
  {
    "i",
    "<D-w>",
    function()
      vim.cmd("stopinsert")
      close_current_tab()
    end,
    { desc = "Close file tab (VS Code)" },
  },

  -- 2. Clipboard: Copy, Cut, Paste (Cmd+C, Cmd+X, Cmd+V)
  { "n", "<D-c>", '"+yy', { desc = "Copy current line (VS Code)" } },
  { "n", "<D-x>", '"+dd', { desc = "Cut current line (VS Code)" } },
  { "n", "<D-v>", '"+p', { desc = "Paste from clipboard (VS Code)" } },
  { "x", "<D-c>", '"+y', { desc = "Copy selection (VS Code)" } },
  { "x", "<D-x>", '"+d', { desc = "Cut selection (VS Code)" } },
  { "x", "<D-v>", '"_d"+P', { desc = "Paste over selection (VS Code)" } },
  { "s", "<D-c>", '<C-g>"+y', { desc = "Copy selection (VS Code)" } },
  { "s", "<D-x>", '<C-g>"+d', { desc = "Cut selection (VS Code)" } },
  { "s", "<D-v>", '<C-g>"_d"+P', { desc = "Paste over selection (VS Code)" } },
  { "i", "<D-c>", "<Cmd>normal! \"+yy<CR>", { desc = "Copy line (VS Code)" } },
  { "i", "<D-x>", "<Cmd>normal! \"+dd<CR>", { desc = "Cut line (VS Code)" } },
  { "i", "<D-v>", "<C-r><C-o>+", { desc = "Paste from clipboard (VS Code)" } },
  { "c", "<D-v>", "<C-r>+", { desc = "Paste from clipboard (VS Code)" } },

  -- 3. Undo, Redo & Select All (Cmd+Z, Cmd+Shift+Z, Cmd+A)
  { "n", "<D-z>", "u", { desc = "Undo (VS Code)" } },
  { "i", "<D-z>", "<C-o>u", { desc = "Undo (VS Code)" } },
  { "x", "<D-z>", "<Esc>u", { desc = "Undo (VS Code)" } },
  { "n", "<D-S-z>", "<C-r>", { desc = "Redo (VS Code)" } },
  { "i", "<D-S-z>", "<C-o><C-r>", { desc = "Redo (VS Code)" } },
  { "x", "<D-S-z>", "<Esc><C-r>", { desc = "Redo (VS Code)" } },
  { { "n", "x" }, "<D-a>", "ggVG", { desc = "Select all (VS Code)" } },
  { "i", "<D-a>", "<Esc>ggVG", { desc = "Select all (VS Code)" } },

  -- 4. Toggle Comment (Cmd+/, Swedish Cmd+Shift+7 & Cmd+' , and Cmd+K Cmd+C)
  { "n", "<D-/>", "gcc", { remap = true, desc = "Toggle comment on line (VS Code)" } },
  { "i", "<D-/>", "<Esc><Cmd>normal gcc<CR>a", { desc = "Toggle comment on line (VS Code)" } },
  { "x", "<D-/>", "gcgv", { remap = true, desc = "Toggle comment on selection (VS Code)" } },
  { "n", "<D-S-7>", "gcc", { remap = true, desc = "Toggle comment on line (VS Code)" } },
  { "i", "<D-S-7>", "<Esc><Cmd>normal gcc<CR>a", { desc = "Toggle comment on line (VS Code)" } },
  { "x", "<D-S-7>", "gcgv", { remap = true, desc = "Toggle comment on selection (VS Code)" } },
  { "n", "<D-'>", "gcc", { remap = true, desc = "Toggle comment on line (VS Code)" } },
  { "i", "<D-'>", "<Esc><Cmd>normal gcc<CR>a", { desc = "Toggle comment on line (VS Code)" } },
  { "x", "<D-'>", "gcgv", { remap = true, desc = "Toggle comment on selection (VS Code)" } },
  { "n", "<D-k><D-c>", "gcc", { remap = true, desc = "Toggle comment on line (VS Code)" } },
  { "i", "<D-k><D-c>", "<Esc><Cmd>normal gcc<CR>a", { desc = "Toggle comment on line (VS Code)" } },
  { "x", "<D-k><D-c>", "gcgv", { remap = true, desc = "Toggle comment on selection (VS Code)" } },

  -- 5. Multi-Cursor: Select Next Occurrence (Cmd+D) & Skip Occurrence (Cmd+K Cmd+D)
  {
    { "n", "x" },
    "<D-d>",
    function()
      match_add_cursor(1)
    end,
    { desc = "Add cursor to next occurrence (Cmd+D)" },
  },
  {
    "i",
    "<D-d>",
    function()
      vim.cmd("stopinsert")
      match_add_cursor(1)
    end,
    { desc = "Add cursor to next occurrence (Cmd+D)" },
  },
  {
    { "n", "x" },
    "<D-k><D-d>",
    function()
      match_skip_cursor(1)
    end,
    { desc = "Skip current occurrence & add next (Cmd+K Cmd+D)" },
  },

  -- 6. Move Lines Up/Down (Option+j/k, Option+Down/Up & Swedish macOS Option+j/k ``/`ª`)
  {
    "n",
    "<A-j>",
    "<Cmd>execute 'move .+' . v:count1<CR>==",
    { silent = true, desc = "Move line down (VS Code)" },
  },
  {
    "n",
    "<A-Down>",
    "<Cmd>execute 'move .+' . v:count1<CR>==",
    { silent = true, desc = "Move line down (VS Code)" },
  },
  {
    "n",
    "",
    "<Cmd>execute 'move .+' . v:count1<CR>==",
    { silent = true, desc = "Move line down (VS Code)" },
  },
  { "i", "<A-j>", "<Esc><Cmd>m .+1<CR>==gi", { silent = true, desc = "Move line down (VS Code)" } },
  { "i", "<A-Down>", "<Esc><Cmd>m .+1<CR>==gi", { silent = true, desc = "Move line down (VS Code)" } },
  { "i", "", "<Esc><Cmd>m .+1<CR>==gi", { silent = true, desc = "Move line down (VS Code)" } },
  {
    "x",
    "<A-j>",
    ":<C-u>execute \"'<,'>move '>+\" . v:count1<CR>gv=gv",
    { silent = true, desc = "Move selection down (VS Code)" },
  },
  {
    "x",
    "<A-Down>",
    ":<C-u>execute \"'<,'>move '>+\" . v:count1<CR>gv=gv",
    { silent = true, desc = "Move selection down (VS Code)" },
  },
  {
    "x",
    "",
    ":<C-u>execute \"'<,'>move '>+\" . v:count1<CR>gv=gv",
    { silent = true, desc = "Move selection down (VS Code)" },
  },

  {
    "n",
    "<A-k>",
    "<Cmd>execute 'move .-' . (v:count1 + 1)<CR>==",
    { silent = true, desc = "Move line up (VS Code)" },
  },
  {
    "n",
    "<A-Up>",
    "<Cmd>execute 'move .-' . (v:count1 + 1)<CR>==",
    { silent = true, desc = "Move line up (VS Code)" },
  },
  {
    "n",
    "ª",
    "<Cmd>execute 'move .-' . (v:count1 + 1)<CR>==",
    { silent = true, desc = "Move line up (VS Code)" },
  },
  { "i", "<A-k>", "<Esc><Cmd>m .-2<CR>==gi", { silent = true, desc = "Move line up (VS Code)" } },
  { "i", "<A-Up>", "<Esc><Cmd>m .-2<CR>==gi", { silent = true, desc = "Move line up (VS Code)" } },
  { "i", "ª", "<Esc><Cmd>m .-2<CR>==gi", { silent = true, desc = "Move line up (VS Code)" } },
  {
    "x",
    "<A-k>",
    ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<CR>gv=gv",
    { silent = true, desc = "Move selection up (VS Code)" },
  },
  {
    "x",
    "<A-Up>",
    ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<CR>gv=gv",
    { silent = true, desc = "Move selection up (VS Code)" },
  },
  {
    "x",
    "ª",
    ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<CR>gv=gv",
    { silent = true, desc = "Move selection up (VS Code)" },
  },

  -- 7. Duplicate Line / Selection Up & Down (Option+Shift+Down / Option+Shift+Up)
  { "n", "<M-S-Down>", "<Cmd>t.<CR>", { silent = true, desc = "Duplicate line down (VS Code)" } },
  { "i", "<M-S-Down>", "<C-o><Cmd>t.<CR>", { silent = true, desc = "Duplicate line down (VS Code)" } },
  { "x", "<M-S-Down>", ":<C-u>'<,'>t'><CR>gv", { silent = true, desc = "Duplicate selection down (VS Code)" } },
  { "n", "<M-S-Up>", "<Cmd>t-1<CR>", { silent = true, desc = "Duplicate line up (VS Code)" } },
  { "i", "<M-S-Up>", "<C-o><Cmd>t-1<CR>", { silent = true, desc = "Duplicate line up (VS Code)" } },
  { "x", "<M-S-Up>", ":<C-u>'<,'>t'<-1<CR>gv", { silent = true, desc = "Duplicate selection up (VS Code)" } },

  -- 8. Word & Line Navigation (Option+Left/Right, Cmd+Left/Right)
  { "n", "<M-Left>", "b", { desc = "Move backward one word (VS Code)" } },
  { "n", "<M-Right>", "w", { desc = "Move forward one word (VS Code)" } },
  { "i", "<M-Left>", "<C-o>b", { desc = "Move backward one word (VS Code)" } },
  { "i", "<M-Right>", "<C-o>w", { desc = "Move forward one word (VS Code)" } },
  { "n", "<D-Left>", "^", { desc = "Move to start of line (VS Code)" } },
  { "n", "<D-Right>", "$", { desc = "Move to end of line (VS Code)" } },
  { "i", "<D-Left>", "<C-o>^", { desc = "Move to start of line (VS Code)" } },
  { "i", "<D-Right>", "<C-o>$", { desc = "Move to end of line (VS Code)" } },

  -- 9. Shift+Arrow & Option+Shift+Arrow Selection (Character, Word, and Line Selection)
  { "n", "<S-Left>", "vh", { desc = "Select character left (VS Code)" } },
  { "n", "<S-Right>", "vl", { desc = "Select character right (VS Code)" } },
  { "n", "<S-Up>", "vk", { desc = "Select line up (VS Code)" } },
  { "n", "<S-Down>", "vj", { desc = "Select line down (VS Code)" } },
  { "x", "<S-Left>", "h", { desc = "Extend selection left (VS Code)" } },
  { "x", "<S-Right>", "l", { desc = "Extend selection right (VS Code)" } },
  { "x", "<S-Up>", "k", { desc = "Extend selection up (VS Code)" } },
  { "x", "<S-Down>", "j", { desc = "Extend selection down (VS Code)" } },
  { "i", "<S-Left>", "<Esc>vh", { desc = "Select character left (VS Code)" } },
  { "i", "<S-Right>", "<Esc>vl", { desc = "Select character right (VS Code)" } },
  { "i", "<S-Up>", "<Esc>vk", { desc = "Select line up (VS Code)" } },
  { "i", "<S-Down>", "<Esc>vj", { desc = "Select line down (VS Code)" } },

  { "n", "<M-S-Left>", "vb", { desc = "Select word left (VS Code)" } },
  { "n", "<M-S-Right>", "ve", { desc = "Select word right (VS Code)" } },
  { "x", "<M-S-Left>", "b", { desc = "Extend selection word left (VS Code)" } },
  { "x", "<M-S-Right>", "e", { desc = "Extend selection word right (VS Code)" } },
  { "i", "<M-S-Left>", "<Esc>vb", { desc = "Select word left (VS Code)" } },
  { "i", "<M-S-Right>", "<Esc>ve", { desc = "Select word right (VS Code)" } },

  { "n", "<D-S-Left>", "v^", { desc = "Select to start of line (VS Code)" } },
  { "n", "<D-S-Right>", "v$h", { desc = "Select to end of line (VS Code)" } },
  { "x", "<D-S-Left>", "^", { desc = "Extend selection to start of line (VS Code)" } },
  { "x", "<D-S-Right>", "$h", { desc = "Extend selection to end of line (VS Code)" } },
  { "i", "<D-S-Left>", "<Esc>v^", { desc = "Select to start of line (VS Code)" } },
  { "i", "<D-S-Right>", "<Esc>v$h", { desc = "Select to end of line (VS Code)" } },
}

local function apply_vscode_keys(enabled)
  vim.g.vscode_keys_enabled = enabled
  if enabled then
    vim.opt.keymodel = "startsel,stopsel"
    for _, b in ipairs(vscode_bindings) do
      map(b[1], b[2], b[3], b[4])
    end
  else
    vim.opt.keymodel = ""
    for _, b in ipairs(vscode_bindings) do
      pcall(vim.keymap.del, b[1], b[2])
    end
  end
end

apply_vscode_keys(state.get("vscode_keys", true))

vim.api.nvim_create_user_command("ToggleVSCodeKeys", function()
  local next_state = not vim.g.vscode_keys_enabled
  state.set("vscode_keys", next_state)
  apply_vscode_keys(next_state)
  local ok_ll, lualine = pcall(require, "lualine")
  if ok_ll then
    lualine.refresh()
  end
  vim.notify(
    string.format(
      "VS Code Keybindings: %s (saved for %s)",
      next_state and "ON" or "OFF",
      state.get_project_key()
    )
  )
end, { desc = "Toggle VS Code / macOS keybindings (Cmd+D, Shift+Arrows, Option+j/k, Cmd+S/C/V)" })

-- ============================================================================
-- Keymaps, Which-Key & Context Menu
-- ============================================================================

vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("CoreVSCodeWhichKey", { clear = true }),
  once = true,
  callback = function()
    local ok_wk, wk = pcall(require, "which-key")
    if ok_wk then
      wk.add({
        { "<leader>ov", icon = { icon = "󰨞 ", color = "azure" } },
      })
    end
  end,
})

map("n", "<leader>ov", "<Cmd>ToggleVSCodeKeys<CR>", { desc = "Toggle VS Code Keybindings" })

require("core.context-menu").register("editor", {
  { priority = "100.88", label = "Toggle VS Code Keybindings (<Space>ov)", cmd = "<Cmd>ToggleVSCodeKeys<CR>" },
})
