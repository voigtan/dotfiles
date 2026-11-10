-- ============================================================================
-- Core Editor Options (mapped from VS Code settings.json)
-- ============================================================================

local opt = vim.opt

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
  -- If currently inside the undotree or another sidebar, focus the code editor first
  if vim.bo.filetype == "nvim-undotree" then
    vim.api.nvim_win_close(0, true)
    if _G.win_nav and _G.win_nav.focus_editor then
      _G.win_nav.focus_editor()
    end
    return
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
    vim.bo[args.buf].bufhidden = "hide"
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
    vim.opt_local.list = false
    vim.opt_local.spell = false
    vim.opt_local.colorcolumn = ""
    vim.opt_local.winfixwidth = true
    vim.keymap.set("n", "q", "<Cmd>ToggleUndotree<CR>", { buffer = args.buf, silent = true, desc = "Close Undo Tree" })
    vim.keymap.set("n", "<Esc>", "<Cmd>ToggleUndotree<CR>", { buffer = args.buf, silent = true, desc = "Close Undo Tree" })
  end,
})

-- ============================================================================
-- Keymaps & Context Menu Bindings
-- ============================================================================

-- Clear search highlight on <Esc>
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlights" })

-- Paste over selection & Delete/Change without overwriting yanked text (black-hole register `"_`)
vim.keymap.set("x", "p", "P", { desc = "Paste over selection without losing yanked text" })
vim.keymap.set({ "n", "x" }, "x", '"_x', { desc = "Delete character without yanking" })
vim.keymap.set({ "n", "x" }, "X", '"_X', { desc = "Delete character before cursor without yanking" })
vim.keymap.set({ "n", "x" }, "<Del>", '"_x', { desc = "Delete character without yanking" })
vim.keymap.set({ "n", "x" }, "<leader>D", '"_d', { desc = "Delete without yanking (black-hole)" })
vim.keymap.set({ "n", "x" }, "<leader>C", '"_c', { desc = "Change without yanking (black-hole)" })

-- Commenting shortcuts: Ctrl+k, Ctrl+c (works in Normal, Visual, and Insert mode, plus <leader>/ and gcc/gc)
-- vim.keymap.set("n", "<C-k><C-c>", "gcc", { remap = true, desc = "Toggle comment on line" })
-- vim.keymap.set("x", "<C-k><C-c>", "gc", { remap = true, desc = "Toggle comment on selection" })
-- vim.keymap.set("i", "<C-k><C-c>", "<Cmd>normal gcc<CR>", { desc = "Toggle comment on line" })
-- vim.keymap.set("n", "<C-k>c", "gcc", { remap = true, desc = "Toggle comment on line" })
-- vim.keymap.set("x", "<C-k>c", "gc", { remap = true, desc = "Toggle comment on selection" })
-- vim.keymap.set("i", "<C-k>c", "<Cmd>normal gcc<CR>", { desc = "Toggle comment on line" })
vim.keymap.set("n", "<leader>/", "gcc", { remap = true, desc = "Toggle comment on line" })
vim.keymap.set("x", "<leader>/", "gc", { remap = true, desc = "Toggle comment on selection" })

-- Right-Click Context Menu: Toggle Comment
require("core.context-menu").register("editor", {
  { priority = "100.82", label = "Toggle Comment (gcc)", cmd = "gcc", mode = "n", remap = true },
  { priority = "100.82", label = "Toggle Comment (gc)", cmd = "gc", mode = "v", remap = true },
})


-- macOS Cmd (Super) shortcuts for Save, Close, Copy, Cut, Paste & Comment
vim.keymap.set({ "n", "x" }, "<D-s>", "<Cmd>write<CR>", { desc = "Save file" })
vim.keymap.set("i", "<D-s>", "<Cmd>write<CR>", { desc = "Save file" })
vim.keymap.set("i", "<D-w>", "<Esc><Cmd>bd<CR>", { desc = "Close buffer" })

-- Visual & Select mode: Cmd+C copies selection, Cmd+X cuts selection, Cmd+V pastes over selection
vim.keymap.set("x", "<D-c>", '"+y', { desc = "Copy selection" })
vim.keymap.set("x", "<D-x>", '"+d', { desc = "Cut selection" })
vim.keymap.set("x", "<D-v>", '"_d"+P', { desc = "Paste over selection" })
vim.keymap.set("s", "<D-c>", '<C-g>"+y', { desc = "Copy selection" })
vim.keymap.set("s", "<D-x>", '<C-g>"+d', { desc = "Cut selection" })
vim.keymap.set("s", "<D-v>", '<C-g>"_d"+P', { desc = "Paste over selection" })

-- Insert & Command-line mode: Cmd+C copies current line, Cmd+V pastes at cursor from clipboard
vim.keymap.set("i", "<D-c>", "<Cmd>normal! yy<CR>", { desc = "Copy line" })
vim.keymap.set("i", "<D-v>", "<C-r><C-o>+", { desc = "Paste from clipboard" })
vim.keymap.set("c", "<D-v>", "<C-r>+", { desc = "Paste from clipboard" })

vim.keymap.set("i", "<D-k><D-c>", "<Esc><Cmd>normal gcc<CR>a", { desc = "Toggle comment on line" })
-- Keep the visual selection active so `gc` toggles comments on the selected rows.
vim.keymap.set("x", "<D-k><D-c>", "gcgv", { remap = true, desc = "Toggle comment on selection" })

-- Native Undo Tree toggle (<Space>tu)
local ok_wk, wk = pcall(require, "which-key")
if ok_wk then
  wk.add({
    { "<leader>tu", icon = { icon = "󰕌 ", color = "purple" } },
  })
end
vim.keymap.set("n", "<leader>tu", "<Cmd>ToggleUndotree<CR>", { desc = "Toggle Undo Tree" })

vim.keymap.set("n", "<leader>re", "<cmd>restart<cr>", { desc = "Restart Neovim" })
