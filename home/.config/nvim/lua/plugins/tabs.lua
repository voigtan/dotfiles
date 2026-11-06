-- ============================================================================
-- File Tabs (Top Tab Bar, Window-safe Tab Close, <S-h>/<S-l> Cycling & Toggle)
-- ============================================================================

local map = vim.keymap.set
local state = require("core.state")

-- Helper to close a file tab without collapsing the editor split or quitting Neovim
_G.close_buffer_tab = function(bufnr, force)
  bufnr = (bufnr and bufnr > 0) and bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].filetype == "neo-tree" then
    return
  end

  if not force and vim.bo[bufnr].modified then
    local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t")
    if name == "" then
      name = "[No Name]"
    end
    local choice = vim.fn.confirm(
      string.format('Save changes to "%s" before closing?', name),
      "&Yes\n&No (Discard)\n&Cancel",
      1
    )
    if choice == 1 then
      vim.api.nvim_buf_call(bufnr, function()
        vim.cmd("write")
      end)
    elseif choice == 2 then
      force = true
    else
      return
    end
  end

  local alt_buf = nil
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if b ~= bufnr and vim.bo[b].buflisted and vim.api.nvim_buf_is_loaded(b) and vim.bo[b].filetype ~= "neo-tree" then
      alt_buf = b
      break
    end
  end

  for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
    if vim.api.nvim_win_is_valid(win) then
      if alt_buf then
        vim.api.nvim_win_set_buf(win, alt_buf)
      else
        local empty_buf = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_win_set_buf(win, empty_buf)
      end
    end
  end

  if vim.api.nvim_buf_is_valid(bufnr) then
    pcall(vim.cmd, (force and "bdelete! " or "bdelete ") .. bufnr)
  end
end

local ok_bufferline, bufferline = pcall(require, "bufferline")
if ok_bufferline then
  local ok_ctp_bl, ctp_bufferline = pcall(require, "catppuccin.special.bufferline")
  bufferline.setup({
    highlights = ok_ctp_bl and ctp_bufferline.get_theme() or nil,
    options = {
      mode = "buffers",
      close_command = _G.close_buffer_tab,
      right_mouse_command = _G.close_buffer_tab,
      custom_filter = function(bufnr)
        return vim.bo[bufnr].buftype ~= "terminal" and vim.bo[bufnr].filetype ~= "neo-tree"
      end,
      diagnostics = "nvim_lsp",
      always_show_bufferline = true,
      auto_toggle_bufferline = false, -- Allow manual :ToggleTabs without auto-reopening
      show_buffer_close_icons = true,
      show_close_icon = false,
      separator_style = "thin",
      offsets = {
        {
          filetype = "neo-tree",
          text = "󰙅 File Explorer",
          highlight = "Directory",
          text_align = "left",
          separator = true,
        },
      },
    },
  })
  vim.o.showtabline = state.get("tabs", true) and 2 or 0

  -- Show BOTH the orange modified circle (●) AND the clickable close button (󰅖) on modified tabs
  local ok_ui, ui = pcall(require, "bufferline.ui")
  local ok_cfg, bl_config = pcall(require, "bufferline.config")
  local ok_hl, bl_highlights = pcall(require, "bufferline.highlights")
  if ok_ui and ok_cfg and ok_hl and not ui._patched_modified_close then
    ui._patched_modified_close = true
    local orig_element = ui.element
    ui.element = function(current_state, element)
      element = orig_element(current_state, element)
      if element.modified and element.component then
        local orig_comp = element.component
        local curr_hl = bl_highlights.for_element(element)
        local close_icon = (bl_config.options and bl_config.options.buffer_close_icon) or "󰅖"
        local mod_icon = (bl_config.options and bl_config.options.modified_icon) or "●"
        local close_seg = ui.make_clickable("handle_close", element.id, {
          text = " " .. close_icon,
          highlight = curr_hl.close_button,
        })
        element.length = element.length + vim.fn.strwidth(" " .. close_icon)
        element.component = function(...)
          local segs = orig_comp(...)
          for i, seg in ipairs(segs) do
            if seg.text == mod_icon then
              table.insert(segs, i + 1, close_seg)
              break
            end
          end
          return segs
        end
      end
      return element
    end
  end
end

-- Command & helper to toggle the top File Tabs bar on/off (persisted per-folder on disk)
vim.api.nvim_create_user_command("ToggleTabs", function()
  if vim.o.showtabline == 0 then
    vim.o.showtabline = 2
    state.set("tabs", true)
    vim.notify("File Tabs Bar: ON (saved for " .. state.get_project_key() .. ")")
  else
    vim.o.showtabline = 0
    state.set("tabs", false)
    vim.notify("File Tabs Bar: OFF (saved for " .. state.get_project_key() .. ")")
  end
end, { desc = "Toggle top File Tabs bar on/off" })

local function cycle_buffer_tab(direction)
  if _G.win_nav and not _G.win_nav.is_editor_buf(0) then
    _G.win_nav.focus_editor()
  end
  if direction > 0 then
    vim.cmd("BufferLineCycleNext")
  else
    vim.cmd("BufferLineCyclePrev")
  end
end

-- ============================================================================
-- Keymaps & Which-Key Group
-- ============================================================================

local ok_wk, wk = pcall(require, "which-key")
if ok_wk then
  wk.add({
    { "<leader>b", group = "File Tabs" },
    { "<leader>bt", icon = { icon = " ", color = "yellow" } },
    { "<leader>tf", icon = { icon = " ", color = "yellow" } },
  })
end

map("n", "<S-h>", function()
  cycle_buffer_tab(-1)
end, { desc = "Previous file tab" })
map("n", "<S-l>", function()
  cycle_buffer_tab(1)
end, { desc = "Next file tab" })
map("n", "[b", function()
  cycle_buffer_tab(-1)
end, { desc = "Previous file tab" })
map("n", "]b", function()
  cycle_buffer_tab(1)
end, { desc = "Next file tab" })
map("n", "<leader>bt", "<cmd>ToggleTabs<CR>", { desc = "Toggle File Tabs bar" })
map("n", "<leader>tf", "<cmd>ToggleTabs<CR>", { desc = "Toggle File Tabs bar" })
map("n", "<leader>bp", "<cmd>BufferLineTogglePin<CR>", { desc = "Pin / unpin file tab" })
map("n", "<leader>bo", "<cmd>BufferLineCloseOthers<CR>", { desc = "Close all other file tabs" })
map("n", "<leader>bd", function()
  _G.close_buffer_tab(0, false)
end, { desc = "Close current file tab" })
map("n", "<leader>bD", function()
  _G.close_buffer_tab(0, true)
end, { desc = "Force close file tab (discard changes)" })
