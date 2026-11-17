// The ONLY module allowed to write logs (ADR-0002 Aneks A pkt 2; enforced by eslint + test).
import * as platformLogger from "firebase-functions/logger";
import { createHmac } from "node:crypto";

/** Allow-listed fields (ADR-0002, "Logowanie"). Anything else is dropped. */
export interface LogFields {
  fn: string;
  result: string;
  uidHash?: string;
  durationMs?: number;
  attempts?: number;
  days?: number;
  requestBytes?: number;
  errorClass?: string;
  errorCode?: string;
  /** Fixed configuration error code (ADR-0012 pkt 4), never a configured value. */
  configError?: string;
}

const ALLOWED: ReadonlyArray<keyof LogFields> = [
  "fn",
  "result",
  "uidHash",
  "durationMs",
  "attempts",
  "days",
  "requestBytes",
  "errorClass",
  "errorCode",
  "configError",
];

const MAX_STRING = 64;

export function sanitizeFields(fields: Partial<LogFields>): Record<string, string | number> {
  const out: Record<string, string | number> = {};
  const src = fields as Record<string, unknown>;
  for (const key of ALLOWED) {
    const v = src[key];
    if (typeof v === "number" && Number.isFinite(v)) out[key] = v;
    else if (typeof v === "string") out[key] = v.slice(0, MAX_STRING);
  }
  return out;
}

export function logEvent(fields: LogFields): void {
  platformLogger.info("fn_event", sanitizeFields(fields));
}

export function logFailure(fields: LogFields): void {
  platformLogger.error("fn_error", sanitizeFields(fields));
}

/** HMAC-SHA256 of the UID with a secret pepper (Secret Manager); undefined when pepper missing. */
export function uidHash(uid: string, pepper: string | undefined): string | undefined {
  if (!pepper) return undefined;
  return createHmac("sha256", pepper).update(uid).digest("hex").slice(0, 32);
}
