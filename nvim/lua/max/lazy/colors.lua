local function load_theme()
  local path = vim.fn.stdpath("config") .. "/lua/theme/current.lua"
  local ok, theme = pcall(dofile, path)
  if ok and type(theme) == "table" then
    return theme
  end
  return { name = "cyberdream", flavour = "", background = "dark" }
end

function ColorNeovim(color)
  local theme = load_theme()
  color = color or theme.name

  if theme.background and theme.background ~= "" then
    vim.o.background = theme.background
  end

  if color == "catppuccin" and theme.flavour and theme.flavour ~= "" then
    vim.g.catppuccin_flavour = theme.flavour
  end

  if color == "rose-pine" and theme.flavour and theme.flavour ~= "" then
    local ok_rose, rose = pcall(require, "rose-pine")
    if ok_rose then
      rose.setup({
        variant = theme.flavour,
      })
    end
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

function ReloadTheme()
  ColorNeovim()
end

local runtime_dir = vim.env.XDG_RUNTIME_DIR
if runtime_dir and vim.v.servername == "" then
  pcall(vim.fn.serverstart, runtime_dir .. "/nvim-theme-" .. vim.fn.getpid() .. ".sock")
end

return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1100,
  },
  {
    "rose-pine/neovim",
    name = "rose-pine",
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
