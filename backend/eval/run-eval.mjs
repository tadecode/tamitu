// P3-05 evaluation runner (ADR-0001 pkt 2: >= 20 cases x PL/EN, >= 95% valid within 2 attempts).
// Uses the PRODUCTION code path (prompt from --prompt, default plan-v1 as in production; responseSchema, validator incl. dup_place warnings, retry) from functions/lib.
//
// Modes (default = --estimate):
//   --estimate   no network: number of generations/calls and a cost estimate (costs.md prices)
//   --dry-run    no network: full pipeline with a fake model (checks the harness itself)
//   --paid       REAL Vertex AI calls in tamitu-dev-tadecode (PAID). Requires ALL of:
//                --confirm-paid-run, the owner's approval, env VERTEX_ACCESS_TOKEN
//                (owner: `gcloud auth print-access-token`, never stored in files), and stops at --stop-pln.
//
// Build first: npm --prefix backend/functions run build
// Run:        node backend/eval/run-eval.mjs [--estimate|--dry-run|--paid --confirm-paid-run] [--prompt plan-v1|plan-v2] [--stop-pln 2.5] [--only E03,E04] [--lang pl|en]
// Outputs (paid/dry-run): %TEMP%\tamitu-eval-p305\<timestamp>\ (plans for the owner's manual K3/K4 review + results.csv).
// Logs nothing to the cloud; prints only metadata (case id, attempts, issue codes, tokens, seconds, PLN).
import { createRequire } from "node:module";
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const require = createRequire(import.meta.url);
const lib = (m) => require(join(here, "..", "functions", "lib", m));
const { parseAiConfig, vertexModel } = lib("ai.js");
const { generateValidPlan } = lib("generate.js");
const { computeDayTargets } = lib("plan-targets.js");
const { parseGeneratePlan } = lib("schemas.js");
const { PROMPTS } = lib("prompt/index.js");

import { attemptCostPln, canStart, costPln, GuardError, parsePromptVersion, parseStopPln, priceFor, rawOption } from "./eval-guard.mjs";

const DEV_PROJECT = "tamitu-dev-tadecode";

const args = process.argv.slice(2);
const flag = (n) => args.includes(n);
let mode, stopPln, modelId, only, langs, location, promptVersion;
try {
  // Fail-closed (review PR #136 #3): a malformed option stops the run in EVERY mode.
  mode = flag("--paid") ? "paid" : flag("--dry-run") ? "dry-run" : "estimate";
  stopPln = parseStopPln(rawOption(args, "--stop-pln"));
  modelId = rawOption(args, "--model") ?? "gemini-3.1-flash-lite";
  priceFor(modelId);
  only = (rawOption(args, "--only") ?? "").split(",").filter(Boolean);
  const lang = rawOption(args, "--lang");
  if (lang !== undefined && lang !== "pl" && lang !== "en") throw new GuardError("--lang must be pl or en");
  langs = lang ? [lang] : ["pl", "en"];
  location = rawOption(args, "--location") ?? "eu";
  promptVersion = parsePromptVersion(rawOption(args, "--prompt"), Object.keys(PROMPTS));
} catch (e) {
  if (!(e instanceof GuardError)) throw e;
  console.error(`Refusing: ${e.message}`);
  process.exit(2);
}

const set = JSON.parse(readFileSync(join(here, "cases.json"), "utf8"));
const cases = set.cases.filter((c) => !only?.length || only.includes(c.id));

function isoDate(daysFromNow) {
  const d = new Date();
  d.setUTCDate(d.getUTCDate() + daysFromNow);
  return d.toISOString().slice(0, 10);
}

