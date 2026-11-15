import { describe, expect, it } from "vitest";
import { AppError } from "../src/errors.js";
import { parseDeleteAccount, parseGeneratePlan, parseRecordConsent } from "../src/schemas.js";

const NOW = new Date("2026-11-15T10:00:00Z");

const valid = () => ({
  apiVersion: 1,
  requestId: "7f0c2a9e-6f0e-4c3a-9a43-0b6c4a1f5d11",
  planLanguage: "pl",
  trip: {
    destination: "Lizbona",
    lodging: "Baixa, okolice Rossio",
    days: 4,
    arrival: { mode: "flight", date: "2027-03-12", time: "18:10", airport: "Lisbon Humberto Delgado (LIS)" },
  },
  preferences: { interests: ["monuments_history", "local_food"], budget: "medium", pace: "moderate", partySize: 2 },
  testData: false,
});

function errOf(fn: () => unknown): AppError {
  try {
    fn();
  } catch (e) {
    if (e instanceof AppError) return e;
    throw e;
  }
  throw new Error("expected AppError");
}

describe("generatePlan request", () => {
  it("accepts the documented example and applies defaults", () => {
    const r = parseGeneratePlan(valid(), NOW);
    expect(r.trip.days).toBe(4);
    const minimal = { ...valid(), preferences: {} };
    const d = parseGeneratePlan(minimal, NOW);
    expect(d.preferences).toEqual({ interests: [], budget: "medium", pace: "moderate", partySize: 2 });
  });

  it("rejects unknown fields (strict)", () => {
    const e = errOf(() => parseGeneratePlan({ ...valid(), email: "a@b.c" }, NOW));
    expect(e.appCode).toBe("invalid_argument");
  });

  it.each([
    ["trip.days", (r: ReturnType<typeof valid>) => (r.trip.days = 15)],
    ["trip.days", (r: ReturnType<typeof valid>) => (r.trip.days = 0)],
    ["trip.destination", (r: ReturnType<typeof valid>) => (r.trip.destination = "x".repeat(81))],
    ["trip.destination", (r: ReturnType<typeof valid>) => (r.trip.destination = "   ")],
    ["trip.lodging", (r: ReturnType<typeof valid>) => (r.trip.lodging = "a\u0000b")],
    ["trip.arrival.time", (r: ReturnType<typeof valid>) => (r.trip.arrival.time = "24:00")],
    ["trip.arrival.mode", (r: ReturnType<typeof valid>) => ((r.trip.arrival as { mode: string }).mode = "train")],
    ["preferences.interests.0", (r: ReturnType<typeof valid>) => (r.preferences.interests = ["skydiving"])],
    ["preferences.interests", (r: ReturnType<typeof valid>) => (r.preferences.interests = ["shopping", "shopping"])],
    ["preferences.interests", (r: ReturnType<typeof valid>) =>
      (r.preferences.interests = ["shopping", "nightlife", "relaxation", "architecture", "art_museums", "local_food"])],
    ["preferences.partySize", (r: ReturnType<typeof valid>) => (r.preferences.partySize = 11)],
    ["requestId", (r: ReturnType<typeof valid>) => (r.requestId = "not-a-uuid")],
    ["planLanguage", (r: ReturnType<typeof valid>) => ((r as { planLanguage: string }).planLanguage = "de")],
  ])("rejects invalid %s", (field, mutate) => {
    const r = valid();
    mutate(r);
    const e = errOf(() => parseGeneratePlan(r, NOW));
    expect(e.appCode).toBe("invalid_argument");
    expect(String(e.details["field"]).startsWith(field)).toBe(true);
  });

  it("requires airport for flight and forbids it for car", () => {
    const f = valid();
    delete (f.trip.arrival as { airport?: string }).airport;
    expect(errOf(() => parseGeneratePlan(f, NOW)).details["field"]).toBe("trip.arrival.airport");
    const c = valid();
    (c.trip.arrival as { mode: string }).mode = "car";
    expect(errOf(() => parseGeneratePlan(c, NOW)).details["field"]).toBe("trip.arrival.airport");
    delete (c.trip.arrival as { airport?: string }).airport;
    expect(parseGeneratePlan(c, NOW).trip.arrival.mode).toBe("car");
  });

  it("reports unsupported_version with minVersion", () => {
    const e = errOf(() => parseGeneratePlan({ ...valid(), apiVersion: 2 }, NOW));
    expect(e.appCode).toBe("unsupported_version");
    expect(e.details["minVersion"]).toBe(1);
  });

  it("rejects requests over 4 KB", () => {
    const r = valid();
    r.trip.destination = "x".repeat(80);
    const big = { ...r, pad: "y".repeat(5000) };
    expect(errOf(() => parseGeneratePlan(big, NOW)).details["field"]).toBe("request");
  });

  it("checks the arrival date window and real calendar dates", () => {
    const at = (date: string) => () => {
      const r = valid();
      r.trip.arrival.date = date;
      return parseGeneratePlan(r, NOW);
    };
    expect(at("2026-11-14")).not.toThrow(); // today - 1 tolerated
    expect(at("2026-11-13")).toThrow();
    expect(at("2028-11-15")).not.toThrow(); // within 2 years
    expect(at("2028-12-30")).toThrow();
    expect(at("2027-02-30")).toThrow();
  });

  it("never puts input values in error details", () => {
    const CANARY = "CANARY-7Q9X";
    const r = valid();
    r.preferences.interests = [CANARY];
    const e = errOf(() => parseGeneratePlan({ ...r, [CANARY]: CANARY }, NOW));
    expect(JSON.stringify(e.details)).not.toContain(CANARY);
    expect(e.message).not.toContain(CANARY);
  });
});

describe("recordConsent request", () => {
  const ok = {
    apiVersion: 1,
    consentId: "0d8f1c1e-33b8-4a3e-bf4a-0a3d8c1f9e22",
    type: "ai_processing",
    granted: true,
    policyVersion: "ai-consent-v1",
    lang: "pl",
    clientAt: "2026-11-15T10:12:03Z",
  };
  it("accepts a valid request and rejects bad ones", () => {
    expect(parseRecordConsent(ok).granted).toBe(true);
    expect(() => parseRecordConsent({ ...ok, type: "marketing" })).toThrow();
    expect(() => parseRecordConsent({ ...ok, policyVersion: "v".repeat(41) })).toThrow();
    expect(() => parseRecordConsent({ ...ok, clientAt: "yesterday" })).toThrow();
    expect(() => parseRecordConsent({ ...ok, extra: 1 })).toThrow();
  });
});

describe("deleteAccount request", () => {
  it("accepts only {apiVersion: 1}", () => {
    expect(() => parseDeleteAccount({ apiVersion: 1 })).not.toThrow();
    expect(() => parseDeleteAccount({ apiVersion: 1, x: 1 })).toThrow();
    expect(() => parseDeleteAccount({})).toThrow();
  });
});
