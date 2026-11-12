-- ============================================================================
-- Lualine Statusbar (Catppuccin Frappé + Active LSP Indicator)
-- ============================================================================

local ok_lualine, lualine = pcall(require, "lualine")

if ok_lualine then
  lualine.setup({
    options = {
      globalstatus = true,
      component_separators = { left = "│", right = "│" },
      section_separators = { left = "", right = "" },
      disabled_filetypes = { statusline = { "neo-tree" } }, -- Disable Lualine statusline for Neo-tree file explorer
    },
    sections = {
      lualine_a = { "mode" },
      lualine_b = { "branch", "diff", "diagnostics" },
      lualine_c = { { "filename", path = 1 } },
      lualine_x = {
        {
          function()
            if vim.g.vscode_keys_enabled then
              return "󰨞 VSCode"
            end
            return " Neovim"
          end,
          color = function()
            if vim.g.vscode_keys_enabled then
              return { fg = "#8caaee" } -- Catppuccin Frappé Blue (VS Code)
            end
            return { fg = "#a6d189" } -- Catppuccin Frappé Green (Neovim)
          end,
          on_click = function()
            vim.cmd("ToggleVSCodeKeys")
          end,
        },
        {
          function()
            local ok_dc, dc = pcall(require, "core.devcontainer")
            if not ok_dc then
              return ""
            end
            local st = dc.get_state()
            if st == "running" then
              return "  Devcontainer"
            elseif st == "starting" then
              return "  Starting..."
            elseif st == "stopped" then
              return "  Devcontainer (off)"
            end
            return ""
          end,
          color = function()
            local ok_dc, dc = pcall(require, "core.devcontainer")
            local st = ok_dc and dc.get_state() or "none"
            if st == "running" then
              return { fg = "#a6d189" } -- Catppuccin Frappé Green
            elseif st == "starting" then
              return { fg = "#e5c890" } -- Catppuccin Frappé Yellow
            end
            return { fg = "#737994" } -- Catppuccin Frappé Overlay0 (dimmed when stopped)
          end,
        },
        {
          function()
            local clients = vim.lsp.get_clients({ bufnr = 0 })
            if #clients == 0 then
              return ""
            end
            local names = {}
            for _, client in ipairs(clients) do
              table.insert(names, client.name)
            end
            return "  " .. table.concat(names, ", ")
          end,
          color = { fg = "#8caaee" },
        },
        "encoding",
        "filetype",
      },
      -- Note: In Lualine, commenting out a section falls back to Lualine's default.
      -- Set a section to `{}` to empty/disable it:
      lualine_y = {},
      lualine_z = { "location" },
    },
  })
end
