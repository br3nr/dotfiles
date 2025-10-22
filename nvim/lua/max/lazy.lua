-- ~/.config/nvim/lua/max/lazy.lua
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("lazy").setup({
  spec = {
    {
      'nvim-telescope/telescope.nvim',
      tag = '0.1.2',
      dependencies = { 'nvim-lua/plenary.nvim' }
    },

    {
      'scottmckendry/cyberdream.nvim',
      name = "cyberdream",
      --lazy = false,
      priority = 1000,
    },

    {
      'vyfor/cord.nvim',
      lazy = false,
      config = function()
        require('cord').setup()
      end
    },

    {
      'nvim-treesitter/nvim-treesitter',
      build = ':TSUpdate',
    },

    'nvim-treesitter/playground',
    'nvim-lua/plenary.nvim',
    'ThePrimeagen/harpoon',
    'mbbill/undotree',
    'tpope/vim-fugitive',

    {
      'VonHeikemen/lsp-zero.nvim',
      branch = 'v2.x',
      dependencies = {
        'neovim/nvim-lspconfig',
        'williamboman/mason.nvim',
        'williamboman/mason-lspconfig.nvim',
        'hrsh7th/nvim-cmp',
        'hrsh7th/cmp-nvim-lsp',
        'L3MON4D3/LuaSnip',
      },
    },
  },
  install = { colorscheme = { "cyberdream" } },
  checker = { enabled = true },
})
