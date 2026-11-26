// generatePlanCore end-to-end with fakes: quota reservation, response shape, slot release (P3-05).
import { beforeEach, describe, expect, it, vi } from "vitest";

const logged: unknown[][] = [];
vi.mock("firebase-functions/logger", () => ({
  info: (...a: unknown[]) => void logged.push(a),
  error: (...a: unknown[]) => void logged.push(a),
  warn: (...a: unknown[]) => void logged.push(a),
}));

import { ModelError } from "../src/ai.js";
import { SAFE_RUNTIME_DEFAULTS, type RuntimeConfig } from "../src/config.js";
import { generatePlanCore, type Deps } from "../src/endpoints.js";
import { runGuarded } from "../src/handler.js";
import { QUOTA_TX_MAX_ATTEMPTS, runQuotaTransaction, type QuotaTxRunner, type ReservationPlan } from "../src/limits.js";
import { resolvePrompt } from "../src/prompt/index.js";
import { echoValidModel, memoryQuota, ok, scriptedModel } from "./helpers/fakes.js";

const NOW = new Date("2026-11-21T10:00:00Z");
const CANARY = "CANARY-plan-Zq81";
const body = () => ({
  apiVersion: 1,
  requestId: "7f0c2a9e-6f0e-4c3a-9a43-0b6c4a1f5d11",
  planLanguage: "pl",
  trip: { destination: CANARY, lodging: "Baixa", days: 4, arrival: { mode: "flight", date: "2027-03-12", time: "18:10", airport: "LIS" } },
  preferences: { interests: ["local_food"] },
  testData: true,
});
const req = (data: unknown) => ({ data, auth: { uid: "owner" }, app: { appId: "x" }, rawRequest: { headers: { authorization: "Bearer t" } } });

function mkDeps(over: Partial<Deps> = {}, runtime: Partial<RuntimeConfig> = {}) {
  const quota = memoryQuota();
  const deps: Deps = {
    verifier: { verifyIdToken: async () => ({ uid: "owner", firebase: { sign_in_provider: "google.com" } }) },
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
    writeConsent: async (_u, _i, d) => ({ receivedAt: d.receivedAt }),
    pepper: "pepper",
    now: () => NOW,
    model: echoValidModel(),
    reserveQuota: quota.reserveQuota,
    releaseQuota: quota.releaseQuota,
    releaseBusyQuota: quota.releaseBusyQuota,
    ...over,
  };
  return { deps, quota };
}

const run = (data: unknown, deps: Deps) => runGuarded("generatePlan", (ctx) => generatePlanCore(req(data), deps, ctx));
const err = (p: Promise<unknown>) =>
  p.then(
    () => undefined,
    (e: { details?: Record<string, unknown> }) => e.details,
  );
const fields = () => logged.map((a) => a[1] as Record<string, unknown>);

beforeEach(() => {
  logged.length = 0;
});

describe("generatePlan - prompt version (TAM-95, review PR #148 #2)", () => {
  it("deps.prompt = plan-v2 is returned and logged; without it the response says plan-v1", async () => {
    const { deps } = mkDeps({ prompt: resolvePrompt("plan-v2") });
    expect((await run(body(), deps)).promptVersion).toBe("plan-v2");
    expect(fields().find((f) => f["fn"] === "generatePlan.attempt")).toMatchObject({ promptVersion: "plan-v2" });
    expect((await run(body(), mkDeps({ prompt: resolvePrompt("plan-v9") }).deps)).promptVersion).toBe("plan-v1");
  });
});

