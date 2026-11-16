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

  {
    -- fork com folke/snacks.nvim#2864: sem ela a imagem quebra no tmux com extended-keys always.
    -- voltar para "folke/snacks.nvim" quando a PR entrar no main.
    "yakovlievv/snacks.nvim",
    commit = "609a230e67a58f859cb2fef6b50a4b5895b9e5b1",
    priority = 1000,
    lazy = false,
    opts = {
      image = {
        enabled = true,
        doc = { enabled = true, inline = true },
      },
    },
  },
}
