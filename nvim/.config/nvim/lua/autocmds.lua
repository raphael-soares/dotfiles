local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

-- Highlight on yank
autocmd("TextYankPost", {
  group = augroup("highlight_yank", { clear = true }),
  callback = function()
    vim.hl.on_yank({ timeout = 200 })
  end,
})

-- Help in vertical split
autocmd("FileType", {
  group = augroup("help_vsplit", { clear = true }),
  pattern = "help",
  command = "wincmd L",
})

-- Auto resize splits
autocmd("VimResized", {
  group = augroup("resize_splits", { clear = true }),
  command = "wincmd =",
})

-- No auto-continue comments
autocmd("FileType", {
  group = augroup("no_auto_comment", { clear = true }),
  callback = function()
    vim.opt_local.formatoptions:remove({ "c", "r", "o" })
  end,
})

-- .env files as dosini syntax
autocmd("BufRead", {
  group = augroup("dotenv_ft", { clear = true }),
  pattern = { ".env", ".env.*" },
  callback = function()
    vim.bo.filetype = "dosini"
    vim.opt_local.commentstring = "# %s"
  end,
})

-- LSP: highlight references under cursor
local lsp_hl_group = augroup("lsp_reference_highlight", { clear = true })
autocmd("CursorHold", {
  group = lsp_hl_group,
  callback = function()
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    for _, client in ipairs(clients) do
      if client.server_capabilities.documentHighlightProvider then
        vim.lsp.buf.document_highlight()
        break
      end
    end
  end,
})
autocmd("CursorMoved", {
  group = lsp_hl_group,
  callback = function()
    vim.lsp.buf.clear_references()
  end,
})
