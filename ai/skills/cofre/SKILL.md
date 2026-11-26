---
name: cofre
description: >
  Use para o cofre Bitwarden do dono: organizar itens e pastas, achar
  duplicados, guardar senha, token ou chave nova, usar um segredo num comando,
  e os segredos de ambiente dos dotfiles (sops, secrets run/check). Não use para
  segredo de outra pessoa ou de outro cofre.
---

# Cofre

O cofre é o Bitwarden do dono. Três ferramentas, nesta ordem de preferência:

| Ferramenta | Para quê |
|---|---|
| `vault` | Organizar, guardar e usar segredo. A listagem nunca mostra senha, nota, campo nem TOTP |
| `secrets` | Segredos de ambiente do dono, criptografados com sops em `secrets/*.env` dos dotfiles |
| MCP `bitwarden` | Só o que o `vault` não faz (anexo, Send, item de cartão ou identidade) |

## Regra de ouro

Valor de segredo nunca entra na conversa. Tudo o que você lê vai para o
modelo, fora do PC do dono.

- Não rode `bw get password`, `bw get item`, `bw list items`, `rbw get` nem
  `cat` de arquivo de segredo com a saída visível. Não use as ferramentas
  `get` e `list` do MCP em item de login ou nota segura: elas devolvem a senha.
- Para ver o que existe, use `vault ls [busca]`, `vault folders` e
  `vault dupes`.
- Se o dono colar um segredo no chat, avise que ele ficou no histórico e
  sugira trocar.

## Destravar

- `vault` e o MCP abrem uma janela pedindo a senha mestra. Só o dono digita.
  Com o cofre trancado, diga que a janela vai abrir e espere.
- `rbw` (usado por `vault run`) fica destravado por 8 h. `secrets` não pede
  senha: a chave age fica em `~/.config/sops/age/keys.txt`.
- `bw` sem login na máquina: peça ao dono para rodar `bw login` uma vez.

## Organizar

1. `vault ls` e `vault dupes` para montar a proposta: pastas novas, nomes
   padronizados (o nome do serviço, como "GitHub"), duplicados, itens sem URL.
2. Mostre a proposta em tabela e espere o dono aprovar.
3. Aplique com `vault mv <id> <pasta>`, `vault rename <id> <nome>` e
   `vault rm <id>`. `rm` manda para a lixeira (30 dias); mesmo assim, confirme
   cada exclusão com o dono, citando nome e id.

Duplicado com o mesmo nome e host pode ter senhas diferentes. Você não as
compara: pergunte ao dono qual fica.

## Guardar

- Senha nova para um site: `vault add <nome> --user <u> --uri <url> --folder <pasta> --generate 32`.
  A senha gerada não aparece; o dono pega no app.
- Token que está numa variável ou arquivo: `--from-env VAR` ou
  `--from-file caminho`. Nunca cole o valor num comando.
- Variável de ambiente do dono (token pessoal, VPN, mídia): o dono roda
  `sops edit secrets/personal.env`. Para importar de um arquivo sem ver o
  valor: `sops encrypt --filename-override secrets/personal.env --input-type dotenv --output-type dotenv arquivo`.
  Segredo de projeto de código não entra aqui nem no cofre: fica no `.env`
  do projeto.

## Usar com permissão

Antes de cada uso, pergunte ao dono com `ask`: qual item, para qual comando.
Aprovado, injete direto no processo:

```bash
vault run "GitHub token" GH_TOKEN -- gh repo list
vault run "Servidor X" --field username DB_USER -- ...
```

A saída do comando pode ecoar o segredo (`env`, `--verbose`, `set -x`):
não rode comando assim com segredo injetado.

## Segredos de ambiente

- `secrets run -- comando`: roda o comando com `secrets/personal.env` como
  variáveis. Não rode `sops decrypt` nem `secrets run -- env` com a saída
  visível.
- `secrets aws`: entrega a chave de `secrets/aws.env` ao `credential_process`
  do perfil default da AWS. Não rode no terminal com a saída visível; para
  conferir, `aws sts get-caller-identity`.
- `secrets check`: acusa chave age ausente ou arquivo legível por outros. O
  deploy e a conferência diária da mídia (`media-drift`) rodam.
