// QA TAM-89 (P3-05-EMU) – integration tests of generatePlan quota handling on the Firebase Emulator Suite
// (Auth + Firestore + Functions) with the Vertex fake (backend/functions/test/emulator/vertex-fake.mjs).
// Report: docs/qa/QA-TAM-89-emulator.md.
//
// Covers: reservation documents (usage/{uid} TTL Timestamp, usage_global/{day}), yesterday's document = 0,
// limits 5/account and 25/global, slot release after ai_unavailable / ai_invalid_response (max 2/day,
// usage_global untouched), ai_busy release (account + global, busyReleased <= 10, ADR-0016), consent
// checked before the quota, parallel calls never overshoot the account limit.
//
// No dependencies (Node 22). Synthetic users from the Auth emulator only, demo-* project, 0 paid calls.
// Run ONLY through the farm lock and run-emulator-tests.ps1 (sets AI_ENDPOINT_OVERRIDE etc.), from repo root:
//   powershell -NoProfile -ExecutionPolicy Bypass -File .farm/test-lock.ps1 -Resource firebase-emulators `
//     -Command "powershell -NoProfile -ExecutionPolicy Bypass -File backend/functions/test/emulator/run-emulator-tests.ps1 -Tests tests/firebase-emulator/p3-05-generate-plan.int.mjs"
//
// Tests run sequentially (one file = one node:test process; config/runtime and usage_global/{today} are shared
// state, every test resets them). The quota day is computed like src/limits.ts (Europe/Warsaw); a run that
// crosses Warsaw midnight may fail spuriously – just rerun.
import { test, before, after, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import process from "node:process";
import { startVertexFake } from "../../backend/functions/test/emulator/vertex-fake.mjs";

const PROJECT = process.env.GCLOUD_PROJECT ?? "demo-tamitu-qa";
const AUTH = `http://${process.env.FIREBASE_AUTH_EMULATOR_HOST ?? "127.0.0.1:9099"}`;
const FS_DOCS = `http://${process.env.FIRESTORE_EMULATOR_HOST ?? "127.0.0.1:8080"}/v1/projects/${PROJECT}/databases/(default)/documents`;
const FN = `http://127.0.0.1:5001/${PROJECT}/europe-west4`;
const FAKE_PORT = Number(new URL(process.env.AI_ENDPOINT_OVERRIDE ?? "http://127.0.0.1:8787").port);
const OWNER = { authorization: "Bearer owner" }; // emulator admin bypass of security rules

const USER_LIMIT = 5;
const GLOBAL_LIMIT = 25;

// ---------- helpers ----------
const warsawDay = (d) =>
  new Intl.DateTimeFormat("en-CA", { timeZone: "Europe/Warsaw", year: "numeric", month: "2-digit", day: "2-digit" }).format(d);
const today = () => warsawDay(new Date());
const yesterday = () => warsawDay(new Date(Date.now() - 864e5));

async function googleUser() {
  const sub = `qa-tam89-${randomUUID()}`;
  const claims = { sub, email: `${sub}@example.test`, email_verified: true, name: "QA Synthetic" };
  const r = await fetch(`${AUTH}/identitytoolkit.googleapis.com/v1/accounts:signInWithIdp?key=fake-api-key`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({
      requestUri: "http://localhost",
      postBody: `id_token=${encodeURIComponent(JSON.stringify(claims))}&providerId=google.com`,
      returnSecureToken: true,
    }),
  });
  const j = await r.json();
  assert.equal(r.status, 200, "auth emulator sign-in");
  return { uid: j.localId, idToken: j.idToken };
}

/** Upper bound of one sequential call (cold start ~16 s, ai_busy with backoff ~12 s): a hung emulator worker
 * fails the test instead of blocking the run and the shared `firebase-emulators` lock (review PR #184 #3). */
const CALL_TIMEOUT_MS = 90_000;

