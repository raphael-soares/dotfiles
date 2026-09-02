// Reescreve comandos do bash para as versoes rtk, economizando token.
// Toda a regra de reescrita mora no binario rtk (`rtk rewrite`), igual ao hook
// do Claude Code em ~/.claude/hooks/rtk-rewrite.sh. Aqui so tem a ponte.
//
// Codigos de saida de `rtk rewrite`:
//   0 + stdout  reescreveu, sem regra de permissao
//   1           sem equivalente rtk, passa direto
//   2           regra de deny, passa direto
//   3 + stdout  reescreveu, no Claude pediria confirmacao
import { spawnSync } from "node:child_process";

import type { HookAPI } from "@oh-my-pi/pi-coding-agent/extensibility/hooks";

let rtkMissing = false;

export default function (pi: HookAPI): void {
	pi.on("tool_call", (event) => {
		if (rtkMissing || event.toolName !== "bash") return;

		const command = typeof event.input.command === "string" ? event.input.command : "";
		if (!command) return;

		const res = spawnSync("rtk", ["rewrite", command], { encoding: "utf8" });
		if (res.error) {
			rtkMissing = true;
			pi.logger?.warn?.(`rtk indisponivel no PATH, reescrita desligada: ${res.error.message}`);
			return;
		}
		if (res.status !== 0 && res.status !== 3) return;

		const rewritten = res.stdout.trim();
		if (!rewritten || rewritten === command) return;

		return { input: { ...event.input, command: rewritten } };
	});
}
