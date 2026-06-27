return {
  {
    "mfussenegger/nvim-dap",
    opts = function()
      local dap = require("dap")
      -- assumes gdb is installed with the right version
      -- adapter is a function so we can pass the program via -se,
      -- ensuring symbols are loaded before DAP sets breakpoints
      dap.adapters.gdb = function(callback, config)
        local args = { "-i", "dap" }
        if config.program then
          table.insert(args, "-se")
          table.insert(args, config.program)
        end
        callback({
          type = "executable",
          command = "gdb",
          args = args,
        })
      end

      -- Load .vscode/launch.json, mapping both cppdbg and gdb types to our gdb adapter
      local vscode = require("dap.ext.vscode")
      vscode.getconfigs()
    end,
  },
}
