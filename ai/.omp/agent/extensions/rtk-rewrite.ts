import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";
import { spawnSync } from "node:child_process";

// rtk rewrite: exit 0 or 3 prints the rewritten command; 1 and 2 mean run it unchanged.
export default function (pi: ExtensionAPI) {
  pi.setLabel("rtk rewrite");

  pi.on("tool_call", async (event) => {
    if (event.toolName !== "bash") return;
    const command = event.input.command;
    if (typeof command !== "string" || command.trim() === "") return;

    const result = spawnSync("rtk", ["rewrite", command], { encoding: "utf8", timeout: 2000 });
    if (result.error || (result.status !== 0 && result.status !== 3)) return;

    const rewritten = result.stdout.trim();
    if (rewritten === "" || rewritten === command) return;
    return { input: { ...event.input, command: rewritten } };
  });
}
