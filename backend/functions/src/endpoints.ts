// Function bodies with injected dependencies (testable without Firebase). P3-02 skeletons; P3-04 adds
// the idempotent recordConsent write; P3-05 the generatePlan flow (quota, model, validation, retry).
import type { PlanModel } from "./ai.js";
import {
  requireAppCheck,
  requireFreshLogin,
  requireGoogleProvider,
  verifyCaller,
  type CallerRequest,
  type TokenVerifier,
} from "./auth.js";
import {
  assertDataPolicy,
  assertRequestConfig,
  type RuntimeConfig,
  type StaticConfig,
} from "./config.js";
import {
  assertConsents,
  buildConsentDoc,
  currentVersionNumbers,
  type ConsentWriter,
  type LatestConsents,
} from "./consents.js";
import { AppError } from "./errors.js";
import type { HandlerContext } from "./handler.js";
import { generateValidPlan, type AttemptLog } from "./generate.js";
import { shouldDisableAi, type QuotaInfo, type ReservationPlan } from "./limits.js";
import { logEvent, uidHash } from "./logger.js";
import type { PlanDay } from "./plan-validator.js";
import { PROMPT_VERSION } from "./prompt/plan-v1.js";
import {
  budgetNotificationSchema,
  parseDeleteAccount,
  parseGeneratePlan,
  parseRecordConsent,
  requestSizeBytes,
} from "./schemas.js";

export interface Deps {
  verifier: TokenVerifier;
  config: StaticConfig;
  loadRuntime: () => Promise<RuntimeConfig>;
  /** Latest consent record per type (by receivedAt) for the caller; called only after the config check. */
  loadLatestConsents: (uid: string) => Promise<LatestConsents>;
  /** Idempotent create of users/{uid}/consents/{consentId}; called only after auth and validation. */
  writeConsent: ConsentWriter;
  pepper?: string | undefined;
  now: () => Date;
  /** undefined = AI configuration missing/invalid (AI_MODEL_ID, AI_LOCATION): ai_unavailable, no reservation. */
  model: PlanModel | undefined;
  /**
   * Quota reservation in ONE Firestore transaction (usage/{uid}, usage_global/{today});
   * decision and written shape: limits.planReservation.
   */
  reserveQuota: (uid: string, limits: { userLimit: number; globalLimit: number }, now: Date) => Promise<ReservationPlan>;
  /** Slot release after a system error (separate transaction; limits.planRelease). */
  releaseQuota: (uid: string, reservationDay: string, now: Date) => Promise<void>;
  /** Clock for attempt durations (tests inject a fake). */
  clock?: () => number;
  /** Wait before a retry after 429/5xx/timeout (tests inject a no-op). */
  sleep?: (ms: number) => Promise<void>;
}

export type CallableReq = CallerRequest & { data: unknown };

export interface GeneratePlanResponse {
  apiVersion: 1;
  requestId: string;
  language: "pl" | "en";
  promptVersion: string;
  days: PlanDay[];
  quota: QuotaInfo;
}

/**
 * Error codes after which the reserved slot is returned - exactly the contract list (posrednik-api.md pkt 2;
 * review PR #136 #8). After `internal` the slot stays used (cost-safer; the model may have been billed).
 */
const RELEASE_ON: ReadonlySet<string> = new Set(["ai_unavailable", "ai_invalid_response"]);

