import { describe, expect, it, vi } from "vitest";

// index.ts initialises firebase-admin at import time; no credentials or network in unit tests.
vi.mock("firebase-admin/app", () => ({ getApps: () => [{}], initializeApp: vi.fn() }));
vi.mock("firebase-admin/auth", () => ({ getAuth: vi.fn() }));
vi.mock("firebase-admin/firestore", () => ({ getFirestore: vi.fn(), Timestamp: { fromDate: vi.fn() } }));

import * as functions from "../src/index.js";
import { SERVICE_ACCOUNTS, serviceAccountFor, type FunctionName } from "../src/service-accounts.js";

/**
 * Full e-mail of the account in a project, as the Firebase CLI expands the `<name>@` shorthand.
 * Test-only (review PR #70 #4b: not used by production code); documents the runbook addresses.
 */
function serviceAccountEmail(fn: FunctionName, projectId: string): string {
  if (!/^[a-z][a-z0-9-]{4,28}[a-z0-9]$/.test(projectId)) {
    throw new Error("invalid project id");
  }
  return `${SERVICE_ACCOUNTS[fn]}@${projectId}.iam.gserviceaccount.com`;
}

interface EndpointLike {
  __endpoint?: { serviceAccountEmail?: unknown; region?: unknown };
}

const exported = Object.entries(functions as Record<string, unknown>).filter(
  ([, v]) => typeof v === "function" && (v as EndpointLike).__endpoint !== undefined,
) as [string, EndpointLike][];

describe("SEC-20: dedicated service account per function", () => {
  it("covers every exported Cloud Function (no function without an account, no stale entries)", () => {
    expect(exported.map(([name]) => name).sort()).toEqual(Object.keys(SERVICE_ACCOUNTS).sort());
  });

  it.each(exported)("%s sets serviceAccount to its own fn-* account in europe-west4", (name, fn) => {
    const expected = SERVICE_ACCOUNTS[name as FunctionName];
    expect(expected).toBeDefined();
    expect(fn.__endpoint?.serviceAccountEmail).toBe(`${expected}@`);
    expect(fn.__endpoint?.region).toEqual(["europe-west4"]);
  });

  it("uses distinct accounts (least privilege, no sharing)", () => {
    const accounts = Object.values(SERVICE_ACCOUNTS);
    expect(new Set(accounts).size).toBe(accounts.length);
  });

  it("maps generatePlan to fn-ai-plan (renamed from fn-ai, O2)", () => {
    expect(serviceAccountFor("generatePlan")).toBe("fn-ai-plan@");
  });

  it("builds the full e-mail from the project id", () => {
    expect(serviceAccountEmail("recordConsent", "tamitu-dev-tadecode")).toBe(
      "fn-consent@tamitu-dev-tadecode.iam.gserviceaccount.com",
    );
    expect(serviceAccountEmail("budgetGuard", "tamitu-prod-tadecode")).toBe(
      "fn-budget@tamitu-prod-tadecode.iam.gserviceaccount.com",
    );
  });

  it("account ids meet Google's rule (6-30 chars, lowercase, digits, hyphens)", () => {
    for (const id of Object.values(SERVICE_ACCOUNTS)) {
      expect(id).toMatch(/^[a-z][a-z0-9-]{4,28}[a-z0-9]$/);
    }
  });

  it("rejects malformed project ids", () => {
    for (const bad of ["", "Tamitu-Dev", "x", "evil.com/a", "tamitu-dev-tadecode-"]) {
      expect(() => serviceAccountEmail("deleteAccount", bad)).toThrow("invalid project id");
    }
  });
});