async function call(fn, data, idToken) {
  const r = await fetch(`${FN}/${fn}`, {
    method: "POST",
    headers: { "content-type": "application/json", authorization: `Bearer ${idToken}` },
    body: JSON.stringify({ data }),
    signal: AbortSignal.timeout(CALL_TIMEOUT_MS),
  });
  const j = await r.json();
  return j.error ? { ok: false, code: j.error.details?.code, details: j.error.details ?? {}, status: j.error.status } : { ok: true, result: j.result };
}

const toValue = (x) => {
  if (x instanceof Date) return { timestampValue: x.toISOString() };
  if (typeof x === "string") return { stringValue: x };
  if (typeof x === "boolean") return { booleanValue: x };
  if (Number.isInteger(x)) return { integerValue: String(x) };
  return { arrayValue: { values: x.map(toValue) } };
};

async function setDoc(path, obj) {
  const fields = Object.fromEntries(Object.entries(obj).map(([k, v]) => [k, toValue(v)]));
  const r = await fetch(`${FS_DOCS}/${path}`, {
    method: "PATCH",
    headers: { ...OWNER, "content-type": "application/json" },
    body: JSON.stringify({ fields }),
  });
  assert.equal(r.status, 200, `owner write ${path.split("/")[0]}`);
}

async function deleteDoc(path) {
  const r = await fetch(`${FS_DOCS}/${path}`, { method: "DELETE", headers: OWNER });
  assert.ok(r.status === 200 || r.status === 404, `owner delete ${path.split("/")[0]}: ${r.status}`);
}

/** Raw Firestore REST fields of a document, or undefined when it does not exist. */
async function getFields(path) {
  const r = await fetch(`${FS_DOCS}/${path}`, { headers: OWNER });
  if (r.status === 404) return undefined;
  assert.equal(r.status, 200, `owner read ${path.split("/")[0]}`);
  return (await r.json()).fields ?? {};
}

const int = (fields, k) => (fields?.[k]?.integerValue === undefined ? undefined : Number(fields[k].integerValue));

async function usage(uid) {
  const f = await getFields(`usage/${uid}`);
  return f && { day: f.day?.stringValue, count: int(f, "count"), released: int(f, "released"), busyReleased: int(f, "busyReleased"), raw: f };
}

async function globalCount(day = today()) {
  return int(await getFields(`usage_global/${day}`), "count");
}

async function setRuntimeConfig(uids, extra = {}) {
  await setDoc("config/runtime", {
    aiEnabled: true,
    testUids: uids,
    perUserDailyLimit: USER_LIMIT,
    globalDailyLimit: GLOBAL_LIMIT,
    policyVersionCurrent: "privacy-v1",
    aiConsentVersionCurrent: "ai-consent-v1",
    ...extra,
  });
}

const consent = (type, policyVersion) => ({
  apiVersion: 1,
  consentId: randomUUID(),
  type,
  granted: true,
  policyVersion,
  lang: "pl",
  clientAt: new Date().toISOString(),
});

async function grantConsents(u, types = ["privacy_policy", "ai_processing"]) {
  const versions = { privacy_policy: "privacy-v1", ai_processing: "ai-consent-v1" };
  for (const t of types) {
    const r = await call("recordConsent", consent(t, versions[t]), u.idToken);
    assert.equal(r.ok, true, `recordConsent ${t}: ${JSON.stringify(r)}`);
  }
}

/** New synthetic user, listed in config/runtime.testUids, optionally with both consents. */
async function readyUser({ consents = true } = {}) {
  const u = await googleUser();
  await setRuntimeConfig([u.uid]);
  if (consents) await grantConsents(u);
  return u;
}

async function readyUsers(n) {
  const us = [];
  for (let i = 0; i < n; i++) us.push(await googleUser());
  await setRuntimeConfig(us.map((u) => u.uid));
  for (const u of us) await grantConsents(u);
  return us;
}

