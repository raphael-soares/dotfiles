# pr-watch: detectar falha pelo step

## Porquê

O pr-watch só vê uma falha quando o check do job conclui. O job continua
rodando depois do step falho (resto da suíte, passos `always()`, post-steps),
e esse tempo é espera à toa.

## Objetivo e não-objetivos

- Objetivo: sair assim que um step falha de forma confirmada, sem esperar o
  job terminar.
- Fora: cancelar runs, fail-fast no CI, novo código de saída. O contrato 0..7
  não muda.

## Abordagens

1. Ler os steps pelo endpoint de jobs da run (escolhida): dado ao vivo, uma
   chamada por run.
2. `gh pr checks --watch --fail-fast`: granularidade de job, não resolve.
3. Log ao vivo: só existe pelo websocket da interface web, sem API pública.

## Desenho

- A cada ciclo, para cada run com check `rodando`, ler
  `repos/{repo}/actions/runs/{run}/jobs`.
- Falha confirmada: step com `conclusion: failure` e o próximo step que não é
  post-step está `skipped`. Com `continue-on-error` o próximo roda, então não
  dispara.
- Saída cedo imprime job, step e link. Código 2 (com a dica de rerun) quando o
  step falho é "Set up job", checkout ou cache; senão código 1.
- Job já concluído segue o caminho atual: trecho do log e classificação por
  regex.
- Intervalo padrão: 30s passa a 15s.

## Verificação

PR real com um teste quebrado de propósito: o pr-watch tem que sair antes do
job concluir, com código 1 e o step certo.
