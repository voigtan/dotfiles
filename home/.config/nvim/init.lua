-- ============================================================================
-- Neovim 0.12 Configuration (VS Code Setup Migration)
-- Modular architecture:
--   lua/core/*    -> Native Neovim options, filetypes, rulers, terminals, navigation
--   lua/plugins/* -> Individual plugin configs colocated with their keymaps & commands
-- ============================================================================

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Disable built-in netrw in favor of neo-tree
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- 1. Core Native Options, State, Context Menu & Filetypes
require("core.options")
require("core.state")
require("core.context-menu")
require("core.filetypes")

-- 2. Native Neovim 0.12 Package Manager (vim.pack.add)
local gh = function(repo)
  return "https://github.com/" .. repo
end

vim.pack.add({
  -- Theme & Icons ("Catppuccin Frappé" & "catppuccin-frappe")
  { src = gh("catppuccin/nvim"), name = "catppuccin" },
  gh("nvim-tree/nvim-web-devicons"),

  -- Syntax, Bracket Colorization & Sticky Scroll
  gh("nvim-treesitter/nvim-treesitter"),
  gh("nvim-treesitter/nvim-treesitter-context"),

  -- LSP Server Configs, Mason Installer, JSON Schemas & Inline Diagnostics
  gh("neovim/nvim-lspconfig"),
  gh("mason-org/mason.nvim"),
  gh("WhoIsSethDaniel/mason-tool-installer.nvim"),
  gh("b0o/SchemaStore.nvim"),
  gh("rachartier/tiny-inline-diagnostic.nvim"),

  -- Format on Save (Prettier + LSP formatters)
  gh("stevearc/conform.nvim"),

  -- Inline Git Blame & Diffs ("git.blame.editorDecoration.enabled")
  gh("lewis6991/gitsigns.nvim"),

  -- Explorer (File nesting, revealIfOpen, confirmDelete: false) & Fuzzy Finder
  gh("nvim-lua/plenary.nvim"),
  gh("MunifTanjim/nui.nvim"),
  gh("nvim-neo-tree/neo-tree.nvim"),
  gh("nvim-telescope/telescope.nvim"),

  -- Keybinding popup guide, Statusbar & Buffer Tabs
  gh("folke/which-key.nvim"),
  gh("nvim-lualine/lualine.nvim"),
  gh("akinsho/bufferline.nvim"),

  -- Vitest Test Runner & Inline Code Coverage
  gh("nvim-neotest/nvim-nio"),
  gh("antoinemadec/FixCursorHold.nvim"),
  gh("nvim-neotest/neotest"),
  gh("marilari88/neotest-vitest"),
  gh("andythigpen/nvim-coverage"),

  -- Fast On-Screen Jump Navigation
  gh("folke/flash.nvim"),
}, { confirm = false })

-- 3. Core Feature Modules & Plugin Feature Modules
require("core.navigation")
require("core.rulers")
require("core.terminals")
require("plugins")