const planRequest = () => ({
  apiVersion: 1,
  requestId: randomUUID(),
  planLanguage: "pl",
  trip: {
    destination: "Testowo",
    lodging: "Hotel Test",
    days: 2,
    arrival: { mode: "car", date: new Date(Date.now() + 7 * 864e5).toISOString().slice(0, 10), time: "10:00" },
  },
  preferences: { pace: "moderate" },
  testData: true,
});

const generate = (u) => call("generatePlan", planRequest(), u.idToken);

// ---------- lifecycle ----------
let fake;
before(async () => {
  fake = await startVertexFake({ port: FAKE_PORT });
});
after(async () => {
  await fake?.close();
});
beforeEach(async () => {
  fake.reset();
  // usage_global/{today} is shared by every test: start each one from an empty global counter.
  await deleteDoc(`usage_global/${today()}`);
});

// ---------- reservation ----------
test("EMU-01 reservation: usage/{uid} with Timestamp expireAt (TTL) and usage_global/{day}", async () => {
  const u = await readyUser();
  const r = await generate(u);
  assert.equal(r.ok, true, JSON.stringify(r));
  assert.equal(r.result.quota.limit, USER_LIMIT);
  assert.equal(r.result.quota.remainingToday, USER_LIMIT - 1);
  assert.equal(fake.calls.length, 1);

  const us = await usage(u.uid);
  assert.equal(us.day, today());
  assert.equal(us.count, 1);
  assert.equal(us.released, 0);
  assert.equal(us.busyReleased, 0);
  const expireAt = us.raw.expireAt?.timestampValue;
  assert.ok(expireAt, "usage/{uid}.expireAt stored as Firestore Timestamp (TTL field)");
  // max(resetAt + 2 d, now + 2 d): always at least 2 days ahead, at most ~3 days.
  const ahead = Date.parse(expireAt) - Date.now();
  assert.ok(ahead >= 2 * 864e5 - 60e3 && ahead <= 3 * 864e5 + 60e3, `expireAt ${ahead} ms ahead`);
  assert.ok(us.raw.updatedAt?.timestampValue, "updatedAt as Timestamp");

  const g = await getFields(`usage_global/${today()}`);
  assert.equal(int(g, "count"), 1);
  const gExp = Date.parse(g.expireAt?.timestampValue);
  assert.ok(Math.abs(gExp - Date.now() - 7 * 864e5) < 5 * 60e3, "usage_global expireAt = now + 7 d (Timestamp)");
});

test("EMU-02 yesterday's usage document counts as 0 (count, released, busyReleased reset)", async () => {
  const u = await readyUser();
  await setDoc(`usage/${u.uid}`, { day: yesterday(), count: USER_LIMIT, released: 2, busyReleased: 10 });
  const r = await generate(u);
  assert.equal(r.ok, true, JSON.stringify(r));
  assert.equal(r.result.quota.remainingToday, USER_LIMIT - 1);
  const us = await usage(u.uid);
  assert.deepEqual([us.day, us.count, us.released, us.busyReleased], [today(), 1, 0, 0]);
});

// ---------- limits ----------
test("EMU-03 account limit: 5 plans per day, the 6th is limit_exceeded without a model call", async () => {
  const u = await readyUser();
  for (let i = 1; i <= USER_LIMIT; i++) {
    const r = await generate(u);
    assert.equal(r.ok, true, `plan ${i}: ${JSON.stringify(r)}`);
    assert.equal(r.result.quota.remainingToday, USER_LIMIT - i);
  }
  const r6 = await generate(u);
  assert.equal(r6.ok, false);
  assert.equal(r6.code, "limit_exceeded");
  assert.equal(r6.status, "RESOURCE_EXHAUSTED");
  assert.equal(r6.details.limit, USER_LIMIT);
  assert.ok(typeof r6.details.resetAt === "string" && Date.parse(r6.details.resetAt) > Date.now(), "details.resetAt in the future");
  assert.equal(fake.calls.length, USER_LIMIT, "no model call for the rejected request");
  assert.equal((await usage(u.uid)).count, USER_LIMIT);
  assert.equal(await globalCount(), USER_LIMIT, "usage_global not incremented by the rejected request");
});

