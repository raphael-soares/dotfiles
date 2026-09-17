/**
 * Contorna o falso 429 do provider google-antigravity.
 *
 * Desde 2026-09-11 o backend (daily-cloudcode-pa.googleapis.com) devolve
 * 429 RESOURCE_EXHAUSTED para envelopes com `requestType: "agent"` vindos de
 * clientes de terceiros, mesmo com quota disponivel. Sem o campo a request
 * cai na quota interativa normal e passa. O cliente oficial (agy) nao manda
 * esse campo. Referencia: can1357/oh-my-pi#11689; fix oficial recusado pelo
 * mantenedor em #11809, por isso o ajuste mora aqui e nao no omp.
 *
 * O omp roda TS nativo e auto-carrega todo .ts de ~/.omp/agent/extensions/.
 * Este arquivo mora nos dotfiles e chega la via symlink (stow).
 */

interface AntigravityEnvelope {
  project?: unknown;
  requestType?: string;
}

interface BeforeProviderRequestEvent {
  type: string;
  payload?: AntigravityEnvelope;
}

interface Pi {
  on(
    event: "before_provider_request",
    handler: (event: BeforeProviderRequestEvent) => AntigravityEnvelope | undefined,
  ): void;
  setLabel?(label: string): void;
}

export default function (pi: Pi) {
  pi.setLabel?.("antigravity-429-fix");
  pi.on("before_provider_request", (event) => {
    const payload = event?.payload;
    if (!payload || payload.requestType !== "agent" || typeof payload.project !== "string") {
      return undefined; // nao e envelope antigravity: nao toca
    }
    delete payload.requestType;
    return payload;
  });
}
