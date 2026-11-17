import { beforeEach, describe, expect, it, vi } from "vitest";

const logged: unknown[][] = [];
vi.mock("firebase-functions/logger", () => ({
  info: (...a: unknown[]) => void logged.push(a),
  error: (...a: unknown[]) => void logged.push(a),
  warn: (...a: unknown[]) => void logged.push(a),
  debug: (...a: unknown[]) => void logged.push(a),
  log: (...a: unknown[]) => void logged.push(a),
}));

import { stubModel } from "../src/ai.js";
import { SAFE_RUNTIME_DEFAULTS, type RuntimeConfig } from "../src/config.js";
import { budgetGuardCore, deleteAccountCore, generatePlanCore, recordConsentCore, type Deps } from "../src/endpoints.js";
import { runGuarded } from "../src/handler.js";
import { uidHash } from "../src/logger.js";

const CANARY = "CANARY-Zq81-do-not-log";
const NOW = new Date("2026-11-15T10:00:00Z");

const planBody = (text = "Lizbona") => ({
  apiVersion: 1,
  requestId: "7f0c2a9e-6f0e-4c3a-9a43-0b6c4a1f5d11",
  planLanguage: "pl",
  trip: {
    destination: text,
    lodging: "Baixa",
    days: 4,
    arrival: { mode: "flight", date: "2027-03-12", time: "18:10", airport: "LIS" },
  },
  preferences: { interests: ["local_food"] },
  testData: true,
});

function mkDeps(over: Partial<Deps> = {}, runtime: Partial<RuntimeConfig> = {}): Deps {
  return {
    verifier: {
      verifyIdToken: async () => ({ uid: "owner", auth_time: NOW.getTime() / 1000 - 60, firebase: { sign_in_provider: "google.com" } }),
    },
    config: { environment: "dev", enforceAppCheck: true, allowRealData: false },
    loadRuntime: async () => ({
      ...SAFE_RUNTIME_DEFAULTS,
      aiEnabled: true,
      testUids: ["owner"],
      policyVersionCurrent: "privacy-v1",
      aiConsentVersionCurrent: "ai-consent-v1",
      ...runtime,
    }),
    loadLatestConsents: async () => ({
      privacy: { granted: true, policyVersion: "privacy-v1" },
      ai: { granted: true, policyVersion: "ai-consent-v1" },
    }),
    now: () => NOW,
    model: stubModel,
    ...over,
  };
}

const req = (data: unknown, over: Record<string, unknown> = {}) => ({
  data,
  auth: { uid: "owner" },
  app: { appId: "x" },
  rawRequest: { headers: { authorization: "Bearer tok" } },
  ...over,
});

const code = async (p: Promise<unknown>) => {
  try {
    await p;
  } catch (e) {
    return (e as { details?: { code?: string } }).details?.code;
  }
  return "no-error";
};

beforeEach(() => {
  logged.length = 0;
});

describe("generatePlan skeleton", () => {
  const run = (r: ReturnType<typeof req>, d: Deps) => runGuarded("generatePlan", (ctx) => generatePlanCore(r, d, ctx));

  it("valid request reaches the stub and returns not_implemented", async () => {
    expect(await code(run(req(planBody()), mkDeps()))).toBe("not_implemented");
  });

  it("rejects missing auth, revoked token (checkRevoked) and non-Google provider", async () => {
    expect(await code(run(req(planBody(), { auth: undefined }), mkDeps()))).toBe("unauthenticated");
    const calls: boolean[] = [];
    const revoked = mkDeps({
      verifier: {
        verifyIdToken: async (_t, check) => {
          calls.push(check);
          throw new Error("auth/id-token-revoked " + CANARY);
        },
      },
    });
    expect(await code(run(req(planBody()), revoked))).toBe("unauthenticated");
    expect(calls).toEqual([true]);
    const anon = mkDeps({ verifier: { verifyIdToken: async () => ({ uid: "owner", firebase: { sign_in_provider: "anonymous" } }) } });
    expect(await code(run(req(planBody()), anon))).toBe("unauthenticated");
  });

  it("enforces App Check only when enabled", async () => {
    expect(await code(run(req(planBody(), { app: undefined }), mkDeps()))).toBe("app_check_failed");
    const off = mkDeps({ config: { environment: "dev", enforceAppCheck: false, allowRealData: false } });
    expect(await code(run(req(planBody(), { app: undefined }), off))).toBe("not_implemented");
  });

  it("validation happens before any runtime lookup", async () => {
    const loadRuntime = vi.fn(async () => SAFE_RUNTIME_DEFAULTS);
    expect(await code(run(req({ ...planBody(), x: 1 }), mkDeps({ loadRuntime })))).toBe("invalid_argument");
    expect(loadRuntime).not.toHaveBeenCalled();
  });

  it("is fail-closed: aiEnabled=false, non-test accounts and conflicting config", async () => {
    expect(await code(run(req(planBody()), mkDeps({}, { aiEnabled: false })))).toBe("ai_unavailable");
    expect(await code(run(req(planBody()), mkDeps({}, { testUids: [] })))).toBe("test_data_only");
    const prod = mkDeps({ config: { environment: "prod", enforceAppCheck: false, allowRealData: false } }, { allowRealData: true });
    expect(await code(run(req(planBody()), prod))).toBe("test_data_only");
  });

  it("missing config/runtime defaults to AI disabled", async () => {
    expect(await code(run(req(planBody()), mkDeps({ loadRuntime: async () => SAFE_RUNTIME_DEFAULTS })))).toBe("test_data_only");
  });
});

