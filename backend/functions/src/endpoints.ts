// Function bodies with injected dependencies (testable without Firebase). Skeletons for P3-02:
// validation + auth + fail-closed configuration are real; business logic returns not_implemented.
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
import { assertConsents, currentVersionNumbers, type LatestConsents } from "./consents.js";
import { AppError } from "./errors.js";
import type { HandlerContext } from "./handler.js";
import { shouldDisableAi } from "./limits.js";
import { uidHash } from "./logger.js";
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
  pepper?: string | undefined;
  now: () => Date;
  model: PlanModel;
}

export type CallableReq = CallerRequest & { data: unknown };

export async function generatePlanCore(req: CallableReq, deps: Deps, ctx: HandlerContext): Promise<never> {
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
  // reservation. Malformed/missing versions in config/runtime fail closed before any read.
  currentVersionNumbers(runtime);
  assertConsents(runtime, await deps.loadLatestConsents(caller.uid));
  if (!runtime.aiEnabled) throw new AppError("ai_unavailable");
  // TODO P3-05: quota reservation (limits.decideQuota), prompt, validation, retry.
  return deps.model.generate(request);
}

export async function recordConsentCore(req: CallableReq, deps: Deps, ctx: HandlerContext): Promise<never> {
  ctx.requestBytes = requestSizeBytes(req.data);
  const caller = await verifyCaller(req, deps.verifier);
  ctx.uidHash = uidHash(caller.uid, deps.pepper);
  requireGoogleProvider(caller);
  requireAppCheck(req, deps.config.enforceAppCheck);
  parseRecordConsent(req.data);
  // TODO P3-04: idempotent write to users/{uid}/consents/{consentId}.
  throw new AppError("not_implemented");
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