describe("generatePlan - success", () => {
  it("returns the contract response and reserves one slot", async () => {
    const { deps, quota } = mkDeps();
    const r = await run(body(), deps);
    expect(Object.keys(r)).toEqual(["apiVersion", "requestId", "language", "promptVersion", "days", "quota"]);
    expect(r).toMatchObject({ apiVersion: 1, requestId: "7f0c2a9e-6f0e-4c3a-9a43-0b6c4a1f5d11", language: "pl", promptVersion: "plan-v1" });
    expect(r.days).toHaveLength(4);
    expect(r.days[0]!.items.every((i) => i.startTime >= "21:10")).toBe(true);
    expect(r.quota).toEqual({ limit: 5, remainingToday: 4, resetAt: "2026-11-21T23:00:00Z" });
    expect(quota.usage.get("owner")).toMatchObject({ day: "2026-11-21", count: 1 });
    expect(quota.global.get("2026-11-21")).toBe(1);
  });
  it("counts down remainingToday and stops at the per-user limit with limit/resetAt", async () => {
    const { deps } = mkDeps({}, { perUserDailyLimit: 2 });
    expect((await run(body(), deps)).quota.remainingToday).toBe(1);
    expect((await run(body(), deps)).quota.remainingToday).toBe(0);
    expect(await err(run(body(), deps))).toEqual({ code: "limit_exceeded", limit: 2, resetAt: "2026-11-21T23:00:00Z" });
  });
  it("global limit -> ai_unavailable before any model call", async () => {
    const model = echoValidModel();
    const { deps, quota } = mkDeps({ model }, { globalDailyLimit: 1 });
    quota.global.set("2026-11-21", 1);
    expect(await err(run(body(), deps))).toEqual({ code: "ai_unavailable", slotReleased: true });
    expect(model.calls).toHaveLength(0);
  });
});

describe("generatePlan - order and fail-closed", () => {
  it("consents and aiEnabled are checked before the reservation", async () => {
    const reserveQuota = vi.fn();
    const { deps } = mkDeps({ reserveQuota, loadLatestConsents: async () => ({}) });
    expect((await err(run(body(), deps)))?.["code"]).toBe("consent_required");
    const { deps: off } = mkDeps({ reserveQuota }, { aiEnabled: false });
    expect((await err(run(body(), off)))?.["code"]).toBe("ai_unavailable");
    expect(reserveQuota).not.toHaveBeenCalled();
  });
  it("missing AI configuration -> ai_unavailable, configError logged, no reservation", async () => {
    const reserveQuota = vi.fn();
    const { deps } = mkDeps({ model: undefined, reserveQuota });
    expect(await err(run(body(), deps))).toEqual({ code: "ai_unavailable", slotReleased: true });
    expect(reserveQuota).not.toHaveBeenCalled();
    expect(JSON.stringify(logged)).toContain('"configError":"ai_config_invalid"');
  });
});

