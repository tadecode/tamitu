// Generation with validation and retries (ADR-0002 "Próby", p3-05 sekcja 5, ADR-0016 pkt 1-7).
// Pure orchestration: the model, the attempt logger, the clock, sleep and jitter are injected.
import { ATTEMPT_TIMEOUT_MS, ModelError, type ModelResult, type PlanModel } from "./ai.js";
import { AppError, ERROR_CODE_PATTERN } from "./errors.js";
import { computeDayTargets, type DayTarget } from "./plan-targets.js";
import { retryHints, validatePlanOutput, type ValidPlan } from "./plan-validator.js";
import { buildUserTurn, DEFAULT_PROMPT, MODEL_RESPONSE_SCHEMA, type PlanPrompt } from "./prompt/index.js";
import type { GeneratePlanRequest } from "./schemas.js";

/**
 * ADR-0016 pkt 1-2: at most 3 model calls per generation and at most 2 billable attempts. A call that
 * ends with HTTP 429 is "rejected" (not billable); every other end (answer, timeout, network, 408, 5xx,
 * bad_body) is billable. A third call is therefore possible only after at least one 429.
 */
export const MAX_CALLS = 3;
export const MAX_BILLABLE_ATTEMPTS = 2;

/** ADR-0016 pkt 4: the whole generation fits in 100 s from the start of the first call (function: 120 s). */
export const GENERATION_BUDGET_MS = 100_000;
/** A further call starts only if at least a full attempt timeout (45 s) of the budget is left after the wait. */
export const MIN_BUDGET_FOR_CALL_MS = ATTEMPT_TIMEOUT_MS;

/** ADR-0016 pkt 3: wait before call 2 = 2-4 s, before call 3 = 4-8 s (base x [1, 2], uniform). */
export const RETRY_BACKOFF_BASE_MS: Readonly<Record<2 | 3, number>> = { 2: 2000, 3: 4000 };

/** Wait before model call `nextCall` (2 or 3) after a retryable error, with uniform jitter. */
export function retryBackoffMs(nextCall: 2 | 3, random: () => number = Math.random): number {
  const base = RETRY_BACKOFF_BASE_MS[nextCall];
  const r = Math.min(1, Math.max(0, random()));
  return Math.round(base * (1 + r));
}

/** `details.retryAfterSec` of ai_busy (ADR-0016 pkt 6). */
export const AI_BUSY_RETRY_AFTER_SEC = 60;

/** Why the generation loop ended (ADR-0016 pkt 15). */
export type StopReason = "ok" | "invalid" | "config" | "busy" | "max_billable" | "max_calls" | "time_budget";

/** Summary of one generation for the final log entry. */
export interface GenerationSummary {
  /** Model calls made (1-3). */
  calls: number;
  stopReason: StopReason;
}

const defaultSleep = (ms: number) => new Promise<void>((resolve) => setTimeout(resolve, ms));

/** Metadata of one attempt (sekcja 6). No prompt, no trip data, no model output. */
export interface AttemptLog {
  /** Model call number (1-3). */
  attempt: number;
  /** Wait before this call in ms (0 for the first call and after an invalid answer). */
  waitMs: number;
  /** ADR-0016 pkt 1: false only for a call rejected with HTTP 429. */
  billable: boolean;
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
  /** Model calls made (1-3). */
  attempts: number;
  targets: DayTarget[];
  /** Version of the prompt actually used (returned to the app as promptVersion). */
  promptVersion: string;
}

const safeToken = (v: string | undefined) => (v !== undefined && ERROR_CODE_PATTERN.test(v) ? v : undefined);

/** ADR-0016 pkt 1: HTTP 429 = the call was rejected, nothing was billed. */
const isRejected = (e: ModelError) => e.kind === "retryable" && e.code === "429";

/**
 * Call -> validate -> (next call with the issue list | wait, then the same request after 408/429/5xx/timeout).
 * - 400 and other configuration errors: no retry, ai_unavailable;
 * - at most MAX_CALLS calls and MAX_BILLABLE_ATTEMPTS billable attempts (429 is not billable);
 * - a further call only when >= 45 s of the 100 s budget is left after the wait;
 * - every call rejected with 429 (0 billable attempts): ai_busy with retryAfterSec;
 * - otherwise by the last failure: retryable error -> ai_unavailable, invalid output -> ai_invalid_response.
 * No "repair" of the output in code (MVP). `onFinish` receives calls and stopReason for the final log entry.
 */