describe("generatePlan consents (ADR-0012 pkt 3-4, 7)", () => {
  const run = (d: Deps) => runGuarded("generatePlan", (ctx) => generatePlanCore(req(planBody()), d, ctx));
  const detailsOf = async (p: Promise<unknown>) => {
    try {
      await p;
    } catch (e) {
      return (e as { details?: Record<string, unknown> }).details;
    }
    return undefined;
  };

  it("no privacy record -> consent_required/privacy_policy, checked before aiEnabled (and quota)", async () => {
    const d = mkDeps({ loadLatestConsents: async () => ({ ai: { granted: true, policyVersion: "ai-consent-v1" } }) }, { aiEnabled: false });
    expect(await detailsOf(run(d))).toEqual({ code: "consent_required", consentType: "privacy_policy" });
  });

  it("older AI consent -> ai_processing; newer records -> accepted (reaches the stub)", async () => {
    const old = mkDeps({}, { aiConsentVersionCurrent: "ai-consent-v2" });
    expect(await detailsOf(run(old))).toEqual({ code: "consent_required", consentType: "ai_processing" });
    const newer = mkDeps({
      loadLatestConsents: async () => ({
        privacy: { granted: true, policyVersion: "privacy-v3" },
        ai: { granted: true, policyVersion: "ai-consent-v2" },
      }),
    });
    expect(await code(run(newer))).toBe("not_implemented");
  });

  it("bad config/runtime versions fail closed without reading consents", async () => {
    const loadLatestConsents = vi.fn(async () => ({}));
    const d = mkDeps({ loadLatestConsents }, { policyVersionCurrent: "privacy-1" });
    expect(await detailsOf(run(d))).toEqual({ code: "consent_required", consentType: "privacy_policy" });
    expect(loadLatestConsents).not.toHaveBeenCalled();
  });

  it("consents are read only after validation and the data policy", async () => {
    const loadLatestConsents = vi.fn(async () => ({}));
    expect(await code(run(mkDeps({ loadLatestConsents }, { testUids: [] })))).toBe("test_data_only");
    expect(loadLatestConsents).not.toHaveBeenCalled();
  });
});

describe("recordConsent and deleteAccount skeletons", () => {
  const consent = {
    apiVersion: 1,
    consentId: "0d8f1c1e-33b8-4a3e-bf4a-0a3d8c1f9e22",
    type: "ai_processing",
    granted: true,
    policyVersion: "ai-consent-v1",
    lang: "pl",
    clientAt: "2026-11-15T10:12:03Z",
  };
  it("recordConsent validates, then not_implemented", async () => {
    const go = (d: unknown, deps = mkDeps()) => runGuarded("recordConsent", (c) => recordConsentCore(req(d), deps, c));
    expect(await code(go(consent))).toBe("not_implemented");
    expect(await code(go({ ...consent, type: "x" }))).toBe("invalid_argument");
    expect(await code(go({ ...consent, policyVersion: "ai-consent-v2" }))).toBe("invalid_argument"); // unknown (SEC-21)
    const gone = mkDeps({ verifier: { verifyIdToken: async () => { throw new Error("user-not-found"); } } });
    expect(await code(go(consent, gone))).toBe("unauthenticated");
  });

  it("deleteAccount requires a fresh login (auth_time <= 5 min)", async () => {
    const go = (deps: Deps) => runGuarded("deleteAccount", (c) => deleteAccountCore(req({ apiVersion: 1 }), deps, c));
    expect(await code(go(mkDeps()))).toBe("not_implemented");
    const stale = mkDeps({ verifier: { verifyIdToken: async () => ({ uid: "owner", auth_time: NOW.getTime() / 1000 - 3600 }) } });
    expect(await code(go(stale))).toBe("reauth_required");
  });

  it("deleteAccount does not require google.com nor reject a newer apiVersion (ADR-0011 pkt 4)", async () => {
    const other = mkDeps({
      verifier: {
        verifyIdToken: async () => ({ uid: "owner", auth_time: NOW.getTime() / 1000 - 60, firebase: { sign_in_provider: "password" } }),
      },
    });
    const go = (data: unknown, deps: Deps, over: Record<string, unknown> = {}) =>
      runGuarded("deleteAccount", (c) => deleteAccountCore(req(data, over), deps, c));
    expect(await code(go({ apiVersion: 1 }, other))).toBe("not_implemented");
    expect(await code(go({ apiVersion: 7 }, mkDeps()))).toBe("not_implemented");
    expect(await code(go({ apiVersion: 1 }, mkDeps(), { app: undefined }))).toBe("app_check_failed");
  });
});

