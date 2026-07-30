# nvim

Personal Neovim configuration. Built on [lazy.nvim](https://github.com/folke/lazy.nvim) with a focus on LSP-first development, minimal UI, and fast startup.

## Structure

```
.
├── init.lua                  # Entry point: options → keymaps → autocmds → plugins
├── lua/
│   ├── options.lua           # Editor settings
│   ├── keymaps.lua           # Global keymaps
│   ├── autocmds.lua          # Autocommands
│   ├── discipline.lua        # Anti-hjkl-spam guard ("Hold it Cowboy!")
│   └── plugins/
│       ├── color.lua         # Theme + git diff signs
│       ├── completion.lua    # blink.cmp + LuaSnip
│       ├── editor.lua        # mini.pairs, mini.ai, mini.clue, marks, vim-sleuth
│       ├── formatting.lua    # conform.nvim
│       ├── java.lua          # nvim-java + jdtls
│       ├── lint.lua          # nvim-lint
│       ├── lsp.lua           # mason + nvim-lspconfig
│       ├── oil.lua           # File explorer
│       ├── telescope.lua     # mini.pick + mini.extra
│       ├── treesitter.lua    # nvim-treesitter + render-markdown
│       └── ui.lua            # (re-exported from color.lua)
└── lua/lsp/
    ├── keymaps.lua           # LSP keymaps (attached on LspAttach)
    └── servers/              # Per-language LSP config overrides
        ├── clangd.lua
        ├── lua_ls.lua
        ├── python.lua
        ├── typescript.lua
        └── vue.lua
```

## Plugins

| Category | Plugin |
|---|---|
| Plugin manager | lazy.nvim |
| Theme | onedarkpro (transparent) |
| LSP | nvim-lspconfig + mason + mason-lspconfig |
| Completion | blink.cmp + LuaSnip + friendly-snippets |
| Formatting | conform.nvim |
| Linting | nvim-lint |
| Treesitter | nvim-treesitter + nvim-ts-autotag + render-markdown |
| Picker | mini.pick + mini.extra |
| File explorer | oil.nvim |
| Git signs | mini.diff |
| Text objects | mini.ai |
| Auto pairs | mini.pairs |
| Key hints | mini.clue |
| Marks | marks.nvim |
| Indent detection | vim-sleuth |
| Java | nvim-java |

## Language Support

| Language | LSP | Formatter | Linter |
|---|---|---|---|
| Lua | lua_ls | stylua | luacheck |
| TypeScript / JavaScript | vtsls | prettier | eslint_d |
| Vue | vue_ls + vtsls | prettier | eslint_d |
| Python | basedpyright | — | ruff |
| HTML / CSS | html, cssls | prettier | — |
| C / C++ | clangd | — | — |
| Java | jdtls (nvim-java) | — | — |
| JSON | jsonls | prettier | — |
| Tailwind CSS | tailwindcss | — | — |
| Terraform | terraformls | — | — |
| Markdown | marksman | — | — |

## Keymaps

Leader key: `<Space>`

### General

| Key | Action |
|---|---|
| `<leader>w` | Save file |
| `<leader><leader>` | Alternate last buffer |
| `<Esc>` | Clear search highlights |
| `<C-d>` / `<C-u>` | Scroll down/up (centered) |
| `<A-j>` / `<A-k>` | Move line/selection down/up |

### Files & Picker

| Key | Action |
|---|---|
| `<leader>f` | Find files |
| `<leader>a` | Find all files (including hidden/ignored) |
| `<leader>g` | Live grep |
| `<leader>h` | Help tags |
| `<leader>r` | Recent files (current dir) |
| `<leader>z` | Fuzzy find in buffer |
| `<leader>m` | Marks |
| `<leader>e` or `-` | Open file explorer (oil.nvim) |

### Buffers

| Key | Action |
|---|---|
| `<leader>bn` | Next buffer |
| `<leader>bp` | Previous buffer |
| `<leader>bd` | Delete buffer (keep split) |
| `<leader>bo` | Close all other buffers |
| `<leader>bf` | Buffer list picker |

### LSP (active when LSP is attached)

| Key | Action |
|---|---|
| `grd` | Go to definition (smart: prefers `.vue` > local > `.d.ts` > node_modules) |
| `grD` | Go to declaration |
| `grr` | References |
| `gO` | Document symbols |
| `grf` | Format (normal + visual) |
| `<leader>th` | Toggle inlay hints |
| `<leader>q` | Diagnostics → quickfix list |

## Requirements

- Neovim ≥ 0.11
- Git
- A [Nerd Font](https://www.nerdfonts.com/) (mono variant)
- `ripgrep` — for live grep
- Node.js — for TypeScript/Vue LSP and prettier
- `stylua`, `eslint_d`, `ruff`, `luacheck` — linters/formatters (or install via Mason)

## Installation

```bash
git clone https://github.com/Raphael-Soares/nvim ~/.config/nvim
nvim  # lazy.nvim bootstraps automatically
```

Mason installs LSP servers automatically on first launch (`ensure_installed` list in `lua/plugins/lsp.lua`). Treesitter parsers install automatically via `auto_install = true`.
