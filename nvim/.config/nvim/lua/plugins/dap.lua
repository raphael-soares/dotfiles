-- Debugging for C only. Adapter is codelldb, installed by mason like the
-- language servers.

local BUILD_DIR = vim.fn.stdpath("cache") .. "/dap-build"

-- Compiles the current buffer and returns the binary path, or dap.ABORT so the
-- session never starts on a broken build.
local function build_current_file()
  local dap = require("dap")

  if vim.fn.executable("clang") == 0 then
    vim.notify("clang not found in PATH", vim.log.levels.ERROR, { title = "dap" })
    return dap.ABORT
  end

  vim.fn.mkdir(BUILD_DIR, "p")
  local src = vim.fn.expand("%:p")
  local out = BUILD_DIR .. "/" .. vim.fn.expand("%:t:r")

  local log = vim.fn.system({ "clang", "-g3", "-O0", "-Wall", src, "-o", out })
  if vim.v.shell_error ~= 0 then
    vim.notify(log, vim.log.levels.ERROR, { title = "build failed" })
    return dap.ABORT
  end

  return out
end

-- Shorthand so the keymap table stays one line per mapping.
local function dap_do(fn)
  return function()
    fn(require("dap"))
  end
end

return {
  "mfussenegger/nvim-dap",
  dependencies = {
    { "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" }, opts = {} },
    { "theHamsta/nvim-dap-virtual-text", opts = {} },
    {
      "jay-babu/mason-nvim-dap.nvim",
      dependencies = { "williamboman/mason.nvim" },
      opts = { ensure_installed = { "codelldb" } },
    },
  },
  keys = {
    { "<leader>db", dap_do(function(d) d.toggle_breakpoint() end), desc = "Toggle Breakpoint" },
    { "<leader>dB", dap_do(function(d) d.set_breakpoint(vim.fn.input("Condition: ")) end), desc = "Conditional Breakpoint" },
    { "<leader>dc", dap_do(function(d) d.continue() end), desc = "Continue / Start" },
    { "<leader>dg", dap_do(function(d) d.run_to_cursor() end), desc = "Run to Cursor" },
    { "<leader>dr", dap_do(function(d) d.repl.toggle() end), desc = "Toggle REPL" },
    { "<leader>dt", dap_do(function(d) d.terminate() end), desc = "Terminate" },
    { "<leader>du", function() require("dapui").toggle() end, desc = "Toggle DAP UI" },
    { "<leader>de", function() require("dapui").eval() end, mode = { "n", "v" }, desc = "Eval Expression" },
    { "<F5>", dap_do(function(d) d.continue() end), desc = "Continue / Start" },
    { "<F10>", dap_do(function(d) d.step_over() end), desc = "Step Over" },
    { "<F11>", dap_do(function(d) d.step_into() end), desc = "Step Into" },
    { "<F12>", dap_do(function(d) d.step_out() end), desc = "Step Out" },
  },
  config = function()
    local dap = require("dap")
    local dapui = require("dapui")

    dap.adapters.codelldb = {
      type = "server",
      port = "${port}",
      executable = {
        command = vim.fn.stdpath("data") .. "/mason/bin/codelldb",
        args = { "--port", "${port}" },
      },
    }

    dap.configurations.c = {
      {
        name = "Build & debug current file",
        type = "codelldb",
        request = "launch",
        program = build_current_file,
        cwd = "${workspaceFolder}",
        terminal = "integrated",
      },
      {
        name = "Debug an existing binary",
        type = "codelldb",
        request = "launch",
        program = function()
          return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
        end,
        cwd = "${workspaceFolder}",
        terminal = "integrated",
      },
    }

    dap.listeners.after.event_initialized["dapui"] = dapui.open
    dap.listeners.before.event_terminated["dapui"] = dapui.close
    dap.listeners.before.event_exited["dapui"] = dapui.close

    vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticSignError" })
    vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticSignWarn" })
    vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticSignInfo", linehl = "Visual" })
  end,
}
