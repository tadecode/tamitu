import { describe, expect, it } from "vitest";
import { computeDayTargets, day1EarliestStart } from "../src/plan-targets.js";
import type { GeneratePlanRequest } from "../src/schemas.js";

const req = (
  days: number,
  pace: "relaxed" | "moderate" | "intense",
  arrival: GeneratePlanRequest["trip"]["arrival"] = { mode: "car", date: "2027-05-08", time: "09:00" },
): GeneratePlanRequest => ({
  apiVersion: 1,
  requestId: "7f0c2a9e-6f0e-4c3a-9a43-0b6c4a1f5d11",
  planLanguage: "pl",
  trip: { destination: "X", lodging: "Y", days, arrival },
  preferences: { interests: [], budget: "medium", pace, partySize: 2 },
});

describe("day 1 floor (N6, US-006)", () => {
  it("adds 3 h for a flight and 0 for a car", () => {
    expect(day1EarliestStart({ mode: "flight", date: "2027-03-12", time: "18:10", airport: "LIS" })).toBe("21:10");
    expect(day1EarliestStart({ mode: "car", date: "2027-03-12", time: "09:00" })).toBe("09:00");
  });
  it("22:00 exactly is allowed; later (or past midnight) means no items", () => {
    expect(day1EarliestStart({ mode: "flight", date: "2027-03-12", time: "19:00", airport: "A" })).toBe("22:00");
    expect(day1EarliestStart({ mode: "flight", date: "2027-03-12", time: "19:01", airport: "A" })).toBeNull();
    expect(day1EarliestStart({ mode: "flight", date: "2027-03-12", time: "20:30", airport: "A" })).toBeNull();
    expect(day1EarliestStart({ mode: "flight", date: "2027-03-12", time: "23:30", airport: "A" })).toBeNull();
    expect(day1EarliestStart({ mode: "car", date: "2027-03-12", time: "22:01" })).toBeNull();
  });
});

describe("computeDayTargets (sekcja 4)", () => {
  it("day 1: 0..max; middle days: full pace range; last day: 1..max", () => {
    expect(computeDayTargets(req(4, "intense"))).toEqual([
      { dayNumber: 1, minItems: 0, maxItems: 7, earliestStart: "09:00" },
      { dayNumber: 2, minItems: 6, maxItems: 7 },
      { dayNumber: 3, minItems: 6, maxItems: 7 },
      { dayNumber: 4, minItems: 1, maxItems: 7 },
    ]);
  });
  it("uses the pace ranges 2-3 / 4-5 / 6-7", () => {
    expect(computeDayTargets(req(3, "relaxed"))[1]).toMatchObject({ minItems: 2, maxItems: 3 });
    expect(computeDayTargets(req(3, "moderate"))[1]).toMatchObject({ minItems: 4, maxItems: 5 });
    expect(computeDayTargets(req(3, "intense"))[1]).toMatchObject({ minItems: 6, maxItems: 7 });
  });
  it("one-day trip follows the day-1 rule; two-day trip has no middle days", () => {
    expect(computeDayTargets(req(1, "moderate"))).toEqual([{ dayNumber: 1, minItems: 0, maxItems: 5, earliestStart: "09:00" }]);
    expect(computeDayTargets(req(2, "relaxed")).map((t) => [t.minItems, t.maxItems])).toEqual([[0, 3], [1, 3]]);
  });
  it("late arrival: day 1 exactly 0 items, never a floor after 22:00", () => {
    const t = computeDayTargets(req(2, "moderate", { mode: "flight", date: "2027-04-20", time: "20:30", airport: "OPO" }));
    expect(t[0]).toEqual({ dayNumber: 1, minItems: 0, maxItems: 0, earliestStart: null });
  });
  it("14 days: 12 full middle days", () => {
    const t = computeDayTargets(req(14, "intense"));
    expect(t).toHaveLength(14);
    expect(t.slice(1, 13).every((d) => d.minItems === 6 && d.maxItems === 7)).toBe(true);
    expect(t[13]).toEqual({ dayNumber: 14, minItems: 1, maxItems: 7 });
  });
});
