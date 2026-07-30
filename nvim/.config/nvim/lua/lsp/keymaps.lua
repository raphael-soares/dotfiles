local function smart_definition()
  local params = vim.lsp.util.make_position_params()
  vim.lsp.buf_request_all(0, "textDocument/definition", params, function(results)
    local locs = {}
    for _, res in pairs(results) do
      if res.result then
        local r = vim.islist(res.result) and res.result or { res.result }
        for _, loc in ipairs(r) do
          table.insert(locs, {
            uri = loc.targetUri or loc.uri,
            range = loc.targetSelectionRange or loc.targetRange or loc.range,
          })
        end
      end
    end

    if #locs == 0 then
      vim.notify("LSP: No definition found", vim.log.levels.WARN)
      return
    end

    -- Prefer .vue > local .ts/.js > .d.ts > node_modules
    local function priority(loc)
      local uri = loc.uri or ""
      if uri:match("node_modules") then return 0 end
      if uri:match("%.d%.ts$") then return 1 end
      if uri:match("%.vue$") then return 3 end
      return 2
    end

    table.sort(locs, function(a, b) return priority(a) > priority(b) end)

    local top_pri = priority(locs[1])
    local top_count = 0
    for _, l in ipairs(locs) do
      if priority(l) == top_pri then top_count = top_count + 1 end
    end

    if top_count == 1 then
      vim.lsp.util.jump_to_location(locs[1], "utf-8", true)
    else
      require("mini.extra").pickers.lsp({ scope = "definition" })
    end
  end)
end


vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("lsp_keymaps", { clear = true }),
  callback = function(event)
    local map = function(keys, func, desc, mode)
      vim.keymap.set(mode or "n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
    end

    map("grd", smart_definition, "Go to Definition")
    map("grD", vim.lsp.buf.declaration, "Go to Declaration")
    map("grr", function() require("mini.extra").pickers.lsp({ scope = "references" }) end, "References")
    map("gO", function() require("mini.extra").pickers.lsp({ scope = "document_symbol" }) end, "Document Symbols")
    map("<leader>th", function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
    end, "Toggle Inlay Hints")

  end,
})
