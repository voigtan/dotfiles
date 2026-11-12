-- ============================================================================
-- Floating Terminal Manager (Named Persistent Profiles: Term, Host, Tmux +
-- Ephemeral Modals for LazyDocker & LazyGit)
-- ============================================================================

local M = {}

local augroup = vim.api.nvim_create_augroup("CoreTerminals", { clear = true })
local map = vim.keymap.set

-- Persistent interactive shell profiles shown in the floating terminal border title bar
local profile_order = { "term", "host", "tmux" }

local profiles = {
  term = {
    id = "term",
    index = 1,
    icon = " ",
    label = "Term",
    filetype = "floating-term",
    get_cmd = function()
      local ok_dc, dc = pcall(require, "core.devcontainer")
      if ok_dc and dc.is_running() then
        return dc.get_shell_cmd()
      end
      return vim.o.shell .. " -l"
    end,
    get_label = function()
      local ok_dc, dc = pcall(require, "core.devcontainer")
      if ok_dc and dc.is_running() then
        return " Devcontainer"
      end
      return " Term"
    end,
  },
  host = {
    id = "host",
    index = 2,
    icon = " ",
    label = "Host",
    filetype = "floating-term",
    get_cmd = function()
      return vim.o.shell .. " -l"
    end,
  },
  tmux = {
    id = "tmux",
    index = 3,
    icon = " ",
    label = "Tmux",
    filetype = "floating-term",
    bin = "tmux",
    get_cmd = function()
      return "tmux"
    end,
  },
}

local state = {
  win = nil,
  active_id = nil,
  last_id = "term",
  bufs = {}, -- profile_id -> bufnr
  switching = false,
}

local function set_float_highlights()
  vim.api.nvim_set_hl(0, "FloatingTermNormal", { bg = "none" })
  vim.api.nvim_set_hl(0, "FloatingTermBorder", { fg = "#8caaee", bg = "none" })
end

set_float_highlights()
vim.api.nvim_create_autocmd("ColorScheme", {
  group = augroup,
  callback = set_float_highlights,
})

local function is_buf_alive(buf)
  return buf ~= nil and vim.api.nvim_buf_is_valid(buf)
end

local function get_float_geometry(scale_w, scale_h)
  scale_w = scale_w or 0.85
  scale_h = scale_h or 0.82
  local width = math.floor(vim.o.columns * scale_w)
  local height = math.floor((vim.o.lines - vim.o.cmdheight) * scale_h)
  local row = math.max(math.floor(((vim.o.lines - vim.o.cmdheight) - height) / 2) - 1, 0)
  local col = math.max(math.floor((vim.o.columns - width) / 2), 0)
  return width, height, row, col
end

local function build_title()
  local parts = {}
  for _, id in ipairs(profile_order) do
    local p = profiles[id]
    local buf = state.bufs[id]
    local is_active = (state.active_id == id)
    if is_active or is_buf_alive(buf) then
      local name = p.get_label and p.get_label() or (p.icon .. p.label)
      if is_active then
        table.insert(parts, { string.format(" [%d:%s] ", p.index, name), "Title" })
      else
        table.insert(parts, { string.format(" %d:%s ", p.index, name), "Comment" })
      end
    end
  end
  if #parts == 0 then
    return "  Terminal "
  end
  return parts
end

local function build_footer()
  return {
    { " <Esc><Esc> / <C-j>: Hide ", "Comment" },
    { "│", "FloatBorder" },
    { " <C-n> / <C-p> or <Space>1..3: Switch Profile ", "Comment" },
  }
end

local function refresh_win_config()
  if not state.win or not vim.api.nvim_win_is_valid(state.win) then
    return
  end
  local width, height, row, col = get_float_geometry()
  pcall(vim.api.nvim_win_set_config, state.win, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = build_title(),
    title_pos = "center",
    footer = build_footer(),
    footer_pos = "center",
  })
end

--- Hide the floating terminal window while keeping all running shell buffers alive
function M.hide()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    pcall(vim.api.nvim_win_close, state.win, true)
  end
  state.win = nil
end

--- Return whether the floating terminal window is currently visible
---@return boolean
function M.is_open()
  return state.win ~= nil and vim.api.nvim_win_is_valid(state.win)
end

