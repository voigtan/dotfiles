# Neovim 0.12 Configuration Guidelines (`AGENTS.md`)

When modifying or extending this Neovim configuration (`~/.config/nvim`), follow these architectural rules:

## 1. Neovim 0.12 Native-First Philosophy
- **Package Manager**: Use Neovim 0.12's built-in `vim.pack.add({ ... }, { confirm = false })` in `init.lua`. Do **not** introduce external plugin managers like `lazy.nvim` or `packer.nvim`.
- **LSP & Completion**: Use native `vim.lsp.config()`, `vim.lsp.enable()`, `vim.lsp.completion`, `vim.lsp.inline_completion` (for GitHub Copilot), `vim.lsp.codelens`, and `vim.lsp.inlay_hint`. Do **not** add `nvim-cmp` or `mason-lspconfig`.
- **Treesitter**: `nvim-treesitter` (`main` branch for Nvim 0.12) uses `require("nvim-treesitter").get_installed()` and `require("nvim-treesitter").install(...)` (not the legacy `nvim-treesitter.configs` module), paired with native `vim.treesitter.start()`.
- **UI & Notifications**: `opt.cmdheight = 0` is paired with native `require("vim._core.ui2").enable(...)` in `lua/core/options.lua`.
- **Spellcheck**: Uses native `require("nvim.spellfile").config({ confirm = false })` in `lua/core/options.lua` with `opt.spellfile = vim.fn.stdpath("config") .. "/spell/en.utf-8.add"`.

## 2. Feature-Colocated Modular Structure
Every feature owns its setup, autocommands, user commands, keymaps, Which-Key group/icons, and Right-Click menu items in a single file:

- `init.lua` — Leader keys, core imports, `vim.pack.add()`, and `require("plugins")`.
- `lua/core/`
  - `options.lua` — Core options, `ui2`, spellcheck, yank highlight, comment shortcuts (`<C-k><C-c>`, `<leader>/`, `gcc`/`gc`).
  - `state.lua` — Persistent on-disk UI toggle state keyed by GitHub project (`owner/repo`) in `~/.local/state/nvim/ui-toggles.json`.
  - `modal.lua` — Centered floating confirmation modal (`require("core.modal").confirm(...)` + global `vim.fn.confirm` override) and centered floating Cmdline (`:`, `/`, `?`, `=`, `input()`) powered by native `vim._core.ui2`.
  - `context-menu.lua` — Right-click `PopUp` context menu registry (`require("core.context-menu").register(context, items)`).
  - `filetypes.lua` — `vim.filetype.add()` rules.
  - `navigation.lua` — Smart `<C-h/j/k/l>` window navigation across Neo-tree, Editor, Neotest Summary, and Terminal + `QuitPre` smart `:q`.
  - `rulers.lua` — 80 (`#ff9900`) and 120 (`#9f0af5`) column rulers + `:ToggleRulers` (`<Space>tr`).
  - `terminals.lua` — `vim.opt.shell = "/bin/zsh"`, `:Term` (`<Space>tt`), `:TermTmux` (`<Space>tx`), `:LazyDocker` (`<Space>td`), `TermOpen`/`TermClose`.
  - `pack.lua` — Native `vim.pack` & toolchain commands (`:PackSync`, `:PackUpdate`, `:PackReview`, `:PackClean`, `:PackRestore`, `:PackLog`) and `<Space>p` Which-Key group.
- `lua/plugins/`
  - `init.lua` — Loads all plugin modules in order.
  - `theme.lua` — `catppuccin-frappe` + `nvim-web-devicons`.
  - `treesitter.lua` — Parser installation + `nvim-treesitter-context` (sticky scroll).
  - `flash.lua` — `flash.nvim` on-screen jump navigation (`s`, `S`, `r`, `R`, `<C-s>`).
  - `lsp.lua` — Mason (`mason-tool-installer`), `tiny-inline-diagnostic.nvim`, `vtsls`, `biome`, `lua_ls`, `dockerls`, `docker_compose_language_service`, `jsonls` (SchemaStore), `yamlls`, `html`, `cssls`, `copilot`, and IntelliSense keymaps/mouse bindings.
  - `formatting.lua` — `conform.nvim` (Biome in Biome repos, fallback to Prettier, LSP for HTML/JSON).
  - `git.lua` — `gitsigns.nvim`, background `git.autofetch` timer, and floating `:LazyGit` (`<Space>gg`).
  - `neo-tree.lua` — File explorer, `.test.ts`/`.spec.ts` file nesting, rename `<Esc>` fix, `:restart` session restore, and `"neo-tree"` right-click menu items.
  - `tabs.lua` — File tabs bar (`bufferline.nvim`), window-safe `_G.close_buffer_tab`, `:ToggleTabs` (`<Space>bt` / `<Space>tf`), and `<S-h>`/`<S-l>` tab cycling.
  - `telescope.lua` — Fuzzy finder (`<C-p>`, `<Space>ff`, `<Space>fg`, `<Space>fb`, `<Space>fs`) with `<C-h>` live dotfile toggle.
  - `testing.lua` — Vitest (`neotest` + `neotest-vitest`) + inline coverage (`nvim-coverage` with `coverage-final.json` & `lcov.info` support).
  - `lualine.lua` — Global bottom statusbar with OS icon, mode, git, diagnostics, and active LSP clients.
  - `which-key.lua` — Core `which-key.nvim` setup, action-verb sorter, and `<C-c>` chord support.

## 3. Conventions When Adding New Features
1. **Place all bindings at the bottom of each file**: In every module (`lua/core/*` and `lua/plugins/*`), keep options, `setup()` calls, helper functions, and autocommands at the top, and place all `vim.keymap.set(...)`, `wk.add(...)`, and `context-menu.register(...)` calls together at the very bottom of the file.
2. **Colocate Which-Key groups & icons** inside the feature's own file using:
   ```lua
   local ok_wk, wk = pcall(require, "which-key")
   if ok_wk then
     wk.add({ ... })
   end
   ```
2. **Colocate Right-Click menu items** inside the feature's own file using:
   ```lua
   require("core.context-menu").register("editor", {
     { priority = "100.xx", label = "My Action", cmd = "<Cmd>...<CR>" },
   })
   ```
3. **Persist UI toggles per GitHub project** using `require("core.state").get(key, default)` and `require("core.state").set(key, value)`.
4. **Keep `readme.md` updated** whenever keymaps, commands, or files are added or changed.
