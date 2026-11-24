// Retry policy with a scripted model (0 paid calls).
import { describe, expect, it } from "vitest";
import { ModelError } from "../src/ai.js";
import { AppError } from "../src/errors.js";
import {
  GENERATION_BUDGET_MS,
  generateValidPlan,
  MAX_BILLABLE_ATTEMPTS,
  MAX_CALLS,
  retryBackoffMs,
  type AttemptLog,
  type GenerationSummary,
} from "../src/generate.js";
import { computeDayTargets } from "../src/plan-targets.js";
import { resolvePrompt } from "../src/prompt/index.js";
import * as v1 from "../src/prompt/plan-v1.js";
import * as v2 from "../src/prompt/plan-v2.js";
import { parseGeneratePlan } from "../src/schemas.js";
import { ok, scriptedModel, validOutput } from "./helpers/fakes.js";

const request = parseGeneratePlan(
  {
    apiVersion: 1,
    requestId: "7f0c2a9e-6f0e-4c3a-9a43-0b6c4a1f5d11",
    planLanguage: "pl",
    trip: { destination: "Rzym", lodging: "Trastevere", days: 5, arrival: { mode: "flight", date: "2027-06-01", time: "13:00", airport: "FCO" } },
    preferences: { pace: "intense" },
    testData: true,
  },
  new Date("2026-11-21T10:00:00Z"),
);
const targets = computeDayTargets(request);
const good = ok(validOutput(targets));
const shortDay3 = ok(validOutput(targets, "pl", (t) => (t.dayNumber === 3 ? 5 : t.maxItems)));
const noSleep = async () => {};
const code = (p: Promise<unknown>) => p.then(() => "no-error", (e: { appCode?: string }) => e.appCode ?? "other");

const e429 = () => new ModelError("retryable", "429");
const timeout = () => new ModelError("retryable", "timeout");

/** Fake time: sleep advances the clock; a model step made by after() takes `ms` before answering. */
function fakeTime(random = 0.5) {
  let now = 1_000_000;
  const waits: number[] = [];
  return {
    clock: () => now,
    sleep: async (ms: number) => {
      waits.push(ms);
      now += ms;
    },
    random: () => random,
    waits,
    after: (ms: number, step: Error | ReturnType<typeof ok>) => () => {
      now += ms;
      if (step instanceof Error) throw step;
      return step;
    },
  };
}

function runWith(steps: Parameters<typeof scriptedModel>[0], t = fakeTime()) {
  const m = scriptedModel(steps);
  const logs: AttemptLog[] = [];
  const summaries: GenerationSummary[] = [];
  const p = generateValidPlan(request, m, {
    clock: t.clock,
    sleep: t.sleep,
    random: t.random,
    onAttempt: (l) => logs.push(l),
    onFinish: (s) => summaries.push(s),
  });
  return { m, logs, summaries, p, t };
}

const hintsOf = (m: ReturnType<typeof scriptedModel>, i: number) => JSON.parse(m.calls[i]!.userText.split("\n")[1]!).previousAttemptErrors;

