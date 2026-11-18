# Per-repo board updated by the agents: design

- **Issue:** raphael-soares/dotfiles#7 (the PRD is there)
- **Date:** 2026-11-17
- **Delivery 2 of 3** (1 was PRD and rules; 3 is the morning check in herdr-automations)

## Why

The owner manages the agents like a software house: decides what and in what
order, and wants to follow the rest on a visual board with no manual work. The
state already exists (queue labels, assignee, PR); what is missing is showing
it.

## Goals

- One GitHub Projects board per repo, with the columns Backlog, Investigação
  (investigating), Pronta (ready), Fazendo (doing), Esperando você (waiting on
  you), Revisão (review), Feita (done), in this order.
- The card moves on its own when the issue state changes.
- Creating a repo's board is one command.

## Non-goals

- A single board for several repos (owner's decision: one per repo).
- Dragging a card on the site changing the label (the path is to change the
  label).
- Daily check and morning summary (delivery 3).
- Wiring the board into the TEAjudo repos: the design works for any repo with
  `ficha.json`, but that is not part of this delivery.

## Anti-goals

- A board that lies: a column different from the issue's real state.
- The board blocking the queue: a board failure never stops the work.

## Approaches

1. **Local `quadro` command + template board with native workflows** (chosen by
   the owner). Updates instantly, with no secret or per-repo workflow. Cost: a
   label changed by hand on the site only shows up on the next `quadro` call
   (the morning check covers it).
2. `project-label-sync` per repo. Rejected: 15-minute polling, secret and
   workflow per repo, a project with no known use.
3. Custom action per event. Rejected: code and secret per repo to cover a case
   (changing a label on the site) that is not the owner's.

A repo without a board, or without a queue, follows the simple flow
(interactive issue and PR), unchanged (owner's decision).

## Design

### Single column rule

The column is never stored as its own data: it is computed from the issue
state, by the first rule that matches.

| State | Column |
|---|---|
| closed | Feita |
| `gh` login among the assignees | Esperando você |
| linked PR | Revisão |
| label `em-execucao` | Fazendo |
| label `ready-for-agent` | Pronta |
| label `investigando` | Investigação |
| none of the above | Backlog |

"Linked PR" is an open or merged PR with head `fila/<N>` in any repo listed in
`repos` of `ficha.json` (the way `fila` searches), or one that closes the issue
(`Closes #N`, in `closedByPullRequestsReferences`). Merged counts because the
issue stays open between the merge and the close; a PR closed without a merge
does not count.

The board belongs to the repository where the issues live: the `fila` repo from
`ficha.json`. In a project with `repos`, the PRs live in the code repos, but the
board, the link and the `investigando` label belong to the queue repo.

### Command `ai/.local/bin/quadro`

Python, in the same style as `fila` (same folder, `gh` as the only
dependency).

- `quadro sync <dir> [N ...]`: reads `quadro` from the `ficha.json` of `<dir>`;
  without the field, exits 0 doing nothing. For each requested issue (without
  N: all open issues of the queue repo and the board items not yet in Feita),
  ensures it is on the board (`addProjectV2ItemById`) and writes the computed
  column to the Status field (`updateProjectV2ItemFieldValue`). Only writes
  when the column changes. An item that is not an issue (draft, loose PR) is
  ignored.
- `quadro criar <dir>` (create): copies the template board (`copyProjectV2`) to
  the account that owns the queue repo, named after the repo, links that repo
  to the board (`linkProjectV2ToRepository`), creates the `investigando` label
  if missing and writes the URL into `quadro` in `ficha.json` (creating the
  file with only that field if it does not exist).
- `quadro modelo` (template): creates the template board through the API
  (`createProjectV2` and the Status field with the seven options, in the order
  above) and prints the number, which becomes a constant in `quadro`.
- Columns match the Status options by exact name, accents included. A missing
  option, a missing `project` scope or missing access: when called by `fila`,
  `sync` warns and exits 0; when called by hand, and in `criar`, it exits with a
  clear error.

### Template board

Owned by the `raphael-soares` account. The owner enables, once, in the UI, the
native workflows "Item closed" and "Pull request merged" moving to Feita: the
API has no mutation for workflows, and `copyProjectV2` copies the template with
them. No auto-add: `sync` already puts the issue on the board.

### `fluxo-desvio`

The gate contract fields (`portao`, `rapido`, `prova`, `risco`,
`nao_se_aplica`, `pendente`, `extras`) are only required of a repo that declares
`portao`. A repo with `ficha.json` that has no `portao` and no `repos` is
light-management: it requires `fila` and `integracao`, accepts `quadro`, and
skips gate verification and the requirement that a workflow call
`scripts/portao`. TEAjudo's `ficha.json` does not change (owner's decision).

### `ficha.json`

New optional field `quadro`: the Project URL. Documented in
`ai/docs/portao.md`. A personal repo with a queue declares at least `fila` and
`integracao`.

### Queue

`fila` calls `quadro sync <dir> <N>` after each state change: picking up the
issue (`em-execucao`), detecting the open PRs the session created (after
`prs_da_issue(..., "open")` in `processar`), handing over to the owner
(`dono()`), resuming, merging (`concluir`) and closing (`fechar()`). A `quadro`
failure becomes a warning in the log and the queue carries on.

### Interactive sessions

Rule in `RULES.md`, Superpowers section: when starting `discussao` or
`brainstorming` about an issue in a repo with a board, put the `investigando`
label; when implementing interactively, swap it for `em-execucao`; after each
swap run `quadro sync . <N>`. The opened PR and the close follow the table on
their own.

### Test

The column rule is a pure function, with a test in `ai/tests/test_quadro.py`
following the pattern of `ai/tests/test_fila.py`: table precedence, merged PR
with open issue, and PR closed without a merge.

## Agent's calls

- Column computed, never stored separately (avoids divergence).
- The board belongs to the queue repo, even in a multi-repo project.
- A merged PR with an open issue stays in Revisão; closed without a merge does
  not count.
- A `quadro` failure does not block the queue.
- Template created through the API; only the two native workflows are done in
  the UI.
- Python and `gh`, following the `fila` pattern.

## Left to the implementer

- The exact GraphQL query and pagination.
- Log messages and `quadro` output.
- How to find an issue's item on the board.
