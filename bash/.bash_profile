# Login shell (TTY, alguns SSH, macOS Terminal) le este arquivo, nao o .bashrc.
[ -f ~/.bashrc ] && . ~/.bashrc

# Coisa de uma maquina so (PATH de instalador, completion de ferramenta local)
# mora aqui, fora do repo.
[ -f ~/.bash_profile.local ] && . ~/.bash_profile.local
