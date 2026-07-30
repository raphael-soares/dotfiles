return {
  {
    "echasnovski/mini.diff",
    version = "*",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      view = {
        style = "sign",
        signs = { add = "│", change = "│", delete = "│" },
      },
    },
  },

  {
    "NvChad/nvim-colorizer.lua",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      filetypes = { "*" },
      user_default_options = {
        RGB = true,
        RRGGBB = true,
        names = false,
        RRGGBBAA = true,
        AARRGGBB = true,
        rgb_fn = true,
        hsl_fn = true,
        css = true,
        css_fn = true,
        mode = "virtualtext",
        virtualtext = " ",
        virtualtext_inline = true,
        always_update = false,
      },
    },
  },
}
