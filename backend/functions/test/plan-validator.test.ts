// Synthetic cases shaped like the ARCH-01 failures (p3-05 sekcja 7); no files from the ARCH-01 run.
import { describe, expect, it } from "vitest";
import type { DayTarget } from "../src/plan-targets.js";
import { isSamePlace, MAX_RETRY_HINTS, placeKey, placeNameTokens, retryHints, sameTokens, validatePlanOutput } from "../src/plan-validator.js";
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

// TAM-95: the same place on two days (QA TAM-88 K4 c). Synthetic plans; names shaped like the QA findings.
describe("repeated places (TAM-95) – warning only, plan stays valid", () => {
  const targets3: DayTarget[] = [
    { dayNumber: 1, minItems: 2, maxItems: 2, earliestStart: "09:00" },
    { dayNumber: 2, minItems: 2, maxItems: 2 },
    { dayNumber: 3, minItems: 2, maxItems: 2 },
  ];
  const withNames = (names: [string, string][], lang: "pl" | "en" = "en") => {
    const body = validOutput(targets3, lang);
    names.forEach((pair, d) => pair.forEach((name, i) => (body.days[d]!.items[i]!.name = name)));
    return run(body, targets3, lang);
  };
  const warnings = (r: ReturnType<typeof run>) => (r.ok ? r.warnings : ["NOT_OK"]);

  it("no repeats -> no warnings", () => {
    expect(warnings(withNames([["Colosseum", "Roman Forum"], ["Pantheon", "Trevi Fountain"], ["Villa Borghese", "Galleria Borghese"]]))).toEqual([]);
  });
  it('E03-en: "X" and "X Morning Market" on two days', () => {
    expect(warnings(withNames([["Colosseum", "Campo de' Fiori"], ["Pantheon", "Trevi Fountain"], ["Vatican Museums", "Campo de' Fiori Morning Market"]]))).toEqual(["dup_place@day3"]);
  });
  it('E17-pl: "Restauracja X" and "Tarihi X Selim Usta" (filler word + longer name)', () => {
    expect(
      warnings(withNames([["Hagia Sophia", "Restauracja Sultanahmet Koftecisi"], ["Tarihi Sultanahmet Koftecisi Selim Usta", "Cysterna Bazyliki"], ["Wielki Bazar", "Galata"]], "pl")),
    ).toEqual(["dup_place@day2"]);
  });
  it("case, diacritics, Polish ł and punctuation do not hide a repeat", () => {
    expect(warnings(withNames([["Wawel", "Sukiennice"], ["Kościół Mariacki", "Muzeum Czartoryskich"], ["KOSCIOL MARIACKI", "Kładka Bernatka"]], "pl"))).toEqual(["dup_place@day3"]);
    expect(warnings(withNames([["Wawel", "Kladka Bernatka"], ["Kładka  Bernatka!", "Sukiennice"], ["Kazimierz", "Podgorze"]], "pl"))).toEqual(["dup_place@day2"]);
  });
  it('E13-en: a colloquial name ("Fontana Pretoria" / "Piazza della Vergogna") is out of reach (documented limit)', () => {
    expect(warnings(withNames([["Palermo Cathedral", "Fontana Pretoria"], ["Teatro Massimo", "Ballaro Market"], ["Monreale", "Piazza della Vergogna"]]))).toEqual([]);
  });
  it("borderline from QA is not a repeat: Pantheon and Piazza della Rotonda; one-word name inside a longer one", () => {
    expect(warnings(withNames([["Pantheon", "Colosseum"], ["Piazza della Rotonda", "Trevi Fountain"], ["Vatican", "Vatican Museums"]]))).toEqual([]);
  });
  it("same name twice in one day is not reported (rule covers different days)", () => {
    expect(warnings(withNames([["Colosseum", "Colosseum"], ["Pantheon", "Trevi Fountain"], ["Villa Borghese", "Spanish Steps"]]))).toEqual([]);
  });
  it("one code per later day; warnings never turn into retry issues", () => {
    const r = withNames([["Colosseum", "Pantheon"], ["The Colosseum", "Pantheon"], ["Colosseum", "Trevi Fountain"]]);
    expect(r.ok).toBe(true);
    expect(warnings(r)).toEqual(["dup_place@day2", "dup_place@day3"]);
  });
  it("names that are only filler words are ignored", () => {
    expect(warnings(withNames([["Restaurant", "Colosseum"], ["Restaurant", "Pantheon"], ["Night Market", "Night Market"]]))).toEqual([]);
  });
});

describe("placeNameTokens / sameTokens", () => {
  it("folds case, marks, punctuation and filler words", () => {
    expect(placeNameTokens("Campo de' Fiori Morning Market")).toEqual(["campo", "de", "fiori"]);
    expect(placeNameTokens("Restauracja Łazienki Królewskie")).toEqual(["lazienki", "krolewskie"]);
    expect(placeNameTokens("Café Central")).toEqual(["central"]);
  });
  it("matches equal lists and contiguous runs of >= 2 tokens only", () => {
    expect(sameTokens(["a", "b"], ["x", "a", "b", "y"])).toBe(true);
    expect(sameTokens(["a", "b"], ["a", "x", "b"])).toBe(false);
    expect(sameTokens(["a"], ["a", "b"])).toBe(false);
    expect(sameTokens(["a"], ["a"])).toBe(true);
    expect(sameTokens([], [])).toBe(false);
  });
});

