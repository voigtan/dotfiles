-- ============================================================================
-- Core Editor Options (mapped from VS Code settings.json)
-- ============================================================================

local opt = vim.opt

-- UI & General
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.termguicolors = true
opt.showmode = false
opt.laststatus = 3 -- Global statusbar at the bottom (like VS Code)
opt.updatetime = 250
opt.timeoutlen = 300
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

-- Highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("CoreYankHighlight", { clear = true }),
  desc = "Highlight yanked text",
  callback = function()
    vim.hl.on_yank({ timeout = 200 })
  end,
})
