local servers = {
  "lua_ls",
  "html",
  "cssls",
  "clangd",
  "basedpyright",
  "tailwindcss",
  "jsonls",
  "marksman",
  "terraformls",
  "vue_ls",
  "vtsls",
}

return {
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },

  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    event = "VeryLazy",
    opts = {},
  },

  {
    "williamboman/mason-lspconfig.nvim",
    event = "VeryLazy",
    dependencies = { "williamboman/mason.nvim" },
    opts = { ensure_installed = servers },
  },

  {
    "neovim/nvim-lspconfig",
    event = "BufReadPre",
    dependencies = { "saghen/blink.cmp" },
    config = function()
      vim.lsp.config("*", { capabilities = require("blink.cmp").get_lsp_capabilities() })

      require("lsp.servers.lua_ls")
      require("lsp.servers.typescript")
      require("lsp.servers.vue")
      require("lsp.servers.python")
      require("lsp.keymaps")

      vim.lsp.enable(servers)
    end,
  },

  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = "ConformInfo",
    opts = {
      default_format_opts = { lsp_format = "fallback" },
      formatters_by_ft = {
        ["*"] = { "trim_whitespace" },
        -- java has no CLI formatter; "prefer" forces jdtls (LSP) to format it.
        -- This must live here (not in the call site) so it survives opts merge.
        java = { lsp_format = "prefer" },
        lua = { "stylua" },
        vue = { "prettier" },
        typescript = { "prettier" },
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        json = { "prettier" },
        html = { "prettier" },
        css = { "prettier" },
      },
      format_on_save = {
        timeout_ms = 300,
      },
    },
  },

  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local lint = require("lint")

      lint.linters_by_ft = {
        javascript = { "eslint_d" },
        typescript = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        typescriptreact = { "eslint_d" },
        vue = { "eslint_d" },
        python = { "ruff" },
        lua = { "luacheck" },
      }

      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup("nvim_lint", { clear = true }),
        callback = function()
          lint.try_lint(nil, { ignore_errors = true })
        end,
      })
    end,
  },
}
