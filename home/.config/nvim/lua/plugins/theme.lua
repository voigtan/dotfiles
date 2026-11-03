-- ============================================================================
-- Theme & Icons ("Catppuccin Frappé" & "catppuccin-frappe")
-- ============================================================================

local ok_catppuccin, catppuccin = pcall(require, "catppuccin")
if ok_catppuccin then
  catppuccin.setup({
    flavour = "frappe",
    integrations = {
      treesitter = true,
      treesitter_context = true,
      gitsigns = true,
      neotree = true,
      telescope = { enabled = true },
      which_key = true,
      native_lsp = {
        enabled = true,
        inlay_hints = { background = true },
      },
    },
  })
  vim.cmd.colorscheme("catppuccin-frappe")
end

local ok_devicons, devicons = pcall(require, "nvim-web-devicons")
if ok_devicons then
  devicons.setup({
    color_icons = true,
    default = true,
  })
end
