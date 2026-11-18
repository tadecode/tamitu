// QA P3-04 – integration tests of recordConsent / consent_required against the Firebase Emulator Suite.
// Test plan: docs/qa/test-plan-p3-04.md (API-05..12, CONS-10, SES-04 server part, PRIV-04, consent_required).
// Report: docs/qa/verify-p3-04-r3.md.
//
// No dependencies (Node 22: fetch + node:test). Only synthetic test users created in the Auth emulator.
// Run (from repo root, via the farm lock; demo-* project = never touches a real Firebase project):
//   powershell -NoProfile -ExecutionPolicy Bypass -File .farm/test-lock.ps1 -Resource firebase-emulators `
//     -Command "cd backend; firebase emulators:exec --project demo-tamitu-qa --only auth,functions,firestore 'node --test ../tests/firebase-emulator/p3-04-record-consent.int.mjs'"
// Env: ENVIRONMENT=dev, ENFORCE_APP_CHECK=false for the main run. With QA_EXPECT_APP_CHECK=1 (and
// ENFORCE_APP_CHECK unset) only the App Check case runs. backend/functions/.secret.local must hold a random
// test UID_HASH_PEPPER (git-ignored; never a real value).
import { test } from "node:test";
import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { writeFileSync } from "node:fs";

const PROJECT = process.env.GCLOUD_PROJECT ?? "demo-tamitu-qa";
const AUTH = `http://${process.env.FIREBASE_AUTH_EMULATOR_HOST ?? "127.0.0.1:9099"}`;
const FS = `http://${process.env.FIRESTORE_EMULATOR_HOST ?? "127.0.0.1:8080"}`;
const FN = `http://127.0.0.1:5001/${PROJECT}/europe-west4`;
const FS_DOCS = `${FS}/v1/projects/${PROJECT}/databases/(default)/documents`;
const EXPECT_APP_CHECK = process.env.QA_EXPECT_APP_CHECK === "1";

// Identifiers used in this run (synthetic), written out so the emulator log can be checked for leaks (PRIV-04).
const used = { uids: [], consentIds: [] };

// ---------- Auth emulator ----------
async function authPost(path, body) {
  const r = await fetch(`${AUTH}/identitytoolkit.googleapis.com/v1/${path}?key=fake-api-key`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(body),
  });
  const j = await r.json();
  if (!r.ok) throw new Error(`auth ${path}: ${r.status} ${JSON.stringify(j)}`);
  return j;
}

/** Google user via signInWithIdp with an unsigned fake Google id_token (accepted only by the emulator). */
async function googleUser() {
  const sub = `qa-${randomUUID()}`;
  const claims = { sub, email: `${sub}@example.test`, email_verified: true, name: "QA Test" };
  const j = await authPost("accounts:signInWithIdp", {
    requestUri: "http://localhost",
    postBody: `id_token=${encodeURIComponent(JSON.stringify(claims))}&providerId=google.com`,
    returnSecureToken: true,
    returnIdpCredential: true,
  });
  used.uids.push(j.localId);
  return { uid: j.localId, idToken: j.idToken };
}

async function passwordUser() {
  const j = await authPost("accounts:signUp", {
    email: `qa-${randomUUID()}@example.test`,
    password: `pw-${randomUUID()}`,
    returnSecureToken: true,
  });
  used.uids.push(j.localId);
  return { uid: j.localId, idToken: j.idToken };
}

async function anonymousUser() {
  const j = await authPost("accounts:signUp", { returnSecureToken: true });
  used.uids.push(j.localId);
  return { uid: j.localId, idToken: j.idToken };
}

async function deleteUser(idToken) {
  await authPost("accounts:delete", { idToken });
}

// ---------- Functions emulator (callable protocol) ----------
async function call(fn, data, idToken) {
  const headers = { "content-type": "application/json" };
  if (idToken) headers.authorization = `Bearer ${idToken}`;
  const r = await fetch(`${FN}/${fn}`, { method: "POST", headers, body: JSON.stringify({ data }) });
  const j = await r.json();
  if (j.error) return { ok: false, http: r.status, status: j.error.status, code: j.error.details?.code, details: j.error.details ?? {} };
  return { ok: true, http: r.status, result: j.result };
}

// ---------- Firestore emulator ----------
const OWNER = { authorization: "Bearer owner" }; // emulator admin bypass of security rules

