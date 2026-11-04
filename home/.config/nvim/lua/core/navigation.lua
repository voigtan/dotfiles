-- ============================================================================
-- Window Navigation (<C-h/j/k/l>) & Smart :q (QuitPre)
-- ============================================================================

local map = vim.keymap.set

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

-- Close Neovim on :q / :wq even when Neo-tree or Terminal splits are open
vim.api.nvim_create_autocmd("QuitPre", {
  group = vim.api.nvim_create_augroup("CoreSmartQuit", { clear = true }),
  desc = "Close auxiliary Neo-tree/Terminal panels when quitting the last file window",
  callback = function()
    local current_win = vim.api.nvim_get_current_win()
    local current_buf = vim.api.nvim_win_get_buf(current_win)

    local non_floating_wins = {}
    local aux_wins = {}
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      local cfg = vim.api.nvim_win_get_config(win)
      if not cfg.relative or cfg.relative == "" then
        table.insert(non_floating_wins, win)
        local buf = vim.api.nvim_win_get_buf(win)
        local ft = vim.bo[buf].filetype
        if ft == "neo-tree" or ft == "neotest-summary" or vim.bo[buf].buftype == "terminal" then
          table.insert(aux_wins, win)
        end
      end
    end

    -- Case 1: :q run inside Neo-tree or Terminal when the only other window is an empty [No Name] buffer
    if vim.bo[current_buf].filetype == "neo-tree" or vim.bo[current_buf].buftype == "terminal" then
      if #non_floating_wins - #aux_wins == 1 then
        for _, win in ipairs(non_floating_wins) do
          local buf = vim.api.nvim_win_get_buf(win)
          if
            vim.bo[buf].filetype ~= "neo-tree"
            and vim.bo[buf].buftype ~= "terminal"
            and vim.api.nvim_buf_get_name(buf) == ""
            and not vim.bo[buf].modified
            and vim.api.nvim_buf_line_count(buf) <= 1
          then
            pcall(vim.api.nvim_win_close, win, true)
          end
        end
      end
      return
    end

    -- Case 2: :q run in the last file window while Neo-tree / Terminal panels are open
    if #non_floating_wins - #aux_wins <= 1 then
      for _, win in ipairs(aux_wins) do
        pcall(vim.api.nvim_win_close, win, true)
      end
    end
  end,
})
