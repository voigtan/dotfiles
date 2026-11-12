-- ============================================================================
-- Core Editor Options (mapped from VS Code settings.json)
-- ============================================================================

local opt = vim.opt
local map = vim.keymap.set

-- UI & General
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes:2" -- 2 sign slots so Neotest (✔/✖), Coverage (▎), and Git/LSP signs never collide
opt.cursorline = true
opt.termguicolors = true
opt.showmode = false
opt.laststatus = 3 -- Global statusbar at the bottom (like VS Code)
opt.cmdheight = 0 -- Push Lualine to the very bottom edge of the screen

-- Native Neovim 0.12 UI2: floating notification/message window above Lualine for cmdheight = 0
pcall(function()
  require("vim._core.ui2").enable({
    enable = true,
    msg = {
      targets = "msg",
      msg = {
        height = 0.5,
        timeout = 4000,
      },
    },
  })
end)
opt.updatetime = 250
opt.timeoutlen = 500
opt.splitright = true
opt.splitbelow = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.mouse = "a"
opt.clipboard = "unnamedplus"
opt.undofile = true
opt.swapfile = false

-- "workbench.editor.revealIfOpen": true
opt.switchbuf = "useopen,usetab"

-- Indentation defaults
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.smartindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.inccommand = "split"

-- "editor.renderWhitespace": "all"
opt.list = true
opt.listchars = {
  space = "·",
  tab = "→ ",
  trail = "·",
  nbsp = "␣",
  extends = "⟩",
  precedes = "⟨",
}

-- "editor.renderControlCharacters": true
opt.display:append("uhex")

-- "diffEditor.ignoreTrimWhitespace": true
opt.diffopt:append("iwhite")

-- "cSpell.language": "en-GB" (+ Swedish "sv") & "cSpell.userWords" (see spell/en.utf-8.add)
-- Native Neovim 0.12 auto-downloader for any language added to `opt.spelllang`
pcall(function()
  require("nvim.spellfile").config({ confirm = false })
  vim.cmd("runtime plugin/spellfile.lua")
end)
opt.spell = true
opt.spelllang = { "en_gb", "sv" }
opt.spelloptions = "camel"
opt.spellfile = vim.fn.stdpath("config") .. "/spell/en.utf-8.add"

-- Native Neovim 0.12 completion menu & floating window border
opt.completeopt = { "menuone", "noselect", "popup" }
opt.winborder = "rounded"

-- "terminal.integrated.defaultProfile.osx": "zsh"
opt.shell = "/bin/zsh"

-- "editor.fontFamily": "'Monaspace Neon', monospace" (for GUI clients like Neovide)
opt.guifont = "Monaspace Neon:h13"

-- Highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("CoreYankHighlight", { clear = true }),
  desc = "Highlight yanked text",
  callback = function()
    vim.hl.on_yank({ timeout = 200 })
  end,
})

-- Native Neovim 0.12 Undo Tree (`nvim.undotree`)
pcall(vim.cmd.packadd, "nvim.undotree")

local function toggle_undotree()
  -- If an Undotree window is already open anywhere in the tabpage, close it and focus the editor
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "nvim-undotree" then
      pcall(vim.api.nvim_win_close, win, true)
      if _G.win_nav and _G.win_nav.focus_editor then
        _G.win_nav.focus_editor()
      end
      return
    end
  end

  if vim.bo.filetype == "neo-tree" or vim.bo.filetype == "neotest-summary" or vim.bo.buftype == "terminal" then
    if _G.win_nav and _G.win_nav.focus_editor then
      _G.win_nav.focus_editor()
    end
  end

  local ok_ut, undotree = pcall(require, "undotree")
  if ok_ut then
    undotree.open({ command = "botright 35vnew" })
  end
end

vim.api.nvim_create_user_command("ToggleUndotree", toggle_undotree, { desc = "Toggle native Neovim Undo Tree" })

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("CoreNativeUndotree", { clear = true }),
  pattern = "nvim-undotree",
  callback = function(args)
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
    vim.opt_local.list = false
    vim.opt_local.spell = false
    vim.opt_local.colorcolumn = ""
    vim.opt_local.winfixwidth = true
    map("n", "q", "<Cmd>ToggleUndotree<CR>", { buffer = args.buf, silent = true, desc = "Close Undo Tree" })
    map("n", "<Esc>", "<Cmd>ToggleUndotree<CR>", { buffer = args.buf, silent = true, desc = "Close Undo Tree" })
  end,
})

-- ============================================================================
-- Keymaps & Context Menu Bindings
-- ============================================================================

-- Clear search highlight on <Esc>
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlights" })

-- Paste over selection & Delete/Change without overwriting yanked text (black-hole register `"_`)
map("x", "p", "P", { desc = "Paste over selection without losing yanked text" })
map({ "n", "x" }, "x", '"_x', { desc = "Delete character without yanking" })
map({ "n", "x" }, "X", '"_X', { desc = "Delete character before cursor without yanking" })
map({ "n", "x" }, "<Del>", '"_x', { desc = "Delete character without yanking" })
-- map({ "n", "x" }, "<leader>D", '"_d', { desc = "Delete without yanking (black-hole)" })
-- map({ "n", "x" }, "<leader>C", '"_c', { desc = "Change without yanking (black-hole)" })

-- Swedish Keyboard Normal/Visual/Operator Ergonomics (å/ä -> [/], Å/Ä -> {/}, ö/Ö -> ^/$)
-- Eliminates needing Option+8/9 or Option+Shift+8/9 for bracket motions & paragraph/line jumps
map({ "n", "x", "o" }, "å", "[", { remap = true, desc = "Previous '[' motion (Swedish å)" })
map({ "n", "x", "o" }, "ä", "]", { remap = true, desc = "Next ']' motion (Swedish ä)" })
map({ "n", "x", "o" }, "Å", "{", { desc = "Paragraph up '{' (Swedish Å)" })
map({ "n", "x", "o" }, "Ä", "}", { desc = "Paragraph down '}' (Swedish Ä)" })
map({ "n", "x", "o" }, "ö", "^", { desc = "Start of line '^' (Swedish ö)" })
map({ "n", "x", "o" }, "Ö", "$", { desc = "End of line '$' (Swedish Ö)" })

-- Right-Click Context Menu: Toggle Comment
require("core.context-menu").register("editor", {
  { priority = "100.82", label = "Toggle Comment (gcc)", cmd = "gcc", mode = "n", remap = true },
  { priority = "100.82", label = "Toggle Comment (gc)", cmd = "gc", mode = "v", remap = true },
})

-- Options / UI Toggles group (<Space>o), Native Undo Tree toggle (<Space>ou) & Restart (<Space>r)
vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("CoreOptionsWhichKey", { clear = true }),
  once = true,
  callback = function()
    local ok_wk, wk = pcall(require, "which-key")
    if ok_wk then
      wk.add({
        { "<leader>o", group = "Options / UI Toggles", icon = { icon = " ", color = "yellow" } },
        { "<leader>ou", icon = { icon = "󰕌 ", color = "purple" } },
        { "<leader>r", icon = { icon = "󰜉 ", color = "orange" } },
      })
    end
  end,
})

map("n", "<leader>ou", "<Cmd>ToggleUndotree<CR>", { desc = "Toggle Undo Tree" })
map("n", "<leader>r", "<cmd>restart<cr>", { desc = "Restart Neovim" })
