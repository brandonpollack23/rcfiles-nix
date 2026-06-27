return {
  {
    "folke/trouble.nvim",
    opts = {
      modes = {
        symbols = { -- Configure symbols mode
          win = {
            type = "split", -- split window
            relative = "win", -- relative to current window
            position = "right", -- right side
            size = 0.3, -- 30% of the window
          },
        },
      },
    },
  },
  {
    "akinsho/bufferline.nvim",
    keys = {
      { "<leader>bh", "<cmd>BufferLineMovePrev<cr>", desc = "Move buffer left" },
      { "<leader>bl", "<cmd>BufferLineMoveNext<cr>", desc = "Move buffer right" },
    },
  },
  -- {
  --   "Isrothy/neominimap.nvim",
  --   dependencies = { "lewis6991/gitsigns.nvim", "nvim-treesitter/nvim-treesitter" },
  --   version = "v3.x.x",
  --   lazy = false, -- NOTE: NO NEED to Lazy load
  --   keys = {
  --     -- Global Minimap Controls
  --     { "<leader>mm", "<cmd>Neominimap Toggle<cr>", desc = "Toggle global minimap" },
  --     { "<leader>mo", "<cmd>Neominimap Enable<cr>", desc = "Enable global minimap" },
  --     { "<leader>mc", "<cmd>Neominimap Disable<cr>", desc = "Disable global minimap" },
  --     { "<leader>mr", "<cmd>Neominimap Refresh<cr>", desc = "Refresh global minimap" },
  --
  --     -- Window-Specific Minimap Controls
  --     { "<leader>mwt", "<cmd>Neominimap WinToggle<cr>", desc = "Toggle minimap for current window" },
  --     { "<leader>mwr", "<cmd>Neominimap WinRefresh<cr>", desc = "Refresh minimap for current window" },
  --     { "<leader>mwo", "<cmd>Neominimap WinEnable<cr>", desc = "Enable minimap for current window" },
  --     { "<leader>mwc", "<cmd>Neominimap WinDisable<cr>", desc = "Disable minimap for current window" },
  --
  --     -- Tab-Specific Minimap Controls
  --     { "<leader>mtt", "<cmd>Neominimap TabToggle<cr>", desc = "Toggle minimap for current tab" },
  --     { "<leader>mtr", "<cmd>Neominimap TabRefresh<cr>", desc = "Refresh minimap for current tab" },
  --     { "<leader>mto", "<cmd>Neominimap TabEnable<cr>", desc = "Enable minimap for current tab" },
  --     { "<leader>mtc", "<cmd>Neominimap TabDisable<cr>", desc = "Disable minimap for current tab" },
  --
  --     -- Buffer-Specific Minimap Controls
  --     { "<leader>mbt", "<cmd>Neominimap BufToggle<cr>", desc = "Toggle minimap for current buffer" },
  --     { "<leader>mbr", "<cmd>Neominimap BufRefresh<cr>", desc = "Refresh minimap for current buffer" },
  --     { "<leader>mbo", "<cmd>Neominimap BufEnable<cr>", desc = "Enable minimap for current buffer" },
  --     { "<leader>mbc", "<cmd>Neominimap BufDisable<cr>", desc = "Disable minimap for current buffer" },
  --
  --     ---Focus Controls
  --     { "<leader>mf", "<cmd>Neominimap Focus<cr>", desc = "Focus on minimap" },
  --     { "<leader>mu", "<cmd>Neominimap Unfocus<cr>", desc = "Unfocus minimap" },
  --     { "<leader>ms", "<cmd>Neominimap ToggleFocus<cr>", desc = "Switch focus on minimap" },
  --   },
  --   init = function()
  --     -- The following options are recommended when layout == "float"
  --     vim.opt.wrap = false
  --     vim.opt.sidescrolloff = 36 -- Set a large value
  --
  --     --- Put your configuration here
  --     ---@type Neominimap.UserConfig
  --     vim.g.neominimap = {
  --       auto_enable = true,
  --       delay = 1000,
  --       click = {
  --         enable = true,
  --       },
  --       mark = {
  --         enable = true,
  --       },
  --       search = {
  --         enable = true,
  --       },
  --     }
  --
  --     -- Make the warning highlight slightly less harsh
  --     vim.api.nvim_set_hl(0, "NeominimapWarnLine", { bg = "#303000" })
  --     vim.api.nvim_set_hl(0, "NeominimapInfoLine", { bg = "#235e8f" })
  --   end,
  -- },
}
