-- ============================================================================
-- Persistent UI Toggle State (Per-GitHub Project + Global Fallback on Disk)
-- Stored in ~/.local/state/nvim/ui-toggles.json
-- ============================================================================

local M = {}

local state_file = vim.fn.stdpath("state") .. "/ui-toggles.json"
local project_key_cache = {}

--- Resolve a stable project identifier from the GitHub remote (e.g. "owner/repo"),
--- falling back to the git root directory or cwd if not in a git repository.
---@return string
function M.get_project_key()
  local cwd = vim.fn.getcwd()
  if project_key_cache[cwd] then
    return project_key_cache[cwd]
  end

  local remote = vim.fn.systemlist({ "git", "-C", cwd, "config", "--get", "remote.origin.url" })[1]
  if vim.v.shell_error == 0 and remote and remote ~= "" then
    -- Normalize SSH (git@github.com:owner/repo.git) and HTTPS (https://github.com/owner/repo.git)
    local cleaned = remote:gsub("%.git$", ""):gsub("/+$", "")
    local owner_repo = cleaned:match("[:/]([^/:]+/[^/:]+)$")
    local key = owner_repo or cleaned
    project_key_cache[cwd] = key
    return key
  end

  local git_root = vim.fn.systemlist({ "git", "-C", cwd, "rev-parse", "--show-toplevel" })[1]
  if vim.v.shell_error == 0 and git_root and git_root ~= "" then
    project_key_cache[cwd] = git_root
    return git_root
  end

  project_key_cache[cwd] = cwd
  return cwd
end

local function read_store()
  if vim.fn.filereadable(state_file) == 0 then
    return { global = {}, projects = {} }
  end
  local lines = vim.fn.readfile(state_file)
  local ok, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
  if not ok or type(decoded) ~= "table" then
    return { global = {}, projects = {} }
  end
  decoded.global = decoded.global or {}
  decoded.projects = decoded.projects or decoded.folders or {}
  return decoded
end

local function write_store(data)
  vim.fn.mkdir(vim.fn.fnamemodify(state_file, ":h"), "p")
  local ok, encoded = pcall(vim.json.encode, data)
  if ok then
    vim.fn.writefile({ encoded }, state_file)
  end
end

--- Get a toggle value for the current GitHub project (falls back to global, then `default`)
---@param key string
---@param default boolean
---@return boolean
function M.get(key, default)
  local store = read_store()
  local proj = M.get_project_key()
  if store.projects[proj] and store.projects[proj][key] ~= nil then
    return store.projects[proj][key]
  end
  if store.global[key] ~= nil then
    return store.global[key]
  end
  return default
end

--- Save a toggle value for the current GitHub project (and update global default)
---@param key string
---@param value boolean
function M.set(key, value)
  local store = read_store()
  local proj = M.get_project_key()
  store.projects[proj] = store.projects[proj] or {}
  store.projects[proj][key] = value
  store.global[key] = value
  write_store(store)
end

return M
