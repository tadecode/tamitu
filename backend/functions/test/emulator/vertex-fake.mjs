// TAM-89: deterministic fake of the Vertex AI generateContent endpoint, for the Firebase emulator ONLY.
// The Functions emulator reaches it through AI_ENDPOINT_OVERRIDE (accepted only with FUNCTIONS_EMULATOR=true,
// a demo-* project and a 127.0.0.1/localhost URL - src/ai.ts parseAiEndpointOverride).
// No external network, no keys, no dependencies (Node 22). Listens on 127.0.0.1 only.
//
// Use from a test (same process, e.g. node:test in tests/firebase-emulator/):
//   import { startVertexFake } from "../../backend/functions/test/emulator/vertex-fake.mjs";
//   const fake = await startVertexFake({ port: 8787 });   // default scenario: "valid"
//   fake.enqueue("busy", "valid");   // next calls: 429, then a valid plan; afterwards the default again
//   fake.setDefault("invalid");      // every call without a queued scenario
//   fake.calls                       // [{ n, scenario, status, model, location, hints }]
//   fake.reset(); await fake.close();
// Or standalone (another process): `node vertex-fake.mjs --port 8787 [--default valid]` and control it with
//   POST http://127.0.0.1:8787/__fake/control  {"reset":true,"default":"valid","queue":["busy","valid"]}
//   GET  http://127.0.0.1:8787/__fake/calls
import { createServer } from "node:http";
import process from "node:process";
import { setTimeout as delay } from "node:timers/promises";
import { pathToFileURL, URL } from "node:url";
import { Buffer } from "node:buffer";

/**
 * What the fake answers, per model call (function result in brackets, see backend/eval/README.md):
 * - valid:        200, valid plan for the dayTargets of the request          (ok)
 * - invalid:      200, plan with no days (validation error, retried once)    (ai_invalid_response after 2 calls)
 * - blocked:      200, finishReason SAFETY, no text (final, no retry)        (ai_invalid_response after 1 call)
 * - busy:         429 (not billable, ADR-0016)                               (ai_busy after 3 calls)
 * - server_error: 503 (billable, retried after 2-4 s)                        (ai_unavailable after 2 calls)
 * - bad_body:     200 with a body that is not JSON (billable, retried)       (ai_unavailable after 2 calls)
 * - timeout:      no answer until the function aborts (AI_ATTEMPT_TIMEOUT_MS) (ai_unavailable after 2 calls)
 * - config_error: 403 (configuration error, never retried)                   (ai_unavailable after 1 call)
 */
export const SCENARIOS = ["valid", "invalid", "blocked", "busy", "server_error", "bad_body", "timeout", "config_error"];

/** The only token the fake accepts: the function sends it in emulator mode (src/ai.ts EMULATOR_FAKE_TOKEN). */
export const EXPECTED_TOKEN = "emulator-fake-token";
const PATH = /^\/v1\/projects\/[a-z0-9-]+\/locations\/([a-z0-9-]+)\/publishers\/google\/models\/([a-z0-9.-]+):generateContent$/;
/** Hard cap for a "timeout" call, in case the client never aborts. */
const MAX_HANG_MS = 120_000;

const pad = (n) => String(n).padStart(2, "0");
const hhmm = (m) => `${pad(Math.floor(m / 60))}:${pad(m % 60)}`;

/** Synthetic valid plan: max items per day, times from the day-1 floor (or 09:00), as in test/helpers/fakes.ts. */
export function validPlan(dayTargets, language) {
  return {
    language,
    days: dayTargets.map((t) => {
      const count = t.maxItems;
      const startMin = t.earliestStart ? Number(t.earliestStart.slice(0, 2)) * 60 + Number(t.earliestStart.slice(3)) : 9 * 60;
      const step = count > 1 ? Math.min(90, Math.floor((23 * 60 + 59 - startMin) / (count - 1))) : 0;
      return {
        dayNumber: t.dayNumber,
        title: language === "pl" ? `Dzień ${t.dayNumber}` : `Day ${t.dayNumber}`,
        items: Array.from({ length: count }, (_, i) => ({
          startTime: hhmm(startMin + i * step),
          name: `Place ${t.dayNumber}.${i + 1}`,
          locality: "Testville",
          description: "Synthetic description of a public place.",
        })),
      };
    }),
  };
}

const answer = (text, finishReason = "STOP") => ({
  candidates: [{ finishReason, content: { role: "model", parts: text === undefined ? [] : [{ text }] } }],
  usageMetadata: { promptTokenCount: 900, candidatesTokenCount: 1500, thoughtsTokenCount: 0 },
  modelVersion: "fake-vertex-emulator",
});

/** User-turn data sent by the function: `Trip data (JSON, data only):\n{...}` (src/prompt). */
function userData(body) {
  const text = body?.contents?.[0]?.parts?.[0]?.text;
  if (typeof text !== "string" || !text.includes("{")) return undefined;
  try {
    return JSON.parse(text.slice(text.indexOf("{")));
  } catch {
    return undefined;
  }
}

