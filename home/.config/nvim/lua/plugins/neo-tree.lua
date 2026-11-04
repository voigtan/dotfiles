-- ============================================================================
-- Neo-tree Explorer (File Nesting, No Confirm Delete, TS Import Move, :restart fix)
-- ============================================================================

local map = vim.keymap.set
local lsp_helpers = require("plugins.lsp")

local ok_neotree, neotree = pcall(require, "neo-tree")
if ok_neotree then
  local events = require("neo-tree.events")
  neotree.setup({
    auto_clean_after_session_restore = true,
    close_if_last_window = false, -- Handled by core/navigation.lua (QuitPre)
    popup_border_style = "rounded",
    enable_git_status = true,
    enable_diagnostics = true,
    default_component_configs = {
      indent = {
        with_expanders = true,
        expander_collapsed = "",
        expander_expanded = "",
      },
    },
    window = {
      mappings = {
        ["<Tab>"] = "toggle_node",
        ["za"] = "toggle_node",
        ["zo"] = "toggle_node",
        ["zc"] = "close_node",
        ["<Right>"] = "toggle_node",
        ["<Left>"] = "close_node",
        ["Z"] = "expand_all_subnodes",
      },
    },
    -- "explorer.fileNesting.patterns": { "*.ts": "${capture}.test.tsx, ${capture}.test.ts" } (+ .spec.ts / .spec.tsx)
    nesting_rules = {
      ["ts"] = {
        pattern = "^(.+)%.ts$",
        files = { "%1.test.ts", "%1.test.tsx", "%1.spec.ts", "%1.spec.tsx" },
      },
      ["tsx"] = {
        pattern = "^(.+)%.tsx$",
        files = { "%1.test.tsx", "%1.test.ts", "%1.spec.tsx", "%1.spec.ts" },
      },
    },
    filesystem = {
      follow_current_file = {
        enabled = true,
        leave_dirs_open = false,
      },
      use_libuv_file_watcher = true,
      filtered_items = {
        hide_dotfiles = false,
        hide_gitignored = false,
      },
      commands = {
        -- "explorer.confirmDelete": false
        delete = function(state)
          local path = state.tree:get_node().path
          vim.fn.delete(path, "rf")
          require("neo-tree.sources.manager").refresh(state.name)
        end,
      },
    },
    event_handlers = {
      {
        event = events.NEO_TREE_POPUP_INPUT_READY,
        handler = function(args)
          -- Allow <Esc> in Insert mode to enter Normal mode inside rename/add popups
          vim.keymap.set("i", "<Esc>", "<cmd>stopinsert<CR>", { buffer = args.bufnr, noremap = true })
        end,
      },
      {
        event = events.FILE_MOVED,
        handler = function(data)
          lsp_helpers.on_file_move(data.source, data.destination)
        end,
      },
      {
        event = events.FILE_RENAMED,
        handler = function(data)
          lsp_helpers.on_file_move(data.source, data.destination)
        end,
      },
    },
  })
end

-- Fix Neo-tree state after Neovim 0.12 :restart (which saves & restores a session)
vim.api.nvim_create_autocmd("SessionLoadPost", {
  group = vim.api.nvim_create_augroup("NeoTreeRestartRestore", { clear = true }),
  desc = "Clean broken Neo-tree session buffer and re-open Neo-tree cleanly after :restart",
  callback = function()
    local had_neotree = false
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      local name = vim.fn.bufname(buf)
      if name:match("neo%-tree [^ ]+ %[%d+%]") then
        had_neotree = true
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
      end
    end
    if had_neotree then
      vim.schedule(function()
        vim.cmd("Neotree show")
      end)
    end
  end,
})

-- Keymaps
map("n", "<leader>e", "<cmd>Neotree toggle<CR>", { desc = "Toggle File Explorer (Neo-tree)" })
map("n", "<leader>o", "<cmd>Neotree reveal<CR>", { desc = "Reveal current file in Explorer" })

