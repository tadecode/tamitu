import { describe, expect, it } from "vitest";
import {
  assertDataPolicy,
  assertRequestConfig,
  assertStartupConfig,
  LIMIT_BOUNDS,
  parseRuntimeConfig,
  parseStaticConfig,
  SAFE_RUNTIME_DEFAULTS,
  type RuntimeConfig,
  type StaticConfig,
} from "../src/config.js";
import { AppError } from "../src/errors.js";

const runtime = (over: Partial<RuntimeConfig> = {}): RuntimeConfig => ({ ...SAFE_RUNTIME_DEFAULTS, ...over });
const cfg = (over: Partial<StaticConfig> = {}): StaticConfig => ({
  environment: "prod",
  enforceAppCheck: true,
  allowRealData: false,
  ...over,
});

describe("parseStaticConfig is fail-closed", () => {
  it("defaults to prod, App Check on, real data off", () => {
    expect(parseStaticConfig({})).toEqual({ environment: "prod", enforceAppCheck: true, allowRealData: false });
  });
  it("garbage values do not relax anything", () => {
    const c = parseStaticConfig({ ENVIRONMENT: "DEV", ENFORCE_APP_CHECK: "0", ALLOW_REAL_DATA: "yes" });
    expect(c).toEqual({ environment: "prod", enforceAppCheck: true, allowRealData: false });
  });
  it("only exact values relax", () => {
    const c = parseStaticConfig({ ENVIRONMENT: "dev", ENFORCE_APP_CHECK: "false", ALLOW_REAL_DATA: "true" });
    expect(c).toEqual({ environment: "dev", enforceAppCheck: false, allowRealData: true });
  });
});

describe("startup rule (Aneks A pkt 3 i)", () => {
  it("refuses prod + App Check off + real data", () => {
    expect(() => assertStartupConfig(cfg({ enforceAppCheck: false, allowRealData: true }))).toThrow();
  });
  it("refuses dev + ALLOW_REAL_DATA=true (ADR-0011 pkt 5, SEC-24)", () => {
    expect(() => assertStartupConfig(cfg({ environment: "dev", allowRealData: true }))).toThrow("invalid_config_dev_real_data");
    expect(() => assertStartupConfig(cfg({ environment: "dev", enforceAppCheck: false, allowRealData: true }))).toThrow();
  });
  it.each([
    ["prod, App Check off, no real data", cfg({ enforceAppCheck: false })],
    ["prod, App Check on, real data", cfg({ allowRealData: true })],
    ["dev, no real data", cfg({ environment: "dev", enforceAppCheck: false })],
  ])("allows %s", (_n, c) => {
    expect(() => assertStartupConfig(c)).not.toThrow();
  });
});

describe("per-request rule (Aneks A pkt 3 ii)", () => {
  it("fails closed with test_data_only when runtime allowRealData conflicts with App Check off in prod", () => {
    try {
      assertRequestConfig(cfg({ enforceAppCheck: false }), runtime({ allowRealData: true }));
      expect.unreachable();
    } catch (e) {
      expect((e as AppError).appCode).toBe("test_data_only");
    }
  });
  it("passes for consistent configurations", () => {
    expect(() => assertRequestConfig(cfg({ enforceAppCheck: false }), runtime())).not.toThrow();
    expect(() => assertRequestConfig(cfg(), runtime({ allowRealData: true }))).not.toThrow();
    expect(() =>
      assertRequestConfig(cfg({ environment: "dev", enforceAppCheck: false }), runtime({ allowRealData: true })),
    ).not.toThrow();
  });
});

describe("data policy (S5)", () => {
  it("real data needs both parameter and runtime flag", () => {
    expect(() => assertDataPolicy(cfg({ allowRealData: true }), runtime({ allowRealData: true }), "u", undefined)).not.toThrow();
    expect(() => assertDataPolicy(cfg({ allowRealData: true }), runtime(), "u", undefined)).toThrow();
    expect(() => assertDataPolicy(cfg(), runtime({ allowRealData: true }), "u", undefined)).toThrow();
  });
  it("dev ignores runtime.allowRealData: only testData=true from testUids (SEC-24)", () => {
    const dev = cfg({ environment: "dev", allowRealData: true });
    const r = runtime({ allowRealData: true, testUids: ["owner"] });
    expect(() => assertDataPolicy(dev, r, "u", undefined)).toThrow();
    expect(() => assertDataPolicy(cfg({ environment: "dev" }), r, "u", undefined)).toThrow();
    expect(() => assertDataPolicy(dev, r, "owner", true)).not.toThrow();
  });
  it("test data only from listed test accounts", () => {
    const r = runtime({ testUids: ["owner"] });
    expect(() => assertDataPolicy(cfg(), r, "owner", true)).not.toThrow();
    expect(() => assertDataPolicy(cfg(), r, "owner", false)).toThrow();
    expect(() => assertDataPolicy(cfg(), r, "other", true)).toThrow();
  });
});

