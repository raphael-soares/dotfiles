return {
  {
    "stevearc/oil.nvim",
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      default_file_explorer = true,
      columns = {
        "icon",
        {
          "git_status",
          show_untracked = true,
        },
      },
      view_options = { show_hidden = true },
      keymaps = {
        ["g?"] = "actions.show_help",
        ["<CR>"] = "actions.select",
        ["<C-v>"] = "actions.select_vsplit",
        ["<C-h>"] = "actions.select_split",
        ["<C-p>"] = "actions.preview",
        ["q"] = "actions.close",
        ["g."] = "actions.toggle_hidden",
      },
    },
  },

  {
    "echasnovski/mini.pick",
    version = "*",
    event = "VeryLazy",
    config = function()
      require("mini.pick").setup({
        mappings = {
          move_down = "<C-j>",
          move_up = "<C-k>",
        },
      })
      vim.ui.select = require("mini.pick").ui_select
    end,
  },

  {
    "echasnovski/mini.extra",
    version = "*",
    event = "VeryLazy",
  },
}
