import * as fs from "fs/promises";
import { View, div } from "gpui-kit";
import { spaces, focused, panes, terminals, run, shared, setShared, nextCommand, notify, openOverlay, checking, appHome } from "herdr";
import { abrirCopia, emCopia, dormir } from "./copia.js";

// No modo cópia o layout vira a variante gerada `<nome>-copia`, com a moldura
// vermelha. A cor sai só de "o pane focado mostra o terminal de cópia".
const base = (nome) => nome?.replace(/-copia$/, "");
let pedido = null;
let abrindo = 0;
let avisado = 0;

// Bloco flutuante sempre vivo: guarda o space anterior, mostra a barra de tabs
// só no layout sem sidebar e com mais de uma tab, e abre menus pelo teclado.
export default class Fluxo extends View {
  init(_props, cx) {
    this.tabsVisiveis = null;
    cx.spawn(async (cx) => {
      for (;;) {
        const c = await nextCommand();
        if (c === "voltar") this.voltar();
        else if (c === "novo") openOverlay({ mod: "new-menu", kind: "dialog", width: 250 });
        else if (c === "ssh") openOverlay({ mod: "sessionizer", props: { ssh: true }, kind: "popup", at: "top", offset: 40, width: 640, height: 0.8 });
        else if (c.startsWith("worktree-")) this.worktree(c.slice("worktree-".length));
        else if (c === "sidebar") this.sidebar();
        else if (c.startsWith("fechar-")) this.fechar(c.slice("fechar-".length));
        else if (c === "copia") this.copia().catch((e) => notify({ title: "Copy mode", body: String(e), level: "error" }));
        else if (c.startsWith("copiado-")) this.copiado(Number(c.slice("copiado-".length)));
      }
    });
  }

  voltar() {
    this.registrar();
    const alvo = shared("fluxo.anterior");
    if (!alvo || alvo === shared("fluxo.atual") || !spaces().some((s) => s.id === alvo)) {
      notify({ title: "No previous space", level: "info", timeout: 2000 });
      return;
    }
    setShared("fluxo.anterior", shared("fluxo.atual"));
    setShared("fluxo.atual", alvo);
    run("space.select", { id: alvo });
  }

  registrar() {
    const ativo = spaces().find((s) => s.active);
    const atual = ativo?.id ?? null;
    const visto = shared("fluxo.atual") ?? null;
    if (atual && atual !== visto) {
      if (visto) setShared("fluxo.anterior", visto);
      setShared("fluxo.atual", atual);
    }
    const nome = shared("layout");
    if (nome !== this.layoutVisto) {
      this.layoutVisto = nome;
      this.tabsVisiveis = null;
    }
    const mostrar = base(nome) !== "raphael" && (ativo?.tabs.length ?? 0) > 1;
    if (mostrar !== this.tabsVisiveis) {
      this.tabsVisiveis = mostrar;
      run(mostrar ? "layout.show" : "layout.hide", { id: "tabs" });
    }
    this.corrigirLayout();
  }

  corrigirLayout() {
    const nome = shared("layout");
    if (!nome) return;
    if (pedido && (pedido.nome === nome || Date.now() - pedido.em > 2000)) pedido = null;
    if (pedido) return;
    const copia = emCopia();
    if (copia) abrindo = 0;
    if (copia && nome === base(nome)) this.trocar(`${nome}-copia`);
    if (!copia && nome !== base(nome)) this.trocar(base(nome));
  }

  trocar(nome) {
    pedido = { nome, em: Date.now() };
    run("layout.switch", { name: nome });
  }

  // O pane não muda de visual por estado; sem sidebar é outro layout, sem moldura.
  async sidebar() {
    const alvo = base(shared("layout")) === "raphael-cheio" ? "raphael" : "raphael-cheio";
    if (!emCopia()) return this.trocar(alvo);
    await gerarVariante(alvo);
    this.trocar(`${alvo}-copia`);
  }