--- Cycle between active/available terminal profiles while the float is open
---@param step integer
function M.cycle(step)
  local active_list = {}
  for _, id in ipairs(profile_order) do
    if is_buf_alive(state.bufs[id]) then
      table.insert(active_list, id)
    end
  end
  if #active_list <= 1 then
    return
  end
  local cur_idx = 1
  for i, id in ipairs(active_list) do
    if id == state.active_id then
      cur_idx = i
      break
    end
  end
  local next_idx = ((cur_idx - 1 + step) % #active_list) + 1
  M.open(active_list[next_idx])
end

local function attach_buffer_keymaps(buf)
  -- Hide floating terminal from Normal mode (`q` or `<Esc>`) or Terminal mode (`<Esc><Esc>`)
  vim.keymap.set("n", "q", M.hide, { buffer = buf, nowait = true, silent = true, desc = "Hide floating terminal" })
  vim.keymap.set("n", "<Esc>", M.hide, { buffer = buf, nowait = true, silent = true, desc = "Hide floating terminal" })
  vim.keymap.set("t", "<Esc><Esc>", function()
    vim.cmd("stopinsert")
    M.hide()
  end, { buffer = buf, silent = true, desc = "Hide floating terminal" })

  -- Cycle between running terminal profiles (<C-n> / <C-p> in Normal mode, or <C-Tab> / <C-S-Tab>)
  vim.keymap.set({ "t", "n" }, "<C-Tab>", function()
    M.cycle(1)
  end, { buffer = buf, silent = true, desc = "Next floating terminal profile" })
  vim.keymap.set({ "t", "n" }, "<C-S-Tab>", function()
    M.cycle(-1)
  end, { buffer = buf, silent = true, desc = "Previous floating terminal profile" })
  vim.keymap.set("n", "<C-n>", function()
    M.cycle(1)
  end, { buffer = buf, silent = true, desc = "Next floating terminal profile" })
  vim.keymap.set("n", "<C-p>", function()
    M.cycle(-1)
  end, { buffer = buf, silent = true, desc = "Previous floating terminal profile" })
  vim.keymap.set("n", "<Tab>", function()
    M.cycle(1)
  end, { buffer = buf, silent = true, desc = "Next floating terminal profile" })
  vim.keymap.set("n", "<S-Tab>", function()
    M.cycle(-1)
  end, { buffer = buf, silent = true, desc = "Previous floating terminal profile" })

  -- Direct profile jump inside floating terminal (1/2/3 in Normal mode, or <D-1>/<D-2>/<D-3> in Terminal/Normal)
  for _, id in ipairs(profile_order) do
    local p = profiles[id]
    vim.keymap.set("n", tostring(p.index), function()
      M.open(id)
    end, { buffer = buf, nowait = true, silent = true, desc = "Switch to " .. p.label .. " terminal" })
    vim.keymap.set({ "t", "n" }, string.format("<D-%d>", p.index), function()
      M.toggle(id)
    end, { buffer = buf, silent = true, desc = "Switch to " .. p.label .. " terminal" })
  end
end

--- Open (or switch to) a specific persistent shell profile inside the floating window
---@param profile_id? string
---@param custom_cmd? string
function M.open(profile_id, custom_cmd)
  profile_id = profile_id or state.last_id or "term"
  local profile = profiles[profile_id] or profiles.term

  if profile.bin and vim.fn.executable(profile.bin) == 0 then
    vim.notify(profile.bin .. " is not installed or not in PATH", vim.log.levels.ERROR)
    return
  end

  state.active_id = profile_id
  state.last_id = profile_id

  local buf = state.bufs[profile_id]
  local need_spawn = false
  if not is_buf_alive(buf) then
    buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].bufhidden = "hide"
    vim.bo[buf].buflisted = false
    vim.bo[buf].filetype = profile.filetype
    state.bufs[profile_id] = buf
    need_spawn = true
  end

  local width, height, row, col = get_float_geometry()
  state.switching = true
  if M.is_open() then
    vim.api.nvim_win_set_buf(state.win, buf)
    refresh_win_config()
    vim.api.nvim_set_current_win(state.win)
  else
    state.win = vim.api.nvim_open_win(buf, true, {
      relative = "editor",
      width = width,
      height = height,
      row = row,
      col = col,
      style = "minimal",
      border = "rounded",
      title = build_title(),
      title_pos = "center",
      footer = build_footer(),
      footer_pos = "center",
      zindex = 120,
    })
  end
  state.switching = false

  vim.wo[state.win].winblend = 0
  vim.wo[state.win].winhighlight = "Normal:FloatingTermNormal,FloatBorder:FloatingTermBorder"

  if need_spawn then
    local cmd = custom_cmd or profile.get_cmd()
    vim.fn.jobstart(cmd, {
      term = true,
      on_exit = function()
        vim.schedule(function()
          state.bufs[profile_id] = nil
          if vim.api.nvim_buf_is_valid(buf) then
            pcall(vim.api.nvim_buf_delete, buf, { force = true })
          end
          if state.active_id == profile_id and M.is_open() then
            for _, other_id in ipairs(profile_order) do
              if other_id ~= profile_id and is_buf_alive(state.bufs[other_id]) then
                M.open(other_id)
                return
              end
            end
            M.hide()
          else
            refresh_win_config()
          end
        end)
      end,
    })
    attach_buffer_keymaps(buf)
  end

  vim.cmd("startinsert")