describe("generatePlan - slot release (contract pkt 2)", () => {
  it("after ai_invalid_response the slot is returned (global counter stays)", async () => {
    const bad = ok({ language: "pl", days: [] });
    const { deps, quota } = mkDeps({ model: scriptedModel([bad, bad]) });
    expect(await err(run(body(), deps))).toEqual({ code: "ai_invalid_response", slotReleased: true });
    expect(quota.usage.get("owner")?.count).toBe(0);
    expect(quota.global.get("2026-11-21")).toBe(1);
  });
  it("after ai_unavailable (400) the slot is returned; after internal it is NOT (contract list, review #8)", async () => {
    const { deps, quota } = mkDeps({ model: scriptedModel([new ModelError("config", "400")]) });
    expect(await err(run(body(), deps))).toEqual({ code: "ai_unavailable", slotReleased: true });
    expect(quota.usage.get("owner")).toMatchObject({ count: 0, released: 1 });
    const { deps: d2, quota: q2 } = mkDeps({ model: scriptedModel([new TypeError(CANARY)]) });
    expect(await err(run(body(), d2))).toEqual({ code: "internal" });
    expect(q2.usage.get("owner")).toMatchObject({ count: 1, released: 0 });
  });
  it("review #2: at most 2 releases per account and day; always-failing requests then use the own limit", async () => {
    const bad = ok({ language: "pl", days: [] });
    const { deps, quota } = mkDeps({ model: scriptedModel(Array(20).fill(bad)) }, { perUserDailyLimit: 2 });
    const codes: unknown[] = [];
    for (let i = 0; i < 6; i++) codes.push((await err(run(body(), deps)))?.["code"]);
    // releases 1-2 return the slot; requests 3-4 consume the limit of 2; then limit_exceeded (no model call)
    expect(codes).toEqual(["ai_invalid_response", "ai_invalid_response", "ai_invalid_response", "ai_invalid_response", "limit_exceeded", "limit_exceeded"]);
    expect(quota.usage.get("owner")).toMatchObject({ count: 2, released: 2 });
    // global fuse counts every generation that reached the model: limit + MAX_RELEASES_PER_DAY = 4
    expect(quota.global.get("2026-11-21")).toBe(4);
  });
  it("a failing release never masks the original error and is logged as a fixed code", async () => {
    const { deps } = mkDeps({
      model: scriptedModel([new ModelError("config", "400")]),
      releaseQuota: async () => {
        throw new Error(CANARY);
      },
    });
    expect(await err(run(body(), deps))).toEqual({ code: "ai_unavailable", slotReleased: false });
    expect(JSON.stringify(logged)).toContain('"quotaRelease":"release_failed"');
    expect(JSON.stringify(logged)).not.toContain(CANARY);
  });
  it("TAM-94: 3rd failure of the day -> slotReleased=false, quotaRelease released x2 then release_capped", async () => {
    const bad = ok({ language: "pl", days: [] });
    const { deps, quota } = mkDeps({ model: scriptedModel(Array(6).fill(bad)) });
    const results: unknown[] = [];
    const releaseLogs: unknown[] = [];
    for (let i = 0; i < 3; i++) {
      logged.length = 0;
      results.push(await err(run(body(), deps)));
      releaseLogs.push(fields().find((f) => f["fn"] === "generatePlan")?.["quotaRelease"]);
    }
    expect(results).toEqual([
      { code: "ai_invalid_response", slotReleased: true },
      { code: "ai_invalid_response", slotReleased: true },
      { code: "ai_invalid_response", slotReleased: false },
    ]);
    expect(releaseLogs).toEqual(["released", "released", "release_capped"]);
    expect(quota.usage.get("owner")).toMatchObject({ count: 1, released: 2 });
  });
  it("TAM-94: ai_unavailable before the reservation -> slotReleased=true, no release attempted, no quotaRelease", async () => {
    const releaseQuota = vi.fn();
    const { deps } = mkDeps({ releaseQuota }, { aiEnabled: false });
    expect(await err(run(body(), deps))).toEqual({ code: "ai_unavailable", slotReleased: true });
    expect(releaseQuota).not.toHaveBeenCalled();
    expect(JSON.stringify(logged)).not.toContain("quotaRelease");
  });
  it("TAM-94: release after midnight (stale day) -> slotReleased=false, quotaRelease release_stale_day", async () => {
    const { deps } = mkDeps({ model: scriptedModel([new ModelError("config", "400")]), releaseQuota: async () => "stale_day" });
    expect(await err(run(body(), deps))).toEqual({ code: "ai_unavailable", slotReleased: false });
    expect(JSON.stringify(logged)).toContain('"quotaRelease":"release_stale_day"');
  });
  it("TAM-94: internal carries no slotReleased", async () => {
    const { deps } = mkDeps({ model: scriptedModel([new TypeError(CANARY)]) });
    expect(await err(run(body(), deps))).toEqual({ code: "internal" });
  });
  it("limit_exceeded does not touch the counter", async () => {
    const releaseQuota = vi.fn();
    const { deps, quota } = mkDeps({ releaseQuota }, { perUserDailyLimit: 1 });
    quota.usage.set("owner", { day: "2026-11-21", count: 1, expireAt: NOW });
    expect((await err(run(body(), deps)))?.["code"]).toBe("limit_exceeded");
    expect(releaseQuota).not.toHaveBeenCalled();
  });
});

