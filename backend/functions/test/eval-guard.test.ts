// Cost guard of backend/eval/run-eval.mjs (review PR #136 #3): the stop must never be disabled silently.
import { join } from "node:path";
import { pathToFileURL } from "node:url";
import { beforeAll, describe, expect, it } from "vitest";

// Plain .mjs outside the TS project: loaded dynamically (typed loosely on purpose).
let g: {
  parseStopPln: (raw: string | undefined) => number;
  rawOption: (argv: string[], name: string) => string | undefined;
  priceFor: (model: string) => [number, number];
  costPln: (model: string, i: number, o: number) => number;
  attemptCostPln: (model: string, a: Record<string, number | undefined>, e: { input: number; output: number }) => number;
  canStart: (spent: number, model: string, e: { input: number; output: number }, stop: number) => boolean;
  GuardError: new (m: string) => Error;
  MAX_STOP_PLN: number;
};

beforeAll(async () => {
  g = await import(pathToFileURL(join(__dirname, "..", "..", "eval", "eval-guard.mjs")).href);
});

describe("parseStopPln (fail-closed)", () => {
  it("defaults to 2.5 and accepts a decimal point or comma", () => {
    expect(g.parseStopPln(undefined)).toBe(2.5);
    expect(g.parseStopPln("2.5")).toBe(2.5);
    expect(g.parseStopPln("2,5")).toBe(2.5);
    expect(g.parseStopPln("1")).toBe(1);
    expect(g.parseStopPln(" 0,75 ")).toBe(0.75);
  });
  it.each(["abc", "", "NaN", "Infinity", "-1", "0", "0,0", "2.6", "3", "1e1", "2,5,1", "2.5 PLN", "0x2"])(
    "refuses %j",
    (raw) => {
      expect(() => g.parseStopPln(raw)).toThrow(g.GuardError);
    },
  );
  it("never returns a value that disables the stop", () => {
    for (const raw of ["2,5", "2.5", "0.01"]) {
      const v = g.parseStopPln(raw);
      expect(Number.isFinite(v) && v > 0 && v <= g.MAX_STOP_PLN).toBe(true);
    }
  });
});

describe("rawOption", () => {
  it("absent -> undefined; flag without a value -> error (no silent default)", () => {
    expect(g.rawOption(["--paid"], "--stop-pln")).toBeUndefined();
    expect(g.rawOption(["--stop-pln", "1,5"], "--stop-pln")).toBe("1,5");
    expect(() => g.rawOption(["--stop-pln"], "--stop-pln")).toThrow(g.GuardError);
    expect(() => g.rawOption(["--stop-pln", "--lang", "pl"], "--stop-pln")).toThrow(g.GuardError);
  });
});

describe("prices and charging", () => {
  it("refuses models without a known price", () => {
    expect(g.priceFor("gemini-3.1-flash-lite")).toEqual([0.275, 1.65]);
    expect(() => g.priceFor("gemini-3.8-pro")).toThrow(g.GuardError);
  });
  it("charges attempts without usage data (timeout/5xx) at the estimate", () => {
    const est = { input: 1200, output: 3000 };
    expect(g.attemptCostPln("gemini-3.1-flash-lite", { tokensIn: 0, tokensOut: 0 }, est)).toBeCloseTo(g.costPln("gemini-3.1-flash-lite", 1200, 3000));
    expect(g.attemptCostPln("gemini-3.1-flash-lite", { tokensIn: 100, tokensOut: 200, tokensThought: 50 }, est)).toBeCloseTo(
      g.costPln("gemini-3.1-flash-lite", 100, 250),
    );
  });
  it("starts a generation only if its worst case still fits under the ceiling", () => {
    const est = { input: 1450, output: 8200 }; // 14 days intense
    const worst = 3 * g.costPln("gemini-3.1-flash-lite", est.input, est.output);
    expect(g.canStart(0, "gemini-3.1-flash-lite", est, 2.5)).toBe(true);
    expect(g.canStart(2.5 - worst + 0.0001, "gemini-3.1-flash-lite", est, 2.5)).toBe(false);
    expect(g.canStart(2.5 - worst - 0.0001, "gemini-3.1-flash-lite", est, 2.5)).toBe(true);
  });
});