end

--- Toggle a persistent floating terminal profile:
--- - If the float is open on the same profile, hide it.
--- - If the float is open on a different profile, switch to the requested profile.
--- - If the float is closed, open the requested profile.
---@param profile_id? string
---@param custom_cmd? string
function M.toggle(profile_id, custom_cmd)
  profile_id = profile_id or state.last_id or "term"
  if M.is_open() and state.active_id == profile_id and not custom_cmd then
    M.hide()
    return
  end
  M.open(profile_id, custom_cmd)
end

--- Open an ephemeral floating TUI modal (like LazyGit or LazyDocker) that closes & terminates on <Esc><Esc> or exit
---@param opts { bin: string, title: string, filetype: string, on_exit?: fun() }
function M.open_ephemeral_tui(opts)
  if vim.fn.executable(opts.bin) == 0 then
    vim.notify(opts.bin .. " is not installed or not in PATH", vim.log.levels.ERROR)
    return
  end

  -- Hide persistent shell float if it is currently open
  if M.is_open() then
    M.hide()
  end

  local width, height, row, col = get_float_geometry(0.9, 0.9)
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
    title = opts.title,
    title_pos = "center",
    footer = { { " q / <Esc><Esc>: Close ", "Comment" } },
    footer_pos = "center",
    zindex = 130,
  })

  vim.wo[win].winblend = 0
  vim.wo[win].winhighlight = "Normal:FloatingTermNormal,FloatBorder:FloatingTermBorder"
  vim.bo[buf].filetype = opts.filetype
  vim.bo[buf].buflisted = false

  local closed = false
  local function close_modal()
    if closed then
      return
    end
    closed = true
    if vim.api.nvim_win_is_valid(win) then
      pcall(vim.api.nvim_win_close, win, true)
    end
    if vim.api.nvim_buf_is_valid(buf) then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
    if opts.on_exit then
      opts.on_exit()
    end
  end

  vim.fn.jobstart(opts.bin, {
    term = true,
    on_exit = function()
      vim.schedule(close_modal)
    end,
  })

  -- Single <Esc> goes to the TUI app (e.g. close LazyGit commit popup); <Esc><Esc> kills & closes the modal
  vim.keymap.set("t", "<Esc>", "<Esc>", { buffer = buf, nowait = true })
  vim.keymap.set("t", "<Esc><Esc>", close_modal, { buffer = buf, silent = true, desc = "Close " .. opts.bin })
  vim.keymap.set("n", "q", close_modal, { buffer = buf, nowait = true, silent = true, desc = "Close " .. opts.bin })
  vim.keymap.set("n", "<Esc>", close_modal, { buffer = buf, nowait = true, silent = true, desc = "Close " .. opts.bin })
  vim.cmd("startinsert")
end

-- Auto-hide the floating terminal if focus leaves the floating window (e.g. clicking the editor)
vim.api.nvim_create_autocmd("WinLeave", {
  group = augroup,
  callback = function()
    if state.switching or not M.is_open() then
      return
    end
    local cur_win = vim.api.nvim_get_current_win()
    if cur_win == state.win then
      vim.schedule(function()
        if not state.switching and M.is_open() and vim.api.nvim_get_current_win() ~= state.win then
          M.hide()
        end
      end)
    end
  end,
})

