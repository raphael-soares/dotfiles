import { View, div } from "gpui-kit";
import { h_flex, v_flex } from "gpui-base";
import { theme, exec, home, openOverlay, notify, terminals, panes, focused, run } from "herdr";

// O omp cuida dos tokens; a cada 5 min pergunta a cada perfil (`omp` e `ompe`) o uso.
const PERFIS = [
  { nome: "Personal", cor: "ansi5", args: [] },
  { nome: "Work", cor: "ansi2", args: ["--profile=enterprise", "--config", `${home()}/.dotfiles/ai/.omp/overlays/enterprise.yml`] },
];
const INTERVALO = 5 * 60_000;
const JANELA = { "5h": "5 hours", "7d": "7 days" };
const ALTURA = [80, 48];

function falta(ms) {
  const m = Math.max(0, Math.round((ms - Date.now()) / 60_000));
  if (m < 60) return `${m}m`;
  if (m < 48 * 60) return `${Math.floor(m / 60)}h ${m % 60}m`;
  return `${Math.floor(m / 1440)}d ${Math.floor((m % 1440) / 60)}h`;
}

// Limite de tier (ex. "7d:fable") repete a janela geral e fica de fora.
function ler(json) {
  const reports = JSON.parse(json).reports ?? [];
  const resets = reports.map((r) => r.resetCredits).find(Boolean);
  return {
    limites: reports
      .flatMap((r) => r.limits)
      .filter((l) => l.amount && !l.scope?.tier)
      .map((l) => ({
        nome: l.amount.unit === "usd" ? "Extra usage" : (JANELA[l.window?.id] ?? l.label),
        fracao: l.amount.usedFraction ?? l.amount.used / l.amount.limit,
        usd: l.amount.unit === "usd" ? l.amount : null,
        reset: l.window?.resetsAt ?? null,
      })),
    resets: resets && {
      prontos: resets.redeemableCount ?? 0,
      guardados: resets.availableCount ?? 0,
      expira: resets.credits?.find((c) => c.usable)?.expiresAt ?? null,
    },
  };
}

export default class Uso extends View {
  init(_props, cx) {
    this.dados = PERFIS.map(() => ({ limites: [], resets: null, velho: false }));
    const buscar = (cx) => PERFIS.forEach((p, i) => cx.spawn(async (cx) => {
      try {
        const r = await exec("omp", [...p.args, "usage", "--json"], { timeout: 60_000 });
        if (r.code !== 0) throw new Error(r.stderr.trim().split("\n").pop());
        this.dados[i] = { ...ler(r.stdout), velho: false };
      } catch {
        this.dados[i].velho = true;
      }
      cx.notify();
    }));
    buscar(cx);
    cx.timer.every(INTERVALO, buscar);
    this.tamanho = null;
    this.depois = (f) => cx.spawn(f);
    cx.timer.every(400, () => this.ajustar(this.visiveis()));
  }

  // Perfis dos omp nos panes da tab em foco, lidos do argv do processo em primeiro plano.
  visiveis() {
    const tab = focused()?.tab;
    const fg = new Map(terminals().map((x) => [x.address, x.foreground]));
    const achados = new Set();
    for (const p of panes()) {
      const f = p.tab === tab && p.terminal ? fg.get(p.terminal) : null;
      if (f?.name !== "omp") continue;
      const a = f.argv ?? [];
      const i = a.indexOf("--profile");
      achados.add(a.includes("--profile=enterprise") || (i >= 0 && a[i + 1] === "enterprise") ? 1 : 0);
    }
    return [...achados].sort();
  }

  // O bloco do layout tem altura fixa e acompanha quantos perfis aparecem. Com 0 px o
  // bloco não renderiza, então quem o traz de volta é o timer, não o render.
  ajustar(vis) {
    const px = vis.length ? 20 + vis.reduce((s, i) => s + ALTURA[i], 0) + 16 * (vis.length - 1) : 0;
    if (px === this.tamanho) return;
    this.tamanho = px;
    this.depois(async () => run("layout.resize", { id: "uso", px }));
  }

  async detalhar(p) {
    try {
      const r = await exec("hc", ["run", "--bg", "--json", "--no-parent", "--no-notify", "--rm", "--",
        "bash", "-c", 'omp "$@" usage; read -rsn1', "omp", ...p.args]);
      if (r.code !== 0) throw new Error(r.stderr.trim() || r.stdout.trim());
      const { address } = JSON.parse(r.stdout);
      // Overlay de um terminal que o app ainda não conhece não abre.
      for (let i = 0; i < 40 && !terminals().some((x) => x.address === address); i++) await exec("sleep", ["0.05"]);
      openOverlay({ layout: { type: "block", content: { terminal: address } }, kind: "dialog", width: 0.7, height: 0.6 });
    } catch (e) {
      notify({ title: "Usage", body: String(e?.message ?? e), level: "error" });
    }
  }

  render() {
    const t = theme();
    const barra = (f, c) => {
      const v = Math.max(0, Math.min(1, f));
      return h_flex().w_full().h(4).rounded_full().overflow_hidden().bg(t.border)
        .child(div().h_full().rounded_full().bg(v >= 0.9 ? t.blocked : c).flex_basis(0).flex_grow(v))
        .child(div().h_full().flex_basis(0).flex_grow(1 - v));
    };
    const limite = (l, c) => v_flex().gap(4)
      .child(h_flex().h(16).items_center().gap(6)
        .child(div().flex_1().text_color(t.muted).child(l.nome))
        .child(div().text_color(t.foreground).font_semibold().child(
          l.usd ? `$${Math.round(l.usd.used)} / $${Math.round(l.usd.limit)}` : `${Math.round(l.fracao * 100)}%`))
        .when(Boolean(l.reset), (el) => el.child(div().text_color(t.dim).child(`· resets in ${falta(l.reset)}`))))
      .child(barra(l.fracao, c));
    const selo = (r, c) => {
      const dica = `${r.guardados} saved, ${r.prontos} usable now` + (r.expira ? `, expires in ${falta(Date.parse(r.expira))}` : "");
      return div()
        .id("uso-resets")
        .px(6)
        .rounded(5)
        .text_size(10.5)
        .bg(`${c}26`)
        .text_color(c)
        .tooltip(dica)
        .child(`${r.prontos} reset ready`);
    };
    const secao = (p, i) => {
      const d = this.dados[i];
      const c = t[p.cor];
      return v_flex()
        .id(`uso-${i}`)
        .gap(8)
        .cursor_pointer()
        .on_click(() => this.detalhar(p))
        .when(d.velho, (el) => el.opacity(0.5))
        .child(h_flex().h(16).items_center().gap(6)
          .child(div().flex_1().font_semibold().text_color(c).child(p.nome))
          .when(d.resets?.prontos > 0, (el) => el.child(selo(d.resets, c))))
        .children(d.limites.length ? d.limites.map((l) => limite(l, c)) : [div().text_color(t.dim).child(d.velho ? "unavailable" : "loading…")]);
    };
    const vis = this.visiveis();
    this.ajustar(vis);
    return v_flex()
      .size_full()
      .px(14)
      .py(10)
      .gap(16)
      .justify_end()
      .text_size(11.5)
      .children(vis.map((i) => secao(PERFIS[i], i)));
  }
}
