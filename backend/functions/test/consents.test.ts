import { describe, expect, it } from "vitest";
import {
  assertConsents,
  currentVersionNumbers,
  isKnownVersion,
  KNOWN_VERSIONS,
  versionNumber,
  type ConsentType,
  type CurrentVersions,
  type LatestConsents,
} from "../src/consents.js";
import { AppError } from "../src/errors.js";

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
    expect(consentTypeOf(() => assertConsents(cfg, both("privacy-v9", "ai-consent-v9")))).toBe("privacy_policy");
  });
});

describe("consent decision (ADR-0012 pkt 3, 7)", () => {
  it("passes with records equal to or newer than current (>=, no race on a version change)", () => {
    expect(consentTypeOf(() => assertConsents(CURRENT, both("privacy-v2", "ai-consent-v2")))).toBe("passed");
    expect(consentTypeOf(() => assertConsents(CURRENT, both("privacy-v3", "ai-consent-v10")))).toBe("passed");
  });

  it("privacy_policy: missing, older, foreign prefix or not granted -> privacy_policy", () => {
    expect(consentTypeOf(() => assertConsents(CURRENT, { ai: rec("ai-consent-v2") }))).toBe("privacy_policy");
    expect(consentTypeOf(() => assertConsents(CURRENT, both("privacy-v1", "ai-consent-v2")))).toBe("privacy_policy");
    expect(consentTypeOf(() => assertConsents(CURRENT, both("ai-consent-v9", "ai-consent-v2")))).toBe("privacy_policy");
    const notGranted = { privacy: rec("privacy-v2", false), ai: rec("ai-consent-v2") };
    expect(consentTypeOf(() => assertConsents(CURRENT, notGranted))).toBe("privacy_policy");
  });

  it("privacy is checked before AI", () => {
    expect(consentTypeOf(() => assertConsents(CURRENT, {}))).toBe("privacy_policy");
  });

  it("ai_processing: missing, older, withdrawn or foreign prefix -> ai_processing", () => {
    expect(consentTypeOf(() => assertConsents(CURRENT, { privacy: rec("privacy-v2") }))).toBe("ai_processing");
    expect(consentTypeOf(() => assertConsents(CURRENT, both("privacy-v2", "ai-consent-v1")))).toBe("ai_processing");
    const withdrawn = { privacy: rec("privacy-v2"), ai: rec("ai-consent-v5", false) };
    expect(consentTypeOf(() => assertConsents(CURRENT, withdrawn))).toBe("ai_processing");
    expect(consentTypeOf(() => assertConsents(CURRENT, both("privacy-v2", "privacy-v5")))).toBe("ai_processing");
  });
});
