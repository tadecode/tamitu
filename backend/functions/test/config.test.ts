import { describe, expect, it } from "vitest";
import {
  assertDataPolicy,
  assertRequestConfig,
  assertStartupConfig,
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
  it.each([
    ["prod, App Check off, no real data", cfg({ enforceAppCheck: false })],
    ["prod, App Check on, real data", cfg({ allowRealData: true })],
    ["dev, App Check off, real data flag", cfg({ environment: "dev", enforceAppCheck: false, allowRealData: true })],
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
  it("test data only from listed test accounts", () => {
    const r = runtime({ testUids: ["owner"] });
    expect(() => assertDataPolicy(cfg(), r, "owner", true)).not.toThrow();
    expect(() => assertDataPolicy(cfg(), r, "owner", false)).toThrow();
    expect(() => assertDataPolicy(cfg(), r, "other", true)).toThrow();
  });
});
