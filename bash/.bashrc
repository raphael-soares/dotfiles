export HISTSIZE=100000
export HISTFILESIZE=100000
export HISTCONTROL=ignoreboth:erasedups
export HISTTIMEFORMAT="%F %T "
export PROMPT_COMMAND="history -a; history -n; $PROMPT_COMMAND"

shopt -s histappend
shopt -s cmdhist
shopt -s cdspell
shopt -s autocd
shopt -s direxpand
shopt -s globstar

bind 'set completion-ignore-case on'
bind 'set show-all-if-ambiguous on'
bind 'set colored-stats on'

alias ls='ls --color=auto'
alias l='ls -lah --color=auto'
alias grep='grep --color=auto'
alias yayf="yay -Slq | fzf --multi --preview 'yay -Sii {1}' --preview-window=down:55% | xargs -ro yay -S"
alias pacmanf="pacman -Slq | fzf --multi --preview 'pacman -Sii {1}' --preview-window=down:55% | xargs -ro yay -S"


alias vim="nvim "


[ -f ~/.config/fzf/fzf.sh ] && source ~/.config/fzf/fzf.sh
export FZF_DEFAULT_OPTS="$FZF_BASE_OPTS"

[ -f /usr/share/fzf/key-bindings.bash ] && source /usr/share/fzf/key-bindings.bash
[ -f /usr/share/fzf/completion.bash ] && source /usr/share/fzf/completion.bash

export FZF_CTRL_R_OPTS='--prompt="HISTORY: "'
export FZF_CTRL_T_OPTS='--prompt="FILES: "'
export FZF_ALT_C_OPTS='--prompt="JUMP: "'

if [ -d "$HOME/.local/bin" ]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

eval "$(starship init bash)"

eval "$($HOME/.local/bin/mise activate bash)"


[ -f ~/.env.local ] && source ~/.env.local
