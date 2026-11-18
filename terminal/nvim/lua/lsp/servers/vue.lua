-- Fix @lsp.type.component.vue linking to @lsp (no color) → link to @type
vim.api.nvim_set_hl(0, "@lsp.type.component.vue", { link = "@type" })
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("vue_component_hl", { clear = true }),
  pattern = "*",
  callback = function()
    vim.api.nvim_set_hl(0, "@lsp.type.component.vue", { link = "@type" })
  end,
})

vim.lsp.config("vue_ls", {
  on_init = function(client)
    -- vtsls + @vue/typescript-plugin handles all TS diagnostics in .vue files; suppress duplicates from vue_ls
    client.handlers["textDocument/publishDiagnostics"] = function() end
    client.handlers["tsserver/request"] = function(_, result, context)
      local clients = vim.lsp.get_clients({ bufnr = context.bufnr, name = "vtsls" })
      if #clients == 0 then
        vim.notify("Could not find `vtsls` — `vue_ls` will not work without it.", vim.log.levels.ERROR)
        return
      end
      local ts_client = clients[1]
      local param = unpack(result)
      local id, command, payload = unpack(param)
      ts_client:exec_cmd({
        title = "vue_request_forward",
        command = "typescript.tsserverRequest",
        arguments = { command, payload },
      }, { bufnr = context.bufnr }, function(_, r)
        local response_data = { { id, r.body } }
        ---@diagnostic disable-next-line: param-type-mismatch
        client:notify("tsserver/response", response_data)
      end)
    end
  end,
})
