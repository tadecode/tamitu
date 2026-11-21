// Per-day item ranges computed in code, not by the model (p3-05-wymagania-generowania.md sekcja 4).
// The same targets go to the model (user turn, `dayTargets`) and to the validator.
import type { GeneratePlanRequest } from "./schemas.js";

export type Pace = GeneratePlanRequest["preferences"]["pace"];

/** Items per day by pace (posrednik-api.md pkt 2, data model pkt 1). */
export const PACE_RANGE: Readonly<Record<Pace, { min: number; max: number }>> = {
  relaxed: { min: 2, max: 3 },
  moderate: { min: 4, max: 5 },
  intense: { min: 6, max: 7 },
};

/** Buffer after arrival before the first activity (N6): 3 h by plane, 0 by car. */
export const ARRIVAL_BUFFER_MIN = { flight: 180, car: 0 } as const;

/** Latest allowed day-1 floor; a later floor means day 1 has no items (N6, US-006). */
export const DAY1_LATEST_FLOOR = "22:00";

export interface DayTarget {
  dayNumber: number;
  minItems: number;
  maxItems: number;
  /** Only on day 1: earliest allowed startTime (HH:MM); null = day 1 without items. */
  earliestStart?: string | null;
}

function toMinutes(hhmm: string): number {
  const [h, m] = hhmm.split(":").map(Number) as [number, number];
  return h * 60 + m;
}

function toHHMM(minutes: number): string {
  return `${String(Math.floor(minutes / 60)).padStart(2, "0")}:${String(minutes % 60).padStart(2, "0")}`;
}

/**
 * Day-1 floor: arrival time + buffer. Null when it is after 22:00 (also when it passes midnight,
 * e.g. 21:30 + 3 h): day 1 then has no activities.
 */
export function day1EarliestStart(arrival: GeneratePlanRequest["trip"]["arrival"]): string | null {
  const floor = toMinutes(arrival.time) + ARRIVAL_BUFFER_MIN[arrival.mode];
  return floor > toMinutes(DAY1_LATEST_FLOOR) ? null : toHHMM(floor);
}

/**
 * Ranges per day (sekcja 4, last-day rule approved by the owner 2026-11-21, O-TAM4-1):
 * - day 1 (also a one-day trip): 0..pace max, with the floor; floor null -> exactly 0;
 * - days 2..N-1: full pace range;
 * - last day (N >= 2): 1..pace max (departure day, lighter but never empty).
 */
export function computeDayTargets(request: GeneratePlanRequest): DayTarget[] {
  const range = PACE_RANGE[request.preferences.pace];
  const n = request.trip.days;
  const floor = day1EarliestStart(request.trip.arrival);
  const out: DayTarget[] = [];
  for (let d = 1; d <= n; d++) {
    if (d === 1) out.push({ dayNumber: 1, minItems: 0, maxItems: floor === null ? 0 : range.max, earliestStart: floor });
    else if (d === n) out.push({ dayNumber: d, minItems: 1, maxItems: range.max });
    else out.push({ dayNumber: d, minItems: range.min, maxItems: range.max });
  }
  return out;
}
