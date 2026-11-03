-- ============================================================================
-- Rulers (Columns 80 & 120 with VS Code colors #ff9900 & #9f0af5 + Toggle)
-- ============================================================================

local augroup = vim.api.nvim_create_augroup("CoreRulers", { clear = true })
local ruler_ns = vim.api.nvim_create_namespace("vscode_rulers")

vim.g.rulers_enabled = true
vim.opt.colorcolumn = "80,120"

local function set_ruler_highlights()
  vim.api.nvim_set_hl(0, "VSCodeRuler80", { fg = "#ff9900", nocombine = true })
  vim.api.nvim_set_hl(0, "VSCodeRuler120", { fg = "#9f0af5", nocombine = true })
end

set_ruler_highlights()
vim.api.nvim_create_autocmd("ColorScheme", {
  group = augroup,
  callback = set_ruler_highlights,
})

local function update_rulers(winid)
  if not vim.api.nvim_win_is_valid(winid) then
    return
  end
  local win_cfg = vim.api.nvim_win_get_config(winid)
  if win_cfg.relative and win_cfg.relative ~= "" then
    return
  end

  local bufnr = vim.api.nvim_win_get_buf(winid)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  if not vim.g.rulers_enabled or vim.bo[bufnr].buftype ~= "" then
    vim.api.nvim_buf_clear_namespace(bufnr, ruler_ns, 0, -1)
    return
  end

  vim.api.nvim_buf_clear_namespace(bufnr, ruler_ns, 0, -1)
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local top = math.max(0, vim.fn.line("w0", winid) - 1)
  local bot = math.min(line_count, vim.fn.line("w$", winid))
  for lnum = top, bot - 1 do
    vim.api.nvim_buf_set_extmark(bufnr, ruler_ns, lnum, 0, {
      virt_text = { { "▏", "VSCodeRuler80" } },
      virt_text_win_col = 79,
      hl_mode = "combine",
      priority = 1,
    })
    vim.api.nvim_buf_set_extmark(bufnr, ruler_ns, lnum, 0, {
      virt_text = { { "▏", "VSCodeRuler120" } },
      virt_text_win_col = 119,
      hl_mode = "combine",
      priority = 1,
    })
  end
end

vim.api.nvim_create_autocmd({ "BufWinEnter", "WinScrolled", "TextChanged", "TextChangedI" }, {
  group = augroup,
  callback = function()
    update_rulers(vim.api.nvim_get_current_win())
  end,
})

vim.api.nvim_create_user_command("ToggleRulers", function()
  vim.g.rulers_enabled = not vim.g.rulers_enabled
  vim.opt.colorcolumn = vim.g.rulers_enabled and "80,120" or ""
  for _, winid in ipairs(vim.api.nvim_list_wins()) do
    local bufnr = vim.api.nvim_win_get_buf(winid)
    if vim.bo[bufnr].buftype == "" then
      vim.wo[winid].colorcolumn = vim.g.rulers_enabled and "80,120" or ""
    end
    update_rulers(winid)
  end
  vim.notify("Rulers (80, 120): " .. (vim.g.rulers_enabled and "ON" or "OFF"))
end, { desc = "Toggle 80/120 column rulers and highlights" })

vim.keymap.set("n", "<leader>tr", "<cmd>ToggleRulers<CR>", { desc = "Toggle 80/120 Rulers & Highlights" })
