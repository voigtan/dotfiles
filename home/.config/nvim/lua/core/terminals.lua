-- ============================================================================
-- Integrated Terminal Profiles ("terminal.integrated.profiles.osx")
-- ============================================================================

local augroup = vim.api.nvim_create_augroup("CoreTerminals", { clear = true })
local map = vim.keymap.set

-- "terminal.integrated.stickyScroll.enabled": false & clean terminal UI
vim.api.nvim_create_autocmd("TermOpen", {
  group = augroup,
  callback = function(args)
    vim.bo[args.buf].buflisted = false -- Keep terminals out of Bufferline file tabs
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
    vim.opt_local.list = false
    vim.opt_local.spell = false
    vim.opt_local.colorcolumn = ""
    vim.opt_local.winfixheight = true
    pcall(function()
      require("treesitter-context").disable()
    end)
  end,
})

-- Auto-close bottom terminal split when shell exits cleanly (skip for LazyGit modal)
vim.api.nvim_create_autocmd("TermClose", {
  group = augroup,
  callback = function(args)
    if vim.bo[args.buf].filetype == "lazygit" then
      return
    end
    if vim.v.event.status == 0 and vim.api.nvim_buf_is_valid(args.buf) then
      pcall(vim.api.nvim_buf_delete, args.buf, { force = true })
    end
  end,
})

local term_profiles = {
  TermZsh = "/bin/zsh -l",
  TermBash = "bash -l",
  TermTmux = "tmux",
  TermPwsh = "pwsh",
}

for cmd_name, shell_cmd in pairs(term_profiles) do
  vim.api.nvim_create_user_command(cmd_name, function()
    if vim.bo.filetype == "neo-tree" then
      vim.cmd("wincmd l")
    end
    vim.cmd("belowright split | resize 15 | terminal " .. shell_cmd)
    vim.bo.buflisted = false
    vim.cmd("startinsert")
  end, { desc = "Open integrated terminal: " .. shell_cmd })
end

-- Keymaps & Which-Key Group
local ok_wk, wk = pcall(require, "which-key")
if ok_wk then
  wk.add({
    { "<leader>t", group = "Terminal / Toggles" },
  })
end

map("n", "<leader>tz", "<cmd>TermZsh<CR>", { desc = "Open Terminal (zsh -l)" })
map("n", "<leader>tb", "<cmd>TermBash<CR>", { desc = "Open Terminal (bash -l)" })
map("n", "<leader>tt", "<cmd>TermTmux<CR>", { desc = "Open Terminal (tmux)" })
map("n", "<leader>tp", "<cmd>TermPwsh<CR>", { desc = "Open Terminal (pwsh)" })
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
