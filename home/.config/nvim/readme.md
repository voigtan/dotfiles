# Neovim 0.12 Configuration

A modular **Neovim 0.12+** configuration migrated from VS Code (`settings.json`), prioritizing native Neovim 0.12 features (`vim.pack`, `vim.lsp.config`, `vim.lsp.completion`, `vim.lsp.inline_completion`, `vim.lsp.codelens`, `vim.lsp.inlay_hint`, and `vim.filetype.add`).

---

## Directory Structure

Each feature is self-contained in its own module (configuration, autocommands, user commands, and keymaps are colocated together):

```text
home/.config/nvim/
├── init.lua                        # Entrypoint: leader keys, core imports, vim.pack.add(), plugin loader
├── nvim-pack-lock.json             # Native Neovim 0.12 plugin lockfile
├── readme.md                       # Documentation & keymap reference
├── spell/
│   └── en.utf-8.add                # Custom dictionary words ("cSpell.userWords")
└── lua/
    ├── core/
    │   ├── options.lua             # Core options, whitespace, control chars, diffopt, en_gb spell, yank highlight
    │   ├── state.lua               # Persistent on-disk UI toggles per-GitHub project (~/.local/state/nvim/ui-toggles.json)
    │   ├── context-menu.lua        # Right-click PopUp context menu registry ("editor", "neo-tree", etc.)
    │   ├── filetypes.lua           # Native vim.filetype.add() ("files.associations")
    │   ├── navigation.lua          # Smart <C-h/j/k/l> pane navigation & QuitPre (:q closes tree/terminal)
    │   ├── rulers.lua              # 80/120 colored rulers (#ff9900 & #9f0af5), :ToggleRulers, <Space>tr
    │   └── terminals.lua           # :TermZsh/Bash/Tmux/Pwsh, TermOpen/TermClose, <Space>tz/tb/tt/tp
    └── plugins/
        ├── init.lua                # Loads all plugin modules in order
        ├── theme.lua               # Catppuccin Frappé + nvim-web-devicons
        ├── treesitter.lua          # Treesitter parsers/highlighting + sticky scroll (treesitter-context)
        ├── flash.lua               # Flash.nvim fast on-screen jump (s, S, f/t/F/T)
        ├── lsp.lua                 # Mason + native Nvim 0.12 LSP, Copilot inline completion & IntelliSense keys
        ├── formatting.lua          # Conform.nvim (Prettier / LSP formatOnSave) + <Space>f
        ├── git.lua                 # Gitsigns (blame & inline diffs), git.autofetch, floating :LazyGit (<Space>gg)
        ├── neo-tree.lua            # Neo-tree (file nesting, rename fix, :restart restore) + <Space>e / <Space>o
        ├── tabs.lua                # File tabs bar, toggle (:ToggleTabs), window-safe tab closing + <S-h>/<S-l>/<Space>b*
        ├── telescope.lua           # Telescope fuzzy finder + <C-p> / <Space>ff / <Space>fg / gd / gr
        ├── testing.lua             # Vitest (neotest-vitest) pass/fail/watch + inline coverage (nvim-coverage)
        ├── lualine.lua             # Statusbar (Catppuccin Frappé + active LSP indicator)
        └── which-key.lua           # Which-Key popup guide + group labels + <Space>?
```

---

## Keymaps Reference

> **Leader Key:** `<Space>`

### Window & Pane Navigation (`lua/core/navigation.lua`)
Works in **both Normal mode and Terminal mode** (no need to press `<Esc><Esc>` first):

| Keymap | Equivalent Arrow | Action |
| :--- | :--- | :--- |
| `<C-h>` | `<C-Left>` | Focus **Neo-tree sidebar** (left) |
| `<C-l>` | `<C-Right>` | Focus **Code Editor** (right) |
| `<C-j>` | `<C-Down>` | Focus **Integrated Terminal** (bottom) |
| `<C-k>` | `<C-Up>` | Focus **Code Editor** (up from terminal) |
| `:q` / `:wq` | — | Quits Neovim cleanly (automatically closes Neo-tree/Terminal if closing the last file) |

