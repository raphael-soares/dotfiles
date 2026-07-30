vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      telemetry = { enable = false },
      hint = {
        enable = true,
        paramName = "Literal",
        paramType = false,
        setType = false,
        arrayIndex = "Disable",
        await = true,
      },
    },
  },
})
