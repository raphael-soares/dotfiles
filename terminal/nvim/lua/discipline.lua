-- stolen from craftdogz :)

local M = {}

function M.cowboy()
  for _, key in ipairs({ "h", "j", "k", "l" }) do
    local count = 0
    local timer = assert(vim.uv.new_timer())
    vim.keymap.set("n", key, function()
      if vim.v.count > 0 then
        count = 0
        return key
      end
      if count >= 10 and vim.bo.buftype ~= "nofile" then
        local ok = pcall(vim.notify, "Hold it Cowboy!", vim.log.levels.WARN, {
          icon = "🤠",
          id = "cowboy",
          keep = function() return count >= 10 end,
        })
        if not ok then
          return key
        end
        return
      end
      count = count + 1
      timer:start(2000, 0, function() count = 0 end)
      return key
    end, { expr = true, silent = true })
  end
end

return M