  // Só fechar tab pede confirmação, inclusive pelo x no último pane dela. Pane e
  // space fecham direto, e a última tab leva o space junto, sem pergunta.
  fechar(oque) {
    const f = focused();
    const space = spaces().find((s) => s.active);
    if (!f || !space) return;
    const fecharSpace = () => run("space.close", { id: space.id, confirmed: true });
    const ultimaTab = space.tabs.length === 1;
    if (oque === "space") return fecharSpace();
    if (oque === "pane") {
      if (!f.pane) return;
      if (panes().filter((p) => p.tab === f.tab).length > 1) return run("pane.close", { pane: f.pane });
    }
    const tab = space.tabs.find((t) => t.id === f.tab);
    if (!tab) return;
    if (ultimaTab) return fecharSpace();
    openOverlay({
      mod: "confirma",
      kind: "dialog",
      width: 380,
      height: 150,
      props: { title: `Close tab ${tab.name}?`, detail: "Its terminals will end.", command: { name: "tab.close", args: { id: tab.id, confirmed: true } } },
    });
  }

  // Todas as instâncias deste mod recebem o comando, e a que abre morre com a
  // troca de layout no meio do await; `abrindo` se solta quando a cópia aparece
  // (corrigirLayout) ou sozinho em 3 s.
  async copia() {
    const f = focused();
    if (Date.now() - abrindo < 3000 || emCopia() || !f?.terminal || !f.pane) return;
    abrindo = Date.now();
    if (await gerarVariante(base(shared("layout")))) await dormir(400);
    await abrirCopia(f);
    abrindo = 0;
  }

  copiado(n) {
    if (Date.now() - avisado < 500) return;
    avisado = Date.now();
    notify({ title: "Copied", body: n > 1 ? `${n} lines` : "1 line", level: "info" });
  }

  worktree(action) {
    const space = spaces().find((s) => s.active);
    if (!space) return;
    const size = action === "open" ? { width: 560, height: 480 } : { width: 440, height: 260 };
    openOverlay({ mod: "worktree", kind: "dialog", ...size, props: { space: space.id, action } });
  }

  // Mexer em estado compartilhado ou no layout durante o render se perde; adia.
  // Ler foco e layout aqui faz o render voltar quando eles mudam.
  render(cx) {
    focused();
    terminals();
    shared("layout");
    if (!checking()) cx.timer.after(0, () => this.registrar());
    return div();
  }
}

// A variante só troca cores. Tamanhos e painéis clicados ficam no estado de
// cada layout (.state/<nome>.json), copiado junto para o pane não mudar de
// tamanho ao entrar na cópia.
async function gerarVariante(nome) {
  const pasta = `${appHome()}/layouts`;
  const no = JSON.parse(await fs.readFile(`${pasta}/${nome}.json`, "utf8"));
  const pintar = (n) => {
    if (!n || typeof n !== "object") return;
    if (n.tab && n.pane) {
      n.pane.border = { ...n.pane.border, color: "blocked" };
      n.pane.focus = { ...n.pane.focus, color: "blocked" };
      n.pane.header = { content: { mod: "cabecalho-copia" }, height: 32, position: "top" };
      if (!n.pane.lone) Object.assign(n.pane, { lone: true, gap: 0 });
    }
    Object.values(n).forEach(pintar);
  };
  pintar(no);
  const estado = JSON.parse((await fs.readFile(`${pasta}/.state/${nome}.json`, "utf8").catch(() => null)) ?? "{}");
  await fs.writeFile(`${pasta}/.state/${nome}-copia.json`, JSON.stringify({ ...estado, file: no }, null, 2));
  const destino = `${pasta}/${nome}-copia.json`;
  const texto = JSON.stringify(no, null, 2);
  if ((await fs.readFile(destino, "utf8").catch(() => null)) === texto) return false;
  await fs.writeFile(destino, texto);
  return true;
}
