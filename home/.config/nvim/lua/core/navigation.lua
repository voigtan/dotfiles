-- ============================================================================
-- Window Navigation (<C-h/j/k/l>) & Smart :q (QuitPre)
-- ============================================================================

local map = vim.keymap.set
local modal = require("core.modal")

local function focus_window_by(predicate, fallback_wincmd)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local cfg = vim.api.nvim_win_get_config(win)
    if not cfg.relative or cfg.relative == "" then
      local buf = vim.api.nvim_win_get_buf(win)
      if predicate(win, buf) then
        vim.api.nvim_set_current_win(win)
        return true
      end
    end
  end
  if fallback_wincmd then
    vim.cmd("wincmd " .. fallback_wincmd)
  end
  return false
end

local function is_editor_buf(buf)
  local ft = vim.bo[buf].filetype
  return ft ~= "neo-tree" and ft ~= "neotest-summary" and vim.bo[buf].buftype ~= "terminal"
end

_G.win_nav = {
  is_editor_buf = is_editor_buf,
  focus_editor = function()
    return focus_window_by(function(_, buf)
      return is_editor_buf(buf)
    end)
  end,
  left = function()
    if vim.bo.filetype == "neo-tree" then
      return
    end
    -- If on the right-hand Neotest Summary sidebar, move left into the Code Editor first
    if vim.bo.filetype == "neotest-summary" then
      focus_window_by(function(_, buf)
        return is_editor_buf(buf)
      end, "h")
      return
    end
    focus_window_by(function(_, buf)
      return vim.bo[buf].filetype == "neo-tree"
    end, "h")
  end,
  right = function()
    if vim.bo.filetype == "neo-tree" then
      focus_window_by(function(_, buf)
        return is_editor_buf(buf)
      end, "l")
    else
      vim.cmd("wincmd l")
    end
  end,
  down = function()
    focus_window_by(function(_, buf)
      return vim.bo[buf].buftype == "terminal"
    end, "j")
  end,
  up = function()
    focus_window_by(function(_, buf)
      return is_editor_buf(buf)
    end, "k")
  end,
}

-- Track the active ":" command line (cleared on next tick so it is never stale from history)
local active_ex_cmd = nil
vim.api.nvim_create_autocmd("CmdlineLeave", {
  group = vim.api.nvim_create_augroup("CoreSmartQuitCmdline", { clear = true }),
  callback = function()
    if vim.v.event.cmdtype == ":" and not vim.v.event.abort then
      active_ex_cmd = vim.trim(vim.fn.getcmdline() or "")
      vim.schedule(function()
        active_ex_cmd = nil
      end)
    end
  end,
})

-- Abort an in-progress :q cleanly by giving it a 1-line ephemeral split to close instead
local function abort_quit()
  local scratch = vim.api.nvim_create_buf(false, true)
  vim.bo[scratch].bufhidden = "wipe"
  vim.api.nvim_open_win(scratch, true, { split = "above", height = 1 })
end

-- Prompt to save or discard a modified buffer before :q closes the window/Neovim
local function prompt_modified_buffer_on_quit(buf)
  local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")
  if name == "" then
    name = "[No Name]"
  end
  local choice = modal.confirm({
    title = " 󰆓 Unsaved Changes ",
    prompt = string.format('Save changes to "%s" before quitting?', name),
    highlight = name,
    buttons = {
      { label = " 󰆓 [Y]es (Save) ", keys = { "y", "s" } },
      { label = " 󰅖 [N]o (Discard) ", keys = { "n", "d" } },
      { label = " 󰜺 [C]ancel ", keys = { "c", "q" } },
    },
    default = 1,
    cancel = 3,
  })
  if choice == 1 then
    return modal.save_buffer(buf, name)
  elseif choice == 2 then
    vim.bo[buf].modified = false
    return true
  else
    return false
  end
end

