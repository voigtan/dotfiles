-- ============================================================================
-- Telescope Fuzzy Finder (Files, Live Grep, Buffers, LSP Symbols & References)
-- ============================================================================

local map = vim.keymap.set

local ok_telescope, telescope = pcall(require, "telescope")
if ok_telescope then
  local action_state = require("telescope.actions.state")
  local hidden_enabled = true

  -- Live toggle for hidden/dotfiles from inside an open Telescope picker (<C-h> or <M-h>)
  local function toggle_hidden_files(prompt_bufnr)
    local picker = action_state.get_current_picker(prompt_bufnr)
    local prompt = picker:_get_prompt()
    local title = picker.prompt_title or ""
    hidden_enabled = not hidden_enabled

    if title:match("Grep") then
      require("telescope.builtin").live_grep({
        default_text = prompt,
        additional_args = hidden_enabled and { "--hidden", "--glob", "!**/.git/*" } or {},
      })
    else
      require("telescope.builtin").find_files({
        default_text = prompt,
        hidden = hidden_enabled,
        file_ignore_patterns = { "^%.git/", "/%.git/" },
      })
    end
  end

  telescope.setup({
    defaults = {
      layout_strategy = "horizontal",
      sorting_strategy = "ascending",
      layout_config = {
        prompt_position = "top",
      },
      file_ignore_patterns = { "^%.git/", "/%.git/" },
      mappings = {
        i = {
          ["<C-h>"] = { toggle_hidden_files, type = "action", opts = { desc = "Toggle dotfiles (hidden files)" } },
          ["<F1>"] = "which_key",
        },
        n = {
          ["<C-h>"] = { toggle_hidden_files, type = "action", opts = { desc = "Toggle dotfiles (hidden files)" } },
          ["?"] = "which_key",
          ["<F1>"] = "which_key",
        },
      },
    },
    pickers = {
      find_files = {
        hidden = true, -- Include dotfiles by default (excludes .git/)
      },
      live_grep = {
        additional_args = function()
          return hidden_enabled and { "--hidden", "--glob", "!**/.git/*" } or {}
        end,
      },
    },
  })
end

-- Keymaps & Which-Key Group + Icons
local ok_wk, wk = pcall(require, "which-key")
if ok_wk then
  wk.add({
    { "<leader>f", group = "Find / Format" },
    { "<leader>fc", icon = { icon = " ", color = "purple" } },
    { "<leader>fg", icon = { icon = " ", color = "green" } },
    { "<leader>fh", icon = { icon = "󰋖 ", color = "yellow" } },
    { "<leader>fk", icon = { icon = "󰌌 ", color = "cyan" } },
    { "<leader>fs", icon = { icon = " ", color = "green" } },
  })
end

map("n", "<C-p>", function()
  require("telescope.builtin").find_files()
end, { desc = "Find files" })
map("n", "<leader>ff", function()
  require("telescope.builtin").find_files()
end, { desc = "Find files" })
map("n", "<leader>fg", function()
  require("telescope.builtin").live_grep()
end, { desc = "Live grep across project" })
map("n", "<leader>fb", function()
  require("telescope.builtin").buffers()
end, { desc = "Switch open buffers" })
map("n", "<leader>fs", function()
  require("telescope.builtin").lsp_document_symbols()
end, { desc = "Document symbols" })
map("n", "<leader>fk", function()
  require("telescope.builtin").keymaps()
end, { desc = "Search all keymaps" })
map("n", "<leader>fc", function()
  require("telescope.builtin").commands()
end, { desc = "Command Palette (search commands)" })
map("n", "<leader>fh", function()
  require("telescope.builtin").help_tags()
end, { desc = "Search Neovim help tags" })
map("n", "gd", function()
  require("telescope.builtin").lsp_definitions()
end, { desc = "Go to definition" })
map("n", "gr", function()
  require("telescope.builtin").lsp_references()
end, { desc = "Find references" })
