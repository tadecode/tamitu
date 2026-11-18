import { beforeEach, describe, expect, it, vi } from "vitest";

// OBS-1 (QA P3-04 r3): contract errors are WARNING, server faults ERROR.
const calls: { level: string; args: unknown[] }[] = [];
vi.mock("firebase-functions/logger", () => ({
  info: (...a: unknown[]) => void calls.push({ level: "info", args: a }),
  warn: (...a: unknown[]) => void calls.push({ level: "warn", args: a }),
  error: (...a: unknown[]) => void calls.push({ level: "error", args: a }),
}));

import { AppError, type AppCode } from "../src/errors.js";
import { runGuarded } from "../src/handler.js";
import { failureSeverity } from "../src/logger.js";

beforeEach(() => {
  calls.length = 0;
});

describe("failureSeverity", () => {
  it.each<AppCode>([
    "unauthenticated",
    "app_check_failed",
    "invalid_argument",
    "unsupported_version",
    "consent_required",
    "limit_exceeded",
    "ai_unavailable",
    "test_data_only",
    "reauth_required",
    "not_implemented",
  ])("AppError %s -> WARNING", (code) => {
    expect(failureSeverity("AppError", code)).toBe("WARNING");
  });

  it.each<AppCode>(["internal", "ai_invalid_response"])("AppError %s -> ERROR", (code) => {
    expect(failureSeverity("AppError", code)).toBe("ERROR");
  });

  it("anything that is not an AppError -> ERROR", () => {
    expect(failureSeverity("TypeError", "unknown")).toBe("ERROR");
    expect(failureSeverity("FirebaseError", "consent_required")).toBe("ERROR");
    expect(failureSeverity(undefined, undefined)).toBe("ERROR");
  });
});

describe("runGuarded log level", () => {
  it("a contract refusal is logged with warn, fields unchanged", async () => {
    await expect(
      runGuarded("recordConsent", () => Promise.reject(new AppError("consent_required", { consentType: "x" }))),
    ).rejects.toMatchObject({ code: "failed-precondition" });
    expect(calls).toHaveLength(1);
    expect(calls[0]?.level).toBe("warn");
    expect(calls[0]?.args[0]).toBe("fn_error");
    expect(calls[0]?.args[1]).toMatchObject({ fn: "recordConsent", result: "error", errorClass: "AppError", errorCode: "consent_required" });
  });

  it("an unexpected exception is logged with error", async () => {
    await expect(runGuarded("generatePlan", () => Promise.reject(new TypeError("boom")))).rejects.toMatchObject({
      code: "internal",
    });
    expect(calls.map((c) => c.level)).toEqual(["error"]);
    expect(calls[0]?.args[1]).toMatchObject({ errorClass: "TypeError" });
  });

  it("success stays info", async () => {
    await runGuarded("deleteAccount", () => Promise.resolve(1));
    expect(calls.map((c) => c.level)).toEqual(["info"]);
  });
});
