-- ============================================================================
-- Devcontainer Integration (Native Neovim 0.12 + @devcontainers/cli)
-- Passive detection of .devcontainer/devcontainer.json or .devcontainer.json
-- ============================================================================

local M = {}

local augroup = vim.api.nvim_create_augroup("CoreDevcontainer", { clear = true })
local map = vim.keymap.set

---@type "none"|"stopped"|"starting"|"running"
local current_state = "none"
local current_container_id = nil
local current_workspace = nil
local poll_in_flight = false

--- Find the workspace folder containing .devcontainer/devcontainer.json or .devcontainer.json
---@param start_dir? string
---@return string|nil workspace_root, string|nil config_path
function M.find_config(start_dir)
  local dir = vim.fn.fnamemodify(start_dir or vim.fn.getcwd(), ":p"):gsub("/+$", "")
  local candidates = {
    dir .. "/.devcontainer/devcontainer.json",
    dir .. "/.devcontainer.json",
  }
  for _, path in ipairs(candidates) do
    if vim.fn.filereadable(path) == 1 then
      return dir, path
    end
  end

  local found = vim.fs.find({ ".devcontainer", ".devcontainer.json" }, {
    upward = true,
    path = dir,
    stop = vim.uv.os_homedir(),
  })

  for _, match in ipairs(found) do
    if vim.fn.isdirectory(match) == 1 and vim.fn.filereadable(match .. "/devcontainer.json") == 1 then
      local root = vim.fn.fnamemodify(match, ":h")
      return root, match .. "/devcontainer.json"
    elseif vim.fn.filereadable(match) == 1 then
      local root = vim.fn.fnamemodify(match, ":h")
      return root, match
    end
  end

  return nil, nil
end

---@return boolean
function M.has_config()
  local root = M.find_config()
  return root ~= nil
end

---@return "none"|"stopped"|"starting"|"running"
function M.get_state()
  return current_state
end

---@return string|nil
function M.get_container_id()
  return current_container_id
end

---@return boolean
function M.is_running()
  return current_state == "running" and current_container_id ~= nil
end

--- Refresh the devcontainer status asynchronously without blocking the UI
---@param callback? fun(state: string, container_id: string|nil)
function M.refresh_status(callback)
  local root = M.find_config()
  current_workspace = root

  if not root then
    current_state = "none"
    current_container_id = nil
    if callback then
      callback(current_state, nil)
    end
    return
  end

  if current_state == "starting" then
    if callback then
      callback(current_state, current_container_id)
    end
    return
  end

  if poll_in_flight or vim.fn.executable("docker") == 0 then
    if current_state == "none" then
      current_state = "stopped"
    end
    if callback then
      callback(current_state, current_container_id)
    end
    return
  end

  poll_in_flight = true
  vim.system(
    {
      "docker",
      "ps",
      "--filter",
      "label=devcontainer.local_folder=" .. root,
      "--format",
      "{{.ID}}",
    },
    { text = true },
    vim.schedule_wrap(function(obj)
      poll_in_flight = false
      if current_state == "starting" then
        return
      end
      if obj.code == 0 and obj.stdout then
        local cid = vim.trim(obj.stdout):match("^([^\r\n]+)")
        if cid and cid ~= "" then
          current_state = "running"
          current_container_id = cid
        else
          current_state = "stopped"
          current_container_id = nil
        end
      else
        current_state = "stopped"
        current_container_id = nil
      end
      vim.cmd("redrawstatus")
      if callback then
        callback(current_state, current_container_id)
      end
    end)
  )
end

--- Build the interactive shell command to run inside the devcontainer
---@param root? string
---@return string
function M.get_shell_cmd(root)
  local ws = root or current_workspace or vim.fn.getcwd()
  local escaped_ws = vim.fn.shellescape(ws)
  return string.format(
    "devcontainer exec --workspace-folder %s sh -c 'if command -v zsh >/dev/null 2>&1; then exec zsh -l; elif command -v bash >/dev/null 2>&1; then exec bash -l; else exec sh -l; fi'",
    escaped_ws
  )
end

--- Open a centered floating terminal modal for devcontainer operations
---@param title string
---@param cmd string|string[]
---@param opts? { auto_close_on_success?: boolean, on_success?: fun(), on_fail?: fun(code: integer) }
local function open_floating_task(title, cmd, opts)
  opts = opts or {}
  local width = math.floor(vim.o.columns * 0.85)
  local height = math.floor((vim.o.lines - vim.o.cmdheight) * 0.8)
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor(((vim.o.lines - vim.o.cmdheight) - height) / 2)

  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
    title = title,
    title_pos = "center",
  })

  vim.bo[buf].filetype = "devcontainer"
  vim.bo[buf].buflisted = false

  vim.keymap.set("n", "q", function()
    if vim.api.nvim_win_is_valid(win) then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end, { buffer = buf, nowait = true, silent = true })

  vim.fn.jobstart(cmd, {
    term = true,
    on_exit = function(_, code)
      vim.schedule(function()
        if code == 0 then
          if opts.on_success then
            opts.on_success()
          end
          if opts.auto_close_on_success then
            vim.defer_fn(function()
              if vim.api.nvim_win_is_valid(win) then
                pcall(vim.api.nvim_win_close, win, true)
              end
              if vim.api.nvim_buf_is_valid(buf) then
                pcall(vim.api.nvim_buf_delete, buf, { force = true })
              end
            end, 600)
          end
        else
          if opts.on_fail then
            opts.on_fail(code)
          end
        end
      end)
    end,
  })

  vim.cmd("startinsert")
end

