// Retry policy with a scripted model (0 paid calls).
import { describe, expect, it } from "vitest";
import { ModelError } from "../src/ai.js";
import { generateValidPlan, retryBackoffMs, RETRY_BACKOFF_MS, type AttemptLog } from "../src/generate.js";
import { computeDayTargets } from "../src/plan-targets.js";
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

describe("generateValidPlan", () => {
  it("first valid answer: 1 attempt, no retry", async () => {
    const m = scriptedModel([good]);
    const logs: AttemptLog[] = [];
    const r = await generateValidPlan(request, m, { onAttempt: (l) => logs.push(l) });
    expect(r.attempts).toBe(1);
    expect(m.calls).toHaveLength(1);
    expect(logs).toEqual([
      expect.objectContaining({ attempt: 1, outcome: "ok", aiModel: "gemini-3.1-flash-lite", aiLocation: "eu", promptVersion: "plan-v2", tokensIn: 900, tokensOut: 1500, tokensThought: 0 }),
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

  it("backoff is 1-2 s with jitter", () => {
    expect(retryBackoffMs(() => 0)).toBe(1000);
    expect(retryBackoffMs(() => 1)).toBe(2000);
    expect(retryBackoffMs(() => 0.5)).toBe(1500);
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

  it("429/503/timeout -> one retry with the same request; twice -> ai_unavailable", async () => {
    const m = scriptedModel([new ModelError("retryable", "429"), good]);
    const waits: number[] = [];
    expect((await generateValidPlan(request, m, { sleep: async (ms) => void waits.push(ms) })).attempts).toBe(2);
    // review #136 #7: 1-2 s backoff before the retry
    expect(waits).toHaveLength(1);
    expect(waits[0]).toBeGreaterThanOrEqual(RETRY_BACKOFF_MS.min);
    expect(waits[0]).toBeLessThanOrEqual(RETRY_BACKOFF_MS.max);
    expect(m.calls[0]!.userText).toBe(m.calls[1]!.userText);
    const m2 = scriptedModel([new ModelError("retryable", "503"), new ModelError("retryable", "timeout")]);
    expect(await code(generateValidPlan(request, m2, { sleep: noSleep }))).toBe("ai_unavailable");
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

  it("sends the simplified schema and the plan-v2 system instruction", async () => {
    const m = scriptedModel([good]);
    await generateValidPlan(request, m);
    expect(m.calls[0]!.systemInstruction).toContain("dayTargets");
    expect(JSON.stringify(m.calls[0]!.responseSchema)).not.toContain('"items":{"type":"ARRAY","maxItems"');
  });
});
