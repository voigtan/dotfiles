-- ============================================================================
-- Git (Gitsigns Blame & Inline Diffs, Background Autofetch, Floating LazyGit)
-- ============================================================================

local map = vim.keymap.set

-- 1. Gitsigns ("git.blame.editorDecoration.enabled": true)
local ok_gitsigns, gitsigns = pcall(require, "gitsigns")
if ok_gitsigns then
  gitsigns.setup({
    current_line_blame = true,
    current_line_blame_opts = {
      virt_text = true,
      virt_text_pos = "eol",
      delay = 300,
      ignore_whitespace = true,
    },
  })
end

-- 2. "git.autofetch": true (periodic background git fetch every 3 minutes)
local autofetch_timer = vim.uv.new_timer()
if autofetch_timer then
  autofetch_timer:start(
    30000,
    180000,
    vim.schedule_wrap(function()
      local cwd = vim.fn.getcwd()
      if vim.fn.isdirectory(cwd .. "/.git") == 1 then
        vim.system({ "git", "fetch", "--quiet" }, { cwd = cwd }, function() end)
      end
    end)
  )
end

-- 3. Floating LazyGit Modal Window (:LazyGit / <leader>gg)
vim.api.nvim_create_user_command("LazyGit", function()
  if vim.fn.executable("lazygit") == 0 then
    vim.notify("lazygit is not installed or not in PATH", vim.log.levels.ERROR)
    return
  end

  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor((vim.o.lines - vim.o.cmdheight) * 0.9)
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor(((vim.o.lines - vim.o.cmdheight) - height) / 2)

  local lg_buf = vim.api.nvim_create_buf(false, true)
  local lg_win = vim.api.nvim_open_win(lg_buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
    title = " 󰊢 LazyGit ",
    title_pos = "center",
  })

  vim.bo[lg_buf].filetype = "lazygit"
  vim.bo[lg_buf].buflisted = false

  vim.fn.jobstart("lazygit", {
    term = true,
    on_exit = function()
      vim.schedule(function()
        if vim.api.nvim_win_is_valid(lg_win) then
          pcall(vim.api.nvim_win_close, lg_win, true)
        end
        if vim.api.nvim_buf_is_valid(lg_buf) then
          pcall(vim.api.nvim_buf_delete, lg_buf, { force = true })
        end
        pcall(function()
          require("gitsigns").refresh()
        end)
        pcall(function()
          require("neo-tree.sources.manager").refresh("filesystem")
        end)
      end)
    end,
  })

  vim.keymap.set("t", "<Esc>", "<Esc>", { buffer = lg_buf, nowait = true })
  vim.cmd("startinsert")
end, { desc = "Open LazyGit in a floating modal window" })

-- 4. Keymaps & Which-Key Group
local ok_wk, wk = pcall(require, "which-key")
if ok_wk then
  wk.add({
    { "<leader>g", group = "Git / Inline Diffs" },
  })
end

map("n", "<leader>gg", "<cmd>LazyGit<CR>", { desc = "Open LazyGit floating window" })

map("n", "<leader>gd", function()
  local gs = require("gitsigns")
  gs.toggle_word_diff()
  gs.toggle_linehl()
  gs.toggle_deleted()
end, { desc = "Toggle inline Git diff (word + line + deleted)" })

map("n", "<leader>gw", function()
  require("gitsigns").toggle_word_diff()
end, { desc = "Toggle intra-line Git word diff" })

map("n", "<leader>gp", function()
  require("gitsigns").preview_hunk_inline()
end, { desc = "Preview Git hunk inline" })

map("n", "<leader>gb", function()
  require("gitsigns").toggle_current_line_blame()
end, { desc = "Toggle inline Git blame" })
