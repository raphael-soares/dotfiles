# PRD na issue e regras de gestão: design

- **Data:** 2026-11-17
- **Status:** aprovado na conversa
- **Entrega 1 de 3** (depois: board no GitHub Projects; conferência da manhã no herdr-automations)

## Por quê

A camada de gestão (issue, milestone, fila) perdeu o formato quando a skill `po`
saiu junto com a adoção do Superpowers. Sem ela, nenhum agente sabe o formato da
issue, a convenção de milestone, nem como ligar spec e PR à issue. A separação
entre o quê/porquê (PRD, na issue) e o como (spec, no repo) volta, no padrão de
quem usa Superpowers em escala (issue como PRD, spec versionada, plano descartado).

## Objetivos

- A issue é o PRD: o quê e o porquê, nunca o como.
- A `discussao` escreve o PRD; o `brainstorming` parte dele para a spec.
- Todo trabalho fica ligado a uma issue, sem trabalho manual do dono.
- A convenção de milestone mora num lugar só e vale em toda sessão.

## Não objetivos

- Board, sincronização de colunas e conferência diária (entregas 2 e 3).
- Mudar o código da `fila` ou do `fluxo-desvio`.
- Ressuscitar a `po`: a entrevista de produto já é do `brainstorming`.

## Abordagens

1. **Regras no `RULES.md` e formato do PRD na `discussao`** (escolhida). A regra
   sticky vale em toda sessão e vence as skills do Superpowers; o formato fica em
   quem escreve a issue.
2. Skill nova de gestão. Descartada: o que se perdeu da `po` é pouco texto, e
   skill só carrega quando chamada.
3. Template de issue por repositório. Descartada: cópia por repo diverge, e a
   convenção precisa ser uma só.

## Desenho

**`ai/skills/discussao/SKILL.md`, saída "Registrar para depois":** o corpo da
issue é um PRD com as seções Problema, Aceite, Restrições e decisões, Risco e a
linha `Repos:` (lida pela `fila`). Aceite é comportamento observável, nunca camada
técnica. A issue recebe milestone pela convenção do `RULES.md`.

**`ai/.omp/agent/RULES.md`, seção Superpowers:**

- O `brainstorming` parte do PRD da issue. Sem issue, o agente cria uma com o PRD
  antes de começar, sem parar para perguntar (decisão do agente, aprovada: parar
  viraria trabalho manual, e trabalho sem issue não aparece no board).
- Branch e nome do arquivo de spec levam o número da issue; a PR leva `Closes #N`.
- A spec vai em `docs/superpowers/specs/` e é versionada; o plano vai em
  `.scratch/` e não é commitado.

**Convenção de milestone, no `RULES.md`:**

- Título `NN. Nome`, dois dígitos, na ordem de execução; sufixo para inserir (`17a.`).
- `00. Saúde técnica` é permanente: bug, dívida técnica e desempenho fora de uma
  milestone de resultado.
- Toda issue aberta tem milestone; milestone sem issue aberta se fecha.
- Sem lista `Itens: #N` na descrição (era manutenção manual; a milestone já lista
  as issues).

## Fica para quem implementa

Redação exata, dentro do limite de concisão do `RULES.md`, e o ajuste da linha
"Mandar trabalho para a fila" para não duplicar a regra nova.
