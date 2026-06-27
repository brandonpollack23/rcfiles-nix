return {
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    keys = {
      -- 0. disable s so replace still works
      { "s", mode = { "n", "x", "o" }, false },
      -- 1. Generic "Jump to anywhere" (The modern way)
      {
        "<leader><leader>s",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump()
        end,
        desc = "Flash Jump",
      },
      -- 2. EasyMotion Style: Jump to Word (<Leader><Leader>w)
      {
        "<leader><leader>w",
        mode = { "n", "x", "o" },
        function()
          local Flash = require("flash")
          local function format(opts)
            return {
              { opts.match.label1, "FlashMatch" },
              { opts.match.label2, "FlashLabel" },
            }
          end
          Flash.jump({
            search = { mode = "search", max_length = 0 },
            label = { after = false, before = { 0, 0 }, uppercase = false, format = format },
            pattern = [[\<]],
            action = function(match, state)
              state:hide()
              Flash.jump({
                search = { max_length = 0 },
                highlight = { matches = false },
                label = { format = format },
                matcher = function(win)
                  return vim.tbl_filter(function(m)
                    return m.label == match.label and m.win == win
                  end, state.results)
                end,
                labeler = function(matches)
                  for _, m in ipairs(matches) do
                    m.label = m.label2
                  end
                end,
              })
            end,
            labeler = function(matches, state)
              local labels = state:labels()
              for m, match in ipairs(matches) do
                match.label1 = labels[math.floor((m - 1) / #labels) + 1]
                match.label2 = labels[(m - 1) % #labels + 1]
                match.label = match.label1
              end
            end,
          })
        end,
        desc = "Jump to Word",
      },
      {
        "<leader><leader>e",
        mode = { "n", "x", "o" },
        function()
          local Flash = require("flash")
          local function format(opts)
            return {
              { opts.match.label1, "FlashMatch" },
              { opts.match.label2, "FlashLabel" },
            }
          end
          Flash.jump({
            search = { mode = "search", max_length = 0 },
            label = { after = false, before = { 0, 0 }, uppercase = false, format = format },
            pattern = [[\>]],
            action = function(match, state)
              state:hide()
              Flash.jump({
                search = { max_length = 0 },
                highlight = { matches = false },
                label = { format = format },
                matcher = function(win)
                  return vim.tbl_filter(function(m)
                    return m.label == match.label and m.win == win
                  end, state.results)
                end,
                labeler = function(matches)
                  for _, m in ipairs(matches) do
                    m.label = m.label2
                  end
                end,
              })
            end,
            labeler = function(matches, state)
              local labels = state:labels()
              for m, match in ipairs(matches) do
                match.label1 = labels[math.floor((m - 1) / #labels) + 1]
                match.label2 = labels[(m - 1) % #labels + 1]
                match.label = match.label1
              end
            end,
          })
        end,
        desc = "Jump to Word",
      },
      {
        "<leader><leader>b",
        mode = { "n", "x", "o" },
        function()
          local Flash = require("flash")
          local function format(opts)
            return {
              { opts.match.label1, "FlashMatch" },
              { opts.match.label2, "FlashLabel" },
            }
          end
          Flash.jump({
            search = { mode = "search", max_length = 0, forward = false, wrap = false },
            label = { after = false, before = { 0, 0 }, uppercase = false, format = format },
            pattern = [[\<]],
            action = function(match, state)
              state:hide()
              Flash.jump({
                search = { max_length = 0 },
                highlight = { matches = false },
                label = { format = format },
                matcher = function(win)
                  return vim.tbl_filter(function(m)
                    return m.label == match.label and m.win == win
                  end, state.results)
                end,
                labeler = function(matches)
                  for _, m in ipairs(matches) do
                    m.label = m.label2
                  end
                end,
              })
            end,
            labeler = function(matches, state)
              local labels = state:labels()
              for m, match in ipairs(matches) do
                match.label1 = labels[math.floor((m - 1) / #labels) + 1]
                match.label2 = labels[(m - 1) % #labels + 1]
                match.label = match.label1
              end
            end,
          })
        end,
        desc = "Jump to Word",
      },
      -- 3. EasyMotion Style: Jump to Line (<Leader><Leader>l)
      {
        "<leader><leader>j",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump({
            search = { mode = "search", max_length = 0 },
            label = { after = { 0, 0 } },
            pattern = [[^\s*\zs\S\|^']],
          })
        end,
        desc = "Jump to Line",
      },
      {
        "<leader><leader>k",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump({
            search = { mode = "search", max_length = 0 },
            label = { after = { 0, 0 } },
            pattern = [[^\s*\zs\S\|^']],
            direction = "backward",
          })
        end,
        desc = "Jump to Line",
      },
    },
  },
  {
    "folke/snacks.nvim",
    keys = {
      -- unlock this for other random stuff
      { "<leader><leader>", false },
    },
  },
}
