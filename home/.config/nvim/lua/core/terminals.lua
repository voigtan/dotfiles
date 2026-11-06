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

-- Auto-close bottom terminal split when shell exits cleanly (skip for LazyGit / LazyDocker modals)
vim.api.nvim_create_autocmd("TermClose", {
  group = augroup,
  callback = function(args)
    local ft = vim.bo[args.buf].filetype
    if ft == "lazygit" or ft == "lazydocker" then
      return
    end
    if vim.v.event.status == 0 and vim.api.nvim_buf_is_valid(args.buf) then
      pcall(vim.api.nvim_buf_delete, args.buf, { force = true })
    end
  end,
})

-- Floating LazyDocker Modal Window (:LazyDocker / <leader>td)
vim.api.nvim_create_user_command("LazyDocker", function()
  if vim.fn.executable("lazydocker") == 0 then
    vim.notify("lazydocker is not installed or not in PATH", vim.log.levels.ERROR)
    return
  end

  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor((vim.o.lines - vim.o.cmdheight) * 0.9)
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor(((vim.o.lines - vim.o.cmdheight) - height) / 2)

  local ld_buf = vim.api.nvim_create_buf(false, true)
  local ld_win = vim.api.nvim_open_win(ld_buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
    title = "  LazyDocker ",
    title_pos = "center",
  })

  vim.bo[ld_buf].filetype = "lazydocker"
  vim.bo[ld_buf].buflisted = false

  vim.fn.jobstart("lazydocker", {
    term = true,
    on_exit = function()
      vim.schedule(function()
        if vim.api.nvim_win_is_valid(ld_win) then
          pcall(vim.api.nvim_win_close, ld_win, true)
        end
        if vim.api.nvim_buf_is_valid(ld_buf) then
          pcall(vim.api.nvim_buf_delete, ld_buf, { force = true })
        end
      end)
    end,
  })

  vim.keymap.set("t", "<Esc>", "<Esc>", { buffer = ld_buf, nowait = true })
  vim.cmd("startinsert")
end, { desc = "Open LazyDocker in a floating modal window" })

local function open_bottom_terminal(cmd)
  if vim.bo.filetype == "neo-tree" or vim.bo.filetype == "neotest-summary" then
    if _G.win_nav and _G.win_nav.focus_editor then
      _G.win_nav.focus_editor()
    end
  end
  vim.cmd("belowright split | resize 15 | terminal " .. cmd)
  vim.bo.buflisted = false
  vim.cmd("startinsert")
end

-- Default shell terminal (uses vim.o.shell, i.e. /bin/zsh -l)
vim.api.nvim_create_user_command("Term", function()
  open_bottom_terminal(vim.o.shell .. " -l")
end, { desc = "Open integrated terminal (default shell)" })

-- Tmux terminal profile
vim.api.nvim_create_user_command("TermTmux", function()
  open_bottom_terminal("tmux")
end, { desc = "Open integrated terminal (tmux)" })

-- Keymaps & Which-Key Group
local ok_wk, wk = pcall(require, "which-key")
if ok_wk then
  wk.add({
    { "<leader>t", group = "Terminal / Toggles" },
    { "<leader>td", icon = { icon = " ", color = "blue" } },
  })
end

map("n", "<leader>tt", "<cmd>Term<CR>", { desc = "Open Terminal (zsh)" })
map("n", "<leader>tx", "<cmd>TermTmux<CR>", { desc = "Open Terminal (tmux)" })
map("n", "<leader>td", "<cmd>LazyDocker<CR>", { desc = "Open LazyDocker floating window" })
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
