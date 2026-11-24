// Test doubles for P3-05: a scripted model (no network, 0 paid calls) and an in-memory quota store
// using the same pure functions as the Firestore transactions in index.ts.
import type { ModelCall, ModelResult, PlanModel } from "../../src/ai.js";
import {
  planBusyReleaseOutcome,
  planReleaseOutcome,
  planReservation,
  warsawDay,
  type BusyReleaseOutcome,
  type ReleaseOutcome,
  type ReservationPlan,
  type UsageDoc,
} from "../../src/limits.js";
import type { DayTarget } from "../../src/plan-targets.js";

/** Synthetic valid output for the given targets (max items, times from the day-1 floor or 09:00). */
export function validOutput(targets: readonly DayTarget[], language: "pl" | "en" = "pl", perDay?: (t: DayTarget) => number) {
  return {
    language,
    days: targets.map((t) => {
      const count = perDay ? perDay(t) : t.maxItems;
      const startMin = t.earliestStart ? Number(t.earliestStart.slice(0, 2)) * 60 + Number(t.earliestStart.slice(3)) : 9 * 60;
      const step = count > 1 ? Math.min(90, Math.floor((23 * 60 + 59 - startMin) / (count - 1))) : 0;
      return {
        dayNumber: t.dayNumber,
        title: `Day ${t.dayNumber}`,
        items: Array.from({ length: count }, (_, i) => {
          const m = startMin + i * step;
          return {
            startTime: `${String(Math.floor(m / 60)).padStart(2, "0")}:${String(m % 60).padStart(2, "0")}`,
            name: `Place ${t.dayNumber}.${i + 1}`,
            locality: "Testville",
            description: "Synthetic description of a public place.",
          };
        }),
      };
    }),
  };
}

export const ok = (body: unknown, finishReason = "STOP"): ModelResult => ({
  text: typeof body === "string" ? body : JSON.stringify(body),
  finishReason,
  modelVersion: "gemini-3.1-flash-lite-test",
  usage: { inputTokens: 900, outputTokens: 1500, thoughtTokens: 0 },
});

export type Step = ModelResult | Error | ((call: ModelCall) => ModelResult | Promise<ModelResult>);

/** Model that answers with the scripted steps in order and records every call. */
export function scriptedModel(steps: Step[]): PlanModel & { calls: ModelCall[] } {
  const calls: ModelCall[] = [];
  return {
    modelId: "gemini-3.1-flash-lite",
    location: "eu",
    calls,
    async generate(call) {
      calls.push(call);
      const s = steps[calls.length - 1];
      if (s === undefined) throw new Error("unexpected model call");
      if (s instanceof Error) throw s;
      return typeof s === "function" ? s(call) : s;
    },
  };
}

/** Model that always answers with a valid plan for the targets sent in the user turn. */
export function echoValidModel(language?: "pl" | "en"): PlanModel & { calls: ModelCall[] } {
  const calls: ModelCall[] = [];
  return {
    modelId: "gemini-3.1-flash-lite",
    location: "eu",
    calls,
    async generate(call) {
      calls.push(call);
      const data = JSON.parse(call.userText.slice(call.userText.indexOf("{"))) as {
        planLanguage: "pl" | "en";
        dayTargets: DayTarget[];
      };
      return ok(validOutput(data.dayTargets, language ?? data.planLanguage));
    },
  };
}

/** In-memory usage/{uid} + usage_global/{day}, same decisions as the Firestore transactions. */
export function memoryQuota() {
  const usage = new Map<string, UsageDoc & { expireAt: Date }>();
  const global = new Map<string, number>();
  return {
    usage,
    global,
    reserveQuota: async (uid: string, limits: { userLimit: number; globalLimit: number }, now: Date): Promise<ReservationPlan> => {
      const real = planReservation({ usage: usage.get(uid), globalCount: global.get(warsawDay(now)), ...limits, now });
      if (real.allowed) {
        const w = real.writes.usage;
        usage.set(uid, { day: w.day, count: w.count, released: w.released, busyReleased: w.busyReleased, expireAt: w.expireAt });
        global.set(real.reservation.day, real.writes.global.count);
      }
      return real;
    },
    releaseQuota: async (uid: string, day: string, now: Date): Promise<ReleaseOutcome> => {
      const r = planReleaseOutcome(usage.get(uid), day, now);
      if (r.outcome === "released") {
        const w = r.write;
        usage.set(uid, { day: w.day, count: w.count, released: w.released, busyReleased: w.busyReleased, expireAt: w.expireAt });
      }
      return r.outcome;
    },
    releaseBusyQuota: async (uid: string, day: string, now: Date): Promise<BusyReleaseOutcome> => {
      const r = planBusyReleaseOutcome(usage.get(uid), global.get(day), day, now);
      if (r.outcome === "busy_released") {
        const w = r.write;
        usage.set(uid, { day: w.day, count: w.count, released: w.released, busyReleased: w.busyReleased, expireAt: w.expireAt });
        if (global.has(day)) global.set(day, r.global.count);
      }
      return r.outcome;
    },
  };
}