describe("safe runtime defaults (ADR-0014 Aneks A pkt 3)", () => {
  it("global daily limit defaults to 25 during the test phase", () => {
    expect(SAFE_RUNTIME_DEFAULTS.globalDailyLimit).toBe(25);
  });
  it("defaults stay fail-closed", () => {
    expect(SAFE_RUNTIME_DEFAULTS).toMatchObject({ aiEnabled: false, allowRealData: false, perUserDailyLimit: 5 });
  });
});

describe("parseRuntimeConfig (SEC-22)", () => {
  it("missing document -> safe defaults", () => {
    expect(parseRuntimeConfig(undefined)).toEqual(SAFE_RUNTIME_DEFAULTS);
  });

  it("parses a valid document", () => {
    const r = parseRuntimeConfig({
      aiEnabled: true,
      allowRealData: true,
      testUids: ["a", 1, null, "b"],
      perUserDailyLimit: 3,
      globalDailyLimit: 25,
      policyVersionCurrent: "privacy-v1",
      aiConsentVersionCurrent: "ai-consent-v1",
    });
    expect(r).toEqual({
      aiEnabled: true,
      allowRealData: true,
      testUids: ["a", "b"],
      perUserDailyLimit: 3,
      globalDailyLimit: 25,
      policyVersionCurrent: "privacy-v1",
      aiConsentVersionCurrent: "ai-consent-v1",
    });
  });

  it("flags are true only for boolean true; wrong types are dropped", () => {
    const r = parseRuntimeConfig({
      aiEnabled: "true",
      allowRealData: 1,
      testUids: "owner",
      policyVersionCurrent: 2,
      aiConsentVersionCurrent: null,
    });
    expect(r).toEqual({ ...SAFE_RUNTIME_DEFAULTS, policyVersionCurrent: undefined, aiConsentVersionCurrent: undefined });
  });

  it("accepts the range bounds", () => {
    const { perUserDailyLimit: u, globalDailyLimit: g } = LIMIT_BOUNDS;
    expect(parseRuntimeConfig({ perUserDailyLimit: u.min, globalDailyLimit: g.min })).toMatchObject({
      perUserDailyLimit: u.min,
      globalDailyLimit: g.min,
    });
    expect(parseRuntimeConfig({ perUserDailyLimit: u.max, globalDailyLimit: g.max })).toMatchObject({
      perUserDailyLimit: u.max,
      globalDailyLimit: g.max,
    });
  });

  it.each([
    ["zero", 0],
    ["negative", -5],
    ["above max (per user)", LIMIT_BOUNDS.perUserDailyLimit.max + 1],
    ["huge", 1e12],
    ["fraction", 2.5],
    ["NaN", Number.NaN],
    ["Infinity", Number.POSITIVE_INFINITY],
    ["string", "10"],
    ["null", null],
  ])("perUserDailyLimit %s -> default", (_n, v) => {
    expect(parseRuntimeConfig({ perUserDailyLimit: v }).perUserDailyLimit).toBe(SAFE_RUNTIME_DEFAULTS.perUserDailyLimit);
  });

  it.each([
    ["zero", 0],
    ["negative", -1],
    ["above max (global)", LIMIT_BOUNDS.globalDailyLimit.max + 1],
    ["huge", 1e12],
    ["fraction", 24.5],
    ["string", "25"],
  ])("globalDailyLimit %s -> default 25", (_n, v) => {
    expect(parseRuntimeConfig({ globalDailyLimit: v }).globalDailyLimit).toBe(25);
  });

  it("defaults lie within the bounds", () => {
    const { perUserDailyLimit: u, globalDailyLimit: g } = LIMIT_BOUNDS;
    expect(SAFE_RUNTIME_DEFAULTS.perUserDailyLimit).toBeGreaterThanOrEqual(u.min);
    expect(SAFE_RUNTIME_DEFAULTS.perUserDailyLimit).toBeLessThanOrEqual(u.max);
    expect(SAFE_RUNTIME_DEFAULTS.globalDailyLimit).toBeGreaterThanOrEqual(g.min);
    expect(SAFE_RUNTIME_DEFAULTS.globalDailyLimit).toBeLessThanOrEqual(g.max);
  });
});
