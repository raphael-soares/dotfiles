vim.lsp.config("basedpyright", {
  settings = {
    basedpyright = {
      analysis = {
        inlayHints = {
          variableTypes = true,
          functionReturnTypes = true,
          callArgumentNames = true,
          genericTypes = false,
        },
      },
    },
  },
})
