// Request validation per docs/api/posrednik-api.md and docs/api/schemas/*.json.
// Validation errors expose ONLY field paths, never values (ADR-0002 Aneks A pkt 2).
import { z } from "zod";
import { isKnownVersion } from "./consents.js";
import { AppError } from "./errors.js";
import { warsawDay } from "./limits.js";

export const MAX_REQUEST_BYTES = 4096;
export const API_VERSION = 1;

export const INTERESTS = [
  "monuments_history",
  "architecture",
  "art_museums",
  "nature_parks",
  "beaches_water",
  "local_food",
  "active_sport",
  "family_attractions",
  "shopping",
  "nightlife",
  "relaxation",
] as const;

const UUID_V4 = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
/**
 * SEC-21: Unicode categories Cc (control), Cf (format: zero-width, bidi overrides/isolates, BOM,
 * soft hyphen), Zl and Zp (line/paragraph separators). Hidden text and direction tricks (T4).
 */
const FORBIDDEN_CHARS = /[\p{Cc}\p{Cf}\p{Zl}\p{Zp}]/u;

/** Trimmed, NFC-normalised, 1..max characters (after normalisation), no Cc/Cf/Zl/Zp characters. */
const text = (max: number) =>
  z
    .string()
    .trim()
    .normalize("NFC")
    .min(1)
    .max(max)
    .refine((s) => !FORBIDDEN_CHARS.test(s));

const timeHHMM = z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/);

const arrival = z
  .strictObject({
    mode: z.enum(["flight", "car"]),
    date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
    time: timeHHMM,
    airport: text(60).optional(),
  })
  .superRefine((a, ctx) => {
    if (a.mode === "flight" && a.airport === undefined) ctx.addIssue({ code: "custom", path: ["airport"], message: "required" });
    if (a.mode === "car" && a.airport !== undefined) ctx.addIssue({ code: "custom", path: ["airport"], message: "forbidden" });
  });

export const generatePlanRequestSchema = z.strictObject({
  apiVersion: z.literal(API_VERSION),
  requestId: z.string().regex(UUID_V4),
  planLanguage: z.enum(["pl", "en"]),
  trip: z.strictObject({
    destination: text(80),
    lodging: text(80),
    days: z.number().int().min(1).max(14),
    arrival,
  }),
  preferences: z.strictObject({
    interests: z.array(z.enum(INTERESTS)).max(5).refine((a) => new Set(a).size === a.length).default([]),
    budget: z.enum(["low", "medium", "high"]).default("medium"),
    pace: z.enum(["relaxed", "moderate", "intense"]).default("moderate"),
    partySize: z.number().int().min(1).max(10).default(2),
  }),
  testData: z.boolean().optional(),
});
export type GeneratePlanRequest = z.infer<typeof generatePlanRequestSchema>;

export const recordConsentRequestSchema = z
  .strictObject({
    apiVersion: z.literal(API_VERSION),
    consentId: z.string().regex(UUID_V4),
    type: z.enum(["privacy_policy", "ai_processing"]),
    granted: z.boolean(),
    // ADR-0012 pkt 1-2 / SEC-21: pattern, prefix matching `type` and known list (refine below).
    policyVersion: z.string().max(40),
    lang: z.enum(["pl", "en"]),
    clientAt: z.iso.datetime(),
  })
  .superRefine((r, ctx) => {
    if (!isKnownVersion(r.type, r.policyVersion)) {
      ctx.addIssue({ code: "custom", path: ["policyVersion"], message: "unknown_version" });
    }
  });
export type RecordConsentRequest = z.infer<typeof recordConsentRequestSchema>;

/**
 * ADR-0011 pkt 4: deleteAccount accepts ANY apiVersion >= 1 (never unsupported_version), so the
 * right to erasure does not depend on the app version. The current version is strict; fields a
 * future version may add are ignored (deleteAccount acts only on the verified token).
 */