test("EMU-04 global limit: 25 plans per day in total, the 26th is rejected (contract: ai_unavailable, slotReleased=true)", async () => {
  // 5 accounts x 5 plans = 25 real reservations through the function, then a 6th account tries the 26th.
  const users = await readyUsers(6);
  for (const u of users.slice(0, 5)) {
    for (let i = 0; i < USER_LIMIT; i++) {
      const r = await generate(u);
      assert.equal(r.ok, true, JSON.stringify(r));
    }
  }
  assert.equal(await globalCount(), GLOBAL_LIMIT);
  const r26 = await generate(users[5]);
  assert.equal(r26.ok, false);
  // posrednik-api.md (error table, rule 1) and limits.decideQuota: an exhausted GLOBAL limit is
  // ai_unavailable with slotReleased=true (the account limit is limit_exceeded, EMU-03).
  assert.equal(r26.code, "ai_unavailable", JSON.stringify(r26));
  assert.equal(r26.details.slotReleased, true);
  assert.equal(fake.calls.length, GLOBAL_LIMIT, "no model call for the 26th request");
  assert.equal(await usage(users[5].uid), undefined, "no slot reserved for the 6th account");
  assert.equal(await globalCount(), GLOBAL_LIMIT);
});

test("EMU-05 global limit is checked before the account limit (both exhausted -> ai_unavailable)", async () => {
  const u = await readyUser();
  await setDoc(`usage/${u.uid}`, { day: today(), count: USER_LIMIT, released: 0, busyReleased: 0 });
  await setDoc(`usage_global/${today()}`, { count: GLOBAL_LIMIT });
  const r = await generate(u);
  assert.equal(r.code, "ai_unavailable", JSON.stringify(r));
  assert.equal(r.details.slotReleased, true);
  assert.equal(fake.calls.length, 0);
  assert.equal((await usage(u.uid)).count, USER_LIMIT, "usage/{uid} unchanged");
  assert.equal(await globalCount(), GLOBAL_LIMIT, "usage_global unchanged");
});

// ---------- release after errors ----------
test("EMU-06 ai_invalid_response releases the account slot, usage_global stays, slotReleased=true", async () => {
  const u = await readyUser();
  fake.enqueue("invalid", "invalid");
  const r = await generate(u);
  assert.equal(r.code, "ai_invalid_response", JSON.stringify(r));
  assert.equal(r.details.slotReleased, true);
  assert.equal(fake.calls.length, 2, "validation error retried once");
  const us = await usage(u.uid);
  assert.deepEqual([us.count, us.released, us.busyReleased], [0, 1, 0]);
  assert.ok(us.raw.expireAt?.timestampValue, "expireAt kept as Timestamp after release");
  assert.equal(await globalCount(), 1, "usage_global is never decremented after a billable failure");
});

test("EMU-07 ai_unavailable (503 x2) releases the account slot, usage_global stays", async () => {
  const u = await readyUser();
  fake.enqueue("server_error", "server_error");
  const r = await generate(u);
  assert.equal(r.code, "ai_unavailable", JSON.stringify(r));
  assert.equal(r.details.slotReleased, true);
  assert.equal(fake.calls.length, 2);
  const us = await usage(u.uid);
  assert.deepEqual([us.count, us.released], [0, 1]);
  assert.equal(await globalCount(), 1);
});

