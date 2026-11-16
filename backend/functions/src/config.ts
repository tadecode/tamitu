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
  globalDailyLimit: 50,
};

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
