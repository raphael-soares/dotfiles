return {
  -- Auto-close brackets, parens, quotes
  {
    "echasnovski/mini.pairs",
    version = "*",
    event = "InsertEnter",
    opts = {},
  },

  -- Better text objects: vif=function, vac=class, via=argument, vib=block
  {
    "echasnovski/mini.ai",
    version = "*",
    event = "VeryLazy",
    opts = { n_lines = 500 },
  },

  -- Static indent guides
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      indent = { char = "│", highlight = "IblIndent" },
      scope = { enabled = false },
    },
    init = function()
      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "*",
        callback = function()
          vim.api.nvim_set_hl(0, "IblIndent", { link = "Whitespace" })
        end,
      })
    end,
  },

  -- Animated scope indicator (highlights current scope's indent line)
  {
    "echasnovski/mini.indentscope",
    version = "*",
    event = { "BufReadPost", "BufNewFile" },
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "help", "dashboard", "oil", "lazy", "mason", "notify", "toggleterm" },
        callback = function()
          vim.b.miniindentscope_disable = true
        end,
      })
      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "*",
        callback = function()
          vim.api.nvim_set_hl(0, "MiniIndentscopeSymbol", { link = "Function" })
        end,
      })
    end,
    config = function()
      local indentscope = require("mini.indentscope")
      indentscope.setup({
        symbol = "│",
        options = { try_as_border = true },
        draw = { animation = indentscope.gen_animation.none() },
      })
      vim.api.nvim_set_hl(0, "MiniIndentscopeSymbol", { link = "Function" })
    end,
  },

  -- Inline git blame of the current line, as virtual text at the end of it
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signcolumn = false,
      current_line_blame = true,
      current_line_blame_opts = { delay = 300, virt_text_pos = "eol" },
      current_line_blame_formatter = "  <author>, <author_time:%d/%m/%Y> - <summary>",
    },
  },

  -- Visual marks: shows mark letters in sign column + virtual text
  {
    "chentoast/marks.nvim",
    event = "BufReadPost",
    opts = {
      default_mappings = true, -- keeps native m{letter}, '{letter}, `{letter}
      builtin_marks = { ".", "<", ">", "^" },
      cyclic = true,
      refresh_interval = 250,
      sign_priority = { lower = 10, upper = 15, builtin = 8, bookmark = 20 },
    },
  },

  -- Shows available keymaps when you pause mid-sequence
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      spec = {
        { "<leader>b", group = "Buffers" },
        { "<leader>d", group = "Debug" },
        { "<leader>t", group = "Toggle" },
      },
    },
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Buffer Keymaps",
      },
    },
  },
}
