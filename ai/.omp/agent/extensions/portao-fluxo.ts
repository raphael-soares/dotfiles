import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";
import { spawnSync } from "node:child_process";
import { homedir } from "node:os";
import { basename, resolve } from "node:path";

export type Sh = (args: string[], cwd: string) => { code: number; out: string };

const LABEL_DONO = "revisar-dono";
const BRANCHES_PROTEGIDAS = new Set(["dev", "main", "master"]);
const MSG_ESPERA =
  "Não espere CI em laço nem com --watch: use `pr-watch <dono/repo> <pr>` numa chamada só; em sessão da fila, termine.";

function tokenizar(texto: string): string[][] {
  const segmentos: string[][] = [];
  let tokens: string[] = [];
  let atual = "";
  let temToken = false;
  let aspa: string | null = null;
  const fechaToken = () => {
    if (temToken) tokens.push(atual);
    atual = "";
    temToken = false;
  };
  const fechaSegmento = () => {
    fechaToken();
    if (tokens.length > 0) segmentos.push(tokens);
    tokens = [];
  };
  for (let i = 0; i < texto.length; i++) {
    const c = texto[i];
    if (aspa) {
      if (c === aspa) aspa = null;
      else if (c === "\\" && aspa === '"' && i + 1 < texto.length) atual += texto[++i];
      else atual += c;
      continue;
    }
    if (c === "'" || c === '"') {
      aspa = c;
      temToken = true;
    } else if (c === "\\" && i + 1 < texto.length) {
      atual += texto[++i];
      temToken = true;
    } else if (c === " " || c === "\t") {
      fechaToken();
    } else if (c === "\n" || c === ";" || c === "&" || c === "|") {
      fechaSegmento();
    } else {
      atual += c;
      temToken = true;
    }
  }
  fechaSegmento();
  return segmentos;
}

function subcomando(args: string[]): { sub: string | undefined; resto: string[] } {
  for (let i = 0; i < args.length; i++) {
    const a = args[i];
    if (a === "-C" || a === "-c") i++;
    else if (!a.startsWith("-")) return { sub: a, resto: args.slice(i + 1) };
  }
  return { sub: undefined, resto: [] };
}

function posicionais(args: string[], comValor: Set<string>): string[] {
  const out: string[] = [];
  for (let i = 0; i < args.length; i++) {
    const a = args[i];
    if (comValor.has(a)) i++;
    else if (!a.startsWith("-")) out.push(a);
  }
  return out;
}

function valorDe(args: string[], ...nomes: string[]): string | undefined {
  for (let i = 0; i < args.length; i++) {
    for (const n of nomes) {
      if (args[i] === n) return args[i + 1];
      if (args[i].startsWith(`${n}=`)) return args[i].slice(n.length + 1);
    }
  }
  return undefined;
}