export async function generatePlanCore(
  req: CallableReq,
  deps: Deps,
  ctx: HandlerContext,
): Promise<GeneratePlanResponse> {
  ctx.requestBytes = requestSizeBytes(req.data);
  const caller = await verifyCaller(req, deps.verifier);
  ctx.uidHash = uidHash(caller.uid, deps.pepper);
  requireGoogleProvider(caller);
  requireAppCheck(req, deps.config.enforceAppCheck);
  const request = parseGeneratePlan(req.data, deps.now());
  ctx.days = request.trip.days;

  const runtime = await deps.loadRuntime();
  assertRequestConfig(deps.config, runtime); // Aneks A pkt 3 (ii)
  assertDataPolicy(deps.config, runtime, caller.uid, request.testData);
  // ADR-0012 pkt 3-4: consents (privacy_policy, then ai_processing; N >= current) BEFORE quota
  // reservation. Malformed/missing versions in config/runtime fail closed before any read and
  // log the fixed code `configError` (never the values).
  const current = currentVersionNumbers(runtime, ctx);
  assertConsents(current, await deps.loadLatestConsents(caller.uid));
  if (!runtime.aiEnabled) throw new AppError("ai_unavailable");
  const model = deps.model;
  if (!model) {
    ctx.configError = "ai_config_invalid";
    throw new AppError("ai_unavailable");
  }

  // ADR-0002 step 5: reserve BEFORE calling the model.
  const reservation = await deps.reserveQuota(
    caller.uid,
    { userLimit: runtime.perUserDailyLimit, globalLimit: runtime.globalDailyLimit },
    deps.now(),
  );
  if (!reservation.allowed) {
    if (reservation.appCode === "limit_exceeded") {
      throw new AppError("limit_exceeded", { limit: reservation.quota.limit, resetAt: reservation.quota.resetAt });
    }
    throw new AppError("ai_unavailable");
  }

  ctx.attempts = 0;
  const onAttempt = (a: AttemptLog) => {
    ctx.attempts = a.attempt;
    logEvent({
      fn: "generatePlan.attempt",
      result: a.outcome,
      ...(ctx.uidHash !== undefined ? { uidHash: ctx.uidHash } : {}),
      days: request.trip.days,
      ...a,
    });
  };
  try {
    const { plan } = await generateValidPlan(request, model, { clock: deps.clock, sleep: deps.sleep, onAttempt });
    return {
      apiVersion: 1,
      requestId: request.requestId,
      language: plan.language,
      promptVersion: PROMPT_VERSION,
      days: plan.days,
      quota: reservation.reservation.quota,
    };
  } catch (e) {
    const code = e instanceof AppError ? e.appCode : "internal";
    if (RELEASE_ON.has(code)) {
      try {
        await deps.releaseQuota(caller.uid, reservation.reservation.day, deps.now());
      } catch {
        // Never mask the original error; the fixed code tells the owner a slot stayed used.
        ctx.quotaRelease = "release_failed";
      }
    }
    throw e;
  }
}

export interface RecordConsentResponse {
  consentId: string;
  receivedAt: string;
}

/**
 * P3-04: idempotent write by consentId (posrednik-api.md pkt 3). Order: token (checkRevoked, so a
 * deleted user is rejected before any write - ADR-0002 Aneks A pkt 1) -> provider -> App Check ->
 * validation (known versions, ADR-0012 pkt 2) -> write. No consent/version enforcement here
 * (ADR-0012, option 4 rejected): this function is how a user accepts a policy.
 */
export async function recordConsentCore(
  req: CallableReq,
  deps: Deps,
  ctx: HandlerContext,
): Promise<RecordConsentResponse> {
  ctx.requestBytes = requestSizeBytes(req.data);
  const caller = await verifyCaller(req, deps.verifier);
  ctx.uidHash = uidHash(caller.uid, deps.pepper);
  requireGoogleProvider(caller);
  requireAppCheck(req, deps.config.enforceAppCheck);
  const r = parseRecordConsent(req.data);
  const doc = buildConsentDoc(r, deps.now());
  const stored = await deps.writeConsent(caller.uid, r.consentId, doc);
  return { consentId: r.consentId, receivedAt: stored.receivedAt.toISOString() };
}

export async function deleteAccountCore(req: CallableReq, deps: Deps, ctx: HandlerContext): Promise<never> {
  ctx.requestBytes = requestSizeBytes(req.data);
  const caller = await verifyCaller(req, deps.verifier);
  ctx.uidHash = uidHash(caller.uid, deps.pepper);
  // Deliberately NO requireGoogleProvider here (ADR-0011 pkt 4, SEC-24 part 2 / U-3): the function
  // deletes only the account from the verified token, so a provider restriction adds no security
  // but could block the right to erasure (GDPR art. 17) after a provider change in the app.
  // Likewise parseDeleteAccount never returns unsupported_version (any apiVersion >= 1).
  requireAppCheck(req, deps.config.enforceAppCheck);
  parseDeleteAccount(req.data);
  requireFreshLogin(caller, deps.now());
  // TODO P3-08: recursiveDelete(users/{uid}), delete(usage/{uid}), deleteUser, control re-delete.
  throw new AppError("not_implemented");
}

/** Pub/Sub budget notification. Returns whether AI should be disabled; does not write yet. */
export function budgetGuardCore(payload: unknown): boolean {
  const r = budgetNotificationSchema.safeParse(payload);
  if (!r.success) throw new AppError("invalid_argument", { field: "message" });
  // TODO P3-09: set config/runtime.aiEnabled=false in prod when this returns true.
  return shouldDisableAi(r.data.costAmount, r.data.budgetAmount);
}