--- Start or rebuild the devcontainer for the current project
---@param rebuild? boolean
function M.up(rebuild)
  local root = M.find_config()
  if not root then
    vim.notify("No .devcontainer/devcontainer.json found in current project", vim.log.levels.WARN)
    return
  end

  if vim.fn.executable("devcontainer") == 0 then
    vim.notify("devcontainer CLI is not installed (run: brew install devcontainer)", vim.log.levels.ERROR)
    return
  end

  current_state = "starting"
  vim.cmd("redrawstatus")

  local args = { "devcontainer", "up", "--workspace-folder", root }
  if rebuild then
    table.insert(args, "--build-no-cache")
    table.insert(args, "--remove-existing-container")
  end

  local title = rebuild and "  Rebuilding Devcontainer " or "  Starting Devcontainer "
  open_floating_task(title, args, {
    auto_close_on_success = true,
    on_success = function()
      current_state = "running"
      M.refresh_status(function(_, cid)
        vim.notify(
          string.format(" Devcontainer running%s", cid and (" (" .. cid .. ")") or ""),
          vim.log.levels.INFO
        )
      end)
    end,
    on_fail = function(code)
      current_state = "stopped"
      M.refresh_status()
      vim.notify(
        string.format("Devcontainer failed to start (exit code %d). Press 'q' to close log window.", code),
        vim.log.levels.ERROR
      )
    end,
  })
end

--- Stop the running devcontainer for the current project
function M.stop()
  local root = M.find_config()
  if not root then
    vim.notify("No .devcontainer/devcontainer.json found in current project", vim.log.levels.WARN)
    return
  end

  M.refresh_status(function(state, cid)
    if state ~= "running" or not cid then
      vim.notify("Devcontainer is not currently running", vim.log.levels.INFO)
      return
    end

    vim.notify("Stopping devcontainer " .. cid .. "...", vim.log.levels.INFO)
    vim.system({ "docker", "stop", cid }, { text = true }, vim.schedule_wrap(function(obj)
      if obj.code == 0 then
        current_state = "stopped"
        current_container_id = nil
        vim.cmd("redrawstatus")
        vim.notify(" Devcontainer stopped", vim.log.levels.INFO)
      else
        vim.notify("Failed to stop devcontainer: " .. tostring(obj.stderr), vim.log.levels.ERROR)
      end
    end))
  end)
end

--- View logs for the running devcontainer in a floating modal
function M.logs()
  M.refresh_status(function(state, cid)
    if state ~= "running" or not cid then
      vim.notify("Devcontainer is not currently running", vim.log.levels.WARN)
      return
    end
    open_floating_task("  Devcontainer Logs (" .. cid .. ") ", { "docker", "logs", "-f", "--tail", "200", cid })
  end)
end

--- Open an interactive floating terminal inside the running devcontainer
function M.open_terminal()
  local root = M.find_config()
  if not root then
    vim.notify("No .devcontainer/devcontainer.json found in current project", vim.log.levels.WARN)
    return
  end

  M.refresh_status(function(state)
    if state ~= "running" then
      vim.notify("Devcontainer is not running. Start it first with <Space>du (:DevcontainerUp)", vim.log.levels.WARN)
      return
    end
    require("core.terminals").open("term", M.get_shell_cmd(root))
  end)
end

-- Passive detection on startup and directory change (zero automatic container startup)
vim.api.nvim_create_autocmd({ "VimEnter", "DirChanged", "FocusGained" }, {
  group = augroup,
  callback = function()
    M.refresh_status()
  end,
})

-- Ex Commands
vim.api.nvim_create_user_command("DevcontainerUp", function()
  M.up(false)
end, { desc = "Start or attach to the project's devcontainer" })

vim.api.nvim_create_user_command("DevcontainerRebuild", function()
  M.up(true)
end, { desc = "Rebuild and start the project's devcontainer (--build-no-cache)" })

vim.api.nvim_create_user_command("DevcontainerStop", function()
  M.stop()
end, { desc = "Stop the running devcontainer for the current project" })

vim.api.nvim_create_user_command("DevcontainerTerm", function()
  M.open_terminal()
end, { desc = "Open integrated terminal inside the running devcontainer" })

vim.api.nvim_create_user_command("DevcontainerLogs", function()
  M.logs()
end, { desc = "Open live logs for the running devcontainer" })

vim.api.nvim_create_user_command("DevcontainerEdit", function()
  local _, cfg_path = M.find_config()
  if not cfg_path then
    vim.notify("No .devcontainer/devcontainer.json found in current project", vim.log.levels.WARN)
    return
  end
  vim.cmd("edit " .. vim.fn.fnameescape(cfg_path))
end, { desc = "Open .devcontainer/devcontainer.json in editor" })

-- Keymaps & Which-Key Group (<leader>d...)
local ok_wk, wk = pcall(require, "which-key")
if ok_wk then
  wk.add({
    { "<leader>d", group = "Devcontainer", icon = { icon = " ", color = "cyan" } },
  })
end

map("n", "<leader>du", "<cmd>DevcontainerUp<CR>", { desc = "Start / Up Devcontainer" })
map("n", "<leader>dR", "<cmd>DevcontainerRebuild<CR>", { desc = "Rebuild Devcontainer (no cache)" })
map("n", "<leader>ds", "<cmd>DevcontainerStop<CR>", { desc = "Stop Devcontainer" })
map("n", "<leader>dt", "<cmd>DevcontainerTerm<CR>", { desc = "Open Terminal in Devcontainer" })
map("n", "<leader>dl", "<cmd>DevcontainerLogs<CR>", { desc = "View Devcontainer Logs" })
map("n", "<leader>dc", "<cmd>DevcontainerEdit<CR>", { desc = "Edit devcontainer.json" })

return M
