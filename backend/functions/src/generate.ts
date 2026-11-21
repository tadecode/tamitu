// Generation with validation and at most one retry (ADR-0002 "Próby", p3-05 sekcja 5).
// Pure orchestration: the model and the attempt logger are injected.
import { ModelError, type ModelResult, type PlanModel } from "./ai.js";
import { AppError, ERROR_CODE_PATTERN } from "./errors.js";
import { computeDayTargets, type DayTarget } from "./plan-targets.js";
import { retryHints, validatePlanOutput, type ValidPlan } from "./plan-validator.js";
import { buildUserTurn, MODEL_RESPONSE_SCHEMA, PROMPT_VERSION, SYSTEM_INSTRUCTION } from "./prompt/plan-v2.js";
import type { GeneratePlanRequest } from "./schemas.js";

/** Contract: max. 2 model calls per generation. */
export const MAX_ATTEMPTS = 2;

/** Wait before retrying a retryable model error: 1-2 s with jitter (fits the 120 s function limit). */
export const RETRY_BACKOFF_MS = { min: 1000, max: 2000 } as const;

export function retryBackoffMs(random: () => number = Math.random): number {
  return Math.round(RETRY_BACKOFF_MS.min + random() * (RETRY_BACKOFF_MS.max - RETRY_BACKOFF_MS.min));
}

const defaultSleep = (ms: number) => new Promise<void>((resolve) => setTimeout(resolve, ms));

/** Metadata of one attempt (sekcja 6). No prompt, no trip data, no model output. */
export interface AttemptLog {
  attempt: number;
  aiModel: string;
  aiLocation: string;
  promptVersion: string;
  modelVersion?: string | undefined;
  durationMs: number;
  tokensIn?: number | undefined;
  tokensOut?: number | undefined;
  tokensThought?: number | undefined;
  /** `ok`, `invalid`, `model_config`, `model_retryable`, `error`. */
  outcome: string;
  /** Validation issue codes joined with ",", e.g. `items_count@day5,time_order@day2`. */
  validationErrors?: string | undefined;
  /** Quality warnings of a valid plan joined with ",", e.g. `dup_place@day14` (TAM-95); log only, no retry. */
  qualityWarnings?: string | undefined;
  /** ModelError code (HTTP status / timeout / network). */
  modelError?: string | undefined;
}

export interface GenerationResult {
  plan: ValidPlan;
  attempts: number;
  targets: DayTarget[];
}

const safeToken = (v: string | undefined) => (v !== undefined && ERROR_CODE_PATTERN.test(v) ? v : undefined);

/**
 * Attempt 1 -> validate -> (attempt 2 with the issue list | retry after 429/5xx/timeout) -> validate.
 * - 400 and other configuration errors: no retry, ai_unavailable;
 * - two retryable failures (or a retryable failure on attempt 2): ai_unavailable;
 * - invalid output on the last attempt: ai_invalid_response.
 * No "repair" of the output in code (MVP).
 */
export async function generateValidPlan(
  request: GeneratePlanRequest,
  model: PlanModel,
  opts: { clock?: () => number; onAttempt?: (log: AttemptLog) => void; sleep?: (ms: number) => Promise<void> } = {},
): Promise<GenerationResult> {
  const clock = opts.clock ?? Date.now;
  const sleep = opts.sleep ?? defaultSleep;
  const targets = computeDayTargets(request);
  let hints: string[] | undefined;
  let lastFailure: "invalid" | "unavailable" = "unavailable";

  for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
    const base = { attempt, aiModel: model.modelId, aiLocation: model.location, promptVersion: PROMPT_VERSION };
    const started = clock();
    let result: ModelResult;
    try {
      result = await model.generate({
        systemInstruction: SYSTEM_INSTRUCTION,
        userText: buildUserTurn(request, targets, hints),
        responseSchema: MODEL_RESPONSE_SCHEMA,
      });
    } catch (e) {
      const durationMs = clock() - started;
      if (e instanceof ModelError) {
        opts.onAttempt?.({ ...base, durationMs, outcome: `model_${e.kind}`, modelError: safeToken(e.code) ?? "unknown" });
        if (e.kind === "config") throw new AppError("ai_unavailable");
        lastFailure = "unavailable";
        hints = undefined; // nothing to correct; same request again
        // Review PR #136 #7: an immediate retry after 429/503 usually gets the same answer.
        if (attempt < MAX_ATTEMPTS) await sleep(retryBackoffMs());
        continue;
      }
      opts.onAttempt?.({ ...base, durationMs, outcome: "error" });
      throw e;
    }

    const durationMs = clock() - started;
    const usage = {
      modelVersion: safeToken(result.modelVersion),
      tokensIn: result.usage.inputTokens,
      tokensOut: result.usage.outputTokens,
      tokensThought: result.usage.thoughtTokens,
    };
    const v = validatePlanOutput({
      finishReason: result.finishReason,
      text: result.text,
      planLanguage: request.planLanguage,
      targets,
    });
    if (v.ok) {
      const qualityWarnings = v.warnings.length > 0 ? v.warnings.join(",") : undefined;
      opts.onAttempt?.({ ...base, ...usage, durationMs, outcome: "ok", ...(qualityWarnings ? { qualityWarnings } : {}) });
      return { plan: v.plan, attempts: attempt, targets };
    }
    opts.onAttempt?.({
      ...base,
      ...usage,
      durationMs,
      outcome: "invalid",
      validationErrors: v.issues.map((i) => i.code).join(","),
    });
    lastFailure = "invalid";
    if (v.final) break; // blocked answer: same input, same result - do not pay for a second call
    hints = retryHints(v.issues);
  }
  throw new AppError(lastFailure === "invalid" ? "ai_invalid_response" : "ai_unavailable");
}