test("EMU-08 at most 2 releases per account and day: the 3rd error keeps the slot (slotReleased=false)", async () => {
  const u = await readyUser();
  fake.setDefault("config_error"); // 403: ai_unavailable after 1 call, no backoff
  const seen = [];
  for (let i = 0; i < 3; i++) {
    const r = await generate(u);
    assert.equal(r.code, "ai_unavailable", JSON.stringify(r));
    seen.push(r.details.slotReleased);
  }
  assert.deepEqual(seen, [true, true, false]);
  const us = await usage(u.uid);
  assert.deepEqual([us.count, us.released], [1, 2], "third slot stays used, released capped at 2");
  assert.equal(await globalCount(), 3, "usage_global counts every attempt");

  // A success afterwards still works and is counted normally: remaining = 5 - 1 (kept) - 1 (this one).
  fake.setDefault("valid");
  const ok = await generate(u);
  assert.equal(ok.ok, true, JSON.stringify(ok));
  assert.equal(ok.result.quota.remainingToday, USER_LIMIT - 2);
});

test("EMU-09 release does not apply to limit_exceeded (no reservation, nothing to return)", async () => {
  const u = await readyUser();
  await setDoc(`usage/${u.uid}`, { day: today(), count: USER_LIMIT, released: 0, busyReleased: 0 });
  const r = await generate(u);
  assert.equal(r.code, "limit_exceeded");
  const us = await usage(u.uid);
  assert.deepEqual([us.count, us.released], [USER_LIMIT, 0]);
});

// ---------- ai_busy (ADR-0016) ----------
test("EMU-10 ai_busy (3 x 429): account AND global slot return, released untouched, busyReleased+1", { timeout: 60_000 }, async () => {
  const u = await readyUser();
  fake.setDefault("busy");
  const r = await generate(u);
  assert.equal(r.code, "ai_busy", JSON.stringify(r));
  assert.equal(r.details.slotReleased, true);
  assert.equal(r.details.retryAfterSec, 60);
  assert.equal(fake.calls.length, 3, "3 calls, all 429");
  const us = await usage(u.uid);
  assert.deepEqual([us.count, us.released, us.busyReleased], [0, 0, 1]);
  assert.equal(await globalCount(), 0, "usage_global returned after ai_busy");
});

test("EMU-11 ai_busy fuse: 10th release still returns, 11th keeps both slots (slotReleased=false)", { timeout: 90_000 }, async () => {
  const u = await readyUser();
  // 9 busy releases already today (seeded – 9 real busy runs would take ~90 s of backoff).
  await setDoc(`usage/${u.uid}`, { day: today(), count: 0, released: 0, busyReleased: 9 });
  fake.setDefault("busy");

  const r10 = await generate(u);
  assert.equal(r10.code, "ai_busy", JSON.stringify(r10));
  assert.equal(r10.details.slotReleased, true, "10th ai_busy of the day is still released");
  let us = await usage(u.uid);
  assert.deepEqual([us.count, us.released, us.busyReleased], [0, 0, 10]);
  assert.equal(await globalCount(), 0);

  const r11 = await generate(u);
  assert.equal(r11.code, "ai_busy", JSON.stringify(r11));
  assert.equal(r11.details.slotReleased, false, "11th ai_busy keeps the slots");
  us = await usage(u.uid);
  assert.deepEqual([us.count, us.released, us.busyReleased], [1, 0, 10]);
  assert.equal(await globalCount(), 1, "global slot stays used after the fuse");
});

test("EMU-12 ai_busy releases do not consume the 2 error releases", { timeout: 60_000 }, async () => {
  const u = await readyUser();
  await setDoc(`usage/${u.uid}`, { day: today(), count: 0, released: 2, busyReleased: 0 });
  fake.setDefault("busy");
  const r = await generate(u);
  assert.equal(r.code, "ai_busy");
  assert.equal(r.details.slotReleased, true, "busy release works although released is already at 2");
  const us = await usage(u.uid);
  assert.deepEqual([us.count, us.released, us.busyReleased], [0, 2, 1]);
});

// ---------- order: consent before quota ----------
test("EMU-13 no consents -> consent_required, quota untouched, no model call", async () => {
  const u = await readyUser({ consents: false });
  const r = await generate(u);
  assert.equal(r.code, "consent_required", JSON.stringify(r));
  assert.equal(await usage(u.uid), undefined, "usage/{uid} not created");
  assert.equal(await globalCount(), undefined, "usage_global not created");
  assert.equal(fake.calls.length, 0);
});

