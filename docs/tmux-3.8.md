# tmux 3.8: o que aplicar quando o Arch atualizar

Config em `tmux/.config/tmux/tmux.conf`. Tudo aqui é nativo do 3.8 e não existe no 3.7c.

- **Barra de rolagem que some**: `set -g pane-scrollbars auto-hide`. Aparece ao rolar ou passar o mouse e não estreita o pane, ao contrário do `modal` do 3.7c.
- **Renomear pane**: `prefix T` já vem como atalho padrão. O título alimenta o nome das janelas de agente (`@agent_window_name`). Nada a configurar.
- **`prefix Tab`**: o padrão do 3.8 abre o `switch-mode`, mas o bind do `tmux.conf` vence e continua abrindo o sessionizer. O seletor de sessões do 3.8 fica em `prefix S-Tab`; ele mostra as sessões `popup-*` porque não tem filtro.
- **Sessionizer**: com o `switch-mode` trocando entre sessões abertas, o `tmux-sessionizer.sh` pode encolher para só criar sessão a partir de pasta.
- **Popup**: o modal pane (`new-pane -O -C -D`) pode substituir o `display-popup` do `C-_`.
- **`set -g mouse on`**: vira o padrão e a linha pode sair.