function destinoDoRefspec(refspec: string, atual: () => string): string {
  let r = refspec.replace(/^\+/, "");
  if (r.includes(":")) r = r.slice(r.lastIndexOf(":") + 1);
  r = r.replace(/^refs\/heads\//, "");
  return r === "HEAD" ? atual() : r;
}

function regraPush(args: string[], dir: string, sh: Sh): string | undefined {
  const { sub, resto } = subcomando(args);
  if (sub !== "push") return;
  const atual = () => sh(["git", "rev-parse", "--abbrev-ref", "HEAD"], dir).out.trim();
  const pos = posicionais(resto, new Set(["-o", "--push-option", "--repo", "--receive-pack", "--exec"]));
  const refspecs = pos.slice(1);
  const destinos = refspecs.length > 0 ? refspecs.map((r) => destinoDoRefspec(r, atual)) : [atual()];
  const alvo = destinos.find((d) => BRANCHES_PROTEGIDAS.has(d));
  if (alvo) {
    return `Push direto em \`${alvo}\` é recusado. Faça o push da sua branch de trabalho e abra uma PR.`;
  }
}

function regraNoVerify(args: string[]): string | undefined {
  const { sub } = subcomando(args);
  if ((sub === "commit" || sub === "push" || sub === "merge") && args.includes("--no-verify")) {
    return "`--no-verify` é recusado: conserte o que o hook acusa. Se o hook estiver errado, pergunte ao dono.";
  }
}

const VALOR_DE_MERGE = new Set([
  "-R",
  "--repo",
  "-b",
  "--body",
  "-F",
  "--body-file",
  "-t",
  "--subject",
  "-A",
  "--author-email",
  "--match-head-commit",
]);

function checkAprovado(c: Record<string, unknown>): boolean {
  if (typeof c.conclusion === "string" && c.conclusion !== "") {
    return ["SUCCESS", "SKIPPED", "NEUTRAL"].includes(c.conclusion.toUpperCase());
  }
  if (typeof c.state === "string") return c.state.toUpperCase() === "SUCCESS";
  return false;
}

function regraMerge(args: string[], dir: string, sh: Sh): string | undefined {
  try {
    const seletor = posicionais(args, VALOR_DE_MERGE)[0];
    const repoArg = valorDe(args, "-R", "--repo");
    const consulta = sh(
      [
        "gh",
        "pr",
        "view",
        ...(seletor ? [seletor] : []),
        ...(repoArg ? ["-R", repoArg] : []),
        "--json",
        "url,baseRefName,labels,statusCheckRollup",
      ],
      dir,
    );
    if (consulta.code !== 0) {
      return "Não consegui consultar a PR antes do merge, então o merge está bloqueado. Verifique o CI e se há `revisar-dono`, ou deixe com o dono.";
    }
    const pr = JSON.parse(consulta.out);
    const base: string = pr.baseRefName;
    const repo = /^https?:\/\/[^/]+\/([^/]+\/[^/]+)\/pull\//.exec(pr.url)?.[1];
    if (!repo || !base) throw new Error("PR sem url ou base");

    let producao: string[] = ["main", "master"];
    const ficha = sh(["gh", "api", `repos/${repo}/contents/ficha.json?ref=${encodeURIComponent(base)}`], dir);
    if (ficha.code === 0) {
      const conteudo = JSON.parse(ficha.out).content;
      const prod = JSON.parse(Buffer.from(String(conteudo), "base64").toString("utf8")).producao;
      producao = typeof prod === "string" && prod !== "" ? [prod] : [];
    }

    if (producao.includes(base)) {
      return `A base \`${base}\` é branch de produção: o merge é do dono.`;
    }
    const labels: { name?: string }[] = pr.labels ?? [];
    if (labels.some((l) => l.name === LABEL_DONO)) {
      return `A PR tem a label \`${LABEL_DONO}\`: o merge é do dono.`;
    }
    const checks: Record<string, unknown>[] = pr.statusCheckRollup ?? [];
    if (checks.length === 0) return "A PR não tem nenhum check: falta o CI rodar.";
    if (!checks.every(checkAprovado)) {
      return "Faltam checks verdes na PR: espere o CI (`pr-watch <dono/repo> <pr>`) antes de mesclar.";
    }
  } catch (e) {
    return `Falha ao avaliar a PR antes do merge (${(e as Error).message}), então o merge está bloqueado.`;
  }
}

function regraGh(args: string[], dir: string, sh: Sh): string | undefined {
  const { sub, resto } = subcomando(args);
  const outro = resto.find((a) => !a.startsWith("-"));
  if (sub === "pr" && outro === "merge") {
    const depoisDoMerge = resto.slice(resto.indexOf("merge") + 1);
    if (depoisDoMerge.includes("--admin")) {
      return "`gh pr merge --admin` é recusado: espere o CI ficar verde.";
    }
    return regraMerge(depoisDoMerge, dir, sh);
  }
  if (sub === "pr" && outro === "edit") {
    const removidas = resto.flatMap((a, i) => {
      if (a === "--remove-label") return [resto[i + 1] ?? ""];
      if (a.startsWith("--remove-label=")) return [a.slice("--remove-label=".length)];
      return [];
    });
    if (removidas.some((v) => v.split(",").includes(LABEL_DONO))) {
      return `A label \`${LABEL_DONO}\` é do CI e do dono: não a remova.`;
    }
  }
  if (sub === "label" && outro === "delete" && resto.includes(LABEL_DONO)) {
    return `A label \`${LABEL_DONO}\` é do CI e do dono: não a apague.`;
  }
  if (sub === "run" && outro === "watch") return MSG_ESPERA;
  if (sub === "pr" && outro === "checks" && resto.some((a) => a === "--watch" || a.startsWith("--watch="))) {
    return MSG_ESPERA;
  }
}

const GOALS_MAVEN = new Set(["test", "verify", "package", "install"]);
const ESCOPO_MAVEN = /^-Dtest=|^-Dit\.test=|^-Dgroups=|^-DskipTests|^-Dmaven\.test\.skip|pitest/;

function regraMaven(args: string[], dir: string, sh: Sh): string | undefined {
  if (!args.some((a) => GOALS_MAVEN.has(a))) return;
  if (args.some((a) => ESCOPO_MAVEN.test(a))) return;
  const topo = sh(["git", "rev-parse", "--show-toplevel"], dir);
  if (topo.code !== 0) return;
  const raiz = topo.out.trim();
  if (raiz === "" || sh(["test", "-f", `${raiz}/scripts/portao`], dir).code !== 0) return;
  return "Maven sem filtro roda a suíte inteira: use `scripts/portao --so teste` ou `-Dtest=<Classe>`. A suíte inteira roda no CI.";
}

function analisar(tokens: string[], dir: string, sh: Sh, profundidade: number): string | undefined {
  for (let i = 0; i < tokens.length; i++) {
    const nome = basename(tokens[i]);
    const args = tokens.slice(i + 1);
    let motivo: string | undefined;
    if (nome === "git") motivo = regraNoVerify(args) ?? regraPush(args, dir, sh);
    else if (nome === "gh") motivo = regraGh(args, dir, sh);
    else if (nome === "mvnw" || nome === "mvn") motivo = regraMaven(args, dir, sh);
    if (motivo) return motivo;
    if (profundidade < 2 && /\s/.test(tokens[i]) && (tokens[i - 1] === "-c" || tokens[i - 1] === "eval")) {
      for (const seg of tokenizar(tokens[i])) {
        const m = analisar(seg, dir, sh, profundidade + 1);
        if (m) return m;
      }
    }
  }
}

function diretorioEfetivo(comando: string, cwd: string): string {
  const m = /(?:^|[\s;&|])cd\s+("[^"]+"|'[^']+'|[^\s;&|]+)\s*&&/.exec(comando);
  if (!m) return cwd;
  let alvo = m[1].replace(/^["']|["']$/g, "");
  if (alvo === "~" || alvo.startsWith("~/")) alvo = homedir() + alvo.slice(1);
  return resolve(cwd, alvo);
}

export function decidir(comando: string, cwd: string, sh: Sh): string | undefined {
  if (
    /\b(while|until|for)\b/.test(comando) &&
    /\bsleep\b/.test(comando) &&
    /\bgh\s+(run|pr|api|workflow)\b/.test(comando)
  ) {
    return MSG_ESPERA;
  }
  try {
    const dir = diretorioEfetivo(comando, cwd);
    for (const tokens of tokenizar(comando)) {
      const motivo = analisar(tokens, dir, sh, 0);
      if (motivo) return motivo;
    }
  } catch {
    return;
  }
}

function shReal(args: string[], cwd: string): { code: number; out: string } {
  const r = spawnSync(args[0], args.slice(1), { cwd, encoding: "utf8", timeout: 10_000 });
  return { code: r.status ?? 1, out: r.stdout ?? "" };
}

export default function (pi: ExtensionAPI) {
  pi.setLabel("portao fluxo");

  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName !== "bash") return;
    const command = event.input.command;
    if (typeof command !== "string" || command.trim() === "") return;
    const reason = decidir(command, ctx.cwd, shReal);
    if (reason) return { block: true, reason };
  });
}