test("EMU-14 only privacy_policy consent (no ai_processing) -> consent_required, quota untouched", async () => {
  const u = await readyUser({ consents: false });
  await grantConsents(u, ["privacy_policy"]);
  const r = await generate(u);
  assert.equal(r.code, "consent_required", JSON.stringify(r));
  assert.equal(await usage(u.uid), undefined);
  assert.equal(fake.calls.length, 0);
});

test("EMU-15 exhausted account limit AND no consent -> consent_required (consent checked first)", async () => {
  const u = await readyUser({ consents: false });
  await setDoc(`usage/${u.uid}`, { day: today(), count: USER_LIMIT, released: 0, busyReleased: 0 });
  const r = await generate(u);
  assert.equal(r.code, "consent_required", JSON.stringify(r));
  const us = await usage(u.uid);
  assert.equal(us.count, USER_LIMIT, "counter unchanged");
});

// ---------- transactions ----------
// The Functions emulator starts one worker process per concurrent request; on a slow machine some workers
// fail to load ("Failed to load function") and their requests never get an answer. Such requests end here as
// `emu_transport` (client timeout). The SAFETY invariants are asserted in every case; the exact counts only
// when the emulator answered every request (otherwise the test is reported as skipped with a diagnostic).
const PARALLEL_CALL_TIMEOUT_MS = 60_000;
/** Function timeout (index.ts timeoutSeconds: 120): a request cut off by the client may run this long. */
const FUNCTION_TIMEOUT_MS = 120_000;

// TEMPORARY (TAM-115, P3-05-CONTENTION) – finding F-1 in docs/qa/QA-TAM-89-emulator.md: under contention the
// reservation transaction can end with ABORTED and generatePlan answers `internal` instead of a contract code.
// Until TAM-115 maps that to a contract code (with slotReleased), EMU-16/17 accept `internal`. The safety
// assertions (no overshoot; an aborted transaction writes nothing: counters = model calls = granted plans)
// stay in force regardless. REMOVE this constant and its uses when TAM-115 is done (TAM-115 acceptance criterion).
const TEMP_TOLERATE_INTERNAL_UNTIL_TAM_115 = ["internal"];

async function generateBounded(u) {
  try {
    const r = await fetch(`${FN}/generatePlan`, {
      method: "POST",
      headers: { "content-type": "application/json", authorization: `Bearer ${u.idToken}` },
      body: JSON.stringify({ data: planRequest() }),
      signal: AbortSignal.timeout(PARALLEL_CALL_TIMEOUT_MS),
    });
    const j = await r.json();
    if (j.error) return { ok: false, code: j.error.details?.code ?? "emu_transport", details: j.error.details ?? {} };
    if (!j.result) return { ok: false, code: "emu_transport" };
    return { ok: true, result: j.result };
  } catch {
    return { ok: false, code: "emu_transport" };
  }
}

/** Waits until fake.calls stops growing for 3 s (requests cut off by the client may still finish). */
async function settle(maxMs = 30_000) {
  const end = Date.now() + maxMs;
  let last = -1;
  while (Date.now() < end) {
    const n = fake.calls.length;
    if (n === last) return;
    last = n;
    await new Promise((r) => setTimeout(r, 3000));
  }
}

function summarize(t, rs) {
  const codes = JSON.stringify(rs.map((r) => (r.ok ? "ok" : r.code)));
  const internal = rs.filter((r) => TEMP_TOLERATE_INTERNAL_UNTIL_TAM_115.includes(r.code)).length; // TEMPORARY (TAM-115)
  const transport = rs.filter((r) => r.code === "emu_transport").length;
  if (internal > 0) t.diagnostic(`F-1, tolerated TEMPORARILY until TAM-115: ${internal}/${rs.length} requests ended with internal (transaction ABORTED): ${codes}`);
  if (transport > 0) t.diagnostic(`emulator: ${transport}/${rs.length} requests got no answer (worker failed to load): ${codes}`);
  return { codes, internal, transport, ok: rs.filter((r) => r.ok) };
}

