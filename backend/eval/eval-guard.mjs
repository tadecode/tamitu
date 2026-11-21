// Cost guard of the evaluation runner (review PR #136 #3). Pure functions, unit-tested in
// backend/functions/test/eval-guard.test.ts. Fail-closed: any doubt -> refuse to run.

/** USD per 1M tokens [input, output], endpoint `eu` = "Non-global" (docs/architecture/costs.md sekcja 0, 2026-11-18). */
export const PRICE_USD_PER_M = Object.freeze({
  "gemini-3.1-flash-lite": [0.275, 1.65],
  "gemini-3.5-flash-lite": [0.33, 2.75],
});
export const USD_PLN = 4.0;
/** Default and maximum stop for one run (PLN). Raising it is a code change and review. */
export const DEFAULT_STOP_PLN = 2.5;
export const MAX_STOP_PLN = 2.5;

export class GuardError extends Error {}

/**
 * Raw value of `--name` from argv: undefined when the flag is absent; GuardError when it is present
 * without a value (e.g. `--stop-pln --lang pl`), so a typo never falls back silently.
 */
export function rawOption(argv, name) {
  const i = argv.indexOf(name);
  if (i < 0) return undefined;
  const v = argv[i + 1];
  if (v === undefined || v.startsWith("--")) throw new GuardError(`${name} needs a value`);
  return v;
}

/**
 * Stop limit in PLN: absent -> 2.5; accepts a decimal point or comma ("2,5"); anything that is not a
 * finite number in (0, 2.5] -> GuardError (never NaN, which would disable the stop).
 */
export function parseStopPln(raw) {
  if (raw === undefined) return DEFAULT_STOP_PLN;
  const s = String(raw).trim();
  if (!/^\d+(?:[.,]\d+)?$/.test(s)) throw new GuardError(`--stop-pln: not a number: use e.g. 2.5 or 2,5`);
  const v = Number(s.replace(",", "."));
  if (!Number.isFinite(v) || v <= 0 || v > MAX_STOP_PLN) {
    throw new GuardError(`--stop-pln must be > 0 and <= ${MAX_STOP_PLN} PLN`);
  }
  return v;
}

/** Price of a model; models without a known price are refused (the guard could not count them). */
export function priceFor(modelId) {
  const p = PRICE_USD_PER_M[modelId];
  if (!p) throw new GuardError(`unknown model ${modelId}: allowed ${Object.keys(PRICE_USD_PER_M).join(", ")}`);
  return p;
}

export function costPln(modelId, inputTokens, outputTokens) {
  const [pi, po] = priceFor(modelId);
  return ((inputTokens * pi + outputTokens * po) / 1e6) * USD_PLN;
}

/**
 * Cost charged for one attempt. An attempt without usage data (timeout, 5xx, network) may still be
 * billed, so it is charged at the estimate (conservative).
 */
export function attemptCostPln(modelId, attempt, estimate) {
  const hasUsage = (attempt.tokensIn ?? 0) + (attempt.tokensOut ?? 0) + (attempt.tokensThought ?? 0) > 0;
  return hasUsage
    ? costPln(modelId, attempt.tokensIn ?? 0, (attempt.tokensOut ?? 0) + (attempt.tokensThought ?? 0))
    : costPln(modelId, estimate.input, estimate.output);
}

/**
 * Starts the next generation only if even its worst case (2 attempts at the estimate, x1.5 margin)
 * keeps the total within the stop. So the stop is a ceiling, not "stop after crossing it".
 */
export function canStart(spentPln, modelId, estimate, stopPln) {
  const worstNext = 2 * 1.5 * costPln(modelId, estimate.input, estimate.output);
  return spentPln + worstNext <= stopPln;
}

/**
 * --prompt (TAM-95, review PR #148 #2): absent -> "plan-v1" (production default); otherwise the exact name
 * of a known version (keys of functions/lib/prompt/index.js PROMPTS). Anything else -> GuardError: the
 * runner never silently evaluates a different prompt than the one asked for.
 */
export function parsePromptVersion(raw, known) {
  if (raw === undefined) return "plan-v1";
  if (!known.includes(raw)) throw new GuardError(`--prompt must be one of: ${known.join(", ")}`);
  return raw;
}
