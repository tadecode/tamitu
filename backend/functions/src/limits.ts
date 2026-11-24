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
  /** Slots returned to this account on `day` (review PR #136 #2); missing = 0. */
  released?: number | undefined;
  /** ai_busy releases of this account on `day` (ADR-0016 pkt 8); missing = 0. */
  busyReleased?: number | undefined;
}

/**
 * Review PR #136 #2: at most this many slot releases per account and day. Further system errors
 * keep the slot used, so one account cannot drain the global cost fuse (usage_global is never
 * decremented) with requests that always fail while its own limit stays untouched.
 * Worst case per account and day: perUserDailyLimit + MAX_RELEASES_PER_DAY generations.
 */
export const MAX_RELEASES_PER_DAY = 2;

/** Releases already made today; a document from an earlier day counts as 0. */
export function effectiveReleased(usage: UsageDoc | undefined, today: string): number {
  const r = usage && usage.day === today ? usage.released ?? 0 : 0;
  return Number.isInteger(r) && r > 0 ? r : 0;
}

/**
 * ADR-0016 pkt 8: abuse fuse for ai_busy. At most this many ai_busy releases (account AND global slot) per
 * account and day; they do not count towards MAX_RELEASES_PER_DAY. From the 11th ai_busy of the day both
 * slots stay used (`slotReleased=false`).
 */
export const MAX_BUSY_RELEASES_PER_DAY = 10;

