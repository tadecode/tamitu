// Pure quota logic (ADR-0002 "Limity i bezpieczniki"). No I/O.
const TZ = "Europe/Warsaw";

const dayFmt = new Intl.DateTimeFormat("en-CA", { timeZone: TZ, year: "numeric", month: "2-digit", day: "2-digit" });
const partsFmt = new Intl.DateTimeFormat("en-GB", {
  timeZone: TZ,
  hourCycle: "h23",
  year: "numeric",
  month: "2-digit",
  day: "2-digit",
  hour: "2-digit",
  minute: "2-digit",
  second: "2-digit",
});

/** Calendar day (YYYY-MM-DD) in Europe/Warsaw (Q5). */
export function warsawDay(now: Date): string {
  return dayFmt.format(now);
}

function offsetMs(t: number): number {
  const p = Object.fromEntries(partsFmt.formatToParts(new Date(t)).map((x) => [x.type, x.value]));
  const wall = Date.UTC(+p["year"]!, +p["month"]! - 1, +p["day"]!, +p["hour"]!, +p["minute"]!, +p["second"]!);
  return wall - Math.floor(t / 1000) * 1000;
}

/** Next midnight in Europe/Warsaw as a UTC instant (ISO, no millis). */
export function resetAt(now: Date): string {
  const [y, m, d] = warsawDay(now).split("-").map(Number) as [number, number, number];
  const wallMidnight = Date.UTC(y, m - 1, d + 1, 0, 0, 0);
  let t = wallMidnight - offsetMs(wallMidnight);
  t = wallMidnight - offsetMs(t);
  return new Date(t).toISOString().replace(".000Z", "Z");
}

export interface UsageDoc {
  day: string;
  count: number;
}

/** Counter of the current day; a document from an earlier day counts as 0. */
export function effectiveCount(usage: UsageDoc | undefined, today: string): number {
  return usage && usage.day === today ? Math.max(0, usage.count) : 0;
}

export type QuotaDecision =
  | { allowed: true; remainingAfter: number }
  | { allowed: false; appCode: "limit_exceeded" | "ai_unavailable" };

/** Global limit is checked first (cost kill-switch), then the per-user limit. */
export function decideQuota(input: {
  userCount: number;
  userLimit: number;
  globalCount: number;
  globalLimit: number;
}): QuotaDecision {
  if (input.globalCount >= input.globalLimit) return { allowed: false, appCode: "ai_unavailable" };
  if (input.userCount >= input.userLimit) return { allowed: false, appCode: "limit_exceeded" };
  return { allowed: true, remainingAfter: input.userLimit - input.userCount - 1 };
}

/** Budget kill-switch decision for budgetGuard (ADR-0003). */
export function shouldDisableAi(costAmount: number, budgetAmount: number): boolean {
  return Number.isFinite(costAmount) && Number.isFinite(budgetAmount) && budgetAmount > 0 && costAmount >= budgetAmount;
}
