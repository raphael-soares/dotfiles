---
name: cofre
description: >
  Use para o cofre Bitwarden do dono: organizar itens e pastas, achar
  duplicados, guardar senha, token ou chave nova, usar um segredo num comando,
  e os segredos da máquina (pasta Dotfiles, chaves SSH, secrets pull/put/run/check).
  Não use para segredo de outra pessoa ou de outro cofre.
---

# Cofre

O cofre é o Bitwarden do dono, acessado só pelo `rbw`. Duas ferramentas:

| Ferramenta | Para quê |
|---|---|
| `vault` | Organizar, guardar e usar segredo. A listagem nunca mostra senha, nota, campo nem TOTP |
| `secrets` | Segredos da máquina na pasta `Dotfiles` do cofre: `env *`, `ssh *` |

O que nenhuma das duas faz (mudar item de pasta, renomear, anexo, Send,
cartão) é no app do Bitwarden, pelo dono.

## Regra de ouro

Valor de segredo nunca entra na conversa. Tudo o que você lê vai para o
modelo, fora do PC do dono.

- Não rode `rbw get`, `cat` de arquivo de segredo nem
  `secrets run -- env` com a saída visível.
- Para ver o que existe: `vault ls [busca]`, `vault folders`, `vault dupes`
  e `secrets ls`.
- Se o dono colar um segredo no chat, avise que ele ficou no histórico e
  sugira trocar.

## Destravar

- `rbw` fica destravado por 8 h. Trancado, o comando abre uma janela pedindo
  a senha mestra, que só o dono digita. Pelo shell do agente essa janela não
  aparece: peça ao dono para rodar `rbw unlock` num terminal dele e espere.
- O deploy nunca pede senha: com o `rbw` trancado ele mantém as cópias que já
  estão no disco.

## Organizar

1. `vault ls` e `vault dupes` para montar a proposta: pastas novas, nomes
   padronizados (o nome do serviço, como "GitHub"), duplicados, itens sem URL.
2. Mostre a proposta em tabela e espere o dono aprovar.
3. Mover de pasta e renomear: o dono faz no app. Excluir: `vault rm <id>`,
   só depois de confirmar cada item com o dono, citando nome e id.

Duplicado com o mesmo nome e host pode ter senhas diferentes. Você não as
compara: pergunte ao dono qual fica.

## Guardar

- Senha nova para um site: `vault add <nome> --user <u> --uri <url> --folder <pasta> --generate 32`.
  A senha gerada não aparece; o dono pega no app.
- Token que está numa variável ou arquivo: `--from-env VAR` ou
  `--from-file caminho`. Nunca cole o valor num comando.
- Segredo da máquina: `secrets put "<item>" <arquivo>` (ou pela entrada
  padrão), sem imprimir. O nome diz o destino:
  - `env personal`, `env aws`, `env media`: linhas `CHAVE=valor`. Para trocar um
    valor, monte o arquivo inteiro sem exibir e faça `put` dele;
  - `ssh key <nome>`: chave privada, vai para `~/.ssh/keys/<nome>`;
  - `ssh config`, `ssh config.d/<área>.conf`: arquivos do `~/.ssh`;
  Depois, `secrets pull` escreve no disco. Pode criar e trocar sem perguntar;
  apagar, só com o dono.
- Segredo de projeto de código não entra no cofre: mora no gerenciador do
  próprio projeto (TEAjudo: SSM da AWS em `/teajudo/<env>/`, lido com
  `aws ssm get-parameters-by-path --with-decryption`). O `.env` local sai do
  `.env.example` e não guarda segredo.
- Notas de um item de volta para arquivo, sem imprimir: `vault env <item> <arquivo>`.

## Usar com permissão

Antes de cada uso de item fora da pasta `Dotfiles`, pergunte ao dono com
`ask`: qual item, para qual comando. Aprovado, injete direto no processo:

```bash
vault run "GitHub token" GH_TOKEN -- gh repo list
vault run "Servidor X" --field username DB_USER -- ...
```

A saída do comando pode ecoar o segredo (`env`, `--verbose`, `set -x`):
não rode comando assim com segredo injetado.

## Segredos da máquina

- `secrets pull`: sincroniza a pasta `Dotfiles` e escreve cada item no lugar
  (modo 600, só o que mudou). Rode depois que o dono editar no app.
- `secrets run -- comando`: roda o comando com `env personal` como variáveis.
- `secrets aws`: entrega `env aws` ao `credential_process` do perfil default
  da AWS. Não rode com a saída visível; para conferir,
  `aws sts get-caller-identity`.
- `secrets check`: acusa cópia local ausente, arquivo legível por outros,
  credencial em texto puro largada na home (`~/.netrc`, credentials da AWS,
  `.env` com chave, token ou senha fora de `~/Code`) e chave em `~/.ssh/keys`
  sem item no cofre. O deploy e a conferência diária da mídia rodam. Achou
  algo: `secrets put` e apague o arquivo.