function fromValue(v) {
  if ("stringValue" in v) return v.stringValue;
  if ("booleanValue" in v) return v.booleanValue;
  if ("integerValue" in v) return Number(v.integerValue);
  if ("timestampValue" in v) return { timestamp: v.timestampValue };
  if ("arrayValue" in v) return (v.arrayValue.values ?? []).map(fromValue);
  if ("nullValue" in v) return null;
  return v;
}
function toValue(x) {
  if (typeof x === "string") return { stringValue: x };
  if (typeof x === "boolean") return { booleanValue: x };
  if (Number.isInteger(x)) return { integerValue: String(x) };
  if (Array.isArray(x)) return { arrayValue: { values: x.map(toValue) } };
  throw new Error("unsupported value");
}

async function listConsents(uid) {
  const r = await fetch(`${FS_DOCS}/users/${uid}/consents?pageSize=100`, { headers: OWNER });
  const j = await r.json();
  return (j.documents ?? []).map((d) => ({
    id: d.name.split("/").pop(),
    fields: Object.fromEntries(Object.entries(d.fields ?? {}).map(([k, v]) => [k, fromValue(v)])),
  }));
}

async function setRuntimeConfig(cfg) {
  const fields = Object.fromEntries(Object.entries(cfg).map(([k, v]) => [k, toValue(v)]));
  const r = await fetch(`${FS_DOCS}/config/runtime`, {
    method: "PATCH",
    headers: { ...OWNER, "content-type": "application/json" },
    body: JSON.stringify({ fields }),
  });
  assert.equal(r.status, 200, "config/runtime write (owner)");
}

// ---------- request builders ----------
function consent(over = {}) {
  const consentId = over.consentId ?? randomUUID();
  used.consentIds.push(consentId);
  return {
    apiVersion: 1,
    consentId,
    type: "privacy_policy",
    granted: true,
    policyVersion: "privacy-v1",
    lang: "pl",
    clientAt: new Date().toISOString(),
    ...over,
  };
}

