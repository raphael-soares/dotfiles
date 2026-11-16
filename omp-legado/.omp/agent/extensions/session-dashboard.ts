/**
 * Dashboard de sessões na abertura do omp.
 *
 * Com autoResume desligado, abrir o omp cria uma sessão nova. Se o projeto já
 * tem sessões salvas, esta extensão abre o seletor nativo (/resume) por cima
 * da sessão vazia: Enter retoma a escolhida, Esc fica na nova.
 *
 * O seletor de sessões não tem API de extensão, então a abertura é feita
 * injetando as teclas "/resume" + Enter no próprio painel do tmux (mesmo
 * padrão do mode-switcher.ts). Fora do tmux, cai num aviso para usar /resume.
 *
 * Só dispara uma vez por processo e só com a sessão atual vazia: -c, --resume
 * e prompt inicial passam direto. O arquivo da sessão nova é excluído da
 * contagem para não se contar como "sessão anterior".
 *
 * Os tipos abaixo descrevem só a parte da ExtensionAPI que este arquivo usa; o
 * pacote @oh-my-pi/pi-coding-agent não está instalado nesta máquina.
 */

const OPEN_DELAY_MS = 1000;

interface ExecResult {
  stdout: string;
  stderr: string;
  code: number;
  killed: boolean;
}

interface BranchEntry {
  type?: string;
}

interface SessionManagerLike {
  getBranch(): BranchEntry[];
  getSessionId?(): string | undefined;
}

interface DashboardContext {
  hasUI: boolean;
  cwd: string;
  sessionManager: SessionManagerLike;
  isIdle(): boolean;
  hasPendingMessages(): boolean;
  ui: {
    notify(message: string, kind: "info" | "warning" | "error"): void;
    getEditorText(): string;
  };
  setTimeout(fn: () => void, ms: number): unknown;
}

interface Pi {
  setLabel(label: string): void;
  exec(bin: string, args: string[]): Promise<ExecResult>;
  on(
    event: "session_start",
    handler: (event: unknown, ctx: DashboardContext) => void,
  ): void;
}

interface DirentLike {
  isFile(): boolean;
  name: string;
}

interface FsLike {
  readdirSync(path: string, options: { withFileTypes: true }): DirentLike[];
}

declare function require(id: string): unknown;

// require de builtin do node: o runtime de extensões roda em Bun e provê os
// dois globais; o cast fecha o tipo mínimo que usamos.
const fs = require("node:fs") as FsLike;

function sessionBucket(cwd: string): string | undefined {
  const home = process.env.HOME;
  if (!home) return undefined;
  const root = process.env.PI_CODING_AGENT_DIR ?? `${home}/.omp/agent`;
  if (cwd === home) return `${root}/sessions/-`;
  if (cwd.startsWith(`${home}/`)) {
    return `${root}/sessions/-${cwd.slice(home.length + 1).split("/").join("-")}`;
  }
  const tmp = process.env.TMPDIR ?? "/tmp";
  if (cwd.startsWith(`${tmp}/`)) {
    return `${root}/sessions/-tmp-${cwd.slice(tmp.length + 1).split("/").join("-")}`;
  }
  return `${root}/sessions/--${cwd.replace(/^\/+/, "").split("/").join("-")}--`;
}

function countOtherSessions(ctx: DashboardContext): number {
  const bucket = sessionBucket(ctx.cwd);
  if (!bucket) return 0;
  let sessionId: string | undefined;
  try {
    sessionId = ctx.sessionManager.getSessionId?.();
  } catch {
    sessionId = undefined;
  }
  try {
    return fs
      .readdirSync(bucket, { withFileTypes: true })
      .filter(
        (d) =>
          d.isFile() &&
          d.name.endsWith(".jsonl") &&
          (!sessionId || !d.name.includes(sessionId)),
      ).length;
  } catch {
    return 0;
  }
}

export default function (pi: Pi) {
  pi.setLabel("Dashboard de sessões");
  let fired = false;

  async function openPicker(): Promise<boolean> {
    const pane = process.env.TMUX_PANE;
    if (!pane) return false;
    try {
      await pi.exec("tmux", ["send-keys", "-t", pane, "-l", "/resume"]);
      await pi.exec("tmux", ["send-keys", "-t", pane, "Enter"]);
      return true;
    } catch {
      return false;
    }
  }

  pi.on("session_start", (_event: unknown, ctx: DashboardContext) => {
    if (fired) return;
    fired = true;
    if (!ctx.hasUI) return;
    try {
      // -c, --resume e prompt inicial já trazem mensagem: não atrapalhar.
      if (ctx.sessionManager.getBranch().some((e) => e.type === "message")) return;
    } catch {
      return; // na dúvida, não atrapalha a abertura
    }
    const others = countOtherSessions(ctx);
    if (others === 0) return;

    ctx.setTimeout(() => {
      void (async () => {
        // Usuário já mandou prompt ou está digitando: não atrapalhar.
        if (!ctx.isIdle() || ctx.hasPendingMessages()) return;
        if (ctx.ui.getEditorText().trim() !== "") return;
        if (await openPicker()) return;
        ctx.ui.notify(
          `${others} sessão(ões) salvas neste projeto. Use /resume para retomar uma.`,
          "info",
        );
      })();
    }, OPEN_DELAY_MS);
  });
}
