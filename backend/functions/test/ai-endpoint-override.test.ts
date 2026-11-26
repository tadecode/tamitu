// TAM-89: AI_ENDPOINT_OVERRIDE is accepted only in the Functions emulator (demo-* project, loopback URL).
// Fake fetch and fake token providers: 0 network calls, 0 paid calls.
import { describe, expect, it, vi } from "vitest";
import {
  createPlanModel,
  EMULATOR_FAKE_TOKEN,
  parseAiEndpointOverride,
  type FetchLike,
} from "../src/ai.js";

const ai = { AI_MODEL_ID: "gemini-3.1-flash-lite", AI_LOCATION: "eu" };
/** What the Functions emulator sets for a demo project, plus the override. */
const emu = {
  ...ai,
  FUNCTIONS_EMULATOR: "true",
  GCLOUD_PROJECT: "demo-tamitu-qa",
  AI_ENDPOINT_OVERRIDE: "http://127.0.0.1:8787",
};
/** Deployed function (dev or prod): no FUNCTIONS_EMULATOR, real project id. */
const deployedDev = { ...ai, GCLOUD_PROJECT: "tamitu-dev-tadecode", ENVIRONMENT: "dev" };
const deployedProd = { ...ai, GCLOUD_PROJECT: "tamitu-prod-tadecode" };

const okBody = { candidates: [{ finishReason: "STOP", content: { parts: [{ text: "{}" }] } }] };

function recordingDeps() {
  const fetch = vi.fn<FetchLike>(async () => ({ ok: true, status: 200, json: async () => okBody }));
  const adcToken = vi.fn(async () => "real-adc-token");
  return { fetch, adcToken };
}

describe("parseAiEndpointOverride", () => {
  it("nothing set -> none (normal Vertex path)", () => {
    expect(parseAiEndpointOverride(ai)).toEqual({ mode: "none" });
    expect(parseAiEndpointOverride(deployedProd)).toEqual({ mode: "none" });
  });

  it("emulator + demo project + loopback -> emulator mode", () => {
    expect(parseAiEndpointOverride(emu)).toEqual({ mode: "emulator", url: "http://127.0.0.1:8787", timeoutMs: undefined });
    expect(parseAiEndpointOverride({ ...emu, AI_ENDPOINT_OVERRIDE: "http://localhost:9000/" })).toEqual({
      mode: "emulator",
      url: "http://localhost:9000",
      timeoutMs: undefined,
    });
    expect(parseAiEndpointOverride({ ...emu, AI_ATTEMPT_TIMEOUT_MS: "1500" })).toMatchObject({ mode: "emulator", timeoutMs: 1500 });
  });

  it("deployed dev and prod: an override is rejected (fail-closed), never ignored", () => {
    for (const base of [deployedDev, deployedProd]) {
      expect(parseAiEndpointOverride({ ...base, AI_ENDPOINT_OVERRIDE: "http://127.0.0.1:8787" })).toEqual({ mode: "rejected" });
      // Even a forged FUNCTIONS_EMULATOR does not help with a real project id.
      expect(
        parseAiEndpointOverride({ ...base, FUNCTIONS_EMULATOR: "true", AI_ENDPOINT_OVERRIDE: "http://127.0.0.1:8787" }),
      ).toEqual({ mode: "rejected" });
      expect(parseAiEndpointOverride({ ...base, AI_ATTEMPT_TIMEOUT_MS: "1000" })).toEqual({ mode: "rejected" });
    }
  });

  it.each([
    ["FUNCTIONS_EMULATOR missing", { FUNCTIONS_EMULATOR: undefined }],
    ["FUNCTIONS_EMULATOR not exactly true", { FUNCTIONS_EMULATOR: "TRUE" }],
    ["FUNCTIONS_EMULATOR = 1", { FUNCTIONS_EMULATOR: "1" }],
    ["project not demo-*", { GCLOUD_PROJECT: "tamitu-dev-tadecode" }],
    ["project missing", { GCLOUD_PROJECT: undefined }],
    ["empty override", { AI_ENDPOINT_OVERRIDE: "" }],
    ["not a URL", { AI_ENDPOINT_OVERRIDE: "127.0.0.1:8787" }],
    ["https", { AI_ENDPOINT_OVERRIDE: "https://127.0.0.1:8787" }],
    ["external host", { AI_ENDPOINT_OVERRIDE: "http://example.com" }],
    ["real Vertex host", { AI_ENDPOINT_OVERRIDE: "http://aiplatform.eu.rep.googleapis.com" }],
    ["loopback lookalike", { AI_ENDPOINT_OVERRIDE: "http://127.0.0.1.example.com:8787" }],
    ["other loopback address", { AI_ENDPOINT_OVERRIDE: "http://127.0.0.2:8787" }],
    ["IPv6 / any address", { AI_ENDPOINT_OVERRIDE: "http://0.0.0.0:8787" }],
    ["credentials in URL", { AI_ENDPOINT_OVERRIDE: "http://user:pw@127.0.0.1:8787" }],
    ["query", { AI_ENDPOINT_OVERRIDE: "http://127.0.0.1:8787/?x=1" }],
    ["fragment", { AI_ENDPOINT_OVERRIDE: "http://127.0.0.1:8787/#x" }],
    ["timeout without override", { AI_ENDPOINT_OVERRIDE: undefined, AI_ATTEMPT_TIMEOUT_MS: "1000" }],
    ["timeout below bound", { AI_ATTEMPT_TIMEOUT_MS: "99" }],
    ["timeout above bound", { AI_ATTEMPT_TIMEOUT_MS: "45001" }],
    ["timeout not a number", { AI_ATTEMPT_TIMEOUT_MS: "1e3" }],
  ])("rejected: %s", (_name, over) => {
    expect(parseAiEndpointOverride({ ...emu, ...over })).toEqual({ mode: "rejected" });
  });
});

