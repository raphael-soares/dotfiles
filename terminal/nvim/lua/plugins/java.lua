return {
  "nvim-java/nvim-java",
  config = function()
    local jdk_dirs = vim.fn.glob(vim.fn.stdpath("data") .. "/nvim-java/packages/openjdk/*/jdk-*/", false, true)
    if #jdk_dirs > 0 then
      vim.env.JAVA_HOME = jdk_dirs[1]:gsub("/$", "")
    end

    require("java").setup({})

    local capabilities = vim.lsp.protocol.make_client_capabilities()
    local ok, blink = pcall(require, "blink.cmp")
    if ok then
      capabilities = vim.tbl_deep_extend("force", capabilities, blink.get_lsp_capabilities())
    end

    vim.lsp.config("jdtls", {
      capabilities = capabilities,
      settings = {
        java = {
          inlayHints = {
            parameterNames = {
              enabled = "all",
            },
          },
        },
      },
    })

    vim.lsp.enable("jdtls")
  end,
}
