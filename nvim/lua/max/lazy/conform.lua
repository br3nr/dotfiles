return {
  "stevearc/conform.nvim",
  config = function()
    require("conform").setup({
      format_on_save = {
        timeout_ms = 5000,
        lsp_format = "fallback",
      },
      formatters_by_ft = {
        lua = { "stylua" },
        html = { "prettier" },
        css = { "prettier" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        json = { "prettier" },
        markdown = { "prettier" },
      },
    })

    vim.keymap.set("n", "<leader>f", function()
      require("conform").format({ bufnr = 0 })
    end)
  end,
}
