import { describe, expect, it } from "vitest";
import { AppError } from "../src/errors.js";
import { checkArrivalDate, parseDeleteAccount, parseGeneratePlan, parseRecordConsent } from "../src/schemas.js";

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
    expect(at("2026-11-13")).not.toThrow(); // today - 2 tolerated (ADR-0011 pkt 3)
    expect(at("2026-11-12")).toThrow();
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

describe("free-text fields: NFC and Unicode Cc/Cf/Zl/Zp (SEC-21, T4)", () => {
  const withDest = (destination: string) => ({ ...valid(), trip: { ...valid().trip, destination } });

  it("normalises to NFC (decomposed input becomes composed)", () => {
    const decomposed = "Málaga Łódź".normalize("NFD");
    expect(decomposed).not.toBe("Málaga Łódź");
    expect(parseGeneratePlan(withDest(decomposed), NOW).trip.destination).toBe("Málaga Łódź");
  });

  it("measures length after NFC (80 composed chars fit although NFD is 160)", () => {
    const nfd = "ó".repeat(80).normalize("NFD");
    expect(nfd.length).toBe(160);
    expect(parseGeneratePlan(withDest(nfd), NOW).trip.destination).toHaveLength(80);
  });

  it("keeps ordinary letters, emoji and inner spaces", () => {
    for (const ok of ["Zakopane – Krupówki", "São Paulo", "Москва", "東京", "Rzym 🍕"]) {
      expect(parseGeneratePlan(withDest(ok), NOW).trip.destination).toBe(ok);
    }
  });

  it.each([
    ["NUL (Cc)", "a\u0000b"],
    ["DEL (Cc)", "a\u007fb"],
    ["C1 control NEL (Cc)", "a\u0085b"],
    ["tab (Cc)", "a\tb"],
    ["zero-width space (Cf)", "Lizbona​"],
    ["zero-width joiner (Cf)", "a‍b"],
    ["LRM (Cf)", "a‎b"],
    ["RLO bidi override (Cf)", "a‮b"],
    ["RLI bidi isolate (Cf)", "a⁧b"],
    ["BOM inside (Cf)", "a﻿b"],
    ["soft hyphen (Cf)", "a­b"],
    ["tag character (Cf)", "a\u{E0041}b"],
    ["line separator (Zl)", "a b"],
    ["paragraph separator (Zp)", "a b"],
  ])("rejects %s with field path only", (_n, bad) => {
    const e = errOf(() => parseGeneratePlan(withDest(bad), NOW));
    expect(e.appCode).toBe("invalid_argument");
    expect(e.details).toEqual({ field: "trip.destination" });
  });

  it("applies to lodging and airport too", () => {
    const lodging = { ...valid(), trip: { ...valid().trip, lodging: "Hotel‮" } };
    expect(errOf(() => parseGeneratePlan(lodging, NOW)).details["field"]).toBe("trip.lodging");
    const t = valid().trip;
    const airport = { ...valid(), trip: { ...t, arrival: { ...t.arrival, airport: "LIS⁦" } } };
    expect(errOf(() => parseGeneratePlan(airport, NOW)).details["field"]).toBe("trip.arrival.airport");
  });

  it("a value made only of format characters is rejected", () => {
    expect(() => parseGeneratePlan(withDest("​​"), NOW)).toThrow();
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
  it.each([
    "ai-consent-v2",
    "privacy-v1",
    "ai-consent-v01",
    "ai-consent-v0",
    "AI-consent-v1",
    "ai-consent-v10000",
    " ai-consent-v1",
    "ai-consent-v1​",
    "ai‐consent-v1",
    "",
  ])(
    "rejects unknown / malformed / foreign-prefix version %s (ADR-0012, SEC-21)",
    (v) => {
      expect(errOf(() => parseRecordConsent({ ...ok, policyVersion: v })).details["field"]).toBe("policyVersion");
    },
  );
  it("accepts known privacy version for privacy_policy", () => {
    expect(parseRecordConsent({ ...ok, type: "privacy_policy", policyVersion: "privacy-v1" }).type).toBe("privacy_policy");
  });
});

describe("deleteAccount request", () => {
  it("accepts any apiVersion >= 1 and never unsupported_version (ADR-0011 pkt 4)", () => {
    expect(() => parseDeleteAccount({ apiVersion: 1 })).not.toThrow();
    expect(() => parseDeleteAccount({ apiVersion: 2 })).not.toThrow();
    expect(() => parseDeleteAccount({ apiVersion: 99, future: true })).not.toThrow();
    expect(() => parseDeleteAccount({ apiVersion: 1, x: 1 })).toThrow();
    expect(() => parseDeleteAccount({})).toThrow();
    for (const v of [0, 1.5, "2"]) expect(errOf(() => parseDeleteAccount({ apiVersion: v })).appCode).toBe("invalid_argument");
  });
});

describe("arrival date window around midnight in Warsaw (review PR #51 #6)", () => {
  const ok = (date: string, now: string) => () => checkArrivalDate(date, new Date(now));

  it("winter (UTC+1): 23:30 UTC is already the next day in Warsaw", () => {
    // 2026-11-15T23:30Z = 16.11 00:30 in Warsaw -> minimum is 14.11
    expect(ok("2026-11-14", "2026-11-15T23:30:00Z")).not.toThrow();
    expect(ok("2026-11-13", "2026-11-15T23:30:00Z")).toThrow();
    // 22:59 UTC = 23:59 Warsaw on 15.11 -> minimum is 13.11
    expect(ok("2026-11-13", "2026-11-15T22:59:00Z")).not.toThrow();
  });

  it("summer (UTC+2): 22:00 UTC is already the next day in Warsaw", () => {
    // 2027-07-10T22:00Z = 11.07 00:00 in Warsaw -> minimum is 09.07
    expect(ok("2027-07-09", "2027-07-10T22:00:00Z")).not.toThrow();
    expect(ok("2027-07-08", "2027-07-10T22:00:00Z")).toThrow();
    // 21:59 UTC = 23:59 Warsaw on 10.07 -> minimum is 08.07
    expect(ok("2027-07-08", "2027-07-10T21:59:00Z")).not.toThrow();
  });

  it("DST change night (last Sunday of March 2027)", () => {
    // 2027-03-28T00:30Z = 01:30 CET, 28.03 in Warsaw -> minimum 26.03
    expect(ok("2027-03-26", "2027-03-28T00:30:00Z")).not.toThrow();
    expect(ok("2027-03-25", "2027-03-28T00:30:00Z")).toThrow();
  });
});
