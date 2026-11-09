-- ============================================================================
-- Native Neovim 0.12 Package Manager & Toolchain Updater (vim.pack + Mason + TS)
-- Provides :PackUpdate, :PackReview, :PackSync, :PackClean, :PackRestore, :PackLog
-- and <leader>p Which-Key bindings
-- ============================================================================

local map = vim.keymap.set

-- Tab-completion helper for installed vim.pack plugin names
local function complete_pack_names(arg_lead)
  local names = {}
  local ok, plugs = pcall(vim.pack.get)
  if not ok or type(plugs) ~= "table" then
    return names
  end
  for _, p in ipairs(plugs) do
    local name = p.spec and p.spec.name
    if name and name:find(arg_lead, 1, true) == 1 then
      table.insert(names, name)
    end
  end
  table.sort(names)
  return names
end

-- Parse optional plugin names from command arguments (nil = all plugins)
local function parse_names(fargs)
  if fargs and #fargs > 0 then
    return fargs
  end
  return nil
end

-- Auto-apply plugin updates immediately without confirmation buffer
local function pack_update(names, force)
  vim.pack.update(names, { force = force })
end

-- Remove inactive plugins from disk & clean unused Mason tools
local function pack_clean()
  local ok, plugs = pcall(vim.pack.get)
  if ok and type(plugs) == "table" then
    local inactive = {}
    for _, p in ipairs(plugs) do
      if not p.active and p.spec and p.spec.name then
        table.insert(inactive, p.spec.name)
      end
    end
    if #inactive > 0 then
      vim.pack.del(inactive)
    else
      vim.notify("vim.pack: No unused plugins to clean", vim.log.levels.INFO)
    end
  end

  if vim.fn.exists(":MasonToolsClean") == 2 then
    vim.cmd("MasonToolsClean")
  end
end

-- Sync all: vim.pack plugins + Treesitter parsers + Mason tools
local function pack_sync()
  vim.notify("Syncing plugins (vim.pack), Treesitter parsers, and Mason tools...", vim.log.levels.INFO)
  vim.pack.update(nil, { force = true })

  local ok_ts, ts = pcall(require, "nvim-treesitter")
  if ok_ts and type(ts.update) == "function" then
    ts.update()
  elseif vim.fn.exists(":TSUpdate") == 2 then
    vim.cmd("TSUpdate")
  end

  if vim.fn.exists(":MasonToolsUpdate") == 2 then
    vim.cmd("MasonToolsUpdate")
  elseif vim.fn.exists(":MasonUpdate") == 2 then
    vim.cmd("MasonUpdate")
  end
end

-- Open the native vim.pack update log file
local function pack_log()
  local log_path = vim.fn.stdpath("log") .. "/nvim-pack.log"
  if vim.fn.filereadable(log_path) == 0 then
    vim.notify("vim.pack log file does not exist yet: " .. log_path, vim.log.levels.WARN)
    return
  end
  vim.cmd.edit(vim.fn.fnameescape(log_path))
end

-- ============================================================================
-- User Commands (:Pack*)
-- ============================================================================

vim.api.nvim_create_user_command("PackUpdate", function(opts)
  pack_update(parse_names(opts.fargs), true)
end, {
  nargs = "*",
  complete = complete_pack_names,
  desc = "Auto-update vim.pack plugins immediately (force = true)",
})

vim.api.nvim_create_user_command("PackReview", function(opts)
  pack_update(parse_names(opts.fargs), false)
end, {
  nargs = "*",
  complete = complete_pack_names,
  desc = "Review incoming vim.pack plugin updates interactively (:w to apply, :q to cancel)",
})

vim.api.nvim_create_user_command("PackSync", function()
  pack_sync()
end, {
  desc = "Update all vim.pack plugins, Treesitter parsers, and Mason tools",
})

vim.api.nvim_create_user_command("PackClean", function()
  pack_clean()
end, {
  desc = "Remove unused vim.pack plugins and Mason tools from disk",
})

vim.api.nvim_create_user_command("PackRestore", function()
  vim.pack.update(nil, { force = true, target = "lockfile" })
end, {
  desc = "Restore all vim.pack plugins to revisions in nvim-pack-lock.json",
})

vim.api.nvim_create_user_command("PackLog", function()
  pack_log()
end, {
  desc = "Open nvim-pack.log update history",
})

-- ============================================================================
-- Keymaps & Which-Key Group (<leader>p...)
-- ============================================================================

local ok_wk, wk = pcall(require, "which-key")
if ok_wk then
  wk.add({
    { "<leader>p", group = "Packages & Updates", icon = { icon = "󰏗 ", color = "cyan" } },
    { "<leader>ps", icon = { icon = "󰑓 ", color = "green" } },
    { "<leader>pu", icon = { icon = "󰚰 ", color = "cyan" } },
    { "<leader>pr", icon = { icon = "󰈈 ", color = "yellow" } },
    { "<leader>pc", icon = { icon = "󰃢 ", color = "red" } },
    { "<leader>pR", icon = { icon = "󰦛 ", color = "orange" } },
    { "<leader>pl", icon = { icon = "󰌱 ", color = "azure" } },
    { "<leader>pm", icon = { icon = "󱌣 ", color = "purple" } },
    { "<leader>pt", icon = { icon = "󰐅 ", color = "green" } },
  })
end

map("n", "<leader>ps", "<cmd>PackSync<CR>", { desc = "Sync All (Plugins + Mason + Treesitter)" })
map("n", "<leader>pu", "<cmd>PackUpdate<CR>", { desc = "Update Plugins (vim.pack auto-apply)" })
map("n", "<leader>pr", "<cmd>PackReview<CR>", { desc = "Review Plugin Updates (interactive)" })
map("n", "<leader>pc", "<cmd>PackClean<CR>", { desc = "Clean Unused Plugins & Mason Tools" })
map("n", "<leader>pR", "<cmd>PackRestore<CR>", { desc = "Restore Plugins to Lockfile" })
map("n", "<leader>pl", "<cmd>PackLog<CR>", { desc = "Open Plugin Update Log" })
map("n", "<leader>pm", "<cmd>Mason<CR>", { desc = "Open Mason Tool Manager" })
map("n", "<leader>pt", "<cmd>TSUpdate<CR>", { desc = "Update Treesitter Parsers" })