-- Close Neovim on :q / :wq even when Neo-tree or Terminal splits are open,
-- and prompt via floating modal for any unsaved buffers before closing panels
vim.api.nvim_create_autocmd("QuitPre", {
  group = vim.api.nvim_create_augroup("CoreSmartQuit", { clear = true }),
  desc = "Prompt for unsaved buffers and close auxiliary panels when quitting",
  callback = function()
    local current_win = vim.api.nvim_get_current_win()
    local current_buf = vim.api.nvim_win_get_buf(current_win)

    local ex_cmd = active_ex_cmd or ""
    local is_force = ex_cmd:find("!", 1, true) ~= nil
    local is_write_quit = ex_cmd:match("^wq") ~= nil or ex_cmd:match("^x") ~= nil

    local non_floating_wins = {}
    local aux_wins = {}
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      local cfg = vim.api.nvim_win_get_config(win)
      if not cfg.relative or cfg.relative == "" then
        table.insert(non_floating_wins, win)
        local buf = vim.api.nvim_win_get_buf(win)
        if not is_editor_buf(buf) or vim.bo[buf].buftype ~= "" then
          table.insert(aux_wins, win)
        end
      end
    end

    -- Case 1: :q run inside Neo-tree / Neotest / Terminal when the only other window is an empty [No Name] buffer
    if not is_editor_buf(current_buf) then
      if #non_floating_wins - #aux_wins == 1 then
        for _, win in ipairs(non_floating_wins) do
          local buf = vim.api.nvim_win_get_buf(win)
          if
            is_editor_buf(buf)
            and vim.api.nvim_buf_get_name(buf) == ""
            and not vim.bo[buf].modified
            and vim.api.nvim_buf_line_count(buf) <= 1
          then
            if not is_force then
              for _, b in ipairs(vim.api.nvim_list_bufs()) do
                if vim.api.nvim_buf_is_valid(b) and vim.bo[b].buflisted and vim.bo[b].modified and is_editor_buf(b) then
                  if not prompt_modified_buffer_on_quit(b) then
                    abort_quit()
                    return
                  end
                end
              end
            end
            pcall(vim.api.nvim_win_close, win, true)
          end
        end
      end
      return
    end

    -- Case 2: :q run in an editor split when OTHER editor splits remain open
    if #non_floating_wins - #aux_wins > 1 then
      if
        not is_force
        and not is_write_quit
        and vim.bo[current_buf].modified
        and #vim.fn.win_findbuf(current_buf) <= 1
      then
        if not prompt_modified_buffer_on_quit(current_buf) then
          abort_quit()
        end
      end
      return
    end

    -- Case 3: :q run in the last file window — prompt for ALL modified buffers BEFORE closing Neo-tree/Terminal
    if not is_force then
      for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if
          vim.api.nvim_buf_is_valid(b)
          and vim.bo[b].buflisted
          and vim.bo[b].modified
          and vim.bo[b].buftype ~= "terminal"
          and not (is_write_quit and b == current_buf)
        then
          if not prompt_modified_buffer_on_quit(b) then
            abort_quit()
            return
          end
        end
      end
    end

    for _, win in ipairs(aux_wins) do
      pcall(vim.api.nvim_win_close, win, true)
    end
  end,
})

-- ============================================================================
-- Keymaps
-- ============================================================================

-- Normal mode window navigation
map("n", "<C-h>", _G.win_nav.left, { desc = "Move focus to Left window (Neo-tree)" })
map("n", "<C-l>", _G.win_nav.right, { desc = "Move focus to Right window (Editor)" })
map("n", "<C-j>", _G.win_nav.down, { desc = "Move focus to Lower window (Terminal)" })
map("n", "<C-k>", _G.win_nav.up, { desc = "Move focus to Upper window (Editor)" })

map("n", "<C-Left>", _G.win_nav.left, { desc = "Move focus to Left window (Neo-tree)" })
map("n", "<C-Right>", _G.win_nav.right, { desc = "Move focus to Right window (Editor)" })
map("n", "<C-Down>", _G.win_nav.down, { desc = "Move focus to Lower window (Terminal)" })
map("n", "<C-Up>", _G.win_nav.up, { desc = "Move focus to Upper window (Editor)" })

-- Terminal mode window navigation (exits terminal insert mode via <C-\><C-n> first)
map("t", "<C-h>", "<C-\\><C-n><cmd>lua _G.win_nav.left()<CR>", { desc = "Move focus to Left window (Neo-tree)" })
map("t", "<C-l>", "<C-\\><C-n><cmd>lua _G.win_nav.right()<CR>", { desc = "Move focus to Right window (Editor)" })
map("t", "<C-j>", "<C-\\><C-n><cmd>lua _G.win_nav.down()<CR>", { desc = "Move focus to Lower window (Terminal)" })
map("t", "<C-k>", "<C-\\><C-n><cmd>lua _G.win_nav.up()<CR>", { desc = "Move focus to Upper window (Editor)" })

map("t", "<C-Left>", "<C-\\><C-n><cmd>lua _G.win_nav.left()<CR>", { desc = "Move focus to Left window (Neo-tree)" })
map("t", "<C-Right>", "<C-\\><C-n><cmd>lua _G.win_nav.right()<CR>", { desc = "Move focus to Right window (Editor)" })
map("t", "<C-Down>", "<C-\\><C-n><cmd>lua _G.win_nav.down()<CR>", { desc = "Move focus to Lower window (Terminal)" })
map("t", "<C-Up>", "<C-\\><C-n><cmd>lua _G.win_nav.up()<CR>", { desc = "Move focus to Upper window (Editor)" })
