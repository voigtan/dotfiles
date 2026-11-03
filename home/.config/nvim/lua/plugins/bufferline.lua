-- ============================================================================
-- Bufferline (File Tabs, Window-safe Tab Close, <S-h>/<S-l> Tab Cycling)
-- ============================================================================

local map = vim.keymap.set

-- Helper to close a buffer tab without collapsing the editor split or quitting Neovim
_G.close_buffer_tab = function(bufnr)
  bufnr = (bufnr and bufnr > 0) and bufnr or vim.api.nvim_get_current_buf()
  if vim.bo[bufnr].filetype == "neo-tree" then
    return
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
    pcall(vim.cmd, "bdelete " .. bufnr)
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
end

-- Keymaps
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
map("n", "<leader>bp", "<cmd>BufferLineTogglePin<CR>", { desc = "Pin / unpin file tab" })
map("n", "<leader>bo", "<cmd>BufferLineCloseOthers<CR>", { desc = "Close all other file tabs" })
map("n", "<leader>bd", function()
  _G.close_buffer_tab(0)
end, { desc = "Close current file tab" })
