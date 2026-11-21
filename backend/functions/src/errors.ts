import { HttpsError, type FunctionsErrorCode } from "firebase-functions/v2/https";

/** Application error codes from docs/api/posrednik-api.md (details.code). */
export type AppCode =
  | "unauthenticated"
  | "app_check_failed"
  | "invalid_argument"
  | "unsupported_version"
  | "consent_required"
  | "limit_exceeded"
  | "ai_unavailable"
  | "ai_invalid_response"
  | "test_data_only"
  | "reauth_required"
  | "not_implemented"
  | "internal";

const HTTPS_CODE: Record<AppCode, FunctionsErrorCode> = {
  unauthenticated: "unauthenticated",
  app_check_failed: "failed-precondition",
  invalid_argument: "invalid-argument",
  unsupported_version: "failed-precondition",
  consent_required: "failed-precondition",
  limit_exceeded: "resource-exhausted",
  ai_unavailable: "unavailable",
  ai_invalid_response: "internal",
  test_data_only: "permission-denied",
  reauth_required: "failed-precondition",
  not_implemented: "unimplemented",
  internal: "internal",
};

/**
 * Error carrying a contract code. `details` must never contain user-provided values
 * (field paths, constants and fixed flags such as `slotReleased` only).
 */
export class AppError extends Error {
  constructor(
    readonly appCode: AppCode,
    readonly details: Record<string, string | number | boolean> = {},
  ) {
    // Fixed message: nothing user-controlled ever ends up in message.
    super(appCode);
    this.name = "AppError";
  }

  toHttpsError(): HttpsError {
    return new HttpsError(HTTPS_CODE[this.appCode], this.appCode, { code: this.appCode, ...this.details });
  }
}

/**
 * SEC-19: allow-list for values that reach the log. Library codes (Firebase, gRPC, Node) are
 * short identifiers like `auth/id-token-revoked`, `ECONNRESET` or `5`; anything else (spaces,
 * quotes, longer text that could carry input fragments) becomes `unknown`. Never truncated:
 * a cut value could still leak a prefix of the input.
 */
export const ERROR_CODE_PATTERN = /^[A-Za-z0-9_./:-]{1,60}$/;
/** Class names: JS identifier characters only, max 60. */
export const ERROR_CLASS_PATTERN = /^[A-Za-z_$][A-Za-z0-9_$]{0,59}$/;

function allowed(value: string, pattern: RegExp): string {
  return pattern.test(value) ? value : "unknown";
}

/** Safe, content-free classification of any thrown value: class name and code only (SEC-19). */
export function classifyError(e: unknown): { errorClass: string; errorCode: string } {
  if (e instanceof AppError) return { errorClass: "AppError", errorCode: e.appCode };
  const rawClass = e instanceof Error ? e.constructor.name : typeof e;
  const raw = (e as { code?: unknown } | null)?.code;
  const rawCode = typeof raw === "string" || (typeof raw === "number" && Number.isFinite(raw)) ? String(raw) : "";
  return { errorClass: allowed(rawClass, ERROR_CLASS_PATTERN), errorCode: allowed(rawCode, ERROR_CODE_PATTERN) };
}