-- Keep floating terminal centered when Neovim window is resized
vim.api.nvim_create_autocmd("VimResized", {
  group = augroup,
  callback = refresh_win_config,
})

-- Clean terminal buffer options
vim.api.nvim_create_autocmd("TermOpen", {
  group = augroup,
  callback = function(args)
    vim.bo[args.buf].buflisted = false
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
    vim.opt_local.list = false
    vim.opt_local.spell = false
    vim.opt_local.colorcolumn = ""
    pcall(function()
      require("treesitter-context").disable()
    end)
  end,
})

-- Backwards-compatible global helper (used by devcontainer.lua)
_G.open_bottom_terminal = function(cmd)
  M.open("term", cmd)
end

-- ============================================================================
-- Ex Commands, Keymaps & Which-Key Group
-- ============================================================================

vim.api.nvim_create_user_command("Term", function()
  M.toggle("term")
end, { desc = "Toggle floating terminal (devcontainer if running, else host shell)" })

vim.api.nvim_create_user_command("TermHost", function()
  M.toggle("host")
end, { desc = "Toggle floating terminal on host macOS" })

vim.api.nvim_create_user_command("TermTmux", function()
  M.toggle("tmux")
end, { desc = "Toggle floating terminal (tmux)" })

vim.api.nvim_create_user_command("LazyDocker", function()
  M.open_ephemeral_tui({
    bin = "lazydocker",
    title = "  LazyDocker ",
    filetype = "lazydocker",
  })
end, { desc = "Open LazyDocker in floating modal window" })

local ok_wk, wk = pcall(require, "which-key")
if ok_wk then
  wk.add({
    { "<leader>t", group = "Terminal", icon = { icon = " ", color = "green" } },
    { "<leader>tt", icon = { icon = " ", color = "green" } },
    { "<leader>th", icon = { icon = " ", color = "cyan" } },
    { "<leader>tx", icon = { icon = " ", color = "orange" } },
    { "<leader>t1", icon = { icon = " ", color = "green" } },
    { "<leader>t2", icon = { icon = " ", color = "cyan" } },
    { "<leader>t3", icon = { icon = " ", color = "orange" } },
    { "<leader>td", icon = { icon = " ", color = "blue" } },
    { "<leader>1", hidden = true },
    { "<leader>2", hidden = true },
    { "<leader>3", hidden = true },
  })
end

-- Normal mode toggles (<Space>tt/th/tx and <Space>1/2/3 or <Space>t1/t2/t3)
map("n", "<leader>tt", "<cmd>Term<CR>", { desc = "Toggle Floating Terminal (1: Term / Devcontainer)" })
map("n", "<leader>th", "<cmd>TermHost<CR>", { desc = "Toggle Host Floating Terminal (2: macOS zsh)" })
map("n", "<leader>tx", "<cmd>TermTmux<CR>", { desc = "Toggle Tmux Floating Terminal (3: Tmux)" })
map("n", "<leader>t1", "<cmd>Term<CR>", { desc = "Toggle Floating Terminal 1 (Term / Devcontainer)" })
map("n", "<leader>t2", "<cmd>TermHost<CR>", { desc = "Toggle Floating Terminal 2 (Host zsh)" })
map("n", "<leader>t3", "<cmd>TermTmux<CR>", { desc = "Toggle Floating Terminal 3 (Tmux)" })
map("n", "<leader>1", "<cmd>Term<CR>", { desc = "Toggle Floating Terminal 1 (Term / Devcontainer)" })
map("n", "<leader>2", "<cmd>TermHost<CR>", { desc = "Toggle Floating Terminal 2 (Host zsh)" })
map("n", "<leader>3", "<cmd>TermTmux<CR>", { desc = "Toggle Floating Terminal 3 (Tmux)" })
map("n", "<leader>td", "<cmd>LazyDocker<CR>", { desc = "Open LazyDocker floating modal" })
map("t", "<Esc><Esc>", "<C-\\><C-n><cmd>lua require('core.terminals').hide()<CR>", { desc = "Hide floating terminal" })

return M
