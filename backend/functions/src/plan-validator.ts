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
  /** `warnings`: quality codes for the log only (no content), e.g. `dup_place@day14`; never a retry. */
  | { ok: true; plan: ValidPlan; warnings: string[] }
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
  return { ok: true, plan: { language: out.language, days }, warnings: findRepeatedPlaces(days) };
}

/**
 * Words the model adds to a place name without changing the place (QA TAM-88 K4 c: "Campo de' Fiori" and
 * "Campo de' Fiori Morning Market", "Restauracja X" and "Tarihi X Selim Usta"). Kept short on purpose:
 * each extra word makes two different places look alike.
 */
const NAME_FILLERS: ReadonlySet<string> = new Set(["the", "market", "morning", "evening", "night", "visit", "wizyta"]);

/**
 * Venue-type words: dropped from the name like fillers, but remembered as the kind of venue, so
 * "Ristorante Da Enzo" and "Caffe Da Enzo" stay two places (review PR #148 #1 c).
 */
const VENUE_KIND: Readonly<Record<string, "restaurant" | "cafe">> = {
  restaurant: "restaurant",
  ristorante: "restaurant",
  restaurante: "restaurant",
  restauracja: "restaurant",
  cafe: "cafe",
  caffe: "cafe",
  kawiarnia: "cafe",
};

/**
 * Generic geographic words. A name made only of these ("Old Town", "Central Park", "Muzeum Narodowe",
 * "Stare Miasto") is not unique enough to count when it is contained in a longer name ("Old Town Hall",
 * "Central Park Zoo"); only an exact match counts (review PR #148 #1 b).
 */
const GENERIC_WORDS: ReadonlySet<string> = new Set([
  "old", "new", "town", "city", "main", "central", "grand", "royal", "national", "square", "park", "garden",
  "gardens", "museum", "gallery", "hall", "palace", "castle", "cathedral", "church", "tower", "bridge", "beach",
  "harbour", "harbor", "port", "street", "viewpoint", "lake", "river", "stare", "stary", "nowe", "nowy", "miasto",
  "rynek", "glowny", "glowna", "plac", "ogrod", "muzeum", "narodowe", "narodowy", "galeria", "ratusz",
  "palac", "zamek", "katedra", "kosciol", "wieza", "most", "plaza", "punkt", "widokowy", "piazza", "centro",
  "storico", "museo", "duomo",
]);

/** Letters that NFKD does not split into base letter + mark. */
const FOLD: Readonly<Record<string, string>> = { ł: "l", ø: "o", đ: "d", ı: "i", ß: "ss", æ: "ae", œ: "oe" };

function words(text: string): string[] {
  return text
    .toLowerCase()
    .normalize("NFKD")
    .replace(/\p{M}/gu, "")
    .replace(/[łøđıßæœ]/g, (c) => FOLD[c] ?? c)
    .split(/[^\p{L}\p{N}]+/u)
    .filter((t) => t.length > 0);
}

/** Lower case, no diacritics, no punctuation, no filler or venue words: "Campo de' Fiori Market" -> [campo, de, fiori]. */
export function placeNameTokens(name: string): string[] {
  return words(name).filter((t) => !NAME_FILLERS.has(t) && VENUE_KIND[t] === undefined);
}

export interface PlaceKey {
  /** Normalised locality: places in different towns are never the same place (review PR #148 #1 a). */
  locality: string;
  tokens: string[];
  kind?: "restaurant" | "cafe" | undefined;
}

export function placeKey(item: Pick<PlanItem, "name" | "locality">): PlaceKey {
  const kind = words(item.name)
    .map((t) => VENUE_KIND[t])
    .find((k) => k !== undefined);
  return { locality: words(item.locality).join(" "), tokens: placeNameTokens(item.name), kind };
}

/**
 * Same place: same locality, no conflicting venue kind, and the token lists are equal, or the shorter one
 * (>= 2 tokens, at least one of them not generic) appears as a contiguous run inside the longer one.
 * One-word names only match exactly ("Vatican" vs "Vatican Museums" is not a repeat). Colloquial names
 * ("Fontana Pretoria" / "Piazza della Vergogna") need knowledge of places and are out of reach of this
 * rule; the prompt covers them. The count is an upper estimate: check a sample by hand before turning
 * the warning into a (paid) retry.
 */
export function isSamePlace(a: PlaceKey, b: PlaceKey): boolean {
  if (a.locality !== b.locality) return false;
  if (a.kind !== undefined && b.kind !== undefined && a.kind !== b.kind) return false;
  return sameTokens(a.tokens, b.tokens);
}

export function sameTokens(a: readonly string[], b: readonly string[]): boolean {
  if (a.length === 0 || b.length === 0) return false;
  const [short, long] = a.length <= b.length ? [a, b] : [b, a];
  if (short.length === long.length) return short.every((t, i) => t === long[i]);
  if (short.length < 2 || short.every((t) => GENERIC_WORDS.has(t))) return false;
  for (let start = 0; start + short.length <= long.length; start++) {
    if (short.every((t, i) => t === long[start + i])) return true;
  }
  return false;
}

/**
 * The same place on two different days (TAM-95). Returns codes `dup_place@dayN` (N = the later day),
 * at most one per day. Repeats within one day are not checked (QA saw none).
 */
export function findRepeatedPlaces(days: readonly PlanDay[]): string[] {
  const earlier: PlaceKey[] = [];
  const codes: string[] = [];
  days.forEach((d, i) => {
    const current = d.items.map(placeKey);
    if (current.some((k) => earlier.some((e) => isSamePlace(e, k)))) codes.push(`dup_place@day${i + 1}`);
    earlier.push(...current);
  });
  return codes;
}

function dedupe(issues: ValidationIssue[]): ValidationIssue[] {
  const seen = new Set<string>();
  return issues.filter((i) => (seen.has(i.code) ? false : (seen.add(i.code), true)));
}

/** Retry hints for the second attempt: at most MAX_RETRY_HINTS entries. */
export function retryHints(issues: readonly ValidationIssue[]): string[] {
  return issues.slice(0, MAX_RETRY_HINTS).map((i) => i.hint);
}