### Fast On-Screen Jump / Flash (`lua/plugins/flash.lua`)
| Keymap | Mode | Action |
| :--- | :--- | :--- |
| `s` | Normal / Visual / Operator | **Flash Jump**: Type 1–2 characters, then press the highlighted label letter to jump anywhere on screen (even across splits) |
| `S` | Normal / Visual / Operator | **Flash Treesitter**: Labels every syntax node around your cursor so you can select an entire function, argument, or block with 1 keypress |
| `f` / `F` / `t` / `T` | Normal / Visual | Enhanced single-line character jump with label hints (press `;` / `,` to repeat) |
| `r` | Operator-pending (e.g. after `y`, `d`, `c`) | **Remote Flash**: Perform an action (like `yr<char><label>iw` to copy a word) at another location and snap right back |
| `<C-s>` | Command-line (`/` or `?`) | Toggle Flash jump labels during a regular `/` search |

### File Tabs (`lua/plugins/tabs.lua`)
| Keymap / Command | Action |
| :--- | :--- |
| `<S-h>` (`Shift + h`) or `[b` | Previous file tab |
| `<S-l>` (`Shift + l`) or `]b` | Next file tab |
| `<Space>bt` or `<Space>tf` (or `:ToggleTabs`) | **Toggle top File Tabs bar** on/off |
| `<Space>bd` | Close current file tab (prompts *Save / Discard / Cancel* if modified) |
| `<Space>bD` | **Force-close** current file tab and discard unsaved changes immediately |
| `<Space>bo` | Close all other file tabs |
| `<Space>bp` | Pin / unpin current file tab |

### File Explorer / Neo-tree (`lua/plugins/neo-tree.lua`)
| Keymap | Where | Action |
| :--- | :--- | :--- |
| `<Space>e` | Global | Toggle Neo-tree sidebar |
| `<Space>o` | Global | Reveal current file in Neo-tree |
| `Right Click` | Inside Neo-tree | Open file explorer context menu (*New File*, *New Folder*, *Rename*, *Move*, *Copy/Cut/Paste*, *Delete*, *Expand Nested*) |
| `<Tab>` / `<Right>` / `za` / `zo` | Inside Neo-tree | **Expand** `<file>.ts` to view nested `<file>.test.ts` / `<file>.test.tsx` |
| `<Left>` / `zc` | Inside Neo-tree | **Collapse** nested file or directory |
| `Z` (`Shift + z`) | Inside Neo-tree | Expand all nested files/subfolders under current node |
| `z` | Inside Neo-tree | Collapse all nodes |
| `r` | Inside Neo-tree | Rename file/folder (`<Esc>` once enters Normal mode inside popup; `<Enter>` confirms) |
| `b` | Inside Neo-tree | Rename basename only (without extension) |
| `m` | Inside Neo-tree | Move file/folder (automatically updates TypeScript/JS imports via `vtsls`) |
| `a` | Inside Neo-tree | Create new file or directory (end with `/` for folder) |
| `d` | Inside Neo-tree | Delete file/folder immediately (`confirmDelete: false`) |
| `?` | Inside Neo-tree | Show all Neo-tree shortcuts |

### Fuzzy Finder / Telescope (`lua/plugins/telescope.lua`)
| Keymap | Action |
| :--- | :--- |
| `<C-p>` or `<Space>ff` | Find files across project |
| `<Space>fg` | Live grep text across project |
| `<C-h>` *(inside Telescope)* | **Live-toggle dotfiles** on/off while keeping your current search text |
| `<Space>fb` | Switch open buffers |
| `<Space>fs` | Search LSP document symbols |

### TypeScript, LSP IntelliSense & Copilot (`lua/plugins/lsp.lua`)
| Keymap | Mode | Action |
| :--- | :--- | :--- |
| `K` | Normal | Show TypeScript type / JSDoc hover popup |
| `Ctrl + Left Click` (`<C-LeftMouse>`) | Normal / Insert | Show TypeScript type / hover popup at mouse position |
| `Option/Alt + Left Click` (`<M-LeftMouse>`) | Normal / Insert | Go to Definition / Reference at mouse position |
| `Right Click` | Normal / Visual / Insert | Open context menu (*Show Type/Hover*, *Find All References*, *Go to Type Definition*, *Code Action*, *Rename*) |
| `<M-i>` (`Alt + i`) or `<Space>ci` / `<Space>ti` | Normal / Insert / Visual | Toggle Inline Type Hints (Inlay Hints) |
| `<C-k>` | Insert | Show function parameter signature help |
| `<C-Space>` | Insert | Manually trigger LSP IntelliSense completion menu |
| `<C-n>` / `<C-p>` / `<C-y>` | Insert | Next item / Previous item / Confirm completion item |
| `<Tab>` | Insert | Accept GitHub Copilot inline ghost-text suggestion |
| `<M-]>` / `<M-[>` | Insert | Cycle next / previous Copilot inline suggestion |
| `gd` | Normal | Go to Definition — works on symbols **and** `import ... from "./path"` strings |
| `gD` or `<Space>cs` | Normal | **Go to Source Definition** (jumps past `.d.ts` declarations to the real `.ts`/`.js` implementation) |
| `gy` or `<Space>ct` | Normal | Go to Type Definition (Telescope) |
| `gi` | Normal | Go to Implementation (Telescope) |
| `gr` | Normal | Find all References (Telescope) |
| `<Space>ca` | Normal / Visual | Code Action / Quick Fix / Auto-import symbol under cursor |
| `<Space>cm` | Normal | **Add All Missing Imports** in current file |
| `<Space>co` | Normal | **Organize Imports** (sorts & removes unused imports) |
| `<Space>cr` | Normal | Rename symbol across project |
| `gcc` / `<Space>/` / `<C-k><C-c>` | Normal / Insert | **Toggle comment** on current line (also in Right-Click menu) |
| `gc` / `<Space>/` / `<C-k><C-c>` | Visual | **Toggle comment** on selected lines (also in Right-Click menu) |
| `<Space>cd` | Normal | Show line type error / diagnostic float |
| `<Space>cl` | Normal | Run LSP CodeLens |

