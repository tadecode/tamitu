// TAM-89 smoke test: generatePlan in the Functions emulator reaches the Vertex fake and reserves a slot
// in the Firestore emulator. ONE test only - the full emulator suite (limits, releases) belongs to QA.
// Run ONLY through run-emulator-tests.ps1 (sets the emulator env) and .farm/test-lock.ps1, see backend/eval/README.md.
// Synthetic users from the Auth emulator only; demo-* project = never touches a real Firebase project.
import { test } from "node:test";
import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import process from "node:process";
import { startVertexFake } from "./vertex-fake.mjs";

const PROJECT = process.env.GCLOUD_PROJECT ?? "demo-tamitu-qa";
const AUTH = `http://${process.env.FIREBASE_AUTH_EMULATOR_HOST ?? "127.0.0.1:9099"}`;
const FS_DOCS = `http://${process.env.FIRESTORE_EMULATOR_HOST ?? "127.0.0.1:8080"}/v1/projects/${PROJECT}/databases/(default)/documents`;
const FN = `http://127.0.0.1:5001/${PROJECT}/europe-west4`;
const FAKE_PORT = Number(new URL(process.env.AI_ENDPOINT_OVERRIDE ?? "http://127.0.0.1:8787").port);
const OWNER = { authorization: "Bearer owner" }; // emulator admin bypass of security rules

async function googleUser() {
  const sub = `smoke-${randomUUID()}`;
  const claims = { sub, email: `${sub}@example.test`, email_verified: true, name: "Smoke Test" };
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

async function call(fn, data, idToken) {
  const r = await fetch(`${FN}/${fn}`, {
    method: "POST",
    headers: { "content-type": "application/json", authorization: `Bearer ${idToken}` },
    body: JSON.stringify({ data }),
  });
  const j = await r.json();
  return j.error ? { ok: false, code: j.error.details?.code, status: j.error.status } : { ok: true, result: j.result };
}

const toValue = (x) =>
  typeof x === "string"
    ? { stringValue: x }
    : typeof x === "boolean"
      ? { booleanValue: x }
      : Number.isInteger(x)
        ? { integerValue: String(x) }
        : { arrayValue: { values: x.map(toValue) } };

async function setRuntimeConfig(cfg) {
  const fields = Object.fromEntries(Object.entries(cfg).map(([k, v]) => [k, toValue(v)]));
  const r = await fetch(`${FS_DOCS}/config/runtime`, {
    method: "PATCH",
    headers: { ...OWNER, "content-type": "application/json" },
    body: JSON.stringify({ fields }),
  });
  assert.equal(r.status, 200, "config/runtime write (owner)");
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

test("SMOKE TAM-89: generatePlan in the emulator reaches the Vertex fake and reserves usage/{uid}", async (t) => {
  const fake = await startVertexFake({ port: FAKE_PORT });
  t.after(() => fake.close());

  const u = await googleUser();
  await setRuntimeConfig({
    aiEnabled: true,
    testUids: [u.uid],
    perUserDailyLimit: 5,
    globalDailyLimit: 25,
    policyVersionCurrent: "privacy-v1",
    aiConsentVersionCurrent: "ai-consent-v1",
  });
  for (const c of [consent("privacy_policy", "privacy-v1"), consent("ai_processing", "ai-consent-v1")]) {
    const r = await call("recordConsent", c, u.idToken);
    assert.equal(r.ok, true, `recordConsent ${c.type}: ${JSON.stringify(r)}`);
  }

  const date = new Date(Date.now() + 7 * 864e5).toISOString().slice(0, 10);
  const r = await call(
    "generatePlan",
    {
      apiVersion: 1,
      requestId: randomUUID(),
      planLanguage: "pl",
      trip: { destination: "Testowo", lodging: "Hotel Test", days: 2, arrival: { mode: "car", date, time: "10:00" } },
      preferences: { pace: "moderate" },
      testData: true,
    },
    u.idToken,
  );

  // If this fails with ai_unavailable and 0 fake calls, AI_ENDPOINT_OVERRIDE did not reach the function
  // runtime (or was rejected by the guard) - check run-emulator-tests.ps1.
  assert.equal(fake.calls.length, 1, `fake calls: ${JSON.stringify(fake.calls)}; response: ${JSON.stringify(r)}`);
  assert.equal(fake.calls[0].model, "gemini-3.1-flash-lite");
  assert.equal(r.ok, true, JSON.stringify(r));
  assert.equal(r.result.days.length, 2);
  assert.equal(r.result.quota.remainingToday, 4);

  const usage = await (await fetch(`${FS_DOCS}/usage/${u.uid}`, { headers: OWNER })).json();
  assert.equal(usage.fields?.count?.integerValue, "1", "usage/{uid}.count after one plan");
  assert.ok(usage.fields?.expireAt?.timestampValue, "usage/{uid}.expireAt stored as Timestamp");
});
