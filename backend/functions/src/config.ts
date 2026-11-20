import { AppError } from "./errors.js";

export type Environment = "dev" | "prod";

export interface StaticConfig {
  environment: Environment;
  enforceAppCheck: boolean;
  allowRealData: boolean;
}

export interface RuntimeConfig {
  aiEnabled: boolean;
  allowRealData: boolean;
  testUids: readonly string[];
  perUserDailyLimit: number;
  globalDailyLimit: number;
  /** ADR-0012: `privacy-vN`; raw value, validated by consents.currentVersionNumbers (fail-closed). */
  policyVersionCurrent?: string | undefined;
  /** ADR-0012: `ai-consent-vN`; raw value, validated like policyVersionCurrent. */
  aiConsentVersionCurrent?: string | undefined;
}

/** Fail-closed defaults used when config/runtime is missing or malformed. */
export const SAFE_RUNTIME_DEFAULTS: RuntimeConfig = {
  aiEnabled: false,
  allowRealData: false,
  testUids: [],
  perUserDailyLimit: 5,
  // ADR-0014 Aneks A pkt 3: 25 generations/day during the test phase (was 50).
  globalDailyLimit: 25,
};

/**
 * SEC-22: accepted ranges for limits read from config/runtime. A value outside the range (or not an
 * integer) falls back to SAFE_RUNTIME_DEFAULTS (fail-closed, T3/T26): an owner's typo in the console
 * can neither switch off nor blow up the cost fuse. ADR-0002/ADR-0014 do not define ranges; values
 * proposed in TAM-60 (question O-SEC22-1). Raising the upper bound needs a code change and review.
 */
export const LIMIT_BOUNDS = {
  perUserDailyLimit: { min: 1, max: 20 },
  globalDailyLimit: { min: 1, max: 100 },
} as const;

function boundedInt(value: unknown, bounds: { min: number; max: number }, fallback: number): number {
  return Number.isInteger(value) && (value as number) >= bounds.min && (value as number) <= bounds.max
    ? (value as number)
    : fallback;
}

/**
 * Parses the config/runtime document (SEC-22; moved from index.ts so it is unit-tested).
 * Missing document -> SAFE_RUNTIME_DEFAULTS; every field is validated on its own, fail-closed.
 */
export function parseRuntimeConfig(d: Record<string, unknown> | undefined): RuntimeConfig {
  if (!d) return SAFE_RUNTIME_DEFAULTS;
  const testUids = d["testUids"];
  return {
    aiEnabled: d["aiEnabled"] === true,
    allowRealData: d["allowRealData"] === true,
    testUids: Array.isArray(testUids) ? testUids.filter((x): x is string => typeof x === "string") : [],
    perUserDailyLimit: boundedInt(
      d["perUserDailyLimit"],
      LIMIT_BOUNDS.perUserDailyLimit,
      SAFE_RUNTIME_DEFAULTS.perUserDailyLimit,
    ),
    globalDailyLimit: boundedInt(
      d["globalDailyLimit"],
      LIMIT_BOUNDS.globalDailyLimit,
      SAFE_RUNTIME_DEFAULTS.globalDailyLimit,
    ),
    // Raw strings; format checked fail-closed in consents.currentVersionNumbers (ADR-0012 pkt 4).
    policyVersionCurrent: typeof d["policyVersionCurrent"] === "string" ? d["policyVersionCurrent"] : undefined,
    aiConsentVersionCurrent: typeof d["aiConsentVersionCurrent"] === "string" ? d["aiConsentVersionCurrent"] : undefined,
  };
}

/**
 * Parses deployment parameters. Fail-closed (ADR-0002 Aneks A pkt 3):
 * - ENVIRONMENT other than "dev" -> "prod" (strictest);
 * - ENFORCE_APP_CHECK disabled only by the exact value "false";
 * - ALLOW_REAL_DATA enabled only by the exact value "true".
 */
export function parseStaticConfig(env: Record<string, string | undefined>): StaticConfig {
  return {
    environment: env["ENVIRONMENT"] === "dev" ? "dev" : "prod",
    enforceAppCheck: env["ENFORCE_APP_CHECK"] !== "false",
    allowRealData: env["ALLOW_REAL_DATA"] === "true",
  };
}

/**
 * Startup checks:
 * - Aneks A pkt 3 (i): prod with App Check off and real data allowed must refuse to start;
 * - ADR-0011 pkt 5 (i) (SEC-24): dev is test-data only, so dev + ALLOW_REAL_DATA=true refuses to start.
 */
export function assertStartupConfig(cfg: StaticConfig): void {
  if (cfg.environment === "prod" && !cfg.enforceAppCheck && cfg.allowRealData) {
    throw new Error("invalid_config_app_check_real_data");
  }
  if (cfg.environment === "dev" && cfg.allowRealData) {
    throw new Error("invalid_config_dev_real_data");
  }
}

/**
 * Per-request check (ii): config/runtime may change without deploy, so the pair is re-evaluated.
 * Either source saying "real data allowed" counts as allowed for the conflict check (fail-closed).
 */
export function assertRequestConfig(cfg: StaticConfig, runtime: RuntimeConfig): void {
  const realData = cfg.allowRealData || runtime.allowRealData;
  if (cfg.environment === "prod" && !cfg.enforceAppCheck && realData) {
    throw new AppError("test_data_only");
  }
}

/**
 * Real data requires BOTH the parameter and config/runtime to allow it; otherwise test accounts only.
 * ADR-0011 pkt 5 (ii) (SEC-24): in dev both flags are ignored (treated as false), so dev accepts
 * only testData=true from config/runtime.testUids, whatever config/runtime says.
 */
export function assertDataPolicy(
  cfg: StaticConfig,
  runtime: RuntimeConfig,
  uid: string,
  testData: boolean | undefined,
): void {
  if (cfg.environment === "prod" && cfg.allowRealData && runtime.allowRealData) return;
  if (testData === true && runtime.testUids.includes(uid)) return;
  throw new AppError("test_data_only");
}
