local cmd = vim.api.nvim_create_user_command

cmd("CRun", function(opts)
  local file = vim.fn.expand("%:p")

  if vim.bo.filetype ~= "c" then
    vim.notify("CRun: not a C file", vim.log.levels.WARN)
    return
  end

  -- Save before compiling
  vim.cmd("silent write")

  local name = vim.fn.expand("%:t:r")
  local out = "/tmp/" .. name

  local flags = (opts.args ~= "") and opts.args or "-Wall -Wextra -g"
  local compile = string.format("gcc %s -o %s %s", flags, vim.fn.shellescape(out), vim.fn.shellescape(file))
  local run = vim.fn.shellescape(out)
  local full_cmd = string.format("%s && %s; echo ''; echo '[Process exited with code '$?']'", compile, run)

  -- Open terminal in horizontal split at the bottom
  vim.cmd("botright 15split | terminal " .. full_cmd)
  vim.cmd("startinsert")
end, {
  nargs = "?",
  desc = "Compile and run the current C file (usage: :CRun [-O2 ...])",
})
