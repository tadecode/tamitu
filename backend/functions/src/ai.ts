// AI provider abstraction (ADR-0001/0002: provider and cost limits behind an interface).
// P3-05: Vertex AI (Gemini) over REST with the function's service account; no SDK dependency.
// Nothing in this module logs; callers log metadata only (ADR-0001 "Dane osobowe").

/** One model call: everything the provider needs, already built by the prompt module. */
export interface ModelCall {
  systemInstruction: string;
  userText: string;
  responseSchema: unknown;
}

export interface ModelUsage {
  inputTokens: number;
  outputTokens: number;
  thoughtTokens: number;
}

export interface ModelResult {
  text: string | undefined;
  finishReason: string | undefined;
  modelVersion: string | undefined;
  usage: ModelUsage;
}

/**
 * Provider failure classes (p3-05 sekcja 3 pkt 3):
 * - `config`: 400/401/403/404 etc. - configuration error, never retried (retry costs a slot, fixes nothing);
 * - `retryable`: 429, 5xx, timeout, network - may be retried once.
 */
export class ModelError extends Error {
  constructor(
    readonly kind: "config" | "retryable",
    /** HTTP status, `timeout` or `network`; a fixed token, safe to log. */
    readonly code: string,
  ) {
    super(`model_${kind}`);
    this.name = "ModelError";
  }
}

export interface PlanModel {
  /** Identifier for logs (AI_MODEL_ID). */
  readonly modelId: string;
  readonly location: string;
  generate(call: ModelCall): Promise<ModelResult>;
}

/** Vertex generation settings (ADR-0001 Aneks C, p3-05 sekcja 2). */
export const GENERATION_CONFIG = {
  temperature: 0.7,
  maxOutputTokens: 10_000,
  responseMimeType: "application/json",
  thinkingConfig: { thinkingLevel: "MINIMAL" },
} as const;

/** Per-attempt timeout (sekcja 5): measured max 14 s; two attempts fit the 120 s function limit. */
export const ATTEMPT_TIMEOUT_MS = 45_000;

/** Allowed Vertex locations (ADR-0001 Aneks B pkt 2): never `global`. */
export const ALLOWED_AI_LOCATIONS = ["europe-west4", "eu"] as const;
export type AiLocation = (typeof ALLOWED_AI_LOCATIONS)[number];

const MODEL_ID = /^gemini-[a-z0-9.-]{1,40}$/;
const PROJECT_ID = /^[a-z][a-z0-9-]{4,28}[a-z0-9]$/;

export interface AiConfig {
  modelId: string;
  location: AiLocation;
  projectId: string;
}

/**
 * Parses AI_MODEL_ID, AI_LOCATION and GCLOUD_PROJECT. Fail-closed: anything missing or outside the
 * allow-list -> undefined (generatePlan then answers ai_unavailable with configError `ai_config_invalid`).
 * `global` and regions outside the EU are rejected by construction.
 */
export function parseAiConfig(env: Record<string, string | undefined>): AiConfig | undefined {
  const modelId = env["AI_MODEL_ID"];
  const location = env["AI_LOCATION"];
  const projectId = env["GCLOUD_PROJECT"];
  if (!modelId || !MODEL_ID.test(modelId)) return undefined;
  if (!location || !(ALLOWED_AI_LOCATIONS as readonly string[]).includes(location)) return undefined;
  if (!projectId || !PROJECT_ID.test(projectId)) return undefined;
  return { modelId, location: location as AiLocation, projectId };
}

/** generateContent URL; `eu` uses the multi-region host (ADR-0001 Aneks C pkt 3). */
export function vertexUrl(cfg: AiConfig): string {
  const host = cfg.location === "eu" ? "aiplatform.eu.rep.googleapis.com" : `${cfg.location}-aiplatform.googleapis.com`;
  return `https://${host}/v1/projects/${cfg.projectId}/locations/${cfg.location}/publishers/google/models/${cfg.modelId}:generateContent`;
}

export function vertexRequestBody(call: ModelCall): unknown {
  return {
    systemInstruction: { parts: [{ text: call.systemInstruction }] },
    contents: [{ role: "user", parts: [{ text: call.userText }] }],
    generationConfig: { ...GENERATION_CONFIG, responseSchema: call.responseSchema },
  };
}

interface VertexResponse {
  candidates?: Array<{
    finishReason?: string;
    content?: { parts?: Array<{ text?: string; thought?: boolean }> };
  }>;
  usageMetadata?: { promptTokenCount?: number; candidatesTokenCount?: number; thoughtsTokenCount?: number };
  modelVersion?: string;
}

const int = (v: unknown) => (typeof v === "number" && Number.isFinite(v) ? v : 0);

/** Extracts the answer text (non-thought parts) and metadata from a Vertex response. */
export function parseVertexResponse(body: unknown): ModelResult {
  const r = (body ?? {}) as VertexResponse;
  const c = r.candidates?.[0];
  const parts = c?.content?.parts ?? [];
  const text = parts
    .filter((p) => p.thought !== true && typeof p.text === "string")
    .map((p) => p.text)
    .join("");
  return {
    text: parts.length > 0 ? text : undefined,
    finishReason: typeof c?.finishReason === "string" ? c.finishReason : undefined,
    modelVersion: typeof r.modelVersion === "string" ? r.modelVersion : undefined,
    usage: {
      inputTokens: int(r.usageMetadata?.promptTokenCount),
      outputTokens: int(r.usageMetadata?.candidatesTokenCount),
      thoughtTokens: int(r.usageMetadata?.thoughtsTokenCount),
    },
  };
}

/** Status -> failure class. Only 408/429/5xx are retryable; every other non-2xx is configuration. */
export function classifyStatus(status: number): "config" | "retryable" {
  return status === 408 || status === 429 || status >= 500 ? "retryable" : "config";
}

export type FetchLike = (url: string, init: { method: string; headers: Record<string, string>; body: string; signal: AbortSignal }) => Promise<{
  ok: boolean;
  status: number;
  json(): Promise<unknown>;
}>;

/** Access token of the function's service account (fn-ai-plan), e.g. from firebase-admin credentials. */
export type TokenProvider = () => Promise<string>;

export function vertexModel(cfg: AiConfig, deps: { fetch: FetchLike; token: TokenProvider; timeoutMs?: number }): PlanModel {
  const url = vertexUrl(cfg);
  return {
    modelId: cfg.modelId,
    location: cfg.location,
    async generate(call) {
      const token = await deps.token();
      let res;
      try {
        res = await deps.fetch(url, {
          method: "POST",
          headers: { authorization: `Bearer ${token}`, "content-type": "application/json; charset=utf-8" },
          body: JSON.stringify(vertexRequestBody(call)),
          signal: AbortSignal.timeout(deps.timeoutMs ?? ATTEMPT_TIMEOUT_MS),
        });
      } catch (e) {
        const name = (e as { name?: unknown } | null)?.name;
        throw new ModelError("retryable", name === "TimeoutError" || name === "AbortError" ? "timeout" : "network");
      }
      // The error body is never read nor logged: it may echo parts of the request.
      if (!res.ok) throw new ModelError(classifyStatus(res.status), String(res.status));
      let body: unknown;
      try {
        body = await res.json();
      } catch {
        throw new ModelError("retryable", "bad_body");
      }
      return parseVertexResponse(body);
    },
  };
}

/** Used when AI config is missing or invalid: every call is a configuration error (no network). */
export const unconfiguredModel: PlanModel = {
  modelId: "unconfigured",
  location: "none",
  generate() {
    return Promise.reject(new ModelError("config", "ai_config_invalid"));
  },
};
