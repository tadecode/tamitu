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
 * (field paths and constants only).
 */
export class AppError extends Error {
  constructor(
    readonly appCode: AppCode,
    readonly details: Record<string, string | number> = {},
  ) {
    // Fixed message: nothing user-controlled ever ends up in message.
    super(appCode);
    this.name = "AppError";
  }

  toHttpsError(): HttpsError {
    return new HttpsError(HTTPS_CODE[this.appCode], this.appCode, { code: this.appCode, ...this.details });
  }
}

/** Safe, content-free classification of any thrown value: class name and code only. */
export function classifyError(e: unknown): { errorClass: string; errorCode: string } {
  if (e instanceof AppError) return { errorClass: "AppError", errorCode: e.appCode };
  const errorClass = e instanceof Error ? e.constructor.name : typeof e;
  const raw = (e as { code?: unknown } | null)?.code;
  const errorCode = typeof raw === "string" || typeof raw === "number" ? String(raw).slice(0, 60) : "unknown";
  return { errorClass: errorClass.slice(0, 60), errorCode };
}
