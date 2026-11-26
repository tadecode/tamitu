// P3-05: TTL formula (firestore-ttl-indexes.md pkt 2.1 and 7) and the pure reservation/release logic.
import { describe, expect, it } from "vitest";
import {
  globalExpireAt,
  MAX_BUSY_RELEASES_PER_DAY,
  MAX_RELEASES_PER_DAY,
  planBusyReleaseOutcome,
  planRelease,
  planReleaseOutcome,
  planReservation,
  resetAt,
  usageExpireAt,
  usageFromDoc,
  isQuotaContention,
  QUOTA_TX_MAX_ATTEMPTS,
  runQuotaTransaction,
  type QuotaTxRunner,
} from "../src/limits.js";
import { AppError } from "../src/errors.js";

const H = 3_600_000;

describe("usageExpireAt (O4-b)", () => {
  const cases: Array<[string, number]> = [
    ["2026-11-18T22:59:59Z", 48 * H + 1000], // 23:59:59 Warsaw, ordinary day
    ["2026-11-18T23:00:00Z", 72 * H], // 00:00:00 Warsaw
    ["2026-03-28T23:00:00Z", 71 * H], // start of the 23 h day (spring change)
    ["2026-03-29T21:59:59Z", 48 * H + 1000], // end of the 23 h day
    ["2026-10-24T22:00:00Z", 73 * H], // start of the 25 h day (autumn change)
    ["2026-10-25T22:59:59Z", 48 * H + 1000], // end of the 25 h day
  ];
  it.each(cases)("at %s: expireAt - resetAt = 2 d, expireAt - now as expected", (iso, delta) => {
    const now = new Date(iso);
    const exp = usageExpireAt(now).getTime();
    const reset = new Date(resetAt(now)).getTime();
    expect(exp).toBeGreaterThan(reset);
    expect(exp - reset).toBe(48 * H);
    expect(exp - now.getTime()).toBe(delta);
    expect(exp - now.getTime()).toBeGreaterThan(48 * H);
    expect(exp - now.getTime()).toBeLessThanOrEqual(73 * H);
  });
  it("global counter expires 7 d after the write", () => {
    const now = new Date("2026-11-21T10:00:00Z");
    expect(globalExpireAt(now).getTime() - now.getTime()).toBe(7 * 24 * H);
  });
});

describe("planReservation / planRelease (pkt 3.2)", () => {
  const now = new Date("2026-11-21T10:00:00Z");
  const limits = { userLimit: 5, globalLimit: 25 };

  it("first reservation of the day writes the full shape", () => {
    expect(planReservation({ usage: undefined, globalCount: undefined, ...limits, now })).toEqual({
      allowed: true,
      reservation: { day: "2026-11-21", quota: { limit: 5, remainingToday: 4, resetAt: "2026-11-21T23:00:00Z" } },
      writes: {
        usage: { day: "2026-11-21", count: 1, released: 0, busyReleased: 0, updatedAt: now, expireAt: usageExpireAt(now) },
        global: { count: 1, expireAt: globalExpireAt(now) },
      },
    });
  });
  it("a document from yesterday counts as 0", () => {
    const r = planReservation({ usage: { day: "2026-11-20", count: 5 }, globalCount: 3, ...limits, now });
    expect(r.allowed && r.writes.usage.count).toBe(1);
    expect(r.allowed && r.writes.global.count).toBe(4);
  });
  it("keeps today's release counter and resets it on a new day", () => {
    const today = planReservation({ usage: { day: "2026-11-21", count: 1, released: 2 }, globalCount: 0, ...limits, now });
    expect(today.allowed && today.writes.usage.released).toBe(2);
    const fresh = planReservation({ usage: { day: "2026-11-20", count: 3, released: 2 }, globalCount: 0, ...limits, now });
    expect(fresh.allowed && fresh.writes.usage.released).toBe(0);
  });
  it("per-user limit -> limit_exceeded with quota; global first -> ai_unavailable", () => {
    expect(planReservation({ usage: { day: "2026-11-21", count: 5 }, globalCount: 0, ...limits, now })).toEqual({
      allowed: false,
      appCode: "limit_exceeded",
      quota: { limit: 5, remainingToday: 0, resetAt: "2026-11-21T23:00:00Z" },
    });
    expect(planReservation({ usage: { day: "2026-11-21", count: 5 }, globalCount: 25, ...limits, now })).toMatchObject({
      allowed: false,
      appCode: "ai_unavailable",
    });
  });
  it("release decrements only on the reservation day and refreshes expireAt", () => {
    const later = new Date("2026-11-21T10:01:00Z");
    expect(planRelease({ day: "2026-11-21", count: 2 }, "2026-11-21", later)).toEqual({
      day: "2026-11-21",
      count: 1,
      released: 1,
      busyReleased: 0,
      updatedAt: later,
      expireAt: usageExpireAt(later),
    });
    expect(planRelease({ day: "2026-11-22", count: 1 }, "2026-11-21", later)).toBeUndefined();
    expect(planRelease({ day: "2026-11-21", count: 0 }, "2026-11-21", later)).toBeUndefined();
    expect(planRelease(undefined, "2026-11-21", later)).toBeUndefined();
  });
  it(`review #2: at most ${MAX_RELEASES_PER_DAY} releases per day, then the slot stays used`, () => {
    const later = new Date("2026-11-21T10:01:00Z");
    expect(MAX_RELEASES_PER_DAY).toBe(2);
    expect(planRelease({ day: "2026-11-21", count: 3, released: 1 }, "2026-11-21", later)?.released).toBe(2);
    expect(planRelease({ day: "2026-11-21", count: 3, released: 2 }, "2026-11-21", later)).toBeUndefined();
  });
  it("TAM-94: planReleaseOutcome names why a slot stays used (released / capped / stale_day)", () => {
    const later = new Date("2026-11-21T10:01:00Z");
    expect(planReleaseOutcome({ day: "2026-11-21", count: 2 }, "2026-11-21", later).outcome).toBe("released");
    expect(planReleaseOutcome({ day: "2026-11-21", count: 3, released: 2 }, "2026-11-21", later)).toEqual({ outcome: "capped" });
    expect(planReleaseOutcome({ day: "2026-11-22", count: 1 }, "2026-11-21", later)).toEqual({ outcome: "stale_day" });
    expect(planReleaseOutcome(undefined, "2026-11-21", later)).toEqual({ outcome: "stale_day" });
  });
});