function planRequest() {
  const d = new Date(Date.now() + 7 * 864e5).toISOString().slice(0, 10);
  return {
    apiVersion: 1,
    requestId: randomUUID(),
    planLanguage: "pl",
    trip: { destination: "Testowo", lodging: "Hotel Test", days: 2, arrival: { mode: "car", date: d, time: "10:00" } },
    preferences: { interests: [], budget: "medium", pace: "moderate", partySize: 2 },
    testData: true,
  };
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// ======================================================================================
if (EXPECT_APP_CHECK) {
  test("API-10 (emulator): enforceAppCheck=true, no App Check token -> app_check_failed, no document", async () => {
    const u = await googleUser();
    const req = consent();
    const r = await call("recordConsent", req, u.idToken);
    assert.equal(r.ok, false);
    assert.equal(r.code, "app_check_failed");
    assert.equal(r.status, "FAILED_PRECONDITION");
    assert.equal((await listConsents(u.uid)).length, 0);
  });
} else {
  test("SMOKE: environment is dev, App Check not enforced (precondition of this run)", async () => {
    const u = await googleUser();
    const r = await call("recordConsent", consent(), u.idToken);
    assert.ok(r.ok || r.code !== "app_check_failed", "ENFORCE_APP_CHECK=false did not reach the function runtime");
  });

  test("API-05: valid request -> users/{uid}/consents/{consentId} with exactly the contract fields; response {consentId, receivedAt}", async () => {
    const u = await googleUser();
    const req = consent({ lang: "en" });
    const r = await call("recordConsent", req, u.idToken);
    assert.equal(r.ok, true, JSON.stringify(r));
    assert.deepEqual(Object.keys(r.result).sort(), ["consentId", "receivedAt"]);
    assert.equal(r.result.consentId, req.consentId);
    assert.ok(!Number.isNaN(Date.parse(r.result.receivedAt)));
    const docs = await listConsents(u.uid);
    assert.equal(docs.length, 1);
    assert.equal(docs[0].id, req.consentId);
    assert.deepEqual(Object.keys(docs[0].fields).sort(), ["clientAt", "granted", "lang", "policyVersion", "receivedAt", "type"]);
    assert.equal(docs[0].fields.type, "privacy_policy");
    assert.equal(docs[0].fields.granted, true);
    assert.equal(docs[0].fields.policyVersion, "privacy-v1");
    assert.equal(docs[0].fields.lang, "en");
    assert.ok(docs[0].fields.clientAt.timestamp, "clientAt stored as Timestamp");
    assert.ok(docs[0].fields.receivedAt.timestamp, "receivedAt stored as Timestamp");
    assert.equal(Date.parse(docs[0].fields.receivedAt.timestamp), Date.parse(r.result.receivedAt));
  });

  test("API-06: same request twice -> one document, receivedAt unchanged, same response", async () => {
    const u = await googleUser();
    const req = consent();
    const r1 = await call("recordConsent", req, u.idToken);
    await sleep(1100);
    const r2 = await call("recordConsent", req, u.idToken);
    assert.equal(r1.ok && r2.ok, true);
    assert.deepEqual(r2.result, r1.result);
    const docs = await listConsents(u.uid);
    assert.equal(docs.length, 1);
    assert.equal(Date.parse(docs[0].fields.receivedAt.timestamp), Date.parse(r1.result.receivedAt));
  });

  test("API-06b: 5 concurrent calls with the same consentId -> all succeed, one document, one receivedAt", async () => {
    const u = await googleUser();
    const req = consent();
    const rs = await Promise.all(Array.from({ length: 5 }, () => call("recordConsent", req, u.idToken)));
    for (const r of rs) assert.equal(r.ok, true, JSON.stringify(r));
    assert.equal(new Set(rs.map((r) => r.result.receivedAt)).size, 1);
    assert.equal((await listConsents(u.uid)).length, 1);
  });

  test("API-07: same consentId with different content (granted / type / version) -> first record untouched (QA7)", async () => {
    const u = await googleUser();
    const first = consent({ type: "ai_processing", policyVersion: "ai-consent-v1", granted: true, lang: "pl" });
    const r1 = await call("recordConsent", first, u.idToken);
    assert.equal(r1.ok, true);
    const variants = [
      { ...first, granted: false },
      { ...first, type: "privacy_policy", policyVersion: "privacy-v1" },
      { ...first, lang: "en" },
    ];
    for (const v of variants) {
      const r = await call("recordConsent", v, u.idToken);
      assert.equal(r.ok, true, "second write with same consentId answers like a retry");
      assert.equal(r.result.receivedAt, r1.result.receivedAt);
    }
    const docs = await listConsents(u.uid);
    assert.equal(docs.length, 1);
    assert.equal(docs[0].fields.type, "ai_processing");
    assert.equal(docs[0].fields.granted, true);
    assert.equal(docs[0].fields.policyVersion, "ai-consent-v1");
    assert.equal(docs[0].fields.lang, "pl");
  });

  test("API-07b: the same consentId used by two different users -> separate documents (path per uid)", async () => {
    const a = await googleUser();
    const b = await googleUser();
    const req = consent();
    assert.equal((await call("recordConsent", req, a.idToken)).ok, true);
    assert.equal((await call("recordConsent", { ...req, lang: "en" }, b.idToken)).ok, true);
    assert.equal((await listConsents(a.uid))[0].fields.lang, "pl");
    assert.equal((await listConsents(b.uid))[0].fields.lang, "en");
  });

  test("API-08 / SES-04 (server): user deleted in Auth, old token -> unauthenticated, no document", async () => {
    const u = await googleUser();
    await deleteUser(u.idToken);
    const r = await call("recordConsent", consent(), u.idToken);
    assert.equal(r.ok, false);
    assert.equal(r.code, "unauthenticated");
    assert.equal(r.status, "UNAUTHENTICATED");
    assert.equal((await listConsents(u.uid)).length, 0);
  });

  test("API-09: password and anonymous providers -> unauthenticated, no document", async () => {
    for (const u of [await passwordUser(), await anonymousUser()]) {
      const r = await call("recordConsent", consent(), u.idToken);
      assert.equal(r.ok, false);
      assert.equal(r.code, "unauthenticated");
      assert.equal((await listConsents(u.uid)).length, 0);
    }
  });

  test("API-09b: no Authorization header -> unauthenticated", async () => {
    const r = await call("recordConsent", consent(), undefined);
    assert.equal(r.ok, false);
    assert.equal(r.code, "unauthenticated");
  });

  test("VAL: version / type / id / size / apiVersion validation through the emulator; no document written", async () => {
    const u = await googleUser();
    const cases = [
      [{ policyVersion: "privacy-v2" }, "invalid_argument", "policyVersion"], // not on the known list
      [{ policyVersion: "privacy-v0" }, "invalid_argument", "policyVersion"],
      [{ policyVersion: "privacy-v01" }, "invalid_argument", "policyVersion"],
      [{ policyVersion: "Privacy-v1" }, "invalid_argument", "policyVersion"],
      [{ policyVersion: "privacy-v1 " }, "invalid_argument", "policyVersion"],
      [{ policyVersion: "ai-consent-v1" }, "invalid_argument", "policyVersion"], // prefix vs type
      [{ type: "ai_processing", policyVersion: "privacy-v1" }, "invalid_argument", "policyVersion"],
      [{ type: "marketing" }, "invalid_argument", "type"],
      [{ lang: "de" }, "invalid_argument", "lang"],
      [{ consentId: "not-a-uuid" }, "invalid_argument", "consentId"],
      [{ clientAt: "yesterday" }, "invalid_argument", "clientAt"],
      [{ extra: "x" }, "invalid_argument", undefined],
      [{ policyVersion: "x".repeat(5000) }, "invalid_argument", "request"],
      [{ apiVersion: 2 }, "unsupported_version", undefined],
    ];
    for (const [over, code, field] of cases) {
      const r = await call("recordConsent", consent(over), u.idToken);
      assert.equal(r.ok, false, `expected rejection for ${JSON.stringify(Object.keys(over))}`);
      assert.equal(r.code, code, `code for ${JSON.stringify(Object.keys(over))}`);
      if (field) assert.equal(r.details.field, field);
      // details carry no submitted values (ADR-0002 Aneks A pkt 2)
      for (const v of Object.values(over)) {
        if (typeof v === "string" && v.length > 3) assert.ok(!JSON.stringify(r.details).includes(v), "value echoed in details");
      }
    }
    assert.equal((await listConsents(u.uid)).length, 0);
  });

  test("CONS-10: clientAt +3 days -> server stores server time and clientAtCorrected=true; response OK", async () => {
    const u = await googleUser();
    const req = consent({ clientAt: new Date(Date.now() + 3 * 864e5).toISOString() });
    const r = await call("recordConsent", req, u.idToken);
    assert.equal(r.ok, true);
    const [d] = await listConsents(u.uid);
    assert.equal(d.fields.clientAtCorrected, true);
    assert.equal(d.fields.clientAt.timestamp, d.fields.receivedAt.timestamp);
    // clientAt within 24 h is kept and not flagged
    const ok = consent({ clientAt: new Date(Date.now() - 3600e3).toISOString() });
    assert.equal((await call("recordConsent", ok, u.idToken)).ok, true);
    const kept = (await listConsents(u.uid)).find((x) => x.id === ok.consentId);
    assert.equal(kept.fields.clientAtCorrected, undefined);
    assert.equal(Date.parse(kept.fields.clientAt.timestamp), Date.parse(ok.clientAt));
  });

  test("API-11: Firestore rules deny-all – client SDK token cannot read or write own users/{uid}/consents", async () => {
    const u = await googleUser();
    const req = consent();
    assert.equal((await call("recordConsent", req, u.idToken)).ok, true);
    const h = { authorization: `Bearer ${u.idToken}`, "content-type": "application/json" };
    const read = await fetch(`${FS_DOCS}/users/${u.uid}/consents/${req.consentId}`, { headers: h });
    assert.equal(read.status, 403, "read own consent");
    const list = await fetch(`${FS_DOCS}/users/${u.uid}/consents`, { headers: h });
    assert.equal(list.status, 403, "list own consents");
    const write = await fetch(`${FS_DOCS}/users/${u.uid}/consents/${randomUUID()}`, {
      method: "PATCH",
      headers: h,
      body: JSON.stringify({ fields: { type: { stringValue: "privacy_policy" } } }),
    });
    assert.equal(write.status, 403, "write own consent");
    const cfg = await fetch(`${FS_DOCS}/config/runtime`, { headers: h });
    assert.equal(cfg.status, 403, "read config/runtime");
    assert.equal((await listConsents(u.uid)).length, 1);
  });

  test("API-12 (partial): recordConsent does not require a current acceptance – refusal and repeated acceptance are recorded", async () => {
    const u = await googleUser();
    await setRuntimeConfig({ policyVersionCurrent: "privacy-v1", aiConsentVersionCurrent: "ai-consent-v1" });
    const refuse = consent({ type: "ai_processing", policyVersion: "ai-consent-v1", granted: false });
    assert.equal((await call("recordConsent", refuse, u.idToken)).ok, true, "first ever record (no acceptance yet) is accepted");
    assert.equal((await call("recordConsent", consent(), u.idToken)).ok, true);
    assert.equal((await call("recordConsent", consent(), u.idToken)).ok, true, "second acceptance, new consentId");
    assert.equal((await listConsents(u.uid)).length, 3, "append-only history");
  });

  // ---------- consent_required (generatePlan, ADR-0012 pkt 3-4) ----------
  test("CONSENT_REQUIRED: privacy -> ai order, latest record wins, version N, fail-closed config", async () => {
    const u = await googleUser();
    const base = { aiEnabled: false, allowRealData: false, testUids: [u.uid], policyVersionCurrent: "privacy-v1", aiConsentVersionCurrent: "ai-consent-v1" };
    await setRuntimeConfig(base);

    let r = await call("generatePlan", planRequest(), u.idToken);
    assert.equal(r.code, "consent_required", "no records");
    assert.equal(r.status, "FAILED_PRECONDITION");
    assert.equal(r.details.consentType, "privacy_policy");

    // ai consent alone is not enough: privacy checked first
    assert.equal((await call("recordConsent", consent({ type: "ai_processing", policyVersion: "ai-consent-v1" }), u.idToken)).ok, true);
    r = await call("generatePlan", planRequest(), u.idToken);
    assert.equal(r.details.consentType, "privacy_policy", "ai only -> still privacy_policy");

    assert.equal((await call("recordConsent", consent(), u.idToken)).ok, true);
    r = await call("generatePlan", planRequest(), u.idToken);
    assert.equal(r.code, "ai_unavailable", "both consents OK -> passes consent check (aiEnabled=false)");

    // latest ai record = refusal -> blocked again
    await sleep(50);
    assert.equal((await call("recordConsent", consent({ type: "ai_processing", policyVersion: "ai-consent-v1", granted: false }), u.idToken)).ok, true);
    r = await call("generatePlan", planRequest(), u.idToken);
    assert.equal(r.code, "consent_required");
    assert.equal(r.details.consentType, "ai_processing", "latest ai record granted=false");

    await sleep(50);
    assert.equal((await call("recordConsent", consent({ type: "ai_processing", policyVersion: "ai-consent-v1" }), u.idToken)).ok, true);
    r = await call("generatePlan", planRequest(), u.idToken);
    assert.equal(r.code, "ai_unavailable", "ai granted again");

    // new policy version required by config -> privacy_policy (US-003 AC9 server side)
    await setRuntimeConfig({ ...base, policyVersionCurrent: "privacy-v2" });
    r = await call("generatePlan", planRequest(), u.idToken);
    assert.equal(r.details.consentType, "privacy_policy", "record v1 < current v2");

    await setRuntimeConfig({ ...base, aiConsentVersionCurrent: "ai-consent-v2" });
    r = await call("generatePlan", planRequest(), u.idToken);
    assert.equal(r.details.consentType, "ai_processing", "ai record v1 < current v2");

    // malformed config -> fail closed with privacy_policy, no values in details
    await setRuntimeConfig({ ...base, policyVersionCurrent: "privacy-v01" });
    r = await call("generatePlan", planRequest(), u.idToken);
    assert.equal(r.code, "consent_required");
    assert.deepEqual(r.details, { code: "consent_required", consentType: "privacy_policy" });

    await setRuntimeConfig(base);
  });

  test("CONSENT_REQUIRED: user not on testUids in dev -> test_data_only before any consent read", async () => {
    const u = await googleUser();
    await setRuntimeConfig({ aiEnabled: false, testUids: [], policyVersionCurrent: "privacy-v1", aiConsentVersionCurrent: "ai-consent-v1" });
    const r = await call("generatePlan", planRequest(), u.idToken);
    assert.equal(r.code, "test_data_only");
  });
}

test.after(() => {
  if (process.env.QA_OUT) writeFileSync(process.env.QA_OUT, JSON.stringify(used));
});
