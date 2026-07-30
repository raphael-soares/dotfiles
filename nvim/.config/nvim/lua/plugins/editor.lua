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
    "echasnovski/mini.clue",
    version = "*",
    event = "VeryLazy",
    config = function()
      local clue = require("mini.clue")
      clue.setup({
        triggers = {
          { mode = "n", keys = "<Leader>" },
          { mode = "x", keys = "<Leader>" },
          { mode = "n", keys = "g" },
          { mode = "x", keys = "g" },
          { mode = "n", keys = "'" },
          { mode = "n", keys = "`" },
          { mode = "n", keys = '"' },
          { mode = "n", keys = "<C-w>" },
          { mode = "n", keys = "z" },
          { mode = "x", keys = "z" },
          { mode = "i", keys = "<C-x>" },
        },
        clues = {
          clue.gen_clues.builtin_completion(),
          clue.gen_clues.g(),
          clue.gen_clues.marks(),
          clue.gen_clues.registers(),
          clue.gen_clues.windows(),
          clue.gen_clues.z(),
          { mode = "n", keys = "<Leader>b", desc = "+Buffers" },
          { mode = "n", keys = "<Leader>t", desc = "+Toggle" },
        },
      })
    end,
  },
}
