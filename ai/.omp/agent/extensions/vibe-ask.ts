/**
 * Habilita a ferramenta ask na sessao pai durante o modo vibe.
 *
 * No modo vibe, o omp restringe a sessao pai a ferramentas de gestao de
 * workers (vibe_spawn, vibe_send, etc.) e leitura, removendo a ferramenta
 * ask. Esta extensao detecta o modo vibe ativo na sessao interativa com UI
 * e adiciona ask de volta a lista de ferramentas ativas.
 */

interface ExtensionContext {
  hasUI: boolean;
}

interface BeforeAgentStartEvent {
  type: "before_agent_start";
  prompt: string;
}

interface Pi {
  setLabel?(label: string): void;
  getActiveTools(): string[];
  setActiveTools(toolNames: string[]): Promise<void> | void;
  on(
    event: "before_agent_start",
    handler: (event: BeforeAgentStartEvent, ctx: ExtensionContext) => Promise<void> | void,
  ): void;
}

export default function (pi: Pi) {
  pi.setLabel?.("vibe-ask");

  pi.on("before_agent_start", async (_event, ctx) => {
    if (!ctx?.hasUI) return;

    const activeTools = pi.getActiveTools() ?? [];
    if (activeTools.includes("vibe_spawn") && !activeTools.includes("ask")) {
      await pi.setActiveTools([...activeTools, "ask"]);
    }
  });
}