// Review PR #148 #1: false alarms of dup_place (synthetic, shaped like the reviewer's examples).
describe("repeated places – no false alarms (review PR #148 #1)", () => {
  const targets3: DayTarget[] = [
    { dayNumber: 1, minItems: 2, maxItems: 2, earliestStart: "09:00" },
    { dayNumber: 2, minItems: 2, maxItems: 2 },
    { dayNumber: 3, minItems: 2, maxItems: 2 },
  ];
  type P = [name: string, locality: string];
  const plan = (days: [P, P][], lang: "pl" | "en" = "en") => {
    const body = validOutput(targets3, lang);
    days.forEach((pair, d) =>
      pair.forEach(([name, locality], i) => {
        body.days[d]!.items[i]!.name = name;
        body.days[d]!.items[i]!.locality = locality;
      }),
    );
    const r = run(body, targets3, lang);
    return r.ok ? r.warnings : ["NOT_OK"];
  };

  it("(a) the same name in two different towns is not a repeat", () => {
    expect(plan([[["Stare Miasto", "Gdańsk"], ["Dwór Artusa", "Gdańsk"]], [["Zamek w Malborku", "Malbork"], ["Muzeum Zamkowe", "Malbork"]], [["Stare Miasto", "Toruń"], ["Main Square", "Toruń"]]], "pl")).toEqual([]);
    expect(plan([[["Main Square", "Krakow"], ["Wawel", "Krakow"]], [["Main Square", "Wroclaw"], ["Ostrow Tumski", "Wroclaw"]], [["Old Town", "Gdansk"], ["Crane", "Gdansk"]]])).toEqual([]);
  });
  it("(a) locality is compared after normalisation: case and diacritics do not hide a repeat", () => {
    expect(plan([[["Kosciol Mariacki", "Kraków"], ["Wawel", "Kraków"]], [["Kościół Mariacki", "KRAKOW"], ["Sukiennice", "Krakow"]], [["Kazimierz", "Krakow"], ["Podgorze", "Krakow"]]], "pl")).toEqual(["dup_place@day2"]);
  });
  it("(b) a generic two-word name inside a longer name is not a repeat", () => {
    expect(plan([[["Old Town", "Riga"], ["Central Park", "Riga"]], [["Old Town Hall", "Riga"], ["Central Park Zoo", "Riga"]], [["Muzeum Narodowe", "Riga"], ["Muzeum Narodowe – Sukiennice", "Riga"]]])).toEqual([]);
  });
  it("(b) the exact generic name twice in one town still is a repeat", () => {
    expect(plan([[["Old Town", "Riga"], ["Central Market", "Riga"]], [["The Old Town", "Riga"], ["Art Nouveau District", "Riga"]], [["Jurmala Beach", "Jurmala"], ["Dzintari", "Jurmala"]]])).toEqual(["dup_place@day2"]);
  });
  it("(c) a restaurant and a cafe with the same name stay two places; a restaurant named two ways is one", () => {
    expect(plan([[["Ristorante Da Enzo", "Rome"], ["Colosseum", "Rome"]], [["Caffè Da Enzo", "Rome"], ["Pantheon", "Rome"]], [["Villa Borghese", "Rome"], ["Spanish Steps", "Rome"]]])).toEqual([]);
    expect(plan([[["Ristorante Da Enzo", "Rome"], ["Colosseum", "Rome"]], [["Da Enzo al 29", "Rome"], ["Pantheon", "Rome"]], [["Villa Borghese", "Rome"], ["Spanish Steps", "Rome"]]])).toEqual(["dup_place@day2"]);
  });
  it("QA cases are still caught with a shared locality (E03-en, E17-pl)", () => {
    expect(plan([[["Campo de' Fiori", "Rome"], ["Colosseum", "Rome"]], [["Pantheon", "Rome"], ["Trevi Fountain", "Rome"]], [["Campo de' Fiori Morning Market", "Rome"], ["Vatican Museums", "Vatican City"]]])).toEqual(["dup_place@day3"]);
    expect(plan([[["Restauracja Sultanahmet Koftecisi", "Stambuł"], ["Hagia Sophia", "Stambuł"]], [["Tarihi Sultanahmet Koftecisi Selim Usta", "Stambuł"], ["Galata", "Stambuł"]], [["Wyspy Książęce", "Büyükada"], ["Pałac Dolmabahçe", "Stambuł"]]], "pl")).toEqual(["dup_place@day2"]);
  });
  it("placeKey keeps the venue kind and the normalised locality", () => {
    expect(placeKey({ name: "Caffè Greco", locality: "Roma " })).toEqual({ locality: "roma", tokens: ["greco"], kind: "cafe" });
    expect(isSamePlace(placeKey({ name: "Greco", locality: "Roma" }), placeKey({ name: "Greco", locality: "Milano" }))).toBe(false);
  });
});

// Review PR #148 #4 a/b: the longest possible log value fits the 200-character cap of qualityWarnings.
describe("qualityWarnings length (review PR #148 #4)", () => {
  it("a 14-day plan with a repeat on every day 2-14 gives 13 codes within 200 characters", () => {
    const t14: DayTarget[] = Array.from({ length: 14 }, (_, i) => ({ dayNumber: i + 1, minItems: 1, maxItems: 1, ...(i === 0 ? { earliestStart: "09:00" } : {}) }));
    const body = validOutput(t14);
    body.days.forEach((d) => (d.items[0]!.name = "Colosseum"));
    const r = run(body, t14, "pl");
    expect(r.ok).toBe(true);
    const joined = r.ok ? r.warnings.join(",") : "";
    expect(r.ok && r.warnings).toHaveLength(13);
    expect(joined.length).toBeLessThanOrEqual(200);
  });
});