describe("generateValidPlan - ADR-0016 (429, backoff, budget, ai_busy)", () => {
  it("limits: 3 calls, 2 billable, 100 s budget", () => {
    expect([MAX_CALLS, MAX_BILLABLE_ATTEMPTS, GENERATION_BUDGET_MS]).toEqual([3, 2, 100_000]);
  });

  it("429 -> 429 -> ok: third call, waits 2-4 s and 4-8 s, logs waitMs/billable, calls=3 stopReason=ok", async () => {
    const r = runWith([e429(), e429(), good], fakeTime(0.25));
    expect((await r.p).attempts).toBe(3);
    expect(r.t.waits).toEqual([2500, 5000]);
    expect(r.logs.map((l) => [l.attempt, l.billable, l.waitMs, l.outcome])).toEqual([
      [1, false, 0, "model_retryable"],
      [2, false, 2500, "model_retryable"],
      [3, true, 5000, "ok"],
    ]);
    expect(r.summaries).toEqual([{ calls: 3, stopReason: "ok" }]);
  });

  it("429 x 3 -> ai_busy with retryAfterSec=60 (0 billable), stopReason=busy", async () => {
    const r = runWith([e429(), e429(), e429(), good]);
    const err = await r.p.then(() => undefined, (e: AppError) => e);
    expect(err).toBeInstanceOf(AppError);
    expect(err?.appCode).toBe("ai_busy");
    expect(err?.details).toEqual({ retryAfterSec: 60 });
    expect(r.m.calls).toHaveLength(3);
    expect(r.logs.every((l) => !l.billable)).toBe(true);
    expect(r.summaries).toEqual([{ calls: 3, stopReason: "busy" }]);
  });

  it("invalid -> 429 -> ok: no wait after the invalid answer, the issue list survives the 429 (pkt 5)", async () => {
    const r = runWith([shortDay3, e429(), good]);
    expect((await r.p).attempts).toBe(3);
    expect(hintsOf(r.m, 1)).toEqual(["day 3: 5 items, required 6-7"]);
    expect(hintsOf(r.m, 2)).toEqual(["day 3: 5 items, required 6-7"]);
    expect(r.logs.map((l) => [l.billable, l.waitMs])).toEqual([[true, 0], [false, 0], [true, 6000]]);
  });

  it("429 -> invalid -> ok: third call with the issue list", async () => {
    const r = runWith([e429(), shortDay3, good]);
    expect((await r.p).attempts).toBe(3);
    expect(hintsOf(r.m, 2)).toEqual(["day 3: 5 items, required 6-7"]);
  });

  it("timeout -> 429 -> 429 -> ai_unavailable (a billable attempt, so not ai_busy), stopReason=max_calls", async () => {
    const r = runWith([timeout(), e429(), e429(), good]);
    expect(await code(r.p)).toBe("ai_unavailable");
    expect(r.m.calls).toHaveLength(3);
    expect(r.summaries).toEqual([{ calls: 3, stopReason: "max_calls" }]);
  });

  it("invalid -> 429 -> 429 -> ai_unavailable (by the last error)", async () => {
    const r = runWith([shortDay3, e429(), e429(), good]);
    expect(await code(r.p)).toBe("ai_unavailable");
    expect(r.m.calls).toHaveLength(3);
  });

  it("timeout (45 s) -> 429: no third call when < 45 s of the budget is left, stopReason=time_budget", async () => {
    const t = fakeTime(1); // waits 4 s and 8 s
    const r = runWith([t.after(45_000, timeout()), t.after(1_000, e429()), good], t);
    expect(await code(r.p)).toBe("ai_unavailable");
    expect(r.m.calls).toHaveLength(2);
    expect(t.waits).toEqual([4000]); // the 8 s wait is not started: 100 - 50 - 8 = 42 s < 45 s
    expect(r.summaries).toEqual([{ calls: 2, stopReason: "time_budget" }]);
  });

  it("timeout (45 s) -> timeout (45 s): today's 94 s path still fits the budget", async () => {
    const t = fakeTime(1);
    const r = runWith([t.after(45_000, timeout()), t.after(45_000, timeout()), good], t);
    expect(await code(r.p)).toBe("ai_unavailable");
    expect(r.m.calls).toHaveLength(2);
    expect(r.summaries).toEqual([{ calls: 2, stopReason: "max_billable" }]);
  });

  it("slow 429s that exhaust the budget still end as ai_busy (0 billable), stopReason=time_budget", async () => {
    const t = fakeTime(0);
    const r = runWith([t.after(30_000, e429()), t.after(30_000, e429()), good], t);
    expect(await code(r.p)).toBe("ai_busy");
    expect(r.m.calls).toHaveLength(2);
    expect(r.summaries).toEqual([{ calls: 2, stopReason: "time_budget" }]);
  });

  it("timeout -> timeout, 5xx -> 5xx: 2 calls (2 billable), ai_unavailable, stopReason=max_billable", async () => {
    for (const steps of [[timeout(), timeout(), good], [new ModelError("retryable", "503"), new ModelError("retryable", "500"), good]]) {
      const r = runWith(steps);
      expect(await code(r.p)).toBe("ai_unavailable");
      expect(r.m.calls).toHaveLength(2);
      expect(r.summaries).toEqual([{ calls: 2, stopReason: "max_billable" }]);
    }
  });

  it("invalid -> invalid: 2 calls, ai_invalid_response, stopReason=max_billable", async () => {
    const r = runWith([shortDay3, shortDay3, good]);
    expect(await code(r.p)).toBe("ai_invalid_response");
    expect(r.m.calls).toHaveLength(2);
    expect(r.summaries).toEqual([{ calls: 2, stopReason: "max_billable" }]);
  });

  it("HTTP 400 after a 429: no retry, ai_unavailable, stopReason=config", async () => {
    const r = runWith([e429(), new ModelError("config", "400"), good]);
    expect(await code(r.p)).toBe("ai_unavailable");
    expect(r.m.calls).toHaveLength(2);
    expect(r.summaries).toEqual([{ calls: 2, stopReason: "config" }]);
  });

  it("blocked answer: stopReason=invalid, 1 call", async () => {
    const r = runWith([ok(validOutput(targets), "SAFETY"), good]);
    expect(await code(r.p)).toBe("ai_invalid_response");
    expect(r.summaries).toEqual([{ calls: 1, stopReason: "invalid" }]);
  });

  it("408 and bad_body are billable retryable errors (only 429 is not)", async () => {
    const r = runWith([new ModelError("retryable", "408"), new ModelError("retryable", "bad_body"), good]);
    expect(await code(r.p)).toBe("ai_unavailable");
    expect(r.logs.map((l) => l.billable)).toEqual([true, true]);
  });
});

