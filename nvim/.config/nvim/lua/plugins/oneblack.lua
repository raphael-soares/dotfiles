return {
  "olimorris/onedarkpro.nvim",
  priority = 1000,
  config = function()
    require("onedarkpro").setup({
      options = {
        transparency = true,
      },
      highlights = {
        ["@keyword.type"] = { link = "@keyword" },
        ["@lsp.type.keyword"] = { link = "@keyword" },
        ["@lsp.type.modifier.java"] = { link = "@keyword" },
        javaBlockOther = { link = "@keyword" },
        javaScopeDecl = { link = "@keyword" },
        ["@lsp.mod.unused"] = { fg = "${gray}" },
        ["@lsp.type.annotationMember"] = { fg = "${orange}" },
        Boolean = { fg = "${purple}" },
        ["@lsp.type.record"] = { link = "@type" },
        ["@lsp.type.annotation"] = { link = "@type" },
        ["@variable.parameter"] = { fg = "${orange}" },
        ["@lsp.type.parameter"] = { fg = "${orange}" },
        ["@variable"] = { fg = "NONE" },
        ["@variable.typescript"] = { link = "@variable" },
        ["@variable.javascript"] = { link = "@variable" },
        ["@lsp.type.variable"] = { fg = "NONE" },
        ["@variable.member"] = { fg = "${red}" },
        ["@property"] = { fg = "${red}" },
        ["@lsp.type.field"] = { fg = "${red}" },
        ["@lsp.type.property"] = { fg = "${red}" },
        -- base46-style universal coverage for Vue/HTML/TS
        ["@tag"] = { fg = "${yellow}" },
        ["@tag.attribute"] = { fg = "${red}" },
        ["@tag.delimiter"] = { fg = "${red}" },
        ["@punctuation.bracket"] = { fg = "${red}" },
        ["@punctuation.bracket.typescript"] = { link = "@punctuation.bracket" },
        ["@punctuation.bracket.javascript"] = { link = "@punctuation.bracket" },
        ["@attribute"] = { fg = "${yellow}" },
        ["@constant"] = { fg = "${orange}" },
        ["@constant.builtin"] = { fg = "${orange}" },
        ["@constructor"] = { fg = "${cyan}" },
        ["@function.method.call"] = { link = "@function.method" },
        -- Vue: component names = yellow (type color)
        ["@lsp.type.component.vue"] = { link = "@type" },
        -- const declarations get LSP readonly modifier → override onedarkpro's @constant mapping
        ["@lsp.typemod.variable.readonly"] = { fg = "NONE" },
      },
    })

    vim.api.nvim_create_autocmd("ColorScheme", {
      pattern = "*",
      callback = function()
        vim.api.nvim_set_hl(0, "LspInlayHint", { link = "Comment" })
        vim.api.nvim_set_hl(0, "CursorLineNr", { bg = "NONE", bold = true })
      end,
    })

    -- vim.cmd("colorscheme onedark")
  end,
}
