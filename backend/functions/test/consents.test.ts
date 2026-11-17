import { describe, expect, it } from "vitest";
import {
  assertConsents,
  buildConsentDoc,
  consentDocPath,
  storedReceivedAt,
  toStoredConsent,
  CLIENT_AT_MAX_SKEW_MS,
  CONSENT_VERSIONS_INVALID,
  latestConsentFromDoc,
  currentVersionNumbers,
  isKnownVersion,
  KNOWN_VERSIONS,
  versionNumber,
  type ConsentType,
  type CurrentVersions,
  type LatestConsents,
} from "../src/consents.js";
import { AppError } from "../src/errors.js";

/** Config check + consent check, as generatePlanCore runs them. */
const check = (cfg: CurrentVersions, latest: LatestConsents) => assertConsents(currentVersionNumbers(cfg), latest);

const CURRENT = { policyVersionCurrent: "privacy-v2", aiConsentVersionCurrent: "ai-consent-v2" };
const rec = (policyVersion: string, granted = true) => ({ granted, policyVersion });
const both = (p: string, a: string): LatestConsents => ({ privacy: rec(p), ai: rec(a) });

/** Returns details.consentType of a consent_required error, or "passed". */
function consentTypeOf(fn: () => void): string | number | undefined {
  try {
    fn();
  } catch (e) {
    expect(e).toBeInstanceOf(AppError);
    expect((e as AppError).appCode).toBe("consent_required");
    return (e as AppError).details["consentType"];
  }
  return "passed";
}

describe("version format (ADR-0012 pkt 1)", () => {
  it("parses N within the type prefix", () => {
    expect(versionNumber("privacy_policy", "privacy-v1")).toBe(1);
    expect(versionNumber("privacy_policy", "privacy-v9999")).toBe(9999);
    expect(versionNumber("ai_processing", "ai-consent-v12")).toBe(12);
  });

  const malformed: unknown[] = ["privacy-v0", "privacy-v01", "privacy-v10000", "privacy-1", "Privacy-v1", " privacy-v1", "ai-consent-v1", "", 1, null];
  it.each(malformed.map((v) => [v]))("rejects %j for privacy_policy", (v) => {
    expect(versionNumber("privacy_policy", v)).toBeUndefined();
  });

  it("known list holds only well-formed versions with a matching prefix", () => {
    for (const [type, list] of Object.entries(KNOWN_VERSIONS)) {
      for (const v of list) expect(isKnownVersion(type as ConsentType, v)).toBe(true);
    }
    expect(isKnownVersion("ai_processing", "privacy-v1")).toBe(false);
    expect(isKnownVersion("privacy_policy", "privacy-v2")).toBe(false);
  });
});

describe("config/runtime fail-closed (ADR-0012 pkt 4)", () => {
  const bad: CurrentVersions[] = [
    {},
    { policyVersionCurrent: "privacy-v1" },
    { aiConsentVersionCurrent: "ai-consent-v1" },
    { policyVersionCurrent: "v1", aiConsentVersionCurrent: "ai-consent-v1" },
    { policyVersionCurrent: "privacy-v1", aiConsentVersionCurrent: "privacy-v1" },
  ];
  it.each(bad.map((c) => [c]))("bad config %j -> consent_required/privacy_policy even with valid records", (cfg) => {
    expect(consentTypeOf(() => currentVersionNumbers(cfg))).toBe("privacy_policy");
    expect(consentTypeOf(() => check(cfg, both("privacy-v9", "ai-consent-v9")))).toBe("privacy_policy");
  });
});

describe("consent decision (ADR-0012 pkt 3, 7)", () => {
  it("passes with records equal to or newer than current (>=, no race on a version change)", () => {
    expect(consentTypeOf(() => check(CURRENT, both("privacy-v2", "ai-consent-v2")))).toBe("passed");
    expect(consentTypeOf(() => check(CURRENT, both("privacy-v3", "ai-consent-v10")))).toBe("passed");
  });

  it("privacy_policy: missing, older, foreign prefix or not granted -> privacy_policy", () => {
    expect(consentTypeOf(() => check(CURRENT, { ai: rec("ai-consent-v2") }))).toBe("privacy_policy");
    expect(consentTypeOf(() => check(CURRENT, both("privacy-v1", "ai-consent-v2")))).toBe("privacy_policy");
    expect(consentTypeOf(() => check(CURRENT, both("ai-consent-v9", "ai-consent-v2")))).toBe("privacy_policy");
    const notGranted = { privacy: rec("privacy-v2", false), ai: rec("ai-consent-v2") };
    expect(consentTypeOf(() => check(CURRENT, notGranted))).toBe("privacy_policy");
  });

  it("privacy is checked before AI", () => {
    expect(consentTypeOf(() => check(CURRENT, {}))).toBe("privacy_policy");
  });

  it("ai_processing: missing, older, withdrawn or foreign prefix -> ai_processing", () => {
    expect(consentTypeOf(() => check(CURRENT, { privacy: rec("privacy-v2") }))).toBe("ai_processing");
    expect(consentTypeOf(() => check(CURRENT, both("privacy-v2", "ai-consent-v1")))).toBe("ai_processing");
    const withdrawn = { privacy: rec("privacy-v2"), ai: rec("ai-consent-v5", false) };
    expect(consentTypeOf(() => check(CURRENT, withdrawn))).toBe("ai_processing");
    expect(consentTypeOf(() => check(CURRENT, both("privacy-v2", "privacy-v5")))).toBe("ai_processing");
  });
});

