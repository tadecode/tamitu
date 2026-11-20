import { describe, expect, it, vi } from "vitest";

// index.ts resolves service accounts at import time; the Firebase CLI sets GCLOUD_PROJECT from --project.
vi.hoisted(() => {
  process.env.GCLOUD_PROJECT = "tamitu-dev-tadecode";
});

// index.ts initialises firebase-admin at import time; no credentials or network in unit tests.
vi.mock("firebase-admin/app", () => ({ getApps: () => [{}], initializeApp: vi.fn() }));
vi.mock("firebase-admin/auth", () => ({ getAuth: vi.fn() }));
vi.mock("firebase-admin/firestore", () => ({ getFirestore: vi.fn(), Timestamp: { fromDate: vi.fn() } }));

import * as functions from "../src/index.js";
import { SERVICE_ACCOUNTS, serviceAccountFor, type FunctionName } from "../src/service-accounts.js";

const DEV_SUFFIX = "@tamitu-dev-tadecode.iam.gserviceaccount.com";

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

  it.each(exported)("%s sets serviceAccount to its own full fn-* e-mail in europe-west4", (name, fn) => {
    const expected = SERVICE_ACCOUNTS[name as FunctionName];
    expect(expected).toBeDefined();
    expect(fn.__endpoint?.serviceAccountEmail).toBe(`${expected}${DEV_SUFFIX}`);
    expect(fn.__endpoint?.region).toEqual(["europe-west4"]);
  });

  it("uses distinct accounts (least privilege, no sharing)", () => {
    const accounts = Object.values(SERVICE_ACCOUNTS);
    expect(new Set(accounts).size).toBe(accounts.length);
  });

  it("maps generatePlan to fn-ai-plan (renamed from fn-ai, O2)", () => {
    expect(serviceAccountFor("generatePlan")).toBe(`fn-ai-plan${DEV_SUFFIX}`);
  });

  it("builds the full e-mail from GCLOUD_PROJECT for dev and prod (TAM-86)", () => {
    expect(serviceAccountFor("recordConsent", { GCLOUD_PROJECT: "tamitu-dev-tadecode" })).toBe(
      "fn-consent@tamitu-dev-tadecode.iam.gserviceaccount.com",
    );
    expect(serviceAccountFor("budgetGuard", { GCLOUD_PROJECT: "tamitu-prod-tadecode" })).toBe(
      "fn-budget@tamitu-prod-tadecode.iam.gserviceaccount.com",
    );
  });

  it("never returns the `name@` shorthand (rejected by Secret Manager setIamPolicy, TAM-86)", () => {
    for (const fn of Object.keys(SERVICE_ACCOUNTS) as FunctionName[]) {
      expect(serviceAccountFor(fn)).toMatch(/^[a-z0-9-]+@[a-z0-9-]+\.iam\.gserviceaccount\.com$/);
    }
  });

  it("fails closed when the project id is unknown (no default compute account)", () => {
    expect(() => serviceAccountFor("recordConsent", {})).toThrow("GCLOUD_PROJECT missing or invalid");
    expect(() => serviceAccountFor("recordConsent", { GCLOUD_PROJECT: "" })).toThrow(
      "GCLOUD_PROJECT missing or invalid",
    );
  });

  it("account ids meet Google's rule (6-30 chars, lowercase, digits, hyphens)", () => {
    for (const id of Object.values(SERVICE_ACCOUNTS)) {
      expect(id).toMatch(/^[a-z][a-z0-9-]{4,28}[a-z0-9]$/);
    }
  });

  it("rejects malformed project ids", () => {
    for (const bad of ["Tamitu-Dev", "x", "evil.com/a", "tamitu-dev-tadecode-"]) {
      expect(() => serviceAccountFor("deleteAccount", { GCLOUD_PROJECT: bad })).toThrow(
        "GCLOUD_PROJECT missing or invalid",
      );
    }
  });
});
