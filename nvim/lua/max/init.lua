require("max.set")
require("max.remap")
require("max.lazy_init")

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

local MaxGroup = augroup("Max", {})
local yank_group = augroup("HighlightYank", {})

function R(name)
  require("plenary.reload").reload_module(name)
end

-- Flash highlight on yank
autocmd("TextYankPost", {
  group = yank_group,
  pattern = "*",
  callback = function()
    vim.highlight.on_yank({
      higroup = "IncSearch",
      timeout = 40,
    })
  end,
})

-- Strip trailing whitespace on save
autocmd({ "BufWritePre" }, {
  group = MaxGroup,
  pattern = "*",
  command = [[%s/\s\+$//e]],
})

-- LSP keymaps on attach
autocmd("LspAttach", {
  group = MaxGroup,
  callback = function(e)
    local opts = { buffer = e.buf }
    vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
    vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)
    vim.keymap.set("n", "<leader>vws", function() vim.lsp.buf.workspace_symbol() end, opts)
    vim.keymap.set("n", "<leader>vd", function() vim.diagnostic.open_float() end, opts)
    vim.keymap.set("n", "<leader>vca", function() vim.lsp.buf.code_action() end, opts)
    vim.keymap.set("n", "<leader>vrr", function() vim.lsp.buf.references() end, opts)
    vim.keymap.set("n", "<leader>vrn", function() vim.lsp.buf.rename() end, opts)
    vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help() end, opts)
    vim.keymap.set("n", "[d", function() vim.diagnostic.goto_next() end, opts)
    vim.keymap.set("n", "]d", function() vim.diagnostic.goto_prev() end, opts)
  end,
})

-- Todo list highlighting for .md and .txt files
local function setup_todo_highlights()
  vim.api.nvim_set_hl(0, "TodoPending", { fg = "#A0A0A0" })
  vim.api.nvim_set_hl(0, "TodoInProgress", { fg = "#4169E1" })
  vim.api.nvim_set_hl(0, "TodoDone", { fg = "#228B22", strikethrough = true })

  vim.cmd([[
    syntax match TodoPending /^\s*-\s.*$/
    syntax match TodoInProgress /^\s*\*\s.*$/
    syntax match TodoDone /^\s*+\s.*$/
  ]])
end

autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "*.md", "*.txt" },
  callback = setup_todo_highlights,
})

vim.g.netrw_browse_split = 0
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 25
