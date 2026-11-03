interface UsageAmount {
  used?: number;
  limit?: number;
  unit?: string;
}

interface UsageReport {
  provider: string;
  limits: { amount?: UsageAmount }[];
}

interface UsageCtx {
  hasUI: boolean;
  model?: { provider: string };
  modelRegistry: {
    // API interna do omp (não está em extensions.md): pode mudar ao atualizar.
    authStorage?: {
      usage?: {
        reports?(opts: {
          provider?: string;
          baseUrlResolver?: (provider: string) => string | undefined;
        }): Promise<UsageReport[] | null>;
      };
    };
    getProviderBaseUrl?(provider: string): string | undefined;
  };
  ui: { setStatus(key: string, text: string | undefined): void };
  setInterval(fn: () => unknown, ms: number): unknown;
  clearTimer(handle: unknown): void;
}

interface Pi {
  setLabel(label: string): void;
  on(event: string, handler: (event: unknown, ctx: UsageCtx) => unknown): void;
}

const KEY = "usage-extra";
const INTERVAL_MS = 5 * 60_000;

function format(amount: UsageAmount | undefined): string | undefined {
  if (amount?.unit !== "usd") return undefined;
  const { used, limit } = amount;
  if (typeof used !== "number" || typeof limit !== "number" || limit <= 0) return undefined;
  return `extra $${used.toFixed(2)}/$${limit.toFixed(0)} ${((used / limit) * 100).toFixed(1)}%`;
}

export default function (pi: Pi) {
  pi.setLabel("Uso extra em USD");
  let timer: { handle: unknown; ctx: UsageCtx } | undefined;

  async function refresh(ctx: UsageCtx): Promise<void> {
    if (!ctx.hasUI) return;
    const provider = ctx.model?.provider;
    if (!provider) {
      ctx.ui.setStatus(KEY, undefined);
      return;
    }
    const reports = ctx.modelRegistry.authStorage?.usage?.reports;
    if (typeof reports !== "function") {
      throw new Error("usage-extra: modelRegistry.authStorage.usage.reports não existe mais nesta versão do omp");
    }
    const list = await reports.call(ctx.modelRegistry.authStorage!.usage, {
      provider,
      baseUrlResolver: (p) => ctx.modelRegistry.getProviderBaseUrl?.(p),
    });
    const text = list?.flatMap((r) => r.limits.map((l) => format(l.amount))).find((t) => t !== undefined);
    ctx.ui.setStatus(KEY, text);
  }

  pi.on("session_start", async (_event, ctx) => {
    if (timer) timer.ctx.clearTimer(timer.handle);
    timer = { handle: ctx.setInterval(() => refresh(ctx), INTERVAL_MS), ctx };
    await refresh(ctx);
  });

  pi.on("agent_end", async (_event, ctx) => {
    await refresh(ctx);
  });
}