/** ai_busy releases already made today; a document from an earlier day counts as 0. */
export function effectiveBusyReleased(usage: UsageDoc | undefined, today: string): number {
  const r = usage && usage.day === today ? usage.busyReleased ?? 0 : 0;
  return Number.isInteger(r) && r > 0 ? r : 0;
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

/** Retention of usage/{uid} after the end of the quota day (O4-b, firestore-ttl-indexes.md pkt 2.1). */
export const USAGE_RETENTION_AFTER_RESET_MS = 2 * 86_400_000;
/** Retention of usage_global/{day} after its last write. */
export const GLOBAL_RETENTION_MS = 7 * 86_400_000;

/** TTL field of usage/{uid}: max(resetAt(now) + 2 d, now + 2 d). */
export function usageExpireAt(now: Date): Date {
  const fromReset = new Date(resetAt(now)).getTime() + USAGE_RETENTION_AFTER_RESET_MS;
  return new Date(Math.max(fromReset, now.getTime() + USAGE_RETENTION_AFTER_RESET_MS));
}

/** TTL field of usage_global/{day}: now + 7 d. */
export function globalExpireAt(now: Date): Date {
  return new Date(now.getTime() + GLOBAL_RETENTION_MS);
}

/** Quota block of the generatePlan response (posrednik-api.md pkt 2). */
export interface QuotaInfo {
  limit: number;
  remainingToday: number;
  resetAt: string;
}

/** Result of a successful reservation; `day` is needed to release the slot later. */
export interface Reservation {
  day: string;
  quota: QuotaInfo;
}

/** Writes computed by planReservation (applied in one Firestore transaction in index.ts). */
export interface ReservationWrites {
  usage: UsageWrite;
  global: { count: number; expireAt: Date };
}

/** Full shape of usage/{uid} written by reservation and release. */
export interface UsageWrite {
  day: string;
  count: number;
  released: number;
  busyReleased: number;
  updatedAt: Date;
  expireAt: Date;
}

export type ReservationPlan =
  | { allowed: true; reservation: Reservation; writes: ReservationWrites }
  | { allowed: false; appCode: "limit_exceeded" | "ai_unavailable"; quota: QuotaInfo };

/**
 * Pure part of the reservation transaction (firestore-ttl-indexes.md pkt 3.2, rules 1-2):
 * the caller reads usage/{uid} and usage_global/{today} inside a transaction, passes them here
 * and writes `writes` when allowed. Global limit first (cost kill-switch), then per user.
 */
export function planReservation(input: {
  usage: UsageDoc | undefined;
  globalCount: number | undefined;
  userLimit: number;
  globalLimit: number;
  now: Date;
}): ReservationPlan {
  const day = warsawDay(input.now);
  const reset = resetAt(input.now);
  const userCount = effectiveCount(input.usage, day);
  const globalCount = Math.max(0, input.globalCount ?? 0);
  const d = decideQuota({ userCount, userLimit: input.userLimit, globalCount, globalLimit: input.globalLimit });
  if (!d.allowed) {
    const remaining = Math.max(0, input.userLimit - userCount);
    return { allowed: false, appCode: d.appCode, quota: { limit: input.userLimit, remainingToday: remaining, resetAt: reset } };
  }
  return {
    allowed: true,
    reservation: { day, quota: { limit: input.userLimit, remainingToday: d.remainingAfter, resetAt: reset } },
    writes: {
      usage: {
        day,
        count: userCount + 1,
        released: effectiveReleased(input.usage, day),
        busyReleased: effectiveBusyReleased(input.usage, day),
        updatedAt: input.now,
        expireAt: usageExpireAt(input.now),
      },
      global: { count: globalCount + 1, expireAt: globalExpireAt(input.now) },
    },
  };
}

/**
 * Result of a slot release attempt (TAM-94): `released` = count decremented; `capped` = the account
 * already used its MAX_RELEASES_PER_DAY releases today; `stale_day` = no reservation of that day is
 * stored any more (day changed at midnight, or no/zero counter). Only `released` means the attempt
 * did not count towards the account limit.
 */
export type ReleaseOutcome = "released" | "capped" | "stale_day";

export type ReleasePlan = { outcome: "released"; write: UsageWrite } | { outcome: "capped" | "stale_day" };

/**
 * Pure part of the slot release (rule 3): decrement only when the stored day is still the
 * reservation day and the account has releases left today (MAX_RELEASES_PER_DAY); otherwise no
 * write and the slot stays used. usage_global is NOT decremented: it is the cost fuse
 * and the model calls were made (and billed) anyway - the cost-safer variant (review PR #136 #2).
 */
export function planReleaseOutcome(usage: UsageDoc | undefined, reservationDay: string, now: Date): ReleasePlan {
  if (!usage || usage.day !== reservationDay || usage.count <= 0) return { outcome: "stale_day" };
  const released = effectiveReleased(usage, reservationDay);
  if (released >= MAX_RELEASES_PER_DAY) return { outcome: "capped" };
  return {
    outcome: "released",
    write: {
      day: usage.day,
      count: usage.count - 1,
      released: released + 1,
      busyReleased: effectiveBusyReleased(usage, reservationDay),
      updatedAt: now,
      expireAt: usageExpireAt(now),
    },
  };
}

/** Result of an ai_busy release (ADR-0016 pkt 8); `stale_day` as in planReleaseOutcome (rule 5). */
export type BusyReleaseOutcome = "busy_released" | "busy_capped" | "stale_day";

export type BusyReleasePlan =
  | { outcome: "busy_released"; write: UsageWrite; global: { count: number; expireAt: Date } }
  | { outcome: "busy_capped" | "stale_day" };

/**
 * Pure part of the ai_busy release (posrednik-api.md pkt 2 rule 7): no model call was billed, so the
 * account slot AND the global slot of the reservation day go back, without touching `released` (the
 * 2-per-day limit of rule 2). Fuse: MAX_BUSY_RELEASES_PER_DAY per account and day, then both slots stay
 * used. Rule 5 unchanged: after midnight (stored day != reservation day) nothing is written.
 */
export function planBusyReleaseOutcome(
  usage: UsageDoc | undefined,
  globalCount: number | undefined,
  reservationDay: string,
  now: Date,
): BusyReleasePlan {
  if (!usage || usage.day !== reservationDay || usage.count <= 0) return { outcome: "stale_day" };
  const busy = effectiveBusyReleased(usage, reservationDay);
  if (busy >= MAX_BUSY_RELEASES_PER_DAY) return { outcome: "busy_capped" };
  return {
    outcome: "busy_released",
    write: {
      day: usage.day,
      count: usage.count - 1,
      released: effectiveReleased(usage, reservationDay),
      busyReleased: busy + 1,
      updatedAt: now,
      expireAt: usageExpireAt(now),
    },
    global: { count: Math.max(0, (globalCount ?? 0) - 1), expireAt: globalExpireAt(now) },
  };
}

/** The write of planReleaseOutcome, or undefined when nothing is written (slot stays used). */
export function planRelease(usage: UsageDoc | undefined, reservationDay: string, now: Date): UsageWrite | undefined {
  const r = planReleaseOutcome(usage, reservationDay, now);
  return r.outcome === "released" ? r.write : undefined;
}

/**
 * usage/{uid} as stored -> UsageDoc. Malformed `day`/`count` = "no document" (counter 0 for today);
 * a malformed `released` counts as 0 releases. Pure so the mapping is unit-tested (review PR #136 #10).
 */
export function usageFromDoc(data: unknown): UsageDoc | undefined {
  const d = data as { day?: unknown; count?: unknown; released?: unknown; busyReleased?: unknown } | null | undefined;
  if (typeof d?.day !== "string" || !Number.isInteger(d.count)) return undefined;
  const released = Number.isInteger(d.released) ? (d.released as number) : 0;
  const busyReleased = Number.isInteger(d.busyReleased) ? (d.busyReleased as number) : 0;
  return { day: d.day, count: d.count as number, released, busyReleased };
}