/** Builds the API request exactly like the app would (validated by the production schema). */
function buildRequest(c, lang, i) {
  const t = c.text[lang];
  const arrival = { mode: c.arrival.mode, date: isoDate(c.arrival.arrivalInDays), time: c.arrival.time };
  if (c.arrival.mode === "flight") arrival.airport = t.airport;
  const hex = (i + 1).toString(16).padStart(12, "0");
  return parseGeneratePlan(
    {
      apiVersion: 1,
      requestId: `00000000-0000-4000-8000-${hex}`,
      planLanguage: lang,
      trip: { destination: t.destination, lodging: t.lodging, days: c.days, arrival },
      preferences: { interests: c.interests, budget: c.budget, pace: c.pace, partySize: c.partySize },
      testData: true,
    },
    new Date(),
  );
}

/** Rough per-call token estimate: ~80 output tokens per item (costs.md sekcja 1), input ~1 100 + targets. */
function estimateTokens(request) {
  const targets = computeDayTargets(request);
  const items = targets.reduce((s, t) => s + t.maxItems, 0);
  return { input: 1100 + 25 * targets.length, output: 80 * items + 20 * targets.length + 50 };
}

const runs = [];
cases.forEach((c) => langs.forEach((lang) => runs.push({ c, lang, request: buildRequest(c, lang, runs.length) })));

// ---------------- estimate ----------------
const est = runs.map((r) => estimateTokens(r.request));
runs.forEach((r, i) => (r.estimate = est[i]));
const oneAttempt = est.reduce((s, e) => s + costPln(modelId, e.input, e.output), 0);
console.log(`Eval set ${set.version}: ${cases.length} cases x ${langs.length} languages = ${runs.length} generations (model ${modelId}, prompt ${promptVersion})`);
console.log(`Calls: min ${runs.length}, max ${runs.length * 2} (2 attempts each)`);
console.log(`Estimated cost: ~${oneAttempt.toFixed(2)} PLN at 1 attempt each, ~${(oneAttempt * 1.4).toFixed(2)} PLN with 40% retries, worst case ${(oneAttempt * 2).toFixed(2)} PLN; ceiling ${stopPln} PLN (a generation starts only if its worst case still fits)`);
if (mode === "estimate") process.exit(0);

// ---------------- model ----------------
let model;
if (mode === "paid") {
  if (!flag("--confirm-paid-run")) {
    console.error("Refusing: --paid needs --confirm-paid-run (owner approval required, costs real money).");
    process.exit(2);
  }
  const token = process.env.VERTEX_ACCESS_TOKEN;
  if (!token) {
    console.error("Refusing: set VERTEX_ACCESS_TOKEN (owner: gcloud auth print-access-token). Never write it to a file.");
    process.exit(2);
  }
  const cfg = parseAiConfig({ AI_MODEL_ID: modelId, AI_LOCATION: location, GCLOUD_PROJECT: DEV_PROJECT });
  if (!cfg) {
    console.error("Refusing: invalid model/location (allowed locations: eu, europe-west4).");
    process.exit(2);
  }
  model = vertexModel(cfg, { fetch, token: async () => token });
} else {
  // Fake model: answers with a valid plan for the targets in the data turn (no network).
  model = {
    modelId: `${modelId}-fake`,
    location: "none",
    async generate(call) {
      const data = JSON.parse(call.userText.slice(call.userText.indexOf("{")));
      const days = data.dayTargets.map((t) => {
        const start = t.earliestStart ? Number(t.earliestStart.slice(0, 2)) * 60 + Number(t.earliestStart.slice(3)) : 540;
        const n = t.maxItems;
        const step = n > 1 ? Math.min(90, Math.floor((1439 - start) / (n - 1))) : 0;
        return {
          dayNumber: t.dayNumber,
          title: `Day ${t.dayNumber}`,
          items: Array.from({ length: n }, (_, i) => {
            const m = start + i * step;
            return { startTime: `${String(Math.floor(m / 60)).padStart(2, "0")}:${String(m % 60).padStart(2, "0")}`, name: `Place ${t.dayNumber}.${i + 1}`, locality: "Testville", description: "Synthetic." };
          }),
        };
      });
      return { text: JSON.stringify({ language: data.planLanguage, days }), finishReason: "STOP", modelVersion: "fake", usage: { inputTokens: 0, outputTokens: 0, thoughtTokens: 0 } };
    },
  };
}

