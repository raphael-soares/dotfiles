local o = vim.o
local opt = vim.opt



-- Line numbers
o.number = true
o.relativenumber = true

-- Mouse & UI
o.mouse = "a"
o.showmode = false
o.laststatus = 3
o.breakindent = true
o.confirm = true

-- Tabs & indentation
o.tabstop = 2
o.shiftwidth = 2
o.softtabstop = 2
o.expandtab = true
o.inccommand = 'split'

-- UI
o.signcolumn = "yes"
o.wrap = false
o.scrolloff = 8
o.cursorline = true
o.termguicolors = true
o.winborder = "single"
o.cmdheight = 0

-- Splits
o.splitbelow = true
o.splitright = true

-- Files
o.swapfile = false
o.undofile = true

-- Search
o.ignorecase = true
o.smartcase = true
o.hlsearch = true
o.incsearch  = true

-- Completion
o.completeopt = "menu,menuone,noselect"
o.pumheight = 10

-- Folding (treesitter-based via foldexpr)
o.foldmethod = "expr"
o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
o.foldenable = true
o.foldlevel = 99
o.foldlevelstart = 99
o.foldcolumn = "0"

-- Misc
o.updatetime = 250
o.timeoutlen = 300
o.clipboard = "unnamedplus"

-- Show invisible characters
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Diagnostics
local sev = vim.diagnostic.severity

vim.diagnostic.config({
  virtual_text = {
    prefix = "●",
    source = "if_many",
    spacing = 2,
  },

  severity_sort = true,
  signs = {
    text = {
      [sev.ERROR] = 'E',
      [sev.WARN]  = 'W',
      [sev.INFO]  = 'I',
      [sev.HINT]  = 'H',
    },
  },
  underline = true,
  update_in_insert = false,
  float = {
    border = "single",
    source = true,
  },
})
