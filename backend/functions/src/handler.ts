// Global exception handler (ADR-0002 Aneks A pkt 2). Every function is wrapped by this.
import { HttpsError } from "firebase-functions/v2/https";
import { AppError, classifyError } from "./errors.js";
import { logEvent, logFailure } from "./logger.js";

export interface HandlerContext {
  /** Set by the handler body once known; used only for the hashed log field. */
  uidHash?: string | undefined;
  days?: number | undefined;
  requestBytes?: number | undefined;
  /** Fixed code of a configuration error (e.g. "consent_versions_invalid"); never a value. */
  configError?: string | undefined;
  /** generatePlan: number of model attempts made. */
  attempts?: number | undefined;
  /** Fixed code of the quota slot release after an error. */
  quotaRelease?: string | undefined;
  /** generatePlan: model calls (1-3) and why the generation loop ended (ADR-0016 pkt 15). */
  calls?: number | undefined;
  stopReason?: string | undefined;
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
    ...(ctx.configError !== undefined ? { configError: ctx.configError } : {}),
    ...(ctx.attempts !== undefined ? { attempts: ctx.attempts } : {}),
    ...(ctx.quotaRelease !== undefined ? { quotaRelease: ctx.quotaRelease } : {}),
    ...(ctx.calls !== undefined ? { calls: ctx.calls } : {}),
    ...(ctx.stopReason !== undefined ? { stopReason: ctx.stopReason } : {}),
  };
}