### Formatting (`lua/plugins/formatting.lua`)
- **Format on Save**: Enabled automatically for `javascript`, `javascriptreact`, `typescript`, `typescriptreact`, `css`, `scss` (automatically uses **Biome** if `biome.json`/`biome.jsonc` is present in the project, otherwise falls back to **Prettier**) and `html` (via HTML LSP).
- **Manual Format**: Press **`<Space>f`** in Normal or Visual mode (e.g., to format `json`/`jsonc` via Biome or JSON LSP).

### Vitest & Code Coverage (`lua/plugins/testing.lua`)
| Keymap / Mouse | Action |
| :--- | :--- |
| `<Space>vr` (or Right-Click $\to$ *Run Nearest Test*) | Run the single `it()` / `test()` block under cursor (or companion `.test.ts` if in a source `.ts` file) |
| `<Space>vf` | Run all Vitest tests in the current file (or companion `.test.ts`) |
| `<Space>va` | Run **ALL** Vitest tests in the entire project |
| `<Space>vw` (or Right-Click $\to$ *Toggle Test Watch*) | Toggle **Vitest Watch Mode** (auto-reruns tests on save) |
| `<Space>vs` | Toggle the **Vitest Test Explorer** summary sidebar |
| `<Space>vo` | Open floating popup showing the failure diff / console output of the test |
| `<Space>vO` | Toggle the full Vitest output panel |
| `<Space>vc` | Load & toggle **inline code coverage** bars (`▎` green = covered, `▎` red = uncovered) |
| `<Space>vC` | Open **Coverage Summary** popup with per-file coverage percentages |

### Git & LazyGit (`lua/plugins/git.lua`)
| Keymap / Command | Action |
| :--- | :--- |
| `<Space>gg` or `:LazyGit` | Open **LazyGit** in a centered floating modal window (`q` to close) |
| `<Space>gd` | Toggle full inline Git diff (word diff + modified line highlight + deleted lines) |
| `<Space>gw` | Toggle intra-line Git word diff only |
| `<Space>gp` | Preview current Git hunk inline |
| `<Space>gb` | Toggle end-of-line Git blame decoration |

### Terminals & Rulers (`lua/core/terminals.lua`, `lua/core/rulers.lua`)
| Keymap / Command | Action |
| :--- | :--- |
| `<Space>tt` or `:Term` | Open bottom terminal with default shell (`/bin/zsh -l`) |
| `<Space>tx` or `:TermTmux` | Open bottom terminal with `tmux` |
| `<Space>td` or `:LazyDocker` | Open **LazyDocker** in a centered floating modal window (`q` to close) |
| `<Esc><Esc>` | Exit Terminal mode into Normal mode |
| `<Space>tr` or `:ToggleRulers` | Toggle 80 (`#ff9900`) and 120 (`#9f0af5`) column rulers on/off |

---

## Managing Plugins & LSP Servers

- **Update Neovim 0.12 Plugins (`vim.pack`)**:
  ```vim
  :lua vim.pack.update()
  ```
  *(Opens a review tab showing incoming changes; run `:write` to confirm or `:quit` to cancel).*
- **Inspect Installed LSPs & Formatters (`mason.nvim`)**:
  ```vim
  :Mason
  ```