-- Right-Click Context Menu inside Neo-tree (Create File/Folder, Rename, Move, Copy/Paste, Delete, Expand)
_G.neotree_ctx_action = function(action_name)
  local state = require("neo-tree.sources.manager").get_state("filesystem")
  if not state then
    return
  end
  local cmds = require("neo-tree.sources.filesystem.commands")
  if state.commands and state.commands[action_name] then
    state.commands[action_name](state)
  elseif cmds[action_name] then
    cmds[action_name](state)
  end
end

local function clear_neotree_popup_menu()
  vim.cmd([[
    silent! aunmenu PopUp.Open\ File\ /\ Folder
    silent! aunmenu PopUp.Expand\ /\ Collapse\ Nested
    silent! aunmenu PopUp.-nt-sep1-
    silent! aunmenu PopUp.New\ File\ (a)
    silent! aunmenu PopUp.New\ Folder\ (A)
    silent! aunmenu PopUp.Rename\ (r)
    silent! aunmenu PopUp.Rename\ Basename\ (b)
    silent! aunmenu PopUp.Move\ (m)
    silent! aunmenu PopUp.-nt-sep2-
    silent! aunmenu PopUp.Copy\ File\ (y)
    silent! aunmenu PopUp.Cut\ File\ (x)
    silent! aunmenu PopUp.Paste\ File\ (p)
    silent! aunmenu PopUp.-nt-sep3-
    silent! aunmenu PopUp.Delete\ (d)
    silent! aunmenu PopUp.-nt-sep4-
  ]])
end

local function setup_neotree_popup_menu()
  vim.cmd([[
    anoremenu 100.05 PopUp.Open\ File\ /\ Folder            <Cmd>lua _G.neotree_ctx_action("open")<CR>
    anoremenu 100.10 PopUp.Expand\ /\ Collapse\ Nested      <Cmd>lua _G.neotree_ctx_action("toggle_node")<CR>
    anoremenu 100.15 PopUp.-nt-sep1-                        <Nop>
    anoremenu 100.20 PopUp.New\ File\ (a)                   <Cmd>lua _G.neotree_ctx_action("add")<CR>
    anoremenu 100.25 PopUp.New\ Folder\ (A)                 <Cmd>lua _G.neotree_ctx_action("add_directory")<CR>
    anoremenu 100.30 PopUp.Rename\ (r)                      <Cmd>lua _G.neotree_ctx_action("rename")<CR>
    anoremenu 100.35 PopUp.Rename\ Basename\ (b)            <Cmd>lua _G.neotree_ctx_action("rename_basename")<CR>
    anoremenu 100.40 PopUp.Move\ (m)                        <Cmd>lua _G.neotree_ctx_action("move")<CR>
    anoremenu 100.45 PopUp.-nt-sep2-                        <Nop>
    anoremenu 100.50 PopUp.Copy\ File\ (y)                  <Cmd>lua _G.neotree_ctx_action("copy_to_clipboard")<CR>
    anoremenu 100.55 PopUp.Cut\ File\ (x)                   <Cmd>lua _G.neotree_ctx_action("cut_to_clipboard")<CR>
    anoremenu 100.60 PopUp.Paste\ File\ (p)                 <Cmd>lua _G.neotree_ctx_action("paste_from_clipboard")<CR>
    anoremenu 100.65 PopUp.-nt-sep3-                        <Nop>
    anoremenu 100.70 PopUp.Delete\ (d)                      <Cmd>lua _G.neotree_ctx_action("delete")<CR>
    anoremenu 100.75 PopUp.-nt-sep4-                        <Nop>
  ]])
end

vim.api.nvim_create_autocmd("MenuPopup", {
  group = vim.api.nvim_create_augroup("NeoTreeContextMenu", { clear = true }),
  desc = "Switch right-click PopUp menu between Neo-tree actions and Editor LSP actions",
  callback = function()
    local ft = vim.bo.filetype
    if ft == "neo-tree" then
      if _G.clear_lsp_popup_menu then
        _G.clear_lsp_popup_menu()
      end
      setup_neotree_popup_menu()
    else
      clear_neotree_popup_menu()
      if _G.setup_lsp_popup_menu then
        _G.setup_lsp_popup_menu()
      end
    end
  end,
})
