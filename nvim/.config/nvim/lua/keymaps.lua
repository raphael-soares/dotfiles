local map = vim.keymap.set

-- General
map("n", "<leader>w", "<cmd>write<CR>", { desc = "Save File" })
map("n", "<leader><leader>", "<C-^>", { desc = "Alternate Buffer" })
map("n", "<Esc>", "<cmd>noh<CR>", { desc = "Clear Highlights" })
map("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Replace Word Under Cursor" })

-- Scrolling (centered)
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll Down" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll Up" })

-- Move lines
map("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Line Down" })
map("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Line Up" })
map("v", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Selection Down" })
map("v", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Selection Up" })

-- File explorer
map("n", "<leader>e", "<cmd>Oil<CR>", { desc = "File Explorer" })
map("n", "-", "<cmd>Oil<CR>", { desc = "File Explorer" })

-- Buffers
map("n", "<leader>bn", "<cmd>bnext<CR>", { desc = "Next Buffer" })
map("n", "<leader>bp", "<cmd>bprev<CR>", { desc = "Previous Buffer" })
map("n", "<leader>bd", ":bp | bd #<CR>", { desc = "Close Buffer" })
map("n", "<leader>bo", "<cmd>%bd | e#<CR>", { desc = "Close Other Buffers" })

-- Picker (mini.pick)
map("n", "<leader>f", function()
  require("mini.pick").builtin.files()
end, { desc = "Find Files" })
map("n", "<leader>g", function()
  require("mini.pick").builtin.grep_live()
end, { desc = "Live Grep" })
map("n", "<leader>h", function()
  require("mini.pick").builtin.help()
end, { desc = "Find Help" })
map("n", "<leader>m", function()
  require("mini.extra").pickers.marks()
end, { desc = "Find Marks" })
map("n", "<leader>z", function()
  require("mini.extra").pickers.buf_lines()
end, { desc = "Find in Buffer" })
map("n", "<leader>r", function()
  require("mini.extra").pickers.oldfiles({ current_dir = true })
end, { desc = "Recent Files" })
map("n", "<leader>a", function()
  require("mini.pick").start({
    source = {
      name = "Files (all)",
      items = function()
        return vim.fn.systemlist("rg --files --hidden --no-ignore 2>/dev/null")
      end,
    },
  })
end, { desc = "Find All Files" })
map("n", "<leader>bf", function()
  require("mini.pick").builtin.buffers()
end, { desc = "Find Buffers" })

-- Format
map({ "n", "v" }, "grf", function()
  require("conform").format({ async = true })
end, { desc = "Format Buffer" })

-- Diagnostics to quickfix
map("n", "<leader>q", function()
  vim.diagnostic.setqflist()
  vim.cmd("copen")
end, { desc = "Diagnostics to Quickfix" })
