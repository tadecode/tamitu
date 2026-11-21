// Full server-side validation of the model output (p3-05-wymagania-generowania.md sekcja 5,
// posrednik-api.md "Gwarancje po walidacji serwerowej", schemas/generate-plan.response.schema.json).
// Error codes and retry hints contain only numbers and constants, never model or user text.
import { z } from "zod";
import type { DayTarget } from "./plan-targets.js";

export const TEXT_LIMITS = { title: 80, name: 100, locality: 80, description: 300 } as const;
export const MAX_DAYS = 14;

const TIME = /^([01]\d|2[0-3]):[0-5]\d$/;
/** Same character classes as request validation (SEC-21): Cc, Cf, Zl, Zp. */
const FORBIDDEN_CHARS = /[\p{Cc}\p{Cf}\p{Zl}\p{Zp}]/u;
/** URLs, e-mail addresses, any domain with a path, HTML-like tags, Markdown links/emphasis (T5). */
const URL_OR_MARKUP =
  /(?:https?:\/\/|ftp:\/\/|www\.|\b[a-z0-9-]+(?:\.[a-z0-9-]+)*\.[a-z]{2,}\/|[^\s@]+@[^\s@]+\.[a-z]{2,}|<\s*\/?\s*[a-z!?]|\]\(|\*\*|__|```)/i;
/**
 * Bare domains with common generic and European TLDs (review PR #136 #6). Lower case only, so a
 * missing space after a full stop ("square.It is") is not taken for a domain.
 */
const BARE_DOMAIN =
  /\b[a-z0-9-]+(?:\.[a-z0-9-]+)*\.(?:com|net|org|info|io|eu|pl|de|it|pt|es|fr|at|cz|uk|gr|hu|tr|nl|be|ch|hr|travel)\b/;

const itemShape = z.object({
  startTime: z.string(),
  name: z.string(),
  locality: z.string(),
  description: z.string(),
});
const dayShape = z.object({ dayNumber: z.number().int(), title: z.string(), items: z.array(itemShape) });
const outputShape = z.object({ language: z.enum(["pl", "en"]), days: z.array(dayShape).min(1).max(MAX_DAYS) });

export interface PlanItem {
  startTime: string;
  name: string;
  locality: string;
  description: string;
}
export interface PlanDay {
  dayNumber: number;
  title: string;
  items: PlanItem[];
}
export interface ValidPlan {
  language: "pl" | "en";
  days: PlanDay[];
}

export interface ValidationIssue {
  /** Log code, e.g. `items_count@day5` (no content). */
  code: string;
  /** Short English hint for the retry turn, e.g. "day 5: 5 items, required 6-7" (no content). */
  hint: string;
}

/**
 * `final`: retrying with the same input is pointless (safety filters, blocked prompt), so the
 * generation ends at once with ai_invalid_response (review PR #136 #5).
 */
export type ValidationResult =
  | { ok: true; plan: ValidPlan }
  | { ok: false; issues: ValidationIssue[]; final?: true };

/** finishReason values worth one retry: cut off by length, or an unspecified stop. */
export const RETRYABLE_FINISH = new Set(["MAX_TOKENS", "OTHER"]);

/** Hard cap on issues passed to the retry turn (~50-100 input tokens, sekcja 5). */
export const MAX_RETRY_HINTS = 8;

const fail = (code: string, hint: string): ValidationIssue => ({ code, hint });

function cleanText(s: string): string {
  return s.trim().normalize("NFC");
}

function checkText(
  value: string,
  field: keyof typeof TEXT_LIMITS,
  day: number,
  issues: ValidationIssue[],
): void {
  const max = TEXT_LIMITS[field];
  if (value.length === 0) issues.push(fail(`${field}_empty@day${day}`, `day ${day}: ${field} must not be empty`));
  else if ([...value].length > max) issues.push(fail(`${field}_len@day${day}`, `day ${day}: ${field} longer than ${max} characters`));
  if (FORBIDDEN_CHARS.test(value)) issues.push(fail(`${field}_chars@day${day}`, `day ${day}: ${field} has control or invisible characters`));
  if (URL_OR_MARKUP.test(value) || BARE_DOMAIN.test(value)) issues.push(fail(`${field}_url_markup@day${day}`, `day ${day}: ${field} contains a URL, e-mail or markup`));
}

/**
 * Validates one model attempt. Order as in sekcja 5: finishReason, JSON + shape, language/day count/
 * dayNumber, items per day, times, lengths, URLs/markup. Steps 1-2 stop at the first error (nothing
 * else can be checked); from step 3 on all issues are collected, so the retry gets the full list.
 */
export function validatePlanOutput(input: {
  finishReason: string | undefined;
  text: string | undefined;
  planLanguage: "pl" | "en";
  targets: readonly DayTarget[];
}): ValidationResult {
  if (input.finishReason !== "STOP") {
    const reason = /^[A-Z_]{1,40}$/.test(input.finishReason ?? "") ? input.finishReason! : "UNKNOWN";
    if (RETRYABLE_FINISH.has(reason)) {
      return { ok: false, issues: [fail(`finish_${reason}`, "the answer was cut off; keep descriptions shorter")] };
    }
    // SAFETY, PROHIBITED_CONTENT, SPII, BLOCKLIST, RECITATION, no candidate (UNKNOWN): no retry.
    return { ok: false, issues: [fail(`finish_${reason}`, "the answer was blocked")], final: true };
  }
  let parsed: unknown;
  try {
    parsed = JSON.parse(input.text ?? "");
  } catch {
    return { ok: false, issues: [fail("json_parse", "the answer was not valid JSON")] };
  }
  const shape = outputShape.safeParse(parsed);
  if (!shape.success) {
    return { ok: false, issues: [fail("schema", "the answer did not match the response schema")] };
  }

  const out = shape.data;
  const issues: ValidationIssue[] = [];
  if (out.language !== input.planLanguage) {
    issues.push(fail("language", `language must be "${input.planLanguage}"`));
  }
  if (out.days.length !== input.targets.length) {
    issues.push(fail("days_count", `exactly ${input.targets.length} days required, got ${out.days.length}`));
  }

  const days: PlanDay[] = [];
  out.days.forEach((raw, i) => {
    const n = i + 1;
    if (raw.dayNumber !== n) issues.push(fail(`day_number@day${n}`, `day at position ${n} must have dayNumber ${n}`));
    const target = input.targets[i];
    const count = raw.items.length;
    if (target && (count < target.minItems || count > target.maxItems)) {
      const req = target.minItems === target.maxItems ? `${target.minItems}` : `${target.minItems}-${target.maxItems}`;
      issues.push(fail(`items_count@day${n}`, `day ${n}: ${count} items, required ${req}`));
    }

    const title = cleanText(raw.title);
    checkText(title, "title", n, issues);

    let prev: string | undefined;
    let timeFmtReported = false;
    let orderReported = false;
    let floorReported = false;
    const items: PlanItem[] = raw.items.map((it) => {
      const item: PlanItem = {
        startTime: it.startTime.trim(),
        name: cleanText(it.name),
        locality: cleanText(it.locality),
        description: cleanText(it.description),
      };
      if (!TIME.test(item.startTime)) {
        if (!timeFmtReported) issues.push(fail(`time_format@day${n}`, `day ${n}: startTime must be HH:MM (24h)`));
        timeFmtReported = true;
      } else {
        // HH:MM strings compare correctly as text.
        if (prev !== undefined && item.startTime <= prev && !orderReported) {
          issues.push(fail(`time_order@day${n}`, `day ${n}: startTime must strictly increase`));
          orderReported = true;
        }
        prev = item.startTime;
        const floor = n === 1 ? target?.earliestStart : undefined;
        if (typeof floor === "string" && item.startTime < floor && !floorReported) {
          issues.push(fail("day1_before_floor@day1", `day 1: every startTime must be >= ${floor}`));
          floorReported = true;
        }
      }
      checkText(item.name, "name", n, issues);
      checkText(item.locality, "locality", n, issues);
      checkText(item.description, "description", n, issues);
      return item;
    });
    days.push({ dayNumber: raw.dayNumber, title, items });
  });

  if (issues.length > 0) return { ok: false, issues: dedupe(issues) };
  return { ok: true, plan: { language: out.language, days } };
}

function dedupe(issues: ValidationIssue[]): ValidationIssue[] {
  const seen = new Set<string>();
  return issues.filter((i) => (seen.has(i.code) ? false : (seen.add(i.code), true)));
}

/** Retry hints for the second attempt: at most MAX_RETRY_HINTS entries. */
export function retryHints(issues: readonly ValidationIssue[]): string[] {
  return issues.slice(0, MAX_RETRY_HINTS).map((i) => i.hint);
}
