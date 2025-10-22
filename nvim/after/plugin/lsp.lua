local lsp = require('lsp-zero').preset({
manage_nvim_cmp = {
  set_sources = 'lsp',
  set_basic_mappings = true,
  set_extra_mappings = true,
  use_luasnip = true,
  set_format = true,
  documentation_window = true,
}
})

lsp.on_attach(function(client, bufnr)  -- see :help lsp-zero-keybindings
  -- to learn the available actions
  lsp.default_keymaps({buffer = bufnr})
end)

-- (Optional) Configure lua language server for neovim
require('lspconfig').lua_ls.setup(lsp.nvim_lua_ls())

lsp.ensure_installed({
  'lua-language-server',
  'tsserver',
  'rust_analyzer',
  'pyright'
})

local cmp = require('cmp')
local cmp_select = {behavior = cmp.SelectBehavior.Select}
local cmp_mappings = lsp.defaults.cmp_mappings({
  ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
  ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
  ['<Tab>'] = cmp.mapping.confirm({ select = true }),
})

local cmp_action = require('lsp-zero').cmp_action()

cmp.setup({
  mapping = {
    ['<Tab>'] = cmp_action.tab_complete(),
    ['<S-Tab>'] = cmp_action.select_prev_or_fallback(),
  }
})

lsp.setup() 
