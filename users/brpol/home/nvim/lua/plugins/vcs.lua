return {
  "rafikdraoui/jj-diffconflicts",
  {
    "gitsigns.nvim",
    opts = {
      current_line_blame = true,
      current_line_blame_formatter = "<abbrev_sha> <author>, <author_time:%R> - <summary>",
    },
  },
  --   remember to set workspace root with
  --     require("jj-signs").setup({
  --   jj_repo = "/path/to/workspace",
  -- })
  -- in .nvim.lua of your workspaces
  {
    "bnrobinson93/jj-signs.nvim",
    event = "LazyFile",
    opts = {},
  },
  -- diff view for merge conflicts
  {
    "dlyongemallo/diffview-plus.nvim",
    version = "*",
    -- optional: lazy-load on command
    -- cmd = {
    --     "DiffviewOpen",
    --     "DiffviewToggle",
    --     "DiffviewFileHistory",
    --     "DiffviewDiffFiles",
    --     "DiffviewLog",
    -- },
    -- diffchar.vim gives character-level diff precision, pairs with enhanced_diff_hl below
    dependencies = { "rickhowe/diffchar.vim" },
    opts = {
      enhanced_diff_hl = true,
      diffopt = { algorithm = "histogram" },
      view = {
        merge_tool = {
          layout = "diff4_mixed",
          disable_diagnostics = true,
          winbar_info = true,
        },
        cycle_layouts = {
          merge_tool = { "diff4_mixed", "diff3_mixed", "diff3_horizontal", "diff1_plain" },
        },
      },
    },
    keys = {
      -- Toggle diffview open/close
      { "<leader>zv", "<cmd>DiffviewToggle<cr>", desc = "Toggle Diffview" },

      -- Diff working directory
      { "<leader>zo", "<cmd>DiffviewOpen<cr>", desc = "Diffview open" },
      { "<leader>zc", "<cmd>DiffviewClose<cr>", desc = "Diffview close" },

      -- File history
      { "<leader>zh", "<cmd>DiffviewFileHistory %<cr>", desc = "File history (current file)" },
      { "<leader>zH", "<cmd>DiffviewFileHistory<cr>", desc = "File history (repo)" },

      -- Visual mode: history for selection
      {
        "<leader>zh",
        "<Esc><cmd>'<,'>DiffviewFileHistory --follow<CR>",
        mode = "v",
        desc = "Range history",
      },

      -- Single line history
      { "<leader>zl", "<cmd>.DiffviewFileHistory --follow<CR>", desc = "Line history" },

      -- Diff against main/master branch (useful before merging)
      {
        "<leader>zm",
        function()
          -- Try main first, fall back to master
          local result = vim.fn.systemlist({ "git", "rev-parse", "--verify", "main" })
          local ok = vim.v.shell_error == 0 and result[1] ~= nil and result[1] ~= ""
          local branch = ok and "main" or "master"
          vim.cmd("DiffviewOpen " .. branch)
        end,
        desc = "Diff against main/master",
      },
    },
  },
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>z", group = "Diffview (vcs)" },
      },
    },
  },
}