describe("createPlanModel", () => {
  const call = { systemInstruction: "s", userText: "u", responseSchema: {} };

  it("deployed prod/dev without override: real Vertex URL with the ADC token", async () => {
    for (const env of [deployedDev, deployedProd]) {
      const d = recordingDeps();
      const m = createPlanModel(env, d);
      await m!.generate(call);
      expect(d.adcToken).toHaveBeenCalledTimes(1);
      const [url, init] = d.fetch.mock.calls[0]!;
      expect(url.startsWith("https://aiplatform.eu.rep.googleapis.com/v1/projects/")).toBe(true);
      expect(init.headers.authorization).toBe("Bearer real-adc-token");
    }
  });

  it("deployed prod/dev WITH override: no model at all (ai_unavailable), no call anywhere", () => {
    for (const base of [deployedDev, deployedProd]) {
      const d = recordingDeps();
      const env = { ...base, FUNCTIONS_EMULATOR: "true", AI_ENDPOINT_OVERRIDE: "http://127.0.0.1:8787" };
      expect(createPlanModel(env, d)).toBeUndefined();
      expect(d.fetch).not.toHaveBeenCalled();
      expect(d.adcToken).not.toHaveBeenCalled();
    }
  });

  it("emulator: calls the fake with the Vertex path and a dummy token; ADC is never touched", async () => {
    const d = recordingDeps();
    const m = createPlanModel(emu, d);
    await m!.generate(call);
    expect(d.adcToken).not.toHaveBeenCalled();
    const [url, init] = d.fetch.mock.calls[0]!;
    expect(url).toBe(
      "http://127.0.0.1:8787/v1/projects/demo-tamitu-qa/locations/eu/publishers/google/models/gemini-3.1-flash-lite:generateContent",
    );
    expect(init.headers.authorization).toBe(`Bearer ${EMULATOR_FAKE_TOKEN}`);
  });

  it("emulator override still requires a valid AI config (model allow-list)", () => {
    expect(createPlanModel({ ...emu, AI_MODEL_ID: "gemini-9-pro" }, recordingDeps())).toBeUndefined();
  });

  it("emulator AI_ATTEMPT_TIMEOUT_MS shortens the per-attempt timeout -> retryable `timeout`", async () => {
    const hang: FetchLike = (_url, init) =>
      new Promise((_resolve, reject) => init.signal.addEventListener("abort", () => reject(init.signal.reason)));
    const m = createPlanModel({ ...emu, AI_ATTEMPT_TIMEOUT_MS: "100" }, { fetch: hang, adcToken: async () => "x" });
    await expect(m!.generate(call)).rejects.toMatchObject({ kind: "retryable", code: "timeout" });
  });
});