describe("generatePlan - ai_busy (ADR-0016 pkt 6-8, posrednik-api.md pkt 2 rule 7)", () => {
  const e429 = () => new ModelError("retryable", "429");
  const noSleep = async () => {};
  const busyModel = (n: number) => scriptedModel(Array.from({ length: n }, e429));

  it("429 x 3 -> ai_busy, retryAfterSec=60, slotReleased=true; account AND global slot back, released untouched", async () => {
    const { deps, quota } = mkDeps({ model: busyModel(3), sleep: noSleep });
    expect(await err(run(body(), deps))).toEqual({ code: "ai_busy", retryAfterSec: 60, slotReleased: true });
    expect(quota.usage.get("owner")).toMatchObject({ count: 0, released: 0, busyReleased: 1 });
    expect(quota.global.get("2026-11-21")).toBe(0);
    const final = fields().find((f) => f["fn"] === "generatePlan");
    expect(final).toMatchObject({ result: "error", errorCode: "ai_busy", calls: 3, stopReason: "busy", quotaRelease: "busy_released" });
    const attempts = fields().filter((f) => f["fn"] === "generatePlan.attempt");
    expect(attempts.map((a) => [a["billable"], typeof a["waitMs"]])).toEqual([[false, "number"], [false, "number"], [false, "number"]]);
    // ai_busy is an expected refusal: WARNING, not ERROR (no stack trace in Error Reporting)
    expect(logged.find((a) => (a[1] as Record<string, unknown>)["fn"] === "generatePlan")?.[0]).toBe("fn_error");
  });

  it("ai_busy does not use the 2 ordinary releases: after 2 releases an ai_busy still returns the slot", async () => {
    const bad = ok({ language: "pl", days: [] });
    const { deps, quota } = mkDeps({ model: scriptedModel([bad, bad, bad, bad, e429(), e429(), e429()]), sleep: noSleep });
    expect((await err(run(body(), deps)))?.["slotReleased"]).toBe(true);
    expect((await err(run(body(), deps)))?.["slotReleased"]).toBe(true);
    expect(await err(run(body(), deps))).toEqual({ code: "ai_busy", retryAfterSec: 60, slotReleased: true });
    expect(quota.usage.get("owner")).toMatchObject({ count: 0, released: 2, busyReleased: 1 });
    // two ordinary failures keep their global slots (rule 4); the ai_busy one is returned
    expect(quota.global.get("2026-11-21")).toBe(2);
  });

  it("fuse: the 11th ai_busy of the day -> slotReleased=false, quotaRelease busy_capped, both slots stay used", async () => {
    const { deps, quota } = mkDeps({ model: busyModel(33), sleep: noSleep }, { perUserDailyLimit: 5 });
    const results: unknown[] = [];
    for (let i = 0; i < 11; i++) {
      logged.length = 0;
      results.push(await err(run(body(), deps)));
    }
    expect(results.slice(0, 10).every((r) => (r as { slotReleased: boolean }).slotReleased)).toBe(true);
    expect(results[10]).toEqual({ code: "ai_busy", retryAfterSec: 60, slotReleased: false });
    expect(fields().find((f) => f["fn"] === "generatePlan")?.["quotaRelease"]).toBe("busy_capped");
    expect(quota.usage.get("owner")).toMatchObject({ count: 1, released: 0, busyReleased: 10 });
    expect(quota.global.get("2026-11-21")).toBe(1);
  });

  it("rule 5: ai_busy released after midnight -> slotReleased=false, release_stale_day", async () => {
    const { deps } = mkDeps({ model: busyModel(3), sleep: noSleep, releaseBusyQuota: async () => "stale_day" });
    expect(await err(run(body(), deps))).toEqual({ code: "ai_busy", retryAfterSec: 60, slotReleased: false });
    expect(JSON.stringify(logged)).toContain('"quotaRelease":"release_stale_day"');
  });

  it("rule 6: a failing ai_busy release keeps the code, slotReleased=false, release_failed", async () => {
    const { deps } = mkDeps({
      model: busyModel(3),
      sleep: noSleep,
      releaseBusyQuota: async () => {
        throw new Error(CANARY);
      },
    });
    expect(await err(run(body(), deps))).toEqual({ code: "ai_busy", retryAfterSec: 60, slotReleased: false });
    expect(JSON.stringify(logged)).toContain('"quotaRelease":"release_failed"');
    expect(JSON.stringify(logged)).not.toContain(CANARY);
  });

  it("timeout -> 429 -> 429 -> ai_unavailable with the ordinary release (global stays), no retryAfterSec", async () => {
    const releaseBusyQuota = vi.fn();
    const { deps, quota } = mkDeps({
      model: scriptedModel([new ModelError("retryable", "timeout"), e429(), e429()]),
      sleep: noSleep,
      releaseBusyQuota,
    });
    expect(await err(run(body(), deps))).toEqual({ code: "ai_unavailable", slotReleased: true });
    expect(releaseBusyQuota).not.toHaveBeenCalled();
    expect(quota.usage.get("owner")).toMatchObject({ count: 0, released: 1, busyReleased: 0 });
    expect(quota.global.get("2026-11-21")).toBe(1);
    expect(fields().find((f) => f["fn"] === "generatePlan")).toMatchObject({ calls: 3, stopReason: "max_calls", quotaRelease: "released" });
  });

  it("429 -> ok: plan returned, one slot used, final log calls=2 stopReason=ok", async () => {
    const echo = echoValidModel();
    const { deps, quota } = mkDeps({ model: scriptedModel([e429(), (c) => echo.generate(c)]), sleep: noSleep });
    expect((await run(body(), deps)).days).toHaveLength(4);
    expect(quota.usage.get("owner")).toMatchObject({ count: 1 });
    expect(fields().find((f) => f["fn"] === "generatePlan")).toMatchObject({ result: "ok", calls: 2, stopReason: "ok", attempts: 2 });
  });
});