test("EMU-16 parallel calls of one account never overshoot the limit (Firestore transaction)", { timeout: 240_000 }, async (t) => {
  const u = await readyUser();
  const N = 7; // 5 slots + 2 over the limit
  const rs = await Promise.all(Array.from({ length: N }, () => generateBounded(u)));
  const { codes, internal, transport, ok } = summarize(t, rs);
  await settle();

  // Safety invariants (always): never above the limit; every reserved slot = exactly one model call.
  const count = (await usage(u.uid))?.count ?? 0;
  assert.ok(count <= USER_LIMIT, `usage/{uid}.count ${count} > ${USER_LIMIT}: ${codes}`);
  assert.ok(ok.length <= USER_LIMIT, `more than ${USER_LIMIT} plans granted: ${codes}`);
  assert.equal(fake.calls.length, count, "model calls = reserved slots");
  assert.equal(await globalCount() ?? 0, count, "usage_global = account counter");
  // `internal` only TEMPORARILY (TAM-115); emu_transport = emulator gave no answer (see above).
  assert.ok(rs.every((r) => r.ok || ["limit_exceeded", ...TEMP_TOLERATE_INTERNAL_UNTIL_TAM_115, "emu_transport"].includes(r.code)), codes);
  const rem = ok.map((r) => r.result.quota.remainingToday);
  assert.equal(new Set(rem).size, rem.length, `remainingToday not distinct: ${rem}`);

  if (transport > 0) {
    // A request cut off by the client may still finish later and write usage_global/{today}, which EMU-17
    // reuses (review PR #184 #4b): wait out the function timeout before the next test.
    await new Promise((r) => setTimeout(r, FUNCTION_TIMEOUT_MS - PARALLEL_CALL_TIMEOUT_MS + 5_000));
    return t.skip("emulator did not answer every request – exact counts not verified (invariants passed)");
  }
  assert.equal(count, ok.length, "every granted plan is counted once");
  if (internal === 0) {
    assert.equal(ok.length, USER_LIMIT, codes);
    assert.equal(rs.filter((r) => r.code === "limit_exceeded").length, N - USER_LIMIT, codes);
  }
});

test("EMU-17 parallel calls of several accounts never overshoot the global limit", { timeout: 150_000 }, async (t) => {
  const users = await readyUsers(5);
  const FREE = 3;
  await setDoc(`usage_global/${today()}`, { count: GLOBAL_LIMIT - FREE });
  const rs = await Promise.all(users.flatMap((u) => [generateBounded(u), generateBounded(u)])); // 10 concurrent
  const { codes, internal, transport, ok } = summarize(t, rs);
  await settle();

  const global = await globalCount();
  let sum = 0;
  for (const u of users) sum += (await usage(u.uid))?.count ?? 0;
  assert.ok(global <= GLOBAL_LIMIT, `usage_global ${global} > ${GLOBAL_LIMIT}: ${codes}`);
  assert.ok(ok.length <= FREE, `more than ${FREE} plans granted: ${codes}`);
  assert.equal(global, GLOBAL_LIMIT - FREE + sum, "usage_global = seed + account counters");
  assert.equal(fake.calls.length, sum, "model calls = reserved slots");
  // Global limit exhausted = ai_unavailable (contract); `internal` only TEMPORARILY (TAM-115); emu_transport =
  // emulator gave no answer (see above).
  assert.ok(rs.every((r) => r.ok || ["ai_unavailable", ...TEMP_TOLERATE_INTERNAL_UNTIL_TAM_115, "emu_transport"].includes(r.code)), codes);

  if (transport > 0) return t.skip("emulator did not answer every request – exact counts not verified (invariants passed)");
  assert.equal(sum, ok.length, "every granted plan is counted once");
  if (internal === 0) assert.equal(ok.length, FREE, codes);
});
