# PRD in the issue and management rules: design

- **Date:** 2026-11-17
- **Status:** approved in conversation
- **Delivery 1 of 3** (next: GitHub Projects board; morning check in herdr-automations)

## Why

The management layer (issue, milestone, queue) lost its format when the `po`
skill left along with the Superpowers adoption. Without it, no agent knows the
issue format, the milestone convention, or how to link spec and PR to the
issue. The separation between what/why (PRD, in the issue) and how (spec, in
the repo) comes back, following the pattern of people who use Superpowers at
scale (issue as PRD, versioned spec, throwaway plan).

## Goals

- The issue is the PRD: the what and the why, never the how.
- `discussao` writes the PRD; `brainstorming` starts from it to produce the
  spec.
- All work is linked to an issue, with no manual work for the owner.
- The milestone convention lives in one place and applies in every session.

## Non-goals

- Board, column sync and the daily check (deliveries 2 and 3).
- Changing the code of `fila` or `fluxo-desvio`.
- Resurrecting `po`: the product interview already belongs to `brainstorming`.

## Approaches

1. **Rules in `RULES.md` and the PRD format in `discussao`** (chosen). The
   sticky rule applies in every session and wins over the Superpowers skills;
   the format stays with whoever writes the issue.
2. New management skill. Rejected: what was lost from `po` is a small amount of
   text, and a skill only loads when called.
3. Issue template per repository. Rejected: a per-repo copy diverges, and the
   convention needs to be a single one.

## Design

**`ai/skills/discussao/SKILL.md`, output "Registrar para depois" (save for
later):** the issue body is a PRD with the sections `Problema` (problem),
`Aceite` (acceptance), `Restrições e decisões` (constraints and decisions),
`Risco` (risk) and the `Repos:` line (read by `fila`). Acceptance is observable
behavior, never a technical layer. The issue gets a milestone following the
`RULES.md` convention.

**`ai/.omp/agent/RULES.md`, Superpowers section:**

- `brainstorming` starts from the issue's PRD. Without an issue, the agent
  creates one with the PRD before starting, without stopping to ask (agent's
  decision, approved: stopping would become manual work, and work without an
  issue does not show up on the board).
- Branch and spec file name carry the issue number; the PR carries
  `Closes #N`.
- The spec goes in `docs/superpowers/specs/` and is versioned; the plan goes in
  `.scratch/` and is not committed.

**Milestone convention, in `RULES.md`:**

- Title `NN. Name`, two digits, in execution order; suffix for inserting
  (`17a.`).
- `00. Saúde técnica` (technical health) is permanent: bugs, technical debt and
  performance outside a result milestone.
- Every open issue has a milestone; a milestone with no open issue is closed.
- No `Itens: #N` list in the description (it was manual upkeep; the milestone
  already lists the issues).

## Left to the implementer

Exact wording, within the conciseness limit of `RULES.md`, and the adjustment
of the "send work to the queue" line so it does not duplicate the new rule.
