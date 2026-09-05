/**
 * Seletor visual de modo, modelo e raciocínio.
 *
 * Alt+Shift+M abre um menu com as três opções, para não precisar decorar atalho.
 *
 * Modo e modelo não têm API de extensão no omp, então esses dois itens reinjetam
 * o próprio atalho nativo no painel do tmux (Alt+Shift+P para plano, Alt+M para o
 * seletor de modelo). Fora do tmux o modelo cai num seletor próprio e o modo
 * apenas avisa qual tecla usar.
 *
 * Os tipos abaixo descrevem só a parte da ExtensionAPI que este arquivo usa; o
 * pacote @oh-my-pi/pi-coding-agent não está instalado nesta máquina.
 */

const PLAN_CHORD = "M-P"; // Alt+Shift+P -> app.plan.toggle
const MODEL_CHORD = "M-m"; // Alt+M -> app.model.select

type Level = "off" | "minimal" | "low" | "medium" | "high" | "xhigh" | "max";

interface ModelInfo {
  id: string;
  provider: string;
  name?: string;
  reasoning?: boolean;
  thinking?: { efforts?: Level[] };
}

interface ShortcutContext {
  ui: {
    select(
      title: string,
      options: string[],
      options2?: { initialIndex?: number; helpText?: string },
    ): Promise<string | undefined>;
    notify(message: string, kind: "info" | "warning" | "error"): void;
  };
  models: {
    current(): ModelInfo | undefined;
    list(): ModelInfo[];
  };
}

interface Pi {
  setLabel(label: string): void;
  exec(bin: string, args: string[]): Promise<unknown>;
  setModel(model: ModelInfo): Promise<boolean>;
  getThinkingLevel(): Level | undefined;
  setThinkingLevel(level: Level): void;
  registerShortcut(
    chord: string,
    spec: { description: string; handler: (ctx: ShortcutContext) => void | Promise<void> },
  ): void;
}

export default function (pi: Pi) {
  pi.setLabel("Seletor de modo");

  async function sendChord(chord: string): Promise<boolean> {
    const pane = process.env.TMUX_PANE;
    if (!pane) return false;
    try {
      await pi.exec("tmux", ["send-keys", "-t", pane, chord]);
      return true;
    } catch {
      return false;
    }
  }

  async function pickModel(ctx: ShortcutContext): Promise<void> {
    if (await sendChord(MODEL_CHORD)) return;
    const models = ctx.models.list();
    if (models.length === 0) {
      ctx.ui.notify("Nenhum modelo disponível.", "warning");
      return;
    }
    const current = ctx.models.current();
    const labels = models.map((m) => `${m.provider}/${m.id}`);
    const picked = await ctx.ui.select("Modelo", labels, {
      initialIndex: Math.max(
        0,
        labels.indexOf(current ? `${current.provider}/${current.id}` : ""),
      ),
    });
    if (typeof picked !== "string") return;
    const model = models[labels.indexOf(picked)];
    if (!model) return;
    const ok = await pi.setModel(model);
    ctx.ui.notify(
      ok ? `Modelo: ${picked}` : `Sem credencial para ${picked}.`,
      ok ? "info" : "warning",
    );
  }

  async function pickThinking(ctx: ShortcutContext): Promise<void> {
    const model = ctx.models.current();
    const efforts = model?.thinking?.efforts ?? [];
    if (!model?.reasoning || efforts.length === 0) {
      ctx.ui.notify(`${model?.name ?? "Este modelo"} não ajusta raciocínio.`, "warning");
      return;
    }
    const levels: Level[] = ["off", ...efforts];
    const current = pi.getThinkingLevel();
    const picked = await ctx.ui.select("Raciocínio", levels, {
      initialIndex: Math.max(0, current ? levels.indexOf(current) : 0),
    });
    if (typeof picked !== "string") return;
    pi.setThinkingLevel(picked as Level);
    ctx.ui.notify(`Raciocínio: ${pi.getThinkingLevel()}`, "info");
  }

  pi.registerShortcut("alt+shift+m", {
    description: "Escolher modo, modelo ou raciocínio",
    handler: async (ctx) => {
      const model = ctx.models.current();
      const items = [
        "Modo — alternar entre plano e normal",
        `Modelo — ${model ? `${model.provider}/${model.id}` : "nenhum"}`,
        `Raciocínio — ${pi.getThinkingLevel() ?? "off"}`,
      ];
      const picked = await ctx.ui.select("Trocar", items, {
        helpText: "enter escolhe  esc cancela",
      });
      if (typeof picked !== "string") return;
      switch (items.indexOf(picked)) {
        case 0:
          if (!(await sendChord(PLAN_CHORD))) {
            ctx.ui.notify("Fora do tmux: use Shift+Tab para alternar o modo.", "warning");
          }
          return;
        case 1:
          await pickModel(ctx);
          return;
        case 2:
          await pickThinking(ctx);
          return;
      }
    },
  });
}
