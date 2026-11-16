import * as fs from "fs/promises";
import { focused, terminals, theme, exec, run, appHome } from "herdr";

// Modo cópia: um nvim limpo (copia.lua) num terminal à parte, mostrado no lugar
// do terminal do pane. Ele mesmo devolve o pane ao sair. terminals() não traz
// labels, então o terminal de cópia se reconhece pelo argv.

export function emCopia() {
  const shown = focused()?.shown;
  return !!shown && !!terminals().find((t) => t.address === shown)?.argv?.some((a) => a.startsWith("COPIA_ALVO="));
}

export const dormir = (ms) => exec("sleep", [String(ms / 1000)]);

export async function abrirCopia(f) {
  const tema = `${appHome()}/.copia-tema.json`;
  await fs.writeFile(tema, JSON.stringify(theme()));
  const r = await exec("hc", [
    "run", "--bg", "--json", "--no-parent", "--no-notify", "--rm", "--",
    "env", `COPIA_ALVO=${f.terminal}`, `COPIA_PANE=${f.pane}`, `COPIA_TEMA=${tema}`, "COPIA_HIST=20000",
    "nvim", "--clean", "-u", `${appHome()}/mods/fluxo/copia.lua`,
  ]);
  if (r.code !== 0) throw new Error(r.stderr || r.stdout);
  // Um show antes do app conhecer o terminal novo é ignorado sem erro.
  const addr = JSON.parse(r.stdout).address;
  for (let i = 0; i < 60 && focused()?.shown !== addr; i++) {
    if (terminals().some((t) => t.address === addr)) run("terminal.show", { terminal: addr, pane: f.pane });
    await dormir(50);
  }
  if (focused()?.shown !== addr) {
    exec("hc", ["kill", addr]);
    throw new Error("copy terminal did not show");
  }
}
