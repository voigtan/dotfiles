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

-- Clear search highlight on <Esc>
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlights" })

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

-- Highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("CoreYankHighlight", { clear = true }),
  desc = "Highlight yanked text",
  callback = function()
    vim.hl.on_yank({ timeout = 200 })
  end,
})