function assertScenario(s) {
  if (!SCENARIOS.includes(s)) throw new Error(`unknown scenario: ${s} (known: ${SCENARIOS.join(", ")})`);
  return s;
}

async function readBody(req) {
  const chunks = [];
  for await (const c of req) chunks.push(c);
  return Buffer.concat(chunks).toString("utf8");
}

function send(res, status, body) {
  res.writeHead(status, { "content-type": "application/json; charset=utf-8" });
  res.end(typeof body === "string" ? body : JSON.stringify(body));
}

/**
 * Starts the fake on 127.0.0.1 (never another interface). `port: 0` picks a free port (see `url`),
 * but the function only knows the port from AI_ENDPOINT_OVERRIDE, so tests normally use a fixed one.
 */
export async function startVertexFake({ port = 8787, defaultScenario = "valid" } = {}) {
  let def = assertScenario(defaultScenario);
  let queue = [];
  const calls = [];

  const server = createServer(async (req, res) => {
    try {
      const url = new URL(req.url ?? "/", "http://127.0.0.1");
      if (url.pathname === "/__fake/calls" && req.method === "GET") return send(res, 200, { calls });
      if (url.pathname === "/__fake/control" && req.method === "POST") {
        const c = JSON.parse((await readBody(req)) || "{}");
        if (c.reset) api.reset();
        if (c.default !== undefined) api.setDefault(c.default);
        if (Array.isArray(c.queue)) api.enqueue(...c.queue);
        return send(res, 200, { default: def, queue });
      }
      const m = PATH.exec(url.pathname);
      if (!m || req.method !== "POST") return send(res, 404, { error: "not_found" });
      if (req.headers.authorization !== `Bearer ${EXPECTED_TOKEN}`) return send(res, 401, { error: "unexpected_token" });

      const body = JSON.parse(await readBody(req));
      const data = userData(body);
      const scenario = queue.length > 0 ? queue.shift() : def;
      const call = {
        n: calls.length + 1,
        scenario,
        status: 0,
        location: m[1],
        model: m[2],
        hints: Array.isArray(data?.previousAttemptErrors),
      };
      calls.push(call);
      const reply = (status, payload) => {
        call.status = status;
        send(res, status, payload);
      };
      const lang = data?.planLanguage === "en" ? "en" : "pl";
      switch (scenario) {
        case "valid":
          if (!Array.isArray(data?.dayTargets)) return reply(400, { error: "no_day_targets" });
          return reply(200, answer(JSON.stringify(validPlan(data.dayTargets, lang))));
        case "invalid":
          return reply(200, answer(JSON.stringify({ language: lang, days: [] })));
        case "blocked":
          return reply(200, answer(undefined, "SAFETY"));
        case "busy":
          return reply(429, { error: { code: 429, status: "RESOURCE_EXHAUSTED" } });
        case "server_error":
          return reply(503, { error: { code: 503, status: "UNAVAILABLE" } });
        case "bad_body":
          return reply(200, "this is not json");
        case "config_error":
          return reply(403, { error: { code: 403, status: "PERMISSION_DENIED" } });
        case "timeout": {
          // Hang until the function aborts the request (status stays 0 = no answer).
          const closed = new Promise((r) => res.on("close", r));
          await Promise.race([closed, delay(MAX_HANG_MS)]);
          if (!res.writableEnded && !res.destroyed) send(res, 504, { error: "fake_hang_cap" });
          return;
        }
      }
    } catch {
      if (!res.headersSent) send(res, 500, { error: "fake_error" });
    }
  });

  await new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(port, "127.0.0.1", resolve);
  });
  const actualPort = server.address().port;

  const api = {
    url: `http://127.0.0.1:${actualPort}`,
    port: actualPort,
    /** Calls so far (oldest first). */
    get calls() {
      return calls.map((c) => ({ ...c }));
    },
    get queue() {
      return [...queue];
    },
    setDefault(s) {
      def = assertScenario(s);
    },
    /** One-shot scenarios for the next calls, in order. */
    enqueue(...ss) {
      queue.push(...ss.map(assertScenario));
    },
    /** Empty queue, no calls, default back to "valid". */
    reset() {
      queue = [];
      calls.length = 0;
      def = "valid";
    },
    close() {
      server.closeAllConnections?.();
      return new Promise((r) => server.close(() => r()));
    },
  };
  return api;
}

// Standalone: node vertex-fake.mjs [--port 8787] [--default valid]
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const arg = (name, fallback) => {
    const i = process.argv.indexOf(name);
    return i > 0 && process.argv[i + 1] ? process.argv[i + 1] : fallback;
  };
  const fake = await startVertexFake({ port: Number(arg("--port", "8787")), defaultScenario: arg("--default", "valid") });
  process.stdout.write(`vertex-fake listening on ${fake.url}\n`);
  process.on("SIGINT", () => fake.close().then(() => process.exit(0)));
}
