# SSH nos dotfiles, cifrado com sops

## Por quê

Os segredos estão em quatro lugares (Bitwarden, sops nos dotfiles, repo privado
`~/.ssh`, chaveiro do GNOME). O dono quer o setup inteiro nos dotfiles, com uma
única porta de entrada: destravar o Bitwarden. Daí sai a chave age, e a chave
age abre o resto. Hoje o SSH foge disso: tem um repo próprio, com as chaves
privadas em texto puro no GitHub, e as chaves da TEAjudo só existem no
notebook.

Esta spec muda a decisão de 19/11 (`~/.ssh/docs/.../reorganizacao-ssh-design.md`),
que tinha descartado o sops para o SSH.

## Objetivos

- Config e chaves privadas do SSH em `secrets/ssh/`, cifradas com a mesma chave
  age de `secrets/*.env`.
- O `dotter deploy` monta o `~/.ssh` nos dois PCs, inclusive as chaves da TEAjudo
  no Fedora.
- Máquina nova: destravar o rbw, rodar um comando que restaura a chave age e
  rodar o deploy. Não sobra nenhum passo manual de SSH.
- O repo `~/.ssh` (`raphael-soares/ssh`) é aposentado.

## Fora do escopo

- Trocar as chaves (a mesma chave continua, uma por identidade, sem passphrase).
- O login do gh, que fica no chaveiro de cada PC (é um token por máquina).
- O `known_hosts`, que continua local.
- O agente SSH do Bitwarden (abordagem B, descartada).

## Abordagens

| Abordagem | Troca | Escolha |
|---|---|---|
| A. sops em `secrets/ssh/`, deploy decifra para `~/.ssh` | Mesma ferramenta e chave dos outros segredos; chave em disco em cada PC, como hoje | **sim** |
| B. Chaves no agente SSH do Bitwarden desktop | Chave nunca em disco, mas ssh só com o app aberto e destravado: quebra jobs agendados e o acesso entre os PCs | não |
| C. Híbrido (servidores no sops, chave pessoal no Bitwarden) | Mais seguro para a chave do GitHub, mas volta a ter dois mecanismos | não |

## Desenho

```
secrets/ssh/
  config                    # Include config.d/*.conf + Host *
  config.d/personal.conf
  config.d/teajudo.conf
  config.d/unimed.conf
  keys/personal  keys/unimed  keys/teajudo-dev  keys/teajudo-prd
```

- Cada arquivo é cifrado inteiro pelo sops em formato binário, com o mesmo nome
  do destino. A regra do `.sops.yaml` passa a cobrir `secrets/ssh/`. A config
  também vai cifrada, porque tem host e IP de servidor e os dotfiles são
  públicos.
- `secrets ssh` decifra cada arquivo para o mesmo caminho em `~/.ssh` (modo 600,
  diretórios 700). Só escreve quando o conteúdo mudou, e gera o `.pub` de cada
  chave com `ssh-keygen -y`. Arquivo em `~/.ssh` que não está no repo não é
  tocado.
- O `post_deploy` roda `secrets ssh` no bloco do `terminal` quando a chave age
  existe. Sem a chave age ele pula o passo, e o `missing.sh` já manda restaurar.
- O módulo `sshd` garante que o `personal.pub` está no `authorized_keys`, para os
  dois PCs se alcançarem depois de um deploy limpo.
- `secrets init`: com o rbw destravado, grava a chave age do item
  `age (dotfiles)` em `~/.config/sops/age/keys.txt` (umask 077, sem imprimir).
  O `missing.sh` passa a sugerir esse comando.
- `secrets check` passa a acusar arquivo de `~/.ssh` que difere do repo e chave
  privada em `~/.ssh/keys` que não está em `secrets/ssh/keys`.
- Para editar: `sops edit secrets/ssh/config.d/unimed.conf`. Para chave nova:
  `sops encrypt --input-type binary --output-type binary --filename-override secrets/ssh/keys/<nome> <arquivo>`.

## Migração

1. Commitar no repo `~/.ssh` a mudança pendente em `config.d/personal.conf`.
2. Cifrar a config e as quatro chaves do notebook para `secrets/ssh/`.
3. Deploy nos dois PCs e conferir: `ssh -T git@github.com`, `ssh fedora`,
   `ssh arch` e um host de cada área.
4. `~/.ssh/.git` vai para a lixeira nos dois PCs, e o repo `raphael-soares/ssh` é
   arquivado no GitHub. Apagar o repo (o histórico tem as chaves em texto puro)
   é uma decisão do dono, perguntada na hora.

## Testes

`tests/secrets.sh` ganha casos para `secrets ssh`: escreve com modo 600, não
reescreve o que não mudou, gera o `.pub`, sem chave age não escreve nada e não
apaga arquivo local que não está no repo. Usa uma chave age descartável.

## Fica com quem implementar

Os nomes internos, a mensagem de cada passo e o jeito de comparar conteúdo sem
deixar arquivo decifrado em disco fora do destino.
