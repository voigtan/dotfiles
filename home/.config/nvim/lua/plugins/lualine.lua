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
      disabled_filetypes = { statusline = { "neo-tree" } },
    },
    sections = {
      lualine_a = {
        -- {
        --   function()
        --     local sys = vim.uv.os_uname().sysname
        --     if sys == "Darwin" then
        --       return ""
        --     elseif sys == "Linux" then
        --       return ""
        --     elseif sys:match("Windows") then
        --       return ""
        --     end
        --     return sys
        --   end,
        -- },
        "mode",
      },
      lualine_b = { "branch", "diff", "diagnostics" },
      lualine_c = { { "filename", path = 1 } },
      lualine_x = {
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