describe("planBusyReleaseOutcome (ADR-0016 pkt 8, posrednik-api.md pkt 2 rule 7)", () => {
  const later = new Date("2026-11-21T10:01:00Z");
  it("returns the account AND the global slot without touching released", () => {
    expect(planBusyReleaseOutcome({ day: "2026-11-21", count: 2, released: 2, busyReleased: 3 }, 7, "2026-11-21", later)).toEqual({
      outcome: "busy_released",
      write: { day: "2026-11-21", count: 1, released: 2, busyReleased: 4, updatedAt: later, expireAt: usageExpireAt(later) },
      global: { count: 6, expireAt: globalExpireAt(later) },
    });
  });
  it(`fuse: at most ${MAX_BUSY_RELEASES_PER_DAY} per account and day, then both slots stay used`, () => {
    expect(MAX_BUSY_RELEASES_PER_DAY).toBe(10);
    const ninth = planBusyReleaseOutcome({ day: "2026-11-21", count: 1, busyReleased: 9 }, 1, "2026-11-21", later);
    expect(ninth.outcome === "busy_released" && ninth.write.busyReleased).toBe(10);
    expect(planBusyReleaseOutcome({ day: "2026-11-21", count: 1, busyReleased: 10 }, 1, "2026-11-21", later)).toEqual({ outcome: "busy_capped" });
  });
  it("rule 5: after midnight nothing is written (stale_day); a missing global counter never goes below 0", () => {
    expect(planBusyReleaseOutcome({ day: "2026-11-22", count: 1 }, 1, "2026-11-21", later)).toEqual({ outcome: "stale_day" });
    expect(planBusyReleaseOutcome(undefined, 1, "2026-11-21", later)).toEqual({ outcome: "stale_day" });
    expect(planBusyReleaseOutcome({ day: "2026-11-21", count: 0 }, 1, "2026-11-21", later)).toEqual({ outcome: "stale_day" });
    const r = planBusyReleaseOutcome({ day: "2026-11-21", count: 1 }, undefined, "2026-11-21", later);
    expect(r.outcome === "busy_released" && r.global.count).toBe(0);
  });
  it("busyReleased of yesterday counts as 0; reservation and ordinary release keep today's value", () => {
    const now = new Date("2026-11-21T10:00:00Z");
    const fresh = planReservation({ usage: { day: "2026-11-20", count: 1, busyReleased: 10 }, globalCount: 0, userLimit: 5, globalLimit: 25, now });
    expect(fresh.allowed && fresh.writes.usage.busyReleased).toBe(0);
    const today = planReservation({ usage: { day: "2026-11-21", count: 1, busyReleased: 4 }, globalCount: 0, userLimit: 5, globalLimit: 25, now });
    expect(today.allowed && today.writes.usage.busyReleased).toBe(4);
    expect(planRelease({ day: "2026-11-21", count: 2, busyReleased: 4 }, "2026-11-21", later)?.busyReleased).toBe(4);
  });
});