export const deleteAccountRequestSchema = z.union([
  z.strictObject({ apiVersion: z.literal(API_VERSION) }),
  z.object({ apiVersion: z.number().int().min(API_VERSION + 1) }),
]);

/** Budget notification payload (Pub/Sub); only the fields we need. */
export const budgetNotificationSchema = z.object({
  costAmount: z.number(),
  budgetAmount: z.number(),
});

function fieldPath(path: ReadonlyArray<PropertyKey>): string {
  return path.length === 0 ? "request" : path.map((p) => String(p)).join(".");
}

/** Throws AppError(invalid_argument) with `field` = path only; nothing from the input. */
export function parseOrThrow<T>(schema: z.ZodType<T>, data: unknown): T {
  const r = schema.safeParse(data);
  if (r.success) return r.data;
  const first = r.error.issues[0];
  throw new AppError("invalid_argument", { field: fieldPath(first?.path ?? []) });
}

/** Request size limit (4 KB) measured on the serialised JSON. */
export function requestSizeBytes(data: unknown): number {
  try {
    return Buffer.byteLength(JSON.stringify(data) ?? "", "utf8");
  } catch {
    return Number.POSITIVE_INFINITY;
  }
}

function addDays(day: string, n: number): string {
  const d = new Date(`${day}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + n);
  return d.toISOString().slice(0, 10);
}

/** ADR-0011 pkt 3: lower bound relative to "today" in Europe/Warsaw (covers UTC-12..UTC+14). */
export const ARRIVAL_MIN_OFFSET_DAYS = -2;
/** Upper bound: "today + 2 years" (731 days covers a leap day). Unchanged. */
export const ARRIVAL_MAX_OFFSET_DAYS = 731;

/**
 * Arrival date: real calendar date, not earlier than today-2 (Warsaw), not later than +2 years.
 * The app validates stricter (from "yesterday" in the device time zone), so a valid form never
 * gets invalid_argument here.
 */
export function checkArrivalDate(date: string, now: Date): void {
  const parsed = new Date(`${date}T00:00:00Z`);
  const real = !Number.isNaN(parsed.getTime()) && parsed.toISOString().slice(0, 10) === date;
  const today = warsawDay(now);
  if (!real || date < addDays(today, ARRIVAL_MIN_OFFSET_DAYS) || date > addDays(today, ARRIVAL_MAX_OFFSET_DAYS)) {
    throw new AppError("invalid_argument", { field: "trip.arrival.date" });
  }
}

export function parseGeneratePlan(data: unknown, now: Date): GeneratePlanRequest {
  if (requestSizeBytes(data) > MAX_REQUEST_BYTES) throw new AppError("invalid_argument", { field: "request" });
  // apiVersion mismatch has its own code (checked before the strict schema).
  const v = (data as { apiVersion?: unknown } | null)?.apiVersion;
  if (typeof v === "number" && v !== API_VERSION) throw new AppError("unsupported_version", { minVersion: API_VERSION });
  const req = parseOrThrow(generatePlanRequestSchema, data);
  checkArrivalDate(req.trip.arrival.date, now);
  return req;
}

export function parseRecordConsent(data: unknown): RecordConsentRequest {
  if (requestSizeBytes(data) > MAX_REQUEST_BYTES) throw new AppError("invalid_argument", { field: "request" });
  const v = (data as { apiVersion?: unknown } | null)?.apiVersion;
  if (typeof v === "number" && v !== API_VERSION) throw new AppError("unsupported_version", { minVersion: API_VERSION });
  return parseOrThrow(recordConsentRequestSchema, data);
}

/** No unsupported_version branch on purpose (ADR-0011 pkt 4); a bad shape -> invalid_argument. */
export function parseDeleteAccount(data: unknown): void {
  if (requestSizeBytes(data) > MAX_REQUEST_BYTES) throw new AppError("invalid_argument", { field: "request" });
  parseOrThrow(deleteAccountRequestSchema, data);
}
