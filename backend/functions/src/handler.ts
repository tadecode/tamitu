// Global exception handler (ADR-0002 Aneks A pkt 2). Every function is wrapped by this.
import { HttpsError } from "firebase-functions/v2/https";
import { AppError, classifyError } from "./errors.js";
import { logEvent, logFailure } from "./logger.js";

export interface HandlerContext {
  /** Set by the handler body once known; used only for the hashed log field. */
  uidHash?: string | undefined;
  days?: number | undefined;
  requestBytes?: number | undefined;
}

/**
 * Runs `body`; on success logs allow-listed fields. On any exception logs ONLY the error
 * class and code (never message, stack, or request/response objects) and rethrows either the
 * contract error (AppError) or a bare `internal` HttpsError.
 */
export async function runGuarded<T>(
  fn: string,
  body: (ctx: HandlerContext) => Promise<T>,
  clock: () => number = Date.now,
): Promise<T> {
  const started = clock();
  const ctx: HandlerContext = {};
  try {
    const result = await body(ctx);
    logEvent({ fn, result: "ok", durationMs: clock() - started, ...pick(ctx) });
    return result;
  } catch (e) {
    const { errorClass, errorCode } = classifyError(e);
    logFailure({ fn, result: "error", durationMs: clock() - started, errorClass, errorCode, ...pick(ctx) });
    if (e instanceof AppError) throw e.toHttpsError();
    throw new HttpsError("internal", "internal", { code: "internal" });
  }
}

function pick(ctx: HandlerContext) {
  return {
    ...(ctx.uidHash !== undefined ? { uidHash: ctx.uidHash } : {}),
    ...(ctx.days !== undefined ? { days: ctx.days } : {}),
    ...(ctx.requestBytes !== undefined ? { requestBytes: ctx.requestBytes } : {}),
  };
}
