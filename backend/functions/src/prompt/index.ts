// Prompt selection (TAM-95, review PR #148 #2). plan-v1 stays the production default: it is the version that
// passed the paid evaluation (TAM-88, 95.0%). plan-v2 is chosen only by the deployment parameter
// AI_PROMPT_VERSION=plan-v2, after its own paid evaluation and the owner's approval.
import * as v1 from "./plan-v1.js";
import * as v2 from "./plan-v2.js";

export interface PlanPrompt {
  /** Logged and returned as promptVersion. */
  version: string;
  systemInstruction: string;
}

export const PROMPTS: Readonly<Record<string, PlanPrompt>> = {
  [v1.PROMPT_VERSION]: { version: v1.PROMPT_VERSION, systemInstruction: v1.SYSTEM_INSTRUCTION },
  [v2.PROMPT_VERSION]: { version: v2.PROMPT_VERSION, systemInstruction: v2.SYSTEM_INSTRUCTION },
};

export const DEFAULT_PROMPT: PlanPrompt = PROMPTS[v1.PROMPT_VERSION]!;

/** AI_PROMPT_VERSION -> prompt. Missing, empty or unknown value -> plan-v1 (fail-closed to the evaluated prompt). */
export function resolvePrompt(raw: string | undefined): PlanPrompt {
  const key = raw?.trim();
  return key !== undefined && Object.hasOwn(PROMPTS, key) ? PROMPTS[key]! : DEFAULT_PROMPT;
}

// Shared by all versions: the user turn and the responseSchema are not versioned separately (yet).
export { buildUserTurn, MODEL_RESPONSE_SCHEMA } from "./plan-v1.js";
