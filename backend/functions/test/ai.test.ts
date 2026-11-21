// Vertex provider with a fake fetch: 0 network calls, 0 paid calls.
import { describe, expect, it } from "vitest";
import {
  classifyStatus,
  GENERATION_CONFIG,
  ModelError,
  parseAiConfig,
  parseVertexResponse,
  vertexModel,
  vertexRequestBody,
  vertexUrl,
  type FetchLike,
} from "../src/ai.js";

const env = { AI_MODEL_ID: "gemini-3.1-flash-lite", AI_LOCATION: "eu", GCLOUD_PROJECT: "tamitu-dev-tadecode" };

describe("parseAiConfig (fail-closed, ADR-0001 Aneks B pkt 2 / Aneks C)", () => {
  it("accepts eu and europe-west4 only", () => {
    expect(parseAiConfig(env)).toEqual({ modelId: "gemini-3.1-flash-lite", location: "eu", projectId: "tamitu-dev-tadecode" });
    expect(parseAiConfig({ ...env, AI_LOCATION: "europe-west4" })?.location).toBe("europe-west4");
    for (const loc of ["global", "us-central1", "europe-west1", "", undefined]) {
      expect(parseAiConfig({ ...env, AI_LOCATION: loc })).toBeUndefined();
    }
  });
  it("requires a Gemini model id and a valid project", () => {
    expect(parseAiConfig({ ...env, AI_MODEL_ID: undefined })).toBeUndefined();
    expect(parseAiConfig({ ...env, AI_MODEL_ID: "gpt-4" })).toBeUndefined();
    expect(parseAiConfig({ ...env, AI_MODEL_ID: "gemini-3.1-flash-lite/../x" })).toBeUndefined();
    expect(parseAiConfig({ ...env, GCLOUD_PROJECT: undefined })).toBeUndefined();
  });
});

describe("request building", () => {
  it("uses the eu multi-region host and the regional host for europe-west4", () => {
    expect(vertexUrl(parseAiConfig(env)!)).toBe(
      "https://aiplatform.eu.rep.googleapis.com/v1/projects/tamitu-dev-tadecode/locations/eu/publishers/google/models/gemini-3.1-flash-lite:generateContent",
    );
    expect(vertexUrl(parseAiConfig({ ...env, AI_LOCATION: "europe-west4" })!)).toMatch(
      /^https:\/\/europe-west4-aiplatform\.googleapis\.com\/v1\/projects\/tamitu-dev-tadecode\/locations\/europe-west4\//,
    );
  });
  it("sets MINIMAL thinking (no thinkingBudget), JSON output, 0.7, 10 000 tokens, no tools/cache", () => {
    const body = vertexRequestBody({ systemInstruction: "S", userText: "U", responseSchema: { type: "OBJECT" } }) as Record<string, unknown>;
    expect(body).toEqual({
      systemInstruction: { parts: [{ text: "S" }] },
      contents: [{ role: "user", parts: [{ text: "U" }] }],
      generationConfig: { ...GENERATION_CONFIG, responseSchema: { type: "OBJECT" } },
    });
    expect(GENERATION_CONFIG).toEqual({
      temperature: 0.7,
      maxOutputTokens: 10_000,
      responseMimeType: "application/json",
      thinkingConfig: { thinkingLevel: "MINIMAL" },
    });
    expect(JSON.stringify(body)).not.toMatch(/thinkingBudget|tools|cachedContent|googleSearch/);
  });
});

describe("response parsing", () => {
  it("joins non-thought text parts and reads usage", () => {
    const r = parseVertexResponse({
      candidates: [{ finishReason: "STOP", content: { parts: [{ text: "x", thought: true }, { text: '{"a"' }, { text: ":1}" }] } }],
      usageMetadata: { promptTokenCount: 720, candidatesTokenCount: 1500, thoughtsTokenCount: 0 },
      modelVersion: "gemini-3.1-flash-lite-001",
    });
    expect(r).toEqual({
      text: '{"a":1}',
      finishReason: "STOP",
      modelVersion: "gemini-3.1-flash-lite-001",
      usage: { inputTokens: 720, outputTokens: 1500, thoughtTokens: 0 },
    });
  });
  it("tolerates empty or blocked responses", () => {
    expect(parseVertexResponse({})).toMatchObject({ text: undefined, finishReason: undefined });
    expect(parseVertexResponse(null).usage).toEqual({ inputTokens: 0, outputTokens: 0, thoughtTokens: 0 });
  });
});

describe("vertexModel with a fake fetch", () => {
  const cfg = parseAiConfig(env)!;
  const okFetch: FetchLike = async () => ({ ok: true, status: 200, json: async () => ({ candidates: [{ finishReason: "STOP", content: { parts: [{ text: "{}" }] } }] }) });

  it("sends the bearer token from the provider and the JSON body", async () => {
    const seen: Array<{ url: string; auth: string; body: unknown }> = [];
    const fetch: FetchLike = async (url, init) => {
      seen.push({ url, auth: init.headers["authorization"]!, body: JSON.parse(init.body) });
      return okFetch(url, init);
    };
    const m = vertexModel(cfg, { fetch, token: async () => "tok-123" });
    const r = await m.generate({ systemInstruction: "S", userText: "U", responseSchema: {} });
    expect(r.finishReason).toBe("STOP");
    expect(seen[0]?.auth).toBe("Bearer tok-123");
    expect(seen[0]?.url).toBe(vertexUrl(cfg));
    expect(m.modelId).toBe("gemini-3.1-flash-lite");
  });

  it("classifies HTTP errors: 400/403/404 config, 408/429/5xx retryable; error body never read", async () => {
    expect([400, 401, 403, 404, 417].map(classifyStatus)).toEqual(["config", "config", "config", "config", "config"]);
    expect([408, 429, 500, 503].map(classifyStatus)).toEqual(["retryable", "retryable", "retryable", "retryable"]);
    let bodyRead = false;
    const m = vertexModel(cfg, {
      fetch: async () => ({ ok: false, status: 400, json: async () => ((bodyRead = true), {}) }),
      token: async () => "t",
    });
    const e = await m.generate({ systemInstruction: "S", userText: "U", responseSchema: {} }).catch((x: unknown) => x);
    expect(e).toBeInstanceOf(ModelError);
    expect(e).toMatchObject({ kind: "config", code: "400" });
    expect(bodyRead).toBe(false);
  });

  it("timeout and network failures are retryable", async () => {
    const slow = vertexModel(cfg, {
      fetch: (_u, init) => new Promise((_, rej) => init.signal.addEventListener("abort", () => rej(init.signal.reason))),
      token: async () => "t",
      timeoutMs: 20,
    });
    await expect(slow.generate({ systemInstruction: "", userText: "", responseSchema: {} })).rejects.toMatchObject({ kind: "retryable", code: "timeout" });
    const down = vertexModel(cfg, { fetch: async () => { throw new TypeError("fetch failed"); }, token: async () => "t" });
    await expect(down.generate({ systemInstruction: "", userText: "", responseSchema: {} })).rejects.toMatchObject({ kind: "retryable", code: "network" });
  });
});
