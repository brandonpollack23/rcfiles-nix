return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        htmldjango = { "djlint" },
        -- keep html too if not already set by LazyVim extra
        html = { "prettier" },
        nix = { "alejandra" },
      },
    },
  },
}
