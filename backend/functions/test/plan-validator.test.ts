// Synthetic cases shaped like the ARCH-01 failures (p3-05 sekcja 7); no files from the ARCH-01 run.
import { describe, expect, it } from "vitest";
import type { DayTarget } from "../src/plan-targets.js";
import { MAX_RETRY_HINTS, retryHints, validatePlanOutput } from "../src/plan-validator.js";
import { validOutput } from "./helpers/fakes.js";

const intense4: DayTarget[] = [
  { dayNumber: 1, minItems: 0, maxItems: 7, earliestStart: "16:00" },
  { dayNumber: 2, minItems: 6, maxItems: 7 },
  { dayNumber: 3, minItems: 6, maxItems: 7 },
  { dayNumber: 4, minItems: 1, maxItems: 7 },
];

const run = (body: unknown, targets = intense4, lang: "pl" | "en" = "pl", finishReason = "STOP") =>
  validatePlanOutput({ finishReason, text: typeof body === "string" ? body : JSON.stringify(body), planLanguage: lang, targets });

const codes = (r: ReturnType<typeof run>) => (r.ok ? [] : r.issues.map((i) => i.code));

describe("validatePlanOutput – valid plans", () => {
  it("accepts a plan within all targets and returns only known fields", () => {
    const body = validOutput(intense4) as Record<string, unknown>;
    body["extra"] = "dropped";
    const r = run(body);
    expect(r.ok).toBe(true);
    if (r.ok) {
      expect(Object.keys(r.plan)).toEqual(["language", "days"]);
      expect(r.plan.days).toHaveLength(4);
    }
  });
  it("accepts a short last day (1 item) and a minimal middle day", () => {
    expect(run(validOutput(intense4, "pl", (t) => (t.dayNumber === 4 ? 1 : t.dayNumber === 1 ? 0 : 6))).ok).toBe(true);
  });
  it("trims and NFC-normalises texts", () => {
    const body = validOutput(intense4);
    body.days[1]!.items[0]!.name = "  Café Central  ";
    const r = run(body);
    expect(r.ok && r.plan.days[1]!.items[0]!.name).toBe("Café Central");
  });
});

