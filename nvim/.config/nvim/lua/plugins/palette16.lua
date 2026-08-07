return {
  {
    "raphael-soares/palette16.nvim",
    lazy = false,
    priority = 999,
    config = function()
      require("palette16").setup({
        palette = require("palette16.termcolors").read() or require("palette16.alacritty").read(),
        transparent = true,
      })
      vim.cmd.colorscheme("palette16")
    end,
  },
}
