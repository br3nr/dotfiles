local ok_theme, theme = pcall(require, "theme.current")

function ColorNeovim(color)
  color = color or (ok_theme and theme.name or "cyberdream")

  if ok_theme and theme.background and theme.background ~= "" then
    vim.o.background = theme.background
  end

  if color == "catppuccin" and ok_theme and theme.flavour and theme.flavour ~= "" then
    vim.g.catppuccin_flavour = theme.flavour
  end

  local ok = pcall(vim.cmd.colorscheme, color)
  if not ok then
    vim.defer_fn(function()
      pcall(vim.cmd.colorscheme, color)
    end, 100)
  end

  vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
  vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
end

return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1100,
  },
  {
    "scottmckendry/cyberdream.nvim",
    name = "cyberdream",
    lazy = false,
    priority = 1000,
    config = function()
      ColorNeovim()
    end,
  },
}