// ---------------- run ----------------
const outDir = join(tmpdir(), "tamitu-eval-p305", new Date().toISOString().replace(/[:.]/g, "-"));
mkdirSync(outDir, { recursive: true });
let spent = 0;
const results = [];
for (const r of runs) {
  if (mode === "paid" && !canStart(spent, modelId, r.estimate, stopPln)) {
    console.warn(`STOP: spent ${spent.toFixed(3)} PLN; next generation could exceed the ${stopPln} PLN ceiling`);
    break;
  }
  const attempts = [];
  const started = Date.now();
  let outcome = "ok";
  let plan;
  try {
    plan = (await generateValidPlan(r.request, model, { prompt: PROMPTS[promptVersion], onAttempt: (a) => attempts.push(a) })).plan;
  } catch (e) {
    outcome = e?.appCode ?? "error";
  }
  // Attempts without usage data (timeout, 5xx) are charged at the estimate: they may be billed.
  const cost = attempts.reduce((s, a) => s + attemptCostPln(modelId, a, r.estimate), 0);
  spent += mode === "paid" ? cost : 0;
  const row = {
    case: r.c.id,
    lang: r.lang,
    prompt: attempts[0]?.promptVersion ?? promptVersion,
    days: r.c.days,
    pace: r.c.pace,
    outcome,
    attempts: attempts.length,
    firstAttemptOk: attempts[0]?.outcome === "ok",
    issues: attempts.map((a) => a.validationErrors ?? a.modelError ?? "").filter(Boolean).join(" | "),
    qualityWarnings: attempts.map((a) => a.qualityWarnings ?? "").filter(Boolean).join(" | "),
    tokensIn: attempts.reduce((s, a) => s + (a.tokensIn ?? 0), 0),
    tokensOut: attempts.reduce((s, a) => s + (a.tokensOut ?? 0), 0),
    tokensThought: attempts.reduce((s, a) => s + (a.tokensThought ?? 0), 0),
    seconds: Math.round((Date.now() - started) / 100) / 10,
    pln: Math.round(cost * 1000) / 1000,
  };
  results.push(row);
  if (plan) writeFileSync(join(outDir, `${r.c.id}-${r.lang}.json`), JSON.stringify({ case: r.c, lang: r.lang, plan }, null, 2));
  console.log(`${row.case} ${row.lang} ${row.outcome} attempts=${row.attempts} ${row.issues} ${row.qualityWarnings} ${row.seconds}s ${row.pln} PLN`);
}

const okCount = results.filter((x) => x.outcome === "ok").length;
const first = results.filter((x) => x.firstAttemptOk).length;
const withRepeats = results.filter((x) => x.qualityWarnings).length;
const csvHead = Object.keys(results[0] ?? { case: "" });
writeFileSync(join(outDir, "results.csv"), [csvHead.join(","), ...results.map((x) => csvHead.map((k) => JSON.stringify(x[k] ?? "")).join(","))].join("\n"));
console.log(`\nValid within 2 attempts: ${okCount}/${results.length} (${((100 * okCount) / Math.max(1, results.length)).toFixed(1)}%, threshold 95%)`);
console.log(`Valid at first attempt: ${first}/${results.length} (retry rate ${(100 - (100 * first) / Math.max(1, results.length)).toFixed(1)}%)`);
console.log(`Plans with a repeated place (dup_place, TAM-95; warning only, upper estimate, not counted as invalid): ${withRepeats}/${okCount} valid plans`);
console.log(`Cost (from usage): ${spent.toFixed(3)} PLN. Output: ${outDir}`);
console.log("Manual review K3/K4 (arch-01-gemini-test.md 4.6): the owner reads the plans in the output folder.");
