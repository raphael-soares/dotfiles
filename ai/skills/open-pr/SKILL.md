---
name: open-pr
description: Escreve a descrição de um PR a partir do contexto da conversa e
  abre a criação no navegador. Use ao terminar uma branch que vai virar pull
  request, antes de rodar gh pr create.
disable-model-invocation: true
allowed-tools: Read, Bash, Glob, Grep
---

## Reunir contexto

1. Pegue a base branch (geralmente `main` ou `master`)
2. Pegue o diff: `git diff <base>...HEAD`
3. Pegue as mensagens de commit: `git log <base>...HEAD --format="%s"`
4. Leia os arquivos alterados pra entender o contexto mais amplo

## Commitar mudanças pendentes

1. Rode `git status` pra checar mudanças não commitadas
2. Se houver mudanças, commite antes de seguir (skill `git-commit`)

## Escrever a descrição do PR

Segue a skill `mensagem-pro-usuario`: o problema, a decisão e como verificar;
quem revisa lê o diff pro resto.

Use este modelo:

```markdown
## Problema

[o que estava acontecendo ou faltando, e por que importa]

## Decisão

[o que mudou e por quê; sem jargão que só faz sentido pra quem leu o diff]

## Como verificar

[passo a passo pra quem revisa confirmar que funciona]
```

Diretrizes:

- Comece pelo problema, não pelo caminho até a solução
- Traduza jargão interno: se a frase só faz sentido pra quem leu o diff, ela é
  comentário de código, não descrição de PR
- Inclua antes e depois quando a mudança for de UI ou performance
- Seja direto, corte o que não muda a decisão de quem revisa
- Nunca mencione Claude, IA ou assistente. Sem rodapé de geração automática

## Criar o PR

1. Escreva um título curto (até 72 caracteres), seguindo o formato da skill
   `git-commit` quando o merge for squash

2. Garanta que a branch está no remoto:
   ```bash
   git push -u origin HEAD
   ```

3. Abra a criação do PR no navegador (NÃO crie direto):
   ```bash
   gh pr create --web --title "<title>" --body "<body>"
   ```