describe("validatePlanOutput – rejects (sekcja 5 order)", () => {
  it("1. finishReason other than STOP (e.g. MAX_TOKENS)", () => {
    expect(codes(run(validOutput(intense4), intense4, "pl", "MAX_TOKENS"))).toEqual(["finish_MAX_TOKENS"]);
    expect(run(validOutput(intense4), intense4, "pl", "MAX_TOKENS")).not.toHaveProperty("final");
    expect(run(validOutput(intense4), intense4, "pl", "OTHER")).not.toHaveProperty("final");
    // review #136 #5: blocked answers are final (no paid retry with the same input)
    for (const reason of ["SAFETY", "PROHIBITED_CONTENT", "SPII", "BLOCKLIST", "RECITATION"]) {
      expect(run(validOutput(intense4), intense4, "pl", reason)).toMatchObject({ ok: false, final: true });
    }
    expect(validatePlanOutput({ finishReason: undefined, text: undefined, planLanguage: "pl", targets: intense4 })).toMatchObject({ final: true });
    expect(validatePlanOutput({ finishReason: undefined, text: "{}", planLanguage: "pl", targets: intense4 }).ok).toBe(false);
  });
  it("2. invalid JSON and wrong shape", () => {
    expect(codes(run("{not json"))).toEqual(["json_parse"]);
    expect(codes(run({ language: "pl", days: [{ dayNumber: 1, title: "x" }] }))).toEqual(["schema"]);
    expect(codes(run({ language: "de", days: [] }))).toEqual(["schema"]);
  });
  it("3. language, day count and dayNumber sequence", () => {
    expect(codes(run(validOutput(intense4, "en")))).toContain("language");
    const short = validOutput(intense4);
    short.days.pop();
    expect(codes(run(short))).toContain("days_count");
    const renum = validOutput(intense4);
    renum.days[2]!.dayNumber = 5;
    expect(codes(run(renum))).toContain("day_number@day3");
  });
  it("4. too few items in a middle day (ARCH-01 C3 shape) and an empty last day", () => {
    const r = run(validOutput(intense4, "pl", (t) => (t.dayNumber === 3 ? 5 : t.dayNumber === 4 ? 0 : t.maxItems)));
    expect(codes(r)).toEqual(["items_count@day3", "items_count@day4"]);
    expect(retryHints(r.ok ? [] : r.issues)).toEqual(["day 3: 5 items, required 6-7", "day 4: 0 items, required 1-7"]);
  });
  it("4. too many items on any day", () => {
    expect(codes(run(validOutput(intense4, "pl", (t) => (t.dayNumber === 2 ? 8 : t.maxItems))))).toContain("items_count@day2");
  });
  it("4./5. day 1 not empty when the floor is after 22:00", () => {
    const late: DayTarget[] = [{ dayNumber: 1, minItems: 0, maxItems: 0, earliestStart: null }, { dayNumber: 2, minItems: 1, maxItems: 5 }];
    const body = validOutput([{ dayNumber: 1, minItems: 0, maxItems: 1, earliestStart: "22:00" }, late[1]!], "en");
    const r = run(body, late, "en");
    expect(codes(r)).toEqual(["items_count@day1"]);
    expect(retryHints(r.ok ? [] : r.issues)).toEqual(["day 1: 1 items, required 0"]);
    expect(run(validOutput(late, "en"), late, "en").ok).toBe(true);
  });
  it("5. time format, decreasing/equal times, day 1 before the floor", () => {
    const fmt = validOutput(intense4);
    fmt.days[1]!.items[0]!.startTime = "9:00";
    expect(codes(run(fmt))).toContain("time_format@day2");
    const order = validOutput(intense4);
    order.days[2]!.items[3]!.startTime = order.days[2]!.items[2]!.startTime;
    expect(codes(run(order))).toContain("time_order@day3");
    const early = validOutput(intense4);
    early.days[0]!.items[0]!.startTime = "15:59";
    expect(codes(run(early))).toContain("day1_before_floor@day1");
  });
  it("6. lengths and empty fields", () => {
    const b = validOutput(intense4);
    b.days[1]!.title = "x".repeat(81);
    b.days[1]!.items[0]!.name = "n".repeat(101);
    b.days[1]!.items[1]!.locality = "l".repeat(81);
    b.days[1]!.items[2]!.description = "d".repeat(301);
    b.days[2]!.items[0]!.name = "   ";
    expect(codes(run(b))).toEqual(
      expect.arrayContaining(["title_len@day2", "name_len@day2", "locality_len@day2", "description_len@day2", "name_empty@day3"]),
    );
    const edge = validOutput(intense4);
    edge.days[1]!.title = "x".repeat(80);
    edge.days[1]!.items[0]!.description = "d".repeat(300);
    expect(run(edge).ok).toBe(true);
  });
  it("7. URLs, e-mail, markup and control characters", () => {
    const cases: Array<[string, string]> = [
      ["See https://example.com", "description_url_markup@day2"],
      ["Tickets at www.example.org", "description_url_markup@day2"],
      ["Book on example.com/tickets", "description_url_markup@day2"],
      ["Write to info@example.com", "description_url_markup@day2"],
      ["<b>Bold</b> place", "description_url_markup@day2"],
      ["[link](x)", "description_url_markup@day2"],
      ["**Great** view", "description_url_markup@day2"],
      ["Info: visitporto.pt", "description_url_markup@day2"], // review #136 #6
      ["See ticket.de/x for hours", "description_url_markup@day2"],
      ["museum.it, open 9-17", "description_url_markup@day2"],
      ["Program na kultura.gov.hu/program", "description_url_markup@day2"],
      ["Hidden​text", "description_chars@day2"],
      ["Line\u0007bell", "description_chars@day2"],
    ];
    for (const [text, code] of cases) {
      const b = validOutput(intense4);
      b.days[1]!.items[0]!.description = text;
      expect(codes(run(b))).toContain(code);
    }
    const fine = validOutput(intense4);
    fine.days[1]!.items[0]!.description = "Zamek Królewski na Wawelu – dziedziniec, 3 sale i widok na Wisłę (ok. 2 h).";
    expect(run(fine).ok).toBe(true);
    // no false alarms on ordinary sentences (missing space after a full stop, abbreviations, times)
    for (const text of ["Walk to the square.It is lively at 19.30.", "Ok. 2 h, np. kawa i ciasto.", "St. Stephen's Basilica, 9.00-17.00."]) {
      const b = validOutput(intense4);
      b.days[1]!.items[0]!.description = text;
      expect(run(b).ok).toBe(true);
    }
  });
});

describe("issue codes and hints carry no content", () => {
  it("never include model text", () => {
    const b = validOutput(intense4);
    b.days[1]!.items[0]!.description = "SECRET-CANARY https://evil.example " + "x".repeat(300);
    b.days[1]!.title = "SECRET-CANARY".repeat(10);
    const r = run(b);
    expect(JSON.stringify(r)).not.toContain("SECRET-CANARY");
  });
  it("retry hints are capped", () => {
    const b = validOutput(intense4);
    for (const d of b.days) for (const it of d.items) it.name = "";
    const r = run(b);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(retryHints(r.issues).length).toBeLessThanOrEqual(MAX_RETRY_HINTS);
  });
});