export async function generateValidPlan(
  request: GeneratePlanRequest,
  model: PlanModel,
  opts: {
    clock?: () => number;
    onAttempt?: (log: AttemptLog) => void;
    onFinish?: (summary: GenerationSummary) => void;
    sleep?: (ms: number) => Promise<void>;
    /** Jitter source in [0, 1] (tests inject a fixed value). */
    random?: () => number;
    /** Prompt version (AI_PROMPT_VERSION via prompt/index.ts resolvePrompt); default plan-v1. */
    prompt?: PlanPrompt;
  } = {},
): Promise<GenerationResult> {
  const clock = opts.clock ?? Date.now;
  const sleep = opts.sleep ?? defaultSleep;
  const random = opts.random ?? Math.random;
  const prompt = opts.prompt ?? DEFAULT_PROMPT;
  const targets = computeDayTargets(request);
  let hints: string[] | undefined;
  let lastFailure: "invalid" | "unavailable" = "unavailable";
  let calls = 0;
  let billable = 0;
  /** The previous call ended with a retryable error, so the next one waits (no wait after an invalid answer). */
  let waitBeforeNext = false;
  let budgetStart: number | undefined;

  const finish = (stopReason: StopReason): void => opts.onFinish?.({ calls, stopReason });
  const fail = (stopReason: StopReason): never => {
    if (billable === 0) {
      // Only 429s: nothing was billed (ADR-0016 pkt 6). time_budget keeps its reason for monitoring.
      finish(stopReason === "time_budget" ? stopReason : "busy");
      throw new AppError("ai_busy", { retryAfterSec: AI_BUSY_RETRY_AFTER_SEC });
    }
    finish(stopReason);
    throw new AppError(lastFailure === "invalid" ? "ai_invalid_response" : "ai_unavailable");
  };

  for (;;) {
    if (calls >= MAX_CALLS) return fail("max_calls");
    if (billable >= MAX_BILLABLE_ATTEMPTS) return fail("max_billable");
    const attempt = calls + 1;
    const waitMs = waitBeforeNext ? retryBackoffMs(attempt as 2 | 3, random) : 0;
    if (budgetStart !== undefined && GENERATION_BUDGET_MS - (clock() - budgetStart) - waitMs < MIN_BUDGET_FOR_CALL_MS) {
      return fail("time_budget");
    }
    if (waitMs > 0) await sleep(waitMs);

    const base = { attempt, waitMs, aiModel: model.modelId, aiLocation: model.location, promptVersion: prompt.version };
    const started = clock();
    budgetStart ??= started;
    calls = attempt;
    let result: ModelResult;
    try {
      result = await model.generate({
        systemInstruction: prompt.systemInstruction,
        userText: buildUserTurn(request, targets, hints),
        responseSchema: MODEL_RESPONSE_SCHEMA,
      });
    } catch (e) {
      const durationMs = clock() - started;
      if (e instanceof ModelError) {
        const rejected = isRejected(e);
        if (!rejected) billable++;
        opts.onAttempt?.({
          ...base,
          billable: !rejected,
          durationMs,
          outcome: `model_${e.kind}`,
          modelError: safeToken(e.code) ?? "unknown",
        });
        if (e.kind === "config") {
          finish("config");
          throw new AppError("ai_unavailable");
        }
        lastFailure = "unavailable";
        // ADR-0016 pkt 5: the issue list of an earlier invalid answer survives a 429. After a billable
        // retryable error there is nothing to correct (the same request again).
        if (!rejected) hints = undefined;
        // Review PR #136 #7: an immediate retry after 429/503 usually gets the same answer.
        waitBeforeNext = true;
        continue;
      }
      opts.onAttempt?.({ ...base, billable: true, durationMs, outcome: "error" });
      throw e;
    }

    billable++;
    waitBeforeNext = false;
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
      opts.onAttempt?.({ ...base, billable: true, ...usage, durationMs, outcome: "ok", ...(qualityWarnings ? { qualityWarnings } : {}) });
      finish("ok");
      return { plan: v.plan, attempts: attempt, targets, promptVersion: prompt.version };
    }
    opts.onAttempt?.({
      ...base,
      billable: true,
      ...usage,
      durationMs,
      outcome: "invalid",
      validationErrors: v.issues.map((i) => i.code).join(","),
    });
    lastFailure = "invalid";
    if (v.final) return fail("invalid"); // blocked answer: same input, same result - do not pay for a second call
    hints = retryHints(v.issues);
  }
}
