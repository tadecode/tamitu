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
  // P3-05 (p3-05-wymagania-generowania.md sekcja 6): model call metadata only, never prompt/output.
  attempt?: number;
  aiModel?: string;
  aiLocation?: string;
  modelVersion?: string;
  promptVersion?: string;
  tokensIn?: number;
  tokensOut?: number;
  tokensThought?: number;
  /** `ok`, `invalid`, `model_config`, `model_retryable`, `error`. */
  outcome?: string;
  /** Validation issue codes built by the server (no content), e.g. `items_count@day5`. */
  validationErrors?: string;
  /** Quality warning codes of a valid plan (no content), e.g. `dup_place@day14` (TAM-95). */
  qualityWarnings?: string;
  /** ModelError code: HTTP status, `timeout`, `network`. */
  modelError?: string;
  /** Fixed code of the slot release after an error (`released`, `busy_released`, ...). */
  quotaRelease?: string;
  // ADR-0016 pkt 15: retry metadata, numbers and fixed codes only.
  /** Wait before this model call in ms. */
  waitMs?: number;
  /** false only for a call rejected with HTTP 429. */
  billable?: boolean;
  /** Model calls in this generation (1-3). */
  calls?: number;
  /** `ok`, `invalid`, `config`, `busy`, `max_billable`, `max_calls`, `time_budget`. */
  stopReason?: string;
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
  "attempt",
  "aiModel",
  "aiLocation",
  "modelVersion",
  "promptVersion",
  "tokensIn",
  "tokensOut",
  "tokensThought",
  "outcome",
  "validationErrors",
  "qualityWarnings",
  "modelError",
  "quotaRelease",
  "waitMs",
  "billable",
  "calls",
  "stopReason",
];

const MAX_STRING = 64;
/** validationErrors joins several server-built codes; longer cap, still content-free. */
// qualityWarnings: worst case 13 x `dup_place@dayNN` = 199 characters for 14 days (test in plan-validator.test.ts);
// raise this cap together with MAX_DAYS.
const MAX_STRING_BY_KEY: Partial<Record<keyof LogFields, number>> = { validationErrors: 200, qualityWarnings: 200 };

export function sanitizeFields(fields: Partial<LogFields>): Record<string, string | number | boolean> {
  const out: Record<string, string | number | boolean> = {};
  const src = fields as Record<string, unknown>;
  for (const key of ALLOWED) {
    const v = src[key];
    if (typeof v === "number" && Number.isFinite(v)) out[key] = v;
    else if (typeof v === "boolean") out[key] = v;
    else if (typeof v === "string") out[key] = v.slice(0, MAX_STRING_BY_KEY[key] ?? MAX_STRING);
  }
  return out;
}

export function logEvent(fields: LogFields): void {
  platformLogger.info("fn_event", sanitizeFields(fields));
}

/**
 * Severity of a failed call (QA P3-04 r3, OBS-1). Expected client errors from the contract
 * (AppError: consent_required, invalid_argument, unauthenticated, ...) are WARNING, so ordinary
 * refusals do not look like outages in Cloud Logging / Error Reporting and carry no stack trace
 * (logger.error appends one). ERROR only for server-side faults: anything that is not an AppError
 * (returned to the client as a bare `internal`) and the contract codes that mean the server failed.
 */
export type FailureSeverity = "WARNING" | "ERROR";

const SERVER_FAULT_CODES: ReadonlySet<string> = new Set(["internal", "ai_invalid_response"]);

export function failureSeverity(errorClass: string | undefined, errorCode: string | undefined): FailureSeverity {
  return errorClass === "AppError" && !SERVER_FAULT_CODES.has(errorCode ?? "") ? "WARNING" : "ERROR";
}

export function logFailure(fields: LogFields): void {
  const entry = sanitizeFields(fields);
  if (failureSeverity(fields.errorClass, fields.errorCode) === "WARNING") platformLogger.warn("fn_error", entry);
  else platformLogger.error("fn_error", entry);
}

/** HMAC-SHA256 of the UID with a secret pepper (Secret Manager); undefined when pepper missing. */
export function uidHash(uid: string, pepper: string | undefined): string | undefined {
  if (!pepper) return undefined;
  return createHmac("sha256", pepper).update(uid).digest("hex").slice(0, 32);
}
