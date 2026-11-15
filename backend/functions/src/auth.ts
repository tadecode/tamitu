import { AppError } from "./errors.js";

export interface VerifiedCaller {
  uid: string;
  signInProvider: string | undefined;
  authTimeSec: number | undefined;
}

/** Subset of firebase-admin Auth used here; injectable for tests. */
export interface TokenVerifier {
  verifyIdToken(token: string, checkRevoked: boolean): Promise<{
    uid: string;
    auth_time?: number;
    firebase?: { sign_in_provider?: string };
  }>;
}

export interface CallerRequest {
  auth?: { uid: string } | undefined;
  app?: unknown;
  rawRequest: { headers: Record<string, string | string[] | undefined> };
}

function bearerToken(req: CallerRequest): string | undefined {
  const h = req.rawRequest.headers["authorization"];
  const value = Array.isArray(h) ? h[0] : h;
  const m = value?.match(/^Bearer (.+)$/i);
  return m?.[1];
}

/**
 * ADR-0002 Aneks A pkt 1: verify the raw token with checkRevoked so that deleted users and
 * revoked tokens are rejected before ANY write. Any verification failure -> unauthenticated.
 */
export async function verifyCaller(req: CallerRequest, verifier: TokenVerifier): Promise<VerifiedCaller> {
  const token = bearerToken(req);
  if (!req.auth || !token) throw new AppError("unauthenticated");
  let decoded;
  try {
    decoded = await verifier.verifyIdToken(token, true);
  } catch {
    throw new AppError("unauthenticated");
  }
  if (decoded.uid !== req.auth.uid) throw new AppError("unauthenticated");
  return { uid: decoded.uid, signInProvider: decoded.firebase?.sign_in_provider, authTimeSec: decoded.auth_time };
}

/** MVP: only Google sign-in (ADR-0002, Q8). */
export function requireGoogleProvider(c: VerifiedCaller): void {
  if (c.signInProvider !== "google.com") throw new AppError("unauthenticated");
}

/** App Check: when enforced, a missing/invalid token (req.app undefined) is rejected. */
export function requireAppCheck(req: CallerRequest, enforce: boolean): void {
  if (enforce && !req.app) throw new AppError("app_check_failed");
}

/** deleteAccount needs a fresh login: auth_time within the last 5 minutes. */
export function requireFreshLogin(c: VerifiedCaller, now: Date, maxAgeSec = 300): void {
  if (c.authTimeSec === undefined || now.getTime() / 1000 - c.authTimeSec > maxAgeSec) {
    throw new AppError("reauth_required");
  }
}
