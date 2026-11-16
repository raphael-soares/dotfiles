-- Modo cópia: nvim sem cara de nvim. Mostra uma foto colorida do terminal
-- COPIA_ALVO (via `hc attach --observe`) num buffer de terminal; y copia e sai.
local alvo, pane, hist = vim.env.COPIA_ALVO, vim.env.COPIA_PANE, vim.env.COPIA_HIST or "3000"
local tema = vim.json.decode(io.open(vim.env.COPIA_TEMA):read("a"))

local o = vim.o
o.termguicolors = true
o.number, o.relativenumber, o.ruler, o.showmode, o.showcmd = false, false, false, false, false
o.laststatus, o.cmdheight, o.signcolumn, o.scrolloff = 0, 0, "no", 0
o.fillchars, o.shortmess = "eob: ", "aoOstTIcFWCsq"
o.swapfile, o.shada, o.clipboard, o.mouse = false, "", "", "a"
o.guicursor = "n-v:block,i:block"

for i = 0, 15 do
  vim.g["terminal_color_" .. i] = tema["ansi" .. i]
end
vim.cmd.highlight("clear")
vim.api.nvim_set_hl(0, "Normal", { bg = tema.background, fg = tema.terminal_foreground })
vim.api.nvim_set_hl(0, "NormalNC", { link = "Normal" })
vim.api.nvim_set_hl(0, "Visual", { bg = tema.selection })
vim.api.nvim_set_hl(0, "Search", { bg = tema.selection })
vim.api.nvim_set_hl(0, "CurSearch", { bg = tema.accent, fg = tema.background })
vim.api.nvim_set_hl(0, "IncSearch", { link = "CurSearch" })
vim.api.nvim_set_hl(0, "YankFlash", { bg = tema.accent, fg = tema.background })

local function herdr(...)
  vim.system({ "herdr-app", "do", ... }):wait(1000)
end

local saindo = false
local function sair()
  if saindo then return end
  saindo = true
  herdr("terminal.show", vim.json.encode({ pane = pane }))
  vim.cmd("qa!")
end

local buf = vim.api.nvim_get_current_buf()
vim.bo[buf].scrollback = tonumber(hist) + 500
local job, term
local win = vim.api.nvim_get_current_win()
local ultimo, congelado = vim.uv.now(), false

-- O attach pergunta cores e tamanho da célula e só despeja depois da resposta;
-- o buffer de terminal não responde a todas, então respondo aqui.
local function rgb(hex)
  local r, g, b = (hex or "#000000"):match("#(%x%x)(%x%x)(%x%x)")
  return ("rgb:%s%s/%s%s/%s%s"):format(r, r, g, g, b, b)
end
local respostas = {
  ["\27]10;?"] = "\27]10;" .. rgb(tema.foreground) .. "\27\\",
  ["\27]11;?"] = "\27]11;" .. rgb(tema.background) .. "\27\\",
  ["\27]12;?"] = "\27]12;" .. rgb(tema.foreground) .. "\27\\",
  ["\27[16t"] = "\27[6;20;10t",
}

-- O nvim nasce num terminal escondido de outro tamanho, vai para o pane e
-- encolhe de novo quando o layout de cópia põe moldura e header: o despejo
-- espera os resizes assentarem para sair na largura final.
local function iniciar()
  if term then return end
  term = vim.api.nvim_open_term(buf, {
    on_input = function(_, _, _, data) if job then vim.fn.chansend(job, data) end end,
  })
  ultimo = vim.uv.now()
  job = vim.fn.jobstart({ "hc", "attach", "--observe", "--history", hist, alvo }, {
    pty = true,
    width = vim.api.nvim_win_get_width(win),
    height = vim.api.nvim_win_get_height(win),
    on_stdout = function(_, data)
      if congelado then return end
      ultimo = vim.uv.now()
      local s = table.concat(data, "\n")
      for q, r in pairs(respostas) do
        if s:find(q, 1, true) then vim.fn.chansend(job, r) end
      end
      vim.api.nvim_chan_send(term, s)
    end,
  })

  -- O attach não avisa quando terminou o despejo: sem saída por um instante, congela.
  local timer = vim.uv.new_timer()
  timer:start(150, 30, vim.schedule_wrap(function()
    if congelado or vim.uv.now() - ultimo < 120 then return end
    congelado = true
    timer:stop()
    vim.fn.jobstop(job)
    vim.cmd("normal! G")
    if vim.fn.search("\\S", "bcW") == 0 then vim.cmd("normal! G") end
    vim.cmd("normal! _")
  end))
end

local espera = vim.uv.new_timer()
vim.api.nvim_create_autocmd("VimResized", {
  callback = function()
    if not term then espera:start(150, 0, vim.schedule_wrap(iniciar)) end
  end,
})
vim.defer_fn(iniciar, 1500)

local map = function(lhs, rhs) vim.keymap.set({ "n", "x" }, lhs, rhs, { buffer = buf, nowait = true }) end
for _, k in ipairs({ "i", "a", "I", "A", "o", "O", "<Insert>" }) do
  vim.keymap.set("n", k, "<Nop>", { buffer = buf })
end
map("q", sair)
vim.keymap.set("n", "<Esc>", sair, { buffer = buf })
vim.keymap.set("x", "<CR>", "y", { buffer = buf, remap = true })

vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    local ev = vim.v.event
    local texto = table.concat(ev.regcontents, "\n") .. (ev.regtype == "V" and "\n" or "")
    vim.system({ "wl-copy" }, { stdin = texto })
    vim.hl.on_yank({ higroup = "YankFlash", timeout = 250 })
    herdr("fluxo.copiado-" .. #ev.regcontents)
    vim.defer_fn(sair, 250)
  end,
})
