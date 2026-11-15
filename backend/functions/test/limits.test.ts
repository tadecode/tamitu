import { describe, expect, it } from "vitest";
import { decideQuota, effectiveCount, resetAt, shouldDisableAi, warsawDay } from "../src/limits.js";

describe("Europe/Warsaw day", () => {
  it("uses the local calendar day", () => {
    expect(warsawDay(new Date("2026-11-15T22:59:00Z"))).toBe("2026-11-15");
    expect(warsawDay(new Date("2026-11-15T23:00:00Z"))).toBe("2026-11-16");
    expect(warsawDay(new Date("2026-07-01T21:59:00Z"))).toBe("2026-07-01");
    expect(warsawDay(new Date("2026-07-01T22:00:00Z"))).toBe("2026-07-02");
  });

  it("computes resetAt as next Warsaw midnight in UTC (winter, summer, DST changes)", () => {
    expect(resetAt(new Date("2026-11-15T12:00:00Z"))).toBe("2026-11-15T23:00:00Z");
    expect(resetAt(new Date("2026-07-01T10:00:00Z"))).toBe("2026-07-01T22:00:00Z");
    expect(resetAt(new Date("2027-03-27T12:00:00Z"))).toBe("2027-03-27T23:00:00Z"); // day before spring change
    expect(resetAt(new Date("2027-03-28T12:00:00Z"))).toBe("2027-03-28T22:00:00Z"); // change day, midnight is CEST
    expect(resetAt(new Date("2026-10-25T12:00:00Z"))).toBe("2026-10-25T23:00:00Z"); // autumn change day
  });
});

describe("effectiveCount", () => {
  it("resets on a new day", () => {
    expect(effectiveCount(undefined, "2026-11-15")).toBe(0);
    expect(effectiveCount({ day: "2026-11-14", count: 5 }, "2026-11-15")).toBe(0);
    expect(effectiveCount({ day: "2026-11-15", count: 3 }, "2026-11-15")).toBe(3);
  });
});

describe("decideQuota", () => {
  const base = { userLimit: 5, globalLimit: 50 };
  it("allows and reports remaining slots", () => {
    expect(decideQuota({ ...base, userCount: 0, globalCount: 0 })).toEqual({ allowed: true, remainingAfter: 4 });
    expect(decideQuota({ ...base, userCount: 4, globalCount: 49 })).toEqual({ allowed: true, remainingAfter: 0 });
  });
  it("rejects at the per-user limit", () => {
    expect(decideQuota({ ...base, userCount: 5, globalCount: 0 })).toEqual({ allowed: false, appCode: "limit_exceeded" });
  });
  it("rejects at the global limit with ai_unavailable, taking precedence", () => {
    expect(decideQuota({ ...base, userCount: 5, globalCount: 50 })).toEqual({ allowed: false, appCode: "ai_unavailable" });
  });
});

describe("shouldDisableAi", () => {
  it("triggers at cost >= budget only", () => {
    expect(shouldDisableAi(99.9, 100)).toBe(false);
    expect(shouldDisableAi(100, 100)).toBe(true);
    expect(shouldDisableAi(150, 100)).toBe(true);
    expect(shouldDisableAi(10, 0)).toBe(false);
    expect(shouldDisableAi(Number.NaN, 100)).toBe(false);
  });
});
