-- ============================================================================
-- Right-Click Context Menu Registry (PopUp)
-- Allows each feature module to register its own right-click menu items
-- by context ("editor", "neo-tree", etc.) without cross-module coupling.
-- ============================================================================

local M = {}

---@class ContextMenuItem
---@field priority string       Menu priority (e.g. "100.10")
---@field label? string         Menu item text (spaces will be escaped automatically)
---@field cmd? string           Command to execute
---@field mode? "a"|"n"|"v"     Menu mode ("a" default, "n" normal, "v" visual)
---@field remap? boolean        Use menu (remap) instead of noremenu
---@field sep? string           Separator id (e.g. "-lsp-sep-")

---@type table<string, ContextMenuItem[]>
local registry = {
  editor = {},
  ["neo-tree"] = {},
}

---@type string[]
local mounted_names = {}

local function escape_label(str)
  return (str:gsub(" ", "\\ "))
end

local function clear_mounted()
  for _, escaped_name in ipairs(mounted_names) do
    vim.cmd("silent! aunmenu PopUp." .. escaped_name)
  end
  mounted_names = {}
end

local function mount_context(ctx)
  clear_mounted()
  local items = registry[ctx] or registry.editor or {}
  local seen_names = {}

  for _, item in ipairs(items) do
    local name = item.sep or item.label
    if name then
      local escaped = escape_label(name)
      if not seen_names[escaped] then
        seen_names[escaped] = true
        table.insert(mounted_names, escaped)
      end

      if item.sep then
        vim.cmd(string.format("anoremenu %s PopUp.%s <Nop>", item.priority, escaped))
      else
        local mode = item.mode or "a"
        local menu_cmd = mode .. (item.remap and "menu" or "noremenu")
        vim.cmd(string.format("%s %s PopUp.%s %s", menu_cmd, item.priority, escaped, item.cmd))
      end
    end
  end
end

--- Register right-click PopUp menu items for a context ("editor", "neo-tree", etc.)
---@param context string
---@param items ContextMenuItem[]
function M.register(context, items)
  registry[context] = registry[context] or {}
  vim.list_extend(registry[context], items)
  if context == "editor" and vim.bo.filetype ~= "neo-tree" then
    mount_context("editor")
  end
end

-- Remove noisy default "How-to disable mouse" item once
vim.cmd("silent! aunmenu PopUp.How-to\\ disable\\ mouse")

-- Dynamically switch the right-click menu based on the active buffer's filetype
vim.api.nvim_create_autocmd("MenuPopup", {
  group = vim.api.nvim_create_augroup("CoreContextMenu", { clear = true }),
  desc = "Mount right-click PopUp menu items for current filetype context",
  callback = function()
    local ft = vim.bo.filetype
    if registry[ft] and #registry[ft] > 0 then
      mount_context(ft)
    else
      mount_context("editor")
    end
  end,
})

return M