describe("generateValidPlan", () => {
  it("first valid answer: 1 attempt, no retry", async () => {
    const m = scriptedModel([good]);
    const logs: AttemptLog[] = [];
    const r = await generateValidPlan(request, m, { onAttempt: (l) => logs.push(l) });
    expect(r.attempts).toBe(1);
    expect(m.calls).toHaveLength(1);
    expect(logs).toEqual([
      expect.objectContaining({ attempt: 1, waitMs: 0, billable: true, outcome: "ok", aiModel: "gemini-3.1-flash-lite", aiLocation: "eu", promptVersion: "plan-v1", tokensIn: 900, tokensOut: 1500, tokensThought: 0 }),
    ]);
  });

  it("invalid then valid: second attempt gets the list of errors in the data turn", async () => {
    const m = scriptedModel([shortDay3, good]);
    const logs: AttemptLog[] = [];
    const r = await generateValidPlan(request, m, { onAttempt: (l) => logs.push(l) });
    expect(r.attempts).toBe(2);
    const second = JSON.parse(m.calls[1]!.userText.split("\n")[1]!);
    expect(second.previousAttemptErrors).toEqual(["day 3: 5 items, required 6-7"]);
    expect(JSON.parse(m.calls[0]!.userText.split("\n")[1]!)).not.toHaveProperty("previousAttemptErrors");
    expect(logs.map((l) => [l.outcome, l.validationErrors])).toEqual([["invalid", "items_count@day3"], ["ok", undefined]]);
  });

  it("review #136 #5: a blocked answer (SAFETY) ends at once, no second paid call", async () => {
    const m = scriptedModel([ok(validOutput(targets), "SAFETY"), good]);
    const logs: AttemptLog[] = [];
    expect(await code(generateValidPlan(request, m, { onAttempt: (l) => logs.push(l) }))).toBe("ai_invalid_response");
    expect(m.calls).toHaveLength(1);
    expect(logs[0]).toMatchObject({ outcome: "invalid", validationErrors: "finish_SAFETY" });
  });

  it("ADR-0016 pkt 3: backoff 2-4 s before call 2 and 4-8 s before call 3 (uniform, clamped)", () => {
    expect(retryBackoffMs(2, () => 0)).toBe(2000);
    expect(retryBackoffMs(2, () => 1)).toBe(4000);
    expect(retryBackoffMs(2, () => 0.5)).toBe(3000);
    expect(retryBackoffMs(3, () => 0)).toBe(4000);
    expect(retryBackoffMs(3, () => 1)).toBe(8000);
    expect(retryBackoffMs(3, () => -1)).toBe(4000);
    expect(retryBackoffMs(3, () => 5)).toBe(8000);
    for (let i = 0; i < 50; i++) {
      const w = retryBackoffMs(3);
      expect(w).toBeGreaterThanOrEqual(4000);
      expect(w).toBeLessThanOrEqual(8000);
    }
  });

  it("two invalid answers -> ai_invalid_response (max 2 calls)", async () => {
    const m = scriptedModel([shortDay3, ok(validOutput(targets), "MAX_TOKENS"), good]);
    expect(await code(generateValidPlan(request, m))).toBe("ai_invalid_response");
    expect(m.calls).toHaveLength(2);
  });

  it("HTTP 400 (configuration) -> ai_unavailable, no retry", async () => {
    const m = scriptedModel([new ModelError("config", "400"), good]);
    const logs: AttemptLog[] = [];
    expect(await code(generateValidPlan(request, m, { onAttempt: (l) => logs.push(l) }))).toBe("ai_unavailable");
    expect(m.calls).toHaveLength(1);
    expect(logs[0]).toMatchObject({ outcome: "model_config", modelError: "400" });
  });

  it("429 -> ok: one retry with the same request after 2-4 s; the 429 call is not billable", async () => {
    const m = scriptedModel([e429(), good]);
    const waits: number[] = [];
    const logs: AttemptLog[] = [];
    const r = await generateValidPlan(request, m, { sleep: async (ms) => void waits.push(ms), onAttempt: (l) => logs.push(l) });
    expect(r.attempts).toBe(2);
    expect(waits).toHaveLength(1);
    expect(waits[0]).toBeGreaterThanOrEqual(2000);
    expect(waits[0]).toBeLessThanOrEqual(4000);
    expect(m.calls[0]!.userText).toBe(m.calls[1]!.userText);
    expect(logs.map((l) => [l.attempt, l.billable, l.waitMs])).toEqual([[1, false, 0], [2, true, waits[0]]]);
  });

  it("invalid then unavailable -> ai_unavailable; unexpected errors propagate", async () => {
    expect(await code(generateValidPlan(request, scriptedModel([shortDay3, new ModelError("retryable", "503")]), { sleep: noSleep }))).toBe("ai_unavailable");
    await expect(generateValidPlan(request, scriptedModel([new TypeError("boom")]))).rejects.toBeInstanceOf(TypeError);
  });

  it("modelVersion and error codes outside the safe pattern are not logged", async () => {
    const logs: AttemptLog[] = [];
    const weird = { ...good, modelVersion: "has spaces and \"quotes\"" };
    await generateValidPlan(request, scriptedModel([weird]), { onAttempt: (l) => logs.push(l) });
    expect(logs[0]?.modelVersion).toBeUndefined();
    const logs2: AttemptLog[] = [];
    await code(generateValidPlan(request, scriptedModel([new ModelError("config", "bad code with spaces")]), { onAttempt: (l) => logs2.push(l) }));
    expect(logs2[0]?.modelError).toBe("unknown");
  });

  it("TAM-95: a repeated place is logged as a quality warning, without a second (paid) call", async () => {
    const body = validOutput(targets);
    body.days[1]!.items[0]!.name = "Campo de' Fiori";
    body.days[3]!.items[0]!.name = "Campo de' Fiori Morning Market";
    const m = scriptedModel([ok(body), good]);
    const logs: AttemptLog[] = [];
    const r = await generateValidPlan(request, m, { onAttempt: (l) => logs.push(l) });
    expect(r.attempts).toBe(1);
    expect(m.calls).toHaveLength(1);
    expect(logs).toEqual([expect.objectContaining({ outcome: "ok", qualityWarnings: "dup_place@day4" })]);
    expect(JSON.stringify(logs)).not.toContain("Fiori");
  });

  it("prompt option: plan-v2 is sent and logged only when selected (review PR #148 #2)", async () => {
    const m = scriptedModel([good]);
    const logs: AttemptLog[] = [];
    const r = await generateValidPlan(request, m, { prompt: resolvePrompt("plan-v2"), onAttempt: (l) => logs.push(l) });
    expect(m.calls[0]!.systemInstruction).toBe(v2.SYSTEM_INSTRUCTION);
    expect(r.promptVersion).toBe("plan-v2");
    expect(logs[0]?.promptVersion).toBe("plan-v2");
    const d = scriptedModel([good]);
    expect((await generateValidPlan(request, d)).promptVersion).toBe("plan-v1");
    expect(d.calls[0]!.systemInstruction).toBe(v1.SYSTEM_INSTRUCTION);
  });

  it("a plan without repeats logs no qualityWarnings field", async () => {
    const logs: AttemptLog[] = [];
    await generateValidPlan(request, scriptedModel([good]), { onAttempt: (l) => logs.push(l) });
    expect(logs[0]).not.toHaveProperty("qualityWarnings");
  });

  it("sends the simplified schema and the plan-v1 system instruction (default)", async () => {
    const m = scriptedModel([good]);
    await generateValidPlan(request, m);
    expect(m.calls[0]!.systemInstruction).toContain("dayTargets");
    expect(JSON.stringify(m.calls[0]!.responseSchema)).not.toContain('"items":{"type":"ARRAY","maxItems"');
  });
});