describe("buildConsentDoc (P3-04, clientAt ±24 h)", () => {
  const now = new Date("2026-11-15T10:00:00Z");
  const input = {
    type: "ai_processing" as const,
    granted: false,
    policyVersion: "ai-consent-v1",
    lang: "pl" as const,
    clientAt: "2026-11-14T10:00:01Z",
  };

  it("keeps clientAt inside the window and sets receivedAt to server time", () => {
    const d = buildConsentDoc(input, now);
    expect(d).toEqual({ ...input, clientAt: new Date(input.clientAt), receivedAt: now });
    expect("clientAtCorrected" in d).toBe(false);
  });

  it("replaces clientAt outside ±24 h with server time and flags it", () => {
    for (const clientAt of ["2026-11-14T09:59:59Z", "2026-11-16T10:00:01Z"]) {
      const d = buildConsentDoc({ ...input, clientAt }, now);
      expect(d.clientAt).toEqual(now);
      expect(d.clientAtCorrected).toBe(true);
    }
  });

  it("exactly 24 h is still accepted", () => {
    expect(buildConsentDoc({ ...input, clientAt: "2026-11-16T10:00:00Z" }, now).clientAtCorrected).toBeUndefined();
    expect(CLIENT_AT_MAX_SKEW_MS).toBe(86_400_000);
  });
});

describe("Firestore mapping of consent records (review PR #57 #4)", () => {
  const now = new Date("2026-11-15T10:00:00Z");
  const doc = buildConsentDoc(
    { type: "privacy_policy", granted: true, policyVersion: "privacy-v1", lang: "en", clientAt: "2026-11-15T09:59:00Z" },
    now,
  );

  it("path is users/{uid}/consents/{consentId}", () => {
    expect(consentDocPath("u1", "c-1")).toBe("users/u1/consents/c-1");
  });

  it("stores both dates as timestamps and keeps all contract fields", () => {
    const stored = toStoredConsent(doc, (d) => ({ ts: d.toISOString() }));
    expect(stored).toEqual({
      type: "privacy_policy",
      granted: true,
      policyVersion: "privacy-v1",
      lang: "en",
      clientAt: { ts: "2026-11-15T09:59:00.000Z" },
      receivedAt: { ts: "2026-11-15T10:00:00.000Z" },
    });
  });

  it("reads receivedAt from a Timestamp-like value, else falls back", () => {
    const at = new Date("2026-11-14T08:00:00Z");
    expect(storedReceivedAt({ toDate: () => at }, now)).toEqual(at);
    expect(storedReceivedAt("2026-11-14T08:00:00Z", now)).toEqual(now);
    expect(storedReceivedAt(undefined, now)).toEqual(now);
    expect(storedReceivedAt({ toDate: () => new Date(NaN) }, now)).toEqual(now);
  });
});

describe("config error log code (review PR #51 #1, ADR-0012 pkt 4)", () => {
  it("malformed version sets the fixed code, never the value", () => {
    const log: { configError?: string } = {};
    expect(() => currentVersionNumbers({ policyVersionCurrent: "privacy-1", aiConsentVersionCurrent: "ai-consent-v1" }, log)).toThrow(AppError);
    expect(log.configError).toBe(CONSENT_VERSIONS_INVALID);
    expect(JSON.stringify(log)).not.toContain("privacy-1");
  });

  it("valid versions leave no code", () => {
    const log: { configError?: string } = {};
    currentVersionNumbers({ policyVersionCurrent: "privacy-1".replace("-1", "-v1"), aiConsentVersionCurrent: "ai-consent-v1" }, log);
    expect(log.configError).toBeUndefined();
  });
});

describe("latestConsentFromDoc (review PR #51 #2)", () => {
  it("maps a valid document", () => {
    expect(latestConsentFromDoc({ granted: true, policyVersion: "privacy-v1", type: "privacy_policy" })).toEqual({
      granted: true,
      policyVersion: "privacy-v1",
    });
  });

  it("missing document or wrong types count as no record (fail-closed)", () => {
    expect(latestConsentFromDoc(undefined)).toBeUndefined();
    expect(latestConsentFromDoc(null)).toBeUndefined();
    expect(latestConsentFromDoc({ granted: "true", policyVersion: "privacy-v1" })).toBeUndefined();
    expect(latestConsentFromDoc({ granted: true })).toBeUndefined();
    expect(latestConsentFromDoc({ granted: true, policyVersion: 1 })).toBeUndefined();
  });
});