describe("budgetGuard skeleton", () => {
  it("decides on cost vs budget and validates payload", () => {
    expect(budgetGuardCore({ costAmount: 100, budgetAmount: 100 })).toBe(true);
    expect(budgetGuardCore({ costAmount: 1, budgetAmount: 100 })).toBe(false);
    expect(() => budgetGuardCore({ costAmount: "x" })).toThrow();
  });
});

describe("no content in logs (ADR-0002 Aneks A pkt 2)", () => {
  const everything = () => JSON.stringify(logged);

  it("control string in valid, invalid and exception-causing requests never reaches the logs", async () => {
    const run = (data: unknown, deps = mkDeps()) =>
      runGuarded("generatePlan", (ctx) => generatePlanCore(req(data), deps, ctx));
    await code(run(planBody(CANARY))); // valid -> stub
    await code(run({ ...planBody(), [CANARY]: CANARY })); // unknown key
    await code(run({ ...planBody(), planLanguage: CANARY })); // bad enum value
    await code(run({ ...planBody(CANARY), trip: { ...planBody().trip, days: CANARY } })); // wrong type
    const throwing = mkDeps({
      model: { generate: async () => { throw new TypeError(`model failed for ${CANARY}`); } },
    });
    expect(await code(run(planBody(CANARY), throwing))).toBe("internal"); // thrown with canary in message
    const tokenFail = mkDeps({ verifier: { verifyIdToken: async () => { throw new Error(CANARY); } } });
    await code(run(planBody(CANARY), tokenFail));
    expect(logged.length).toBeGreaterThan(0);
    expect(everything()).not.toContain(CANARY);
  });

  it("client gets a bare internal error for unexpected exceptions", async () => {
    const throwing = mkDeps({ model: { generate: async () => { throw new Error(CANARY); } } });
    try {
      await runGuarded("generatePlan", (ctx) => generatePlanCore(req(planBody()), throwing, ctx));
      expect.unreachable();
    } catch (e) {
      const he = e as { code: string; message: string; details: unknown };
      expect(he.code).toBe("internal");
      expect(JSON.stringify([he.message, he.details])).not.toContain(CANARY);
    }
  });

  it("logs only allow-listed keys, with error class and code", async () => {
    await code(runGuarded("generatePlan", (ctx) => generatePlanCore(req(planBody()), mkDeps({ pepper: "p" }), ctx)));
    const fields = logged.flatMap((a) => a.filter((x): x is Record<string, unknown> => typeof x === "object" && x !== null));
    const allowed = new Set(["fn", "result", "uidHash", "durationMs", "attempts", "days", "requestBytes", "errorClass", "errorCode"]);
    for (const f of fields) for (const k of Object.keys(f)) expect(allowed.has(k)).toBe(true);
    expect(fields[0]).toMatchObject({ fn: "generatePlan", result: "error", errorClass: "AppError", errorCode: "not_implemented", days: 4 });
    expect(fields[0]?.["uidHash"]).toBe(uidHash("owner", "p"));
    expect(everything()).not.toContain("owner\"");
  });
});

describe("uidHash", () => {
  it("is stable, keyed and absent without pepper", () => {
    expect(uidHash("u", undefined)).toBeUndefined();
    expect(uidHash("u", "a")).toBe(uidHash("u", "a"));
    expect(uidHash("u", "a")).not.toBe(uidHash("u", "b"));
    expect(uidHash("u", "a")).not.toContain("u");
  });
});
