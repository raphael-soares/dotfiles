# dotfiles

Config de terminal, com [GNU Stow](https://www.gnu.org/software/stow/). Só linha
de comando, sem nada de desktop. Roda em qualquer Unix.

```bash
git clone git@github.com:Raphael-Soares/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./bootstrap.sh
```

O `bootstrap.sh` faz duas coisas: lista as dependências e linka os configs.
Instalar é com você, inclusive o TPM, que os plugins do tmux precisam. O stow
roda com `--adopt -R`, então o repo ganha de config local que já exista.

Para só refazer os links: `stow bash tmux alacritty git starship fzf local mise nvim ai`.

Chave de API fica em `~/.env.local`, que o `.bashrc` carrega: copie do
`.env.example`. Runtimes (node, python, java, lua) ficam com o mise.

## Scripts

- `acmit`: sugere mensagens de commit a partir do diff. Usa a API do Gemini se
  `GEMINI_API_KEY` estiver setada, senão o Claude Code.
- `vpn`: conecta na VPN da Unimed. Específico do trabalho, conf e DNS chumbados.

## Neovim

[Raphael-Soares/nvim](https://github.com/Raphael-Soares/nvim)
