return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy",
    opts = {
      file_types = { "markdown" },
      render_modes = { "n", "c" },
      latex = { enabled = false },
      yaml = { enabled = false },
      code = {
        enabled = true,
        sign = false,
        width = "block",
        right_pad = 1,
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "windwp/nvim-ts-autotag",
    },
    config = function()
      require("nvim-treesitter").setup({
        ensure_installed = {
          "lua",
          "vim",
          "vimdoc",
          "query",
          "javascript",
          "typescript",
          "tsx",
          "html",
          "css",
          "vue",
          "json",
          "python",
          "bash",
          "c",
          "markdown",
          "markdown_inline",
          "yaml",
          "toml",
        },
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true },
      })

      -- Auto-close and auto-rename HTML/Vue tags
      require("nvim-ts-autotag").setup()

      -- New nvim-treesitter API doesn't enable highlighting automatically — do it for all filetypes
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          pcall(vim.treesitter.start, args.buf)
        end,
      })
    end,
  },
}