describe("generatePlan - logs (sekcja 6)", () => {
  it("attempt logs carry metadata only: no prompt, trip data or model output", async () => {
    const echo = echoValidModel();
    const model = scriptedModel([ok({ language: "pl", days: [{ dayNumber: 1, title: CANARY, items: [] }] }), (call) => echo.generate(call)]);
    const { deps } = mkDeps({ model });
    await run(body(), deps);
    const all = JSON.stringify(logged);
    expect(all).not.toContain(CANARY);
    expect(all).not.toContain("Baixa");
    expect(all).not.toContain("dayTargets");
    const attempts = fields().filter((f) => f["fn"] === "generatePlan.attempt");
    expect(attempts.map((a) => a["outcome"])).toEqual(["invalid", "ok"]);
    expect(attempts[0]).toMatchObject({ attempt: 1, validationErrors: "days_count", aiModel: "gemini-3.1-flash-lite", aiLocation: "eu" });
    expect(fields().find((f) => f["fn"] === "generatePlan")).toMatchObject({ result: "ok", attempts: 2, days: 4 });
  });
});

describe("generatePlan - contention on the quota reservation (TAM-115, ADR-0018 pkt 4-9)", () => {
  /** reserveQuota after exhausted SDK attempts: `runs` transaction runs, then the SDK error. */
  const exhausted = (error: unknown, runs = QUOTA_TX_MAX_ATTEMPTS) =>
    vi.fn(async (_u: string, _l: unknown, _n: Date, onTry?: () => void): Promise<ReservationPlan> => {
      for (let i = 0; i < runs; i++) onTry?.();
      throw error;
    });
  const aborted = () => Object.assign(new Error(`10 ABORTED ${CANARY}`), { code: 10 });

  it.each([
    ["gRPC ABORTED (10)", aborted()],
    ["HTTP 409", { code: 409 }],
  ])("%s -> ai_busy, retryAfterSec=60, slotReleased=true; no model call, no release", async (_n, error) => {
    const model = echoValidModel();
    const releaseQuota = vi.fn();
    const releaseBusyQuota = vi.fn();
    const { deps, quota } = mkDeps({ model, reserveQuota: exhausted(error), releaseQuota, releaseBusyQuota });
    expect(await err(run(body(), deps))).toEqual({ code: "ai_busy", retryAfterSec: 60, slotReleased: true });
    expect(model.calls).toHaveLength(0);
    expect(releaseQuota).not.toHaveBeenCalled();
    expect(releaseBusyQuota).not.toHaveBeenCalled();
    expect(quota.usage.size).toBe(0);
    const final = fields().find((f) => f["fn"] === "generatePlan")!;
    expect(final).toMatchObject({ result: "error", errorCode: "ai_busy", stopReason: "contention", reserveTries: 3 });
    expect(final).not.toHaveProperty("quotaRelease");
    expect(final).not.toHaveProperty("calls");
    expect(JSON.stringify(logged)).not.toContain(CANARY);
  });

  it("any other reservation error (UNAVAILABLE 14) stays internal, without stopReason", async () => {
    const { deps } = mkDeps({ reserveQuota: exhausted({ code: 14 }) });
    expect(await err(run(body(), deps))).toEqual({ code: "internal" });
    const final = fields().find((f) => f["fn"] === "generatePlan")!;
    expect(final).toMatchObject({ errorCode: "14", reserveTries: 3 }); // classifyError logs the code only
    expect(final).not.toHaveProperty("stopReason");
  });

  it.each([1, 2])("success after %i aborted run(s): plan returned, one slot used, reserveTries counts every run", async (abortedRuns) => {
    const { deps, quota } = mkDeps();
    let runs = 0;
    // SDK-like: every run executes fn; the first `abortedRuns` commits fail with ABORTED and are rolled back.
    const runner: QuotaTxRunner<null> = {
      async runTransaction<T>(fn: (tx: null) => Promise<T>, options: { maxAttempts: number }): Promise<T> {
        for (let i = 1; ; i++) {
          runs++;
          const usage = new Map(quota.usage);
          const global = new Map(quota.global);
          const result = await fn(null);
          if (i > abortedRuns) return result;
          quota.usage.clear();
          usage.forEach((v, k) => quota.usage.set(k, v));
          quota.global.clear();
          global.forEach((v, k) => quota.global.set(k, v));
          if (i >= options.maxAttempts) throw aborted();
        }
      },
    };
    deps.reserveQuota = (uid, limits, now, onTry) =>
      runQuotaTransaction(runner, async () => quota.reserveQuota(uid, limits, now), onTry);
    const r = await run(body(), deps);
    expect(r.quota.remainingToday).toBe(4);
    expect(quota.usage.get("owner")).toMatchObject({ count: 1 });
    expect(quota.global.get("2026-11-21")).toBe(1);
    expect(runs).toBe(abortedRuns + 1);
    expect(fields().find((f) => f["fn"] === "generatePlan")).toMatchObject({ result: "ok", reserveTries: abortedRuns + 1 });
  });

  it("3 aborted runs through the SDK-like runner -> ai_busy after exactly 3 runs", async () => {
    let runs = 0;
    const runner: QuotaTxRunner<null> = {
      async runTransaction<T>(fn: (tx: null) => Promise<T>, options: { maxAttempts: number }): Promise<T> {
        for (let i = 1; i <= options.maxAttempts; i++) {
          runs++;
          await fn(null);
        }
        throw aborted();
      },
    };
    const model = echoValidModel();
    const { deps } = mkDeps({ model });
    deps.reserveQuota = (_u, _l, _n, onTry) => runQuotaTransaction(runner, async () => ({}) as ReservationPlan, onTry);
    expect(await err(run(body(), deps))).toEqual({ code: "ai_busy", retryAfterSec: 60, slotReleased: true });
    expect(runs).toBe(3);
    expect(model.calls).toHaveLength(0);
    expect(fields().find((f) => f["fn"] === "generatePlan")).toMatchObject({ stopReason: "contention", reserveTries: 3 });
  });

  it("ordinary reservation logs reserveTries = 1", async () => {
    const { deps } = mkDeps();
    await run(body(), deps);
    expect(fields().find((f) => f["fn"] === "generatePlan")).toMatchObject({ result: "ok", reserveTries: 1 });
  });

  it("refusals before the reservation (aiEnabled=false) have no reserveTries", async () => {
    const { deps } = mkDeps({}, { aiEnabled: false });
    await err(run(body(), deps));
    expect(fields().find((f) => f["fn"] === "generatePlan")).not.toHaveProperty("reserveTries");
  });
});

describe("generatePlan - configError when there is no model (TAM-115, ADR-0018 pkt 12)", () => {
  it.each([
    [undefined, "ai_config_invalid"],
    ["ai_config_invalid", "ai_config_invalid"],
    ["ai_endpoint_override_rejected", "ai_endpoint_override_rejected"],
  ] as const)("deps.modelConfigError=%s -> configError %s, ai_unavailable with slotReleased, no reservation", async (code, logged_) => {
    const reserveQuota = vi.fn();
    const { deps } = mkDeps({ model: undefined, modelConfigError: code, reserveQuota });
    expect(await err(run(body(), deps))).toEqual({ code: "ai_unavailable", slotReleased: true });
    expect(reserveQuota).not.toHaveBeenCalled();
    const final = fields().find((f) => f["fn"] === "generatePlan")!;
    expect(final).toMatchObject({ errorCode: "ai_unavailable", configError: logged_ });
    expect(JSON.stringify(logged)).not.toMatch(/https?:\/\//);
  });
});
