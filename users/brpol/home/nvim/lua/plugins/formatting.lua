return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters = {
        prettier = {
          prepend_args = function(_, ctx)
            local filetype = vim.bo[ctx.buf].filetype
            if filetype == "markdown" or filetype == "markdown.mdx" then
              return { "--print-width", "100", "--prose-wrap", "always" }
            end
            return {}
          end,
        },
      },
      formatters_by_ft = {
        htmldjango = { "djlint" },
        -- keep html too if not already set by LazyVim extra
        html = { "prettier" },
        nix = { "alejandra" },
      },
    },
  },
}
