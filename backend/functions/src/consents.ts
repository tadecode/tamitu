// Consent version rules (ADR-0012). Pure logic, no I/O: Firestore reads live in index.ts.
import { AppError } from "./errors.js";

export type ConsentType = "privacy_policy" | "ai_processing";

/** Version prefix per consent type: privacy-vN <-> privacy_policy, ai-consent-vN <-> ai_processing. */
export const VERSION_PREFIX: Readonly<Record<ConsentType, string>> = {
  privacy_policy: "privacy",
  ai_processing: "ai-consent",
};

/** ADR-0012 pkt 1: N is an integer 1..9999 without leading zeros. */
export const VERSION_PATTERN = /^(privacy|ai-consent)-v([1-9]\d{0,3})$/;

/**
 * ADR-0012 pkt 2 / SEC-21: versions known to the server. A new version is added here and
 * deployed BEFORE the app with the new text is released (procedure in ADR-0012 pkt 6).
 */
export const KNOWN_VERSIONS: Readonly<Record<ConsentType, readonly string[]>> = {
  privacy_policy: ["privacy-v1"],
  ai_processing: ["ai-consent-v1"],
};

/** Returns N for a well-formed version of the given type; undefined otherwise. */
export function versionNumber(type: ConsentType, version: unknown): number | undefined {
  if (typeof version !== "string") return undefined;
  const m = VERSION_PATTERN.exec(version);
  if (!m || m[1] !== VERSION_PREFIX[type]) return undefined;
  return Number(m[2]);
}

/** recordConsent: well-formed, prefix matching `type`, and on the known list. */
export function isKnownVersion(type: ConsentType, version: string): boolean {
  return versionNumber(type, version) !== undefined && KNOWN_VERSIONS[type].includes(version);
}

/** The latest (by receivedAt) consent record of a type, as stored in users/{uid}/consents. */
export interface LatestConsent {
  granted: boolean;
  policyVersion: string;
}

export interface LatestConsents {
  privacy?: LatestConsent | undefined;
  ai?: LatestConsent | undefined;
}

export interface CurrentVersions {
  policyVersionCurrent?: string | undefined;
  aiConsentVersionCurrent?: string | undefined;
}

/**
 * Config check (ADR-0012 pkt 4): both versions in config/runtime must be well-formed,
 * otherwise fail-closed with consent_required (privacy_policy). Runs before any consent read.
 */
export function currentVersionNumbers(current: CurrentVersions): { privacy: number; ai: number } {
  const privacy = versionNumber("privacy_policy", current.policyVersionCurrent);
  const ai = versionNumber("ai_processing", current.aiConsentVersionCurrent);
  if (privacy === undefined || ai === undefined) {
    throw new AppError("consent_required", { consentType: "privacy_policy" });
  }
  return { privacy, ai };
}

/**
 * ADR-0012 pkt 3, in this order (after the config check above):
 *  a. latest privacy_policy record must exist and have N >= current; a record with
 *     granted=false is not an acceptance, so it is rejected too (fail-closed);
 *  b. latest ai_processing record must have granted=true and N >= current.
 * Records with a malformed or foreign-prefix version count as missing.
 * Throws consent_required with details.consentType; returns normally when both pass.
 */
export function assertConsents(current: CurrentVersions, latest: LatestConsents): void {
  const cur = currentVersionNumbers(current);
  const p = latest.privacy;
  const pN = p ? versionNumber("privacy_policy", p.policyVersion) : undefined;
  if (p?.granted !== true || pN === undefined || pN < cur.privacy) {
    throw new AppError("consent_required", { consentType: "privacy_policy" });
  }
  const a = latest.ai;
  const aN = a ? versionNumber("ai_processing", a.policyVersion) : undefined;
  if (a?.granted !== true || aN === undefined || aN < cur.ai) {
    throw new AppError("consent_required", { consentType: "ai_processing" });
  }
}

/** ±24 h window for the client clock (posrednik-api.md pkt 3). */
export const CLIENT_AT_MAX_SKEW_MS = 24 * 60 * 60 * 1000;

/** Document stored at users/{uid}/consents/{consentId} (docs/data/model-danych.md pkt 3). */
export interface ConsentDoc {
  type: ConsentType;
  granted: boolean;
  policyVersion: string;
  lang: "pl" | "en";
  clientAt: Date;
  /** Present (true) only when clientAt was outside ±24 h and replaced by the server time. */
  clientAtCorrected?: true;
  receivedAt: Date;
}

/** Fields of a validated recordConsent request needed to build the stored document. */
export interface ConsentInput {
  type: ConsentType;
  granted: boolean;
  policyVersion: string;
  lang: "pl" | "en";
  clientAt: string;
}

/**
 * Builds the document for a new consent record. clientAt outside ±24 h of the server time is
 * replaced by the server time and flagged (contract pkt 3). receivedAt = server time.
 */
export function buildConsentDoc(input: ConsentInput, now: Date): ConsentDoc {
  const client = new Date(input.clientAt);
  const skewed = Number.isNaN(client.getTime()) || Math.abs(client.getTime() - now.getTime()) > CLIENT_AT_MAX_SKEW_MS;
  return {
    type: input.type,
    granted: input.granted,
    policyVersion: input.policyVersion,
    lang: input.lang,
    clientAt: skewed ? now : client,
    ...(skewed ? { clientAtCorrected: true as const } : {}),
    receivedAt: now,
  };
}

/**
 * Idempotent write by consentId (P3-04): creates users/{uid}/consents/{consentId} only when it does
 * not exist and returns the stored receivedAt. A repeated consentId never creates a duplicate and
 * never overwrites the first record (append-only history, ADR-0005 pkt 3).
 */
export type ConsentWriter = (uid: string, consentId: string, doc: ConsentDoc) => Promise<{ receivedAt: Date }>;

/** Firestore path of a consent record (data model pkt 3). */
export function consentDocPath(uid: string, consentId: string): string {
  return `users/${uid}/consents/${consentId}`;
}

/**
 * Stored shape: dates converted by `toTimestamp` (Firestore Timestamp in index.ts).
 * Pure so the mapping is unit-tested without the emulator (review PR #57 #4).
 */
export function toStoredConsent<T>(doc: ConsentDoc, toTimestamp: (d: Date) => T) {
  return { ...doc, clientAt: toTimestamp(doc.clientAt), receivedAt: toTimestamp(doc.receivedAt) };
}

/** receivedAt of an existing document (anything with toDate(), e.g. Timestamp), else fallback. */
export function storedReceivedAt(value: unknown, fallback: Date): Date {
  const toDate = (value as { toDate?: unknown } | null)?.toDate;
  if (typeof toDate === "function") {
    const d: unknown = toDate.call(value);
    if (d instanceof Date && !Number.isNaN(d.getTime())) return d;
  }
  return fallback;
}