describe("usageFromDoc (stored usage/{uid})", () => {
  it("maps a valid document and treats malformed ones as missing", () => {
    expect(usageFromDoc({ day: "2026-11-21", count: 2, released: 1, expireAt: {} })).toEqual({ day: "2026-11-21", count: 2, released: 1, busyReleased: 0 });
    expect(usageFromDoc({ day: "2026-11-21", count: 2 })).toEqual({ day: "2026-11-21", count: 2, released: 0, busyReleased: 0 });
    expect(usageFromDoc({ day: "2026-11-21", count: 2, released: "x" })?.released).toBe(0);
    expect(usageFromDoc({ day: "2026-11-21", count: 2, busyReleased: 3 })?.busyReleased).toBe(3);
    expect(usageFromDoc({ day: "2026-11-21", count: 2, busyReleased: "x" })?.busyReleased).toBe(0);
    expect(usageFromDoc({ day: 1, count: 2 })).toBeUndefined();
    expect(usageFromDoc({ day: "2026-11-21", count: 1.5 })).toBeUndefined();
    expect(usageFromDoc(undefined)).toBeUndefined();
    expect(usageFromDoc(null)).toBeUndefined();
  });
});

describe("quota transaction contention (ADR-0018 pkt 1-6)", () => {
  it("isQuotaContention: only numeric code 10 (gRPC ABORTED) or 409", () => {
    expect(isQuotaContention({ code: 10 })).toBe(true);
    expect(isQuotaContention(Object.assign(new Error("x"), { code: 10 }))).toBe(true);
    expect(isQuotaContention({ code: 409 })).toBe(true);
    for (const e of [{ code: 14 }, { code: 4 }, { code: 13 }, { code: 8 }, { code: "aborted" }, { code: "10" }, undefined, null, 10, new Error("x"), new AppError("ai_busy")]) {
      expect(isQuotaContention(e)).toBe(false);
    }
  });

  /** Mimics Transaction.runTransaction of the SDK: reruns fn after ABORTED up to options.maxAttempts. */
  function sdkLike(abortedRuns: number) {
    const seen: Array<{ maxAttempts: number }> = [];
    let runs = 0;
    const runner: QuotaTxRunner<string> = {
      async runTransaction<T>(fn: (tx: string) => Promise<T>, options: { maxAttempts: number }): Promise<T> {
        seen.push(options);
        let last: unknown;
        for (let i = 0; i < options.maxAttempts; i++) {
          runs++;
          const result = await fn("tx");
          if (runs <= abortedRuns) {
            last = Object.assign(new Error("ABORTED"), { code: 10 });
            continue;
          }
          return result;
        }
        throw last;
      },
    };
    return { runner, seen, runs: () => runs };
  }

  it(`passes maxAttempts = QUOTA_TX_MAX_ATTEMPTS (${QUOTA_TX_MAX_ATTEMPTS})`, async () => {
    expect(QUOTA_TX_MAX_ATTEMPTS).toBe(3);
    const sdk = sdkLike(0);
    let tries = 0;
    expect(await runQuotaTransaction(sdk.runner, async () => "ok", () => tries++)).toBe("ok");
    expect(sdk.seen).toEqual([{ maxAttempts: 3 }]);
    expect(tries).toBe(1);
  });
  it.each([1, 2])("succeeds after %i aborted run(s); onTry counts every run", async (aborted) => {
    const sdk = sdkLike(aborted);
    let tries = 0;
    expect(await runQuotaTransaction(sdk.runner, async () => "ok", () => tries++)).toBe("ok");
    expect(tries).toBe(aborted + 1);
  });
  it("exhausted: never more than 3 runs, rejects with a contention error", async () => {
    const sdk = sdkLike(99);
    let tries = 0;
    const e = await runQuotaTransaction(sdk.runner, async () => "ok", () => tries++).catch((x: unknown) => x);
    expect(isQuotaContention(e)).toBe(true);
    expect(tries).toBe(3);
    expect(sdk.runs()).toBe(3);
  });
});
