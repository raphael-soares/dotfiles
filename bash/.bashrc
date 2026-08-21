# ── Ambiente: vale para qualquer shell, inclusive `ssh host comando` ───────────
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) [ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH" ;;
esac

# mise resolve os runtimes (node, python, java, lua); nao chumbe caminho de versao no PATH.
command -v mise >/dev/null && eval "$(mise activate bash)"

[ -f ~/.env.local ] && source ~/.env.local

# ── Daqui pra baixo, so shell interativo ──────────────────────────────────────
case $- in
  *i*) ;;
    *) return ;;
esac

export HISTSIZE=100000
export HISTFILESIZE=100000
export HISTCONTROL=ignoreboth:erasedups
export HISTTIMEFORMAT="%F %T "
export PROMPT_COMMAND="history -a; history -n; $PROMPT_COMMAND"
export BROWSER="flatpak run io.github.zen_browser.zen"

shopt -s histappend
shopt -s cmdhist
shopt -s cdspell
shopt -s autocd
shopt -s direxpand
shopt -s globstar

bind 'set completion-ignore-case on'
bind 'set show-all-if-ambiguous on'
bind 'set colored-stats on'

# GNU coreutils usa --color; BSD/macOS usa -G.
if ls --color=auto >/dev/null 2>&1; then
  alias ls='ls --color=auto'
  alias l='ls -lah --color=auto'
else
  alias ls='ls -G'
  alias l='ls -lahG'
fi
grep --color=auto -q '' /dev/null 2>/dev/null && alias grep='grep --color=auto'

if command -v yay >/dev/null; then
  alias yayf="yay -Slq | fzf --multi --preview 'yay -Sii {1}' --preview-window=down:55% | xargs -ro yay -S"
fi
if command -v pacman >/dev/null; then
  alias pacmanf="pacman -Slq | fzf --multi --preview 'pacman -Sii {1}' --preview-window=down:55% | xargs -ro pacman -S"
fi

command -v nvim >/dev/null && alias vim="nvim"

[ -f ~/.config/fzf/fzf.sh ] && source ~/.config/fzf/fzf.sh
export FZF_DEFAULT_OPTS="$FZF_BASE_OPTS"
export FZF_CTRL_R_OPTS='--prompt="HISTORY: "'
export FZF_CTRL_T_OPTS='--prompt="FILES: "'
export FZF_ALT_C_OPTS='--prompt="JUMP: "'

# fd em vez do find padrao do fzf: mais rapido e ja ignora .git/.gitignore.
if command -v fd >/dev/null; then
  export FZF_DEFAULT_COMMAND='fd --hidden --strip-cwd-prefix --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --strip-cwd-prefix --exclude .git'
fi

if command -v fzf >/dev/null; then
  if fzf --bash >/dev/null 2>&1; then
    eval "$(fzf --bash)"
  else
    [ -f /usr/share/fzf/key-bindings.bash ] && source /usr/share/fzf/key-bindings.bash
    [ -f /usr/share/fzf/completion.bash ] && source /usr/share/fzf/completion.bash
  fi
fi

command -v starship >/dev/null && eval "$(starship init bash)"
