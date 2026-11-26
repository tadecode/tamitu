// TAM-89: the emulator fake of Vertex, driven through the REAL provider (createPlanModel in emulator mode,
// real fetch over 127.0.0.1) and the real generation loop. No emulator, no external network, 0 paid calls.
import { afterAll, beforeAll, beforeEach, describe, expect, it } from "vitest";
import { createPlanModel, type FetchLike, type PlanModel } from "../src/ai.js";
import { AppError } from "../src/errors.js";
import { generateValidPlan } from "../src/generate.js";
import { parseGeneratePlan } from "../src/schemas.js";
import { startVertexFake, type Scenario, type VertexFake } from "./emulator/vertex-fake.mjs";

const request = parseGeneratePlan(
  {
    apiVersion: 1,
    requestId: "7f0c2a9e-6f0e-4c3a-9a43-0b6c4a1f5d11",
    planLanguage: "en",
    trip: { destination: "Rzym", lodging: "Trastevere", days: 3, arrival: { mode: "flight", date: "2027-06-01", time: "13:00", airport: "FCO" } },
    preferences: { pace: "moderate" },
    testData: true,
  },
  new Date("2026-11-21T10:00:00Z"),
);

let fake: VertexFake;
let model: PlanModel;

beforeAll(async () => {
  fake = await startVertexFake({ port: 0 });
  model = createPlanModel(
    {
      AI_MODEL_ID: "gemini-3.1-flash-lite",
      AI_LOCATION: "eu",
      GCLOUD_PROJECT: "demo-tamitu-qa",
      FUNCTIONS_EMULATOR: "true",
      AI_ENDPOINT_OVERRIDE: fake.url,
      AI_ATTEMPT_TIMEOUT_MS: "200",
    },
    {
      fetch: fetch as unknown as FetchLike,
      adcToken: () => Promise.reject(new Error("ADC must not be used in emulator mode")),
    },
  )!;
});
afterAll(() => fake.close());
beforeEach(() => fake.reset());

/** No real backoff waits (2-8 s) in unit tests. */
const run = () => generateValidPlan(request, model, { sleep: async () => {} });

async function appCode(p: Promise<unknown>): Promise<string> {
  try {
    await p;
    return "ok";
  } catch (e) {
    if (e instanceof AppError) return e.appCode;
    throw e;
  }
}

describe("vertex-fake through the real provider and generation loop", () => {
  it("valid (default): plan passes the real validator in one call; path carries model and location", async () => {
    const r = await run();
    expect(r.plan.language).toBe("en");
    expect(r.plan.days).toHaveLength(3);
    expect(fake.calls).toEqual([{ n: 1, scenario: "valid", status: 200, location: "eu", model: "gemini-3.1-flash-lite", hints: false }]);
  });

  it.each<[Scenario, string, number[]]>([
    ["invalid", "ai_invalid_response", [200, 200]],
    ["blocked", "ai_invalid_response", [200]],
    ["busy", "ai_busy", [429, 429, 429]],
    ["server_error", "ai_unavailable", [503, 503]],
    ["bad_body", "ai_unavailable", [200, 200]],
    ["timeout", "ai_unavailable", [0, 0]],
    ["config_error", "ai_unavailable", [403]],
  ])("default %s -> %s, statuses %j", async (scenario, code, statuses) => {
    fake.setDefault(scenario);
    expect(await appCode(run())).toBe(code);
    expect(fake.calls.map((c) => c.status)).toEqual(statuses);
  });

  it("queue: invalid then valid -> ok on the 2nd call, which carries the issue list", async () => {
    fake.enqueue("invalid");
    expect(await appCode(run())).toBe("ok");
    expect(fake.calls.map((c) => [c.scenario, c.hints])).toEqual([
      ["invalid", false],
      ["valid", true],
    ]);
  });

  it("queue: busy, busy, valid -> ok after two 429 (not billable)", async () => {
    fake.enqueue("busy", "busy");
    expect(await appCode(run())).toBe("ok");
    expect(fake.calls.map((c) => c.status)).toEqual([429, 429, 200]);
  });

  it("HTTP control endpoint sets the queue; a wrong token is refused", async () => {
    const r = await fetch(`${fake.url}/__fake/control`, { method: "POST", body: JSON.stringify({ queue: ["server_error"] }) });
    expect(r.status).toBe(200);
    expect(fake.queue).toEqual(["server_error"]);
    const bad = await fetch(`${fake.url}/v1/projects/demo-x/locations/eu/publishers/google/models/m:generateContent`, {
      method: "POST",
      headers: { authorization: "Bearer real-looking-token" },
      body: "{}",
    });
    expect(bad.status).toBe(401);
    expect(() => fake.enqueue("nope" as Scenario)).toThrow(/unknown scenario/);
  });
});
