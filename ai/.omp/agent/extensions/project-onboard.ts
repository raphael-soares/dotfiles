/**
 * Detector de onboarding, equivalente ao hook project-onboard.sh do Claude Code.
 *
 * Quando a sessão abre num projeto de código sem setup de agente (sem AGENTS.md,
 * sem CLAUDE.md, sem .omp/ e sem .claude/), guarda um lembrete para rodar a
 * skill project-init. O lembrete é entregue no próximo prompt do usuário
 * (deliverAs nextTurn), então nada é executado sozinho e nenhuma turn nasce sem
 * o usuário pedir.
 *
 * Só age quando há sinal claro de projeto de código, para não avisar no home nem
 * em repo de configuração.
 *
 * Os tipos abaixo descrevem só a parte da ExtensionAPI que este arquivo usa; o
 * pacote @oh-my-pi/pi-coding-agent não está instalado nesta máquina.
 */

import { existsSync } from "node:fs";
import { join } from "node:path";

interface Pi {
  setLabel(label: string): void;
  sendMessage(message: string, options?: { deliverAs?: string }): void;
  on(event: "session_start", handler: (event: unknown, ctx: { cwd: string }) => void): void;
}

const SETUP_MARKERS = ["AGENTS.md", "CLAUDE.md", ".omp", ".claude"];

const CODE_MARKERS = [
  "package.json",
  "pom.xml",
  "build.gradle",
  "build.gradle.kts",
  "go.mod",
  "Cargo.toml",
  "pyproject.toml",
  "requirements.txt",
  "composer.json",
  "Gemfile",
  "src",
];

const REMINDER =
  "Este projeto não tem setup de agente (sem AGENTS.md, sem CLAUDE.md, sem .omp/ ou .claude/). " +
  "ANTES de qualquer tarefa, rode a skill project-init: explore o repo, entreviste o usuário " +
  "sobre produto, domínio e invariantes, e crie a base (AGENTS.md, CONTEXT.md, primeiro ADR). " +
  "Se o usuário só quer algo rápido e pontual, ofereça rodar o onboarding antes em vez de assumir.";

export default function (pi: Pi) {
  pi.setLabel("Detector de onboarding");

  pi.on("session_start", (_event, ctx) => {
    const cwd = ctx?.cwd;
    if (!cwd || !existsSync(cwd)) return;
    if (SETUP_MARKERS.some((m) => existsSync(join(cwd, m)))) return;
    if (!CODE_MARKERS.some((m) => existsSync(join(cwd, m)))) return;

    pi.sendMessage(REMINDER, { deliverAs: "nextTurn" });
  });
}
