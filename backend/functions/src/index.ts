import { applicationDefault, getApps, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { defineSecret } from "firebase-functions/params";
import { onCall, type CallableRequest } from "firebase-functions/v2/https";
import { onMessagePublished } from "firebase-functions/v2/pubsub";
import { createPlanModel, type FetchLike, type PlanModel } from "./ai.js";
import {
  assertStartupConfig,
  parseRuntimeConfig,
  parseStaticConfig,
  type RuntimeConfig,
} from "./config.js";
import {
  consentDocPath,
  latestConsentFromDoc,
  storedReceivedAt,
  toStoredConsent,
  type ConsentType,
  type ConsentWriter,
  type LatestConsent,
  type LatestConsents,
} from "./consents.js";
import { budgetGuardCore, deleteAccountCore, generatePlanCore, recordConsentCore, type Deps } from "./endpoints.js";
import { runGuarded } from "./handler.js";
import {
  planBusyReleaseOutcome,
  planReleaseOutcome,
  planReservation,
  usageFromDoc,
  warsawDay,
  type BusyReleaseOutcome,
  type ReleaseOutcome,
  type ReservationPlan,
} from "./limits.js";
import { resolvePrompt } from "./prompt/index.js";
import { serviceAccountFor } from "./service-accounts.js";

const REGION = "europe-west4";
const UID_PEPPER = defineSecret("UID_HASH_PEPPER");

// Fail-closed startup (Aneks A pkt 3 (i)): throws on prod + App Check off + real data allowed.
const staticConfig = parseStaticConfig(process.env);
assertStartupConfig(staticConfig);

if (getApps().length === 0) initializeApp();

async function loadRuntime(): Promise<RuntimeConfig> {
  const snap = await getFirestore().doc("config/runtime").get();
  // Parsing and bounds live in config.ts (SEC-22, unit-tested).
  return parseRuntimeConfig(snap.data());
}

/** Latest record of one type; uses the existing index (type ASC, receivedAt DESC). ADR-0012 pkt 3. */
async function latestConsent(uid: string, type: ConsentType): Promise<LatestConsent | undefined> {
  const snap = await getFirestore()
    .collection(`users/${uid}/consents`)
    .where("type", "==", type)
    .orderBy("receivedAt", "desc")
    .limit(1)
    .get();
  return latestConsentFromDoc(snap.docs[0]?.data());
}

/** Both reads in parallel (review PR #51 #5a): one round trip instead of two. */
async function loadLatestConsents(uid: string): Promise<LatestConsents> {
  const [privacy, ai] = await Promise.all([
    latestConsent(uid, "privacy_policy"),
    latestConsent(uid, "ai_processing"),
  ]);
  return { privacy, ai };
}

/**
 * P3-04: idempotent create by consentId in a transaction. An existing document is never overwritten
 * (first write wins); the stored receivedAt is returned so a retry gets the same answer.
 */
const writeConsent: ConsentWriter = async (uid, consentId, doc) => {
  const db = getFirestore();
  const ref = db.doc(consentDocPath(uid, consentId));
  return db.runTransaction(async (tx) => {
    const existing = await tx.get(ref);
    if (existing.exists) {
      return { receivedAt: storedReceivedAt(existing.get("receivedAt"), doc.receivedAt) };
    }
    // create() (not set()): never overwrites; concurrent first writes abort one transaction.
    tx.create(ref, toStoredConsent(doc, (d) => Timestamp.fromDate(d)));
    return { receivedAt: doc.receivedAt };
  });
};

/**
 * P3-05 quota reservation: ONE transaction reads usage/{uid} and usage_global/{today} and writes both
 * (firestore-ttl-indexes.md pkt 3.2, rules 1-2). Concurrent calls retry the transaction, so the
 * counters cannot be overshot. Decision logic: limits.planReservation (unit-tested).
 */
async function reserveQuota(
  uid: string,
  limits: { userLimit: number; globalLimit: number },
  now: Date,
): Promise<ReservationPlan> {
  const db = getFirestore();
  const usageRef = db.doc(`usage/${uid}`);
  return db.runTransaction(async (tx) => {
    const globalRef = db.doc(`usage_global/${warsawDay(now)}`);
    const [u, g] = await Promise.all([tx.get(usageRef), tx.get(globalRef)]);
    const gc = g.get("count");
    const plan = planReservation({
      usage: usageFromDoc(u.data()),
      globalCount: Number.isInteger(gc) ? (gc as number) : 0,
      ...limits,
      now,
    });
    if (plan.allowed) {
      const w = plan.writes;
      tx.set(usageRef, { ...w.usage, updatedAt: Timestamp.fromDate(w.usage.updatedAt), expireAt: Timestamp.fromDate(w.usage.expireAt) });
      tx.set(globalRef, { count: w.global.count, expireAt: Timestamp.fromDate(w.global.expireAt) });
    }
    return plan;
  });
}

/** Rule 3: separate transaction; decrements only when the stored day is still the reservation day. */
async function releaseQuota(uid: string, reservationDay: string, now: Date): Promise<ReleaseOutcome> {
  const db = getFirestore();
  const ref = db.doc(`usage/${uid}`);
  return db.runTransaction(async (tx) => {
    const r = planReleaseOutcome(usageFromDoc((await tx.get(ref)).data()), reservationDay, now);
    if (r.outcome === "released") {
      const w = r.write;
      tx.set(ref, { ...w, updatedAt: Timestamp.fromDate(w.updatedAt), expireAt: Timestamp.fromDate(w.expireAt) });
    }
    return r.outcome;
  });
}

/**
 * ADR-0016 pkt 8 (posrednik-api.md pkt 2 rule 7): after ai_busy ONE transaction returns the account slot
 * and the global slot of the reservation day, without touching `released`; fuse busyReleased <= 10/day.
 */
async function releaseBusyQuota(uid: string, reservationDay: string, now: Date): Promise<BusyReleaseOutcome> {
  const db = getFirestore();
  const usageRef = db.doc(`usage/${uid}`);
  const globalRef = db.doc(`usage_global/${reservationDay}`);
  return db.runTransaction(async (tx) => {
    const [u, g] = await Promise.all([tx.get(usageRef), tx.get(globalRef)]);
    const gc = g.get("count");
    const r = planBusyReleaseOutcome(usageFromDoc(u.data()), Number.isInteger(gc) ? (gc as number) : 0, reservationDay, now);
    if (r.outcome === "busy_released") {
      const w = r.write;
      tx.set(usageRef, { ...w, updatedAt: Timestamp.fromDate(w.updatedAt), expireAt: Timestamp.fromDate(w.expireAt) });
      if (g.exists) tx.set(globalRef, { count: r.global.count, expireAt: Timestamp.fromDate(r.global.expireAt) });
    }
    return r.outcome;
  });
}

/**
 * Vertex model from AI_MODEL_ID / AI_LOCATION (.env.<project>); undefined when missing or not allowed
 * (fail-closed: generatePlan answers ai_unavailable before reserving a slot). Token: the function's
 * own service account (fn-ai-plan) via Application Default Credentials - no keys.
 * TAM-89: AI_ENDPOINT_OVERRIDE redirects calls to a local fake ONLY in the Functions emulator with a
 * demo-* project and a loopback URL (ai.ts parseAiEndpointOverride); anywhere else it disables the model.
 */
/** AI_PROMPT_VERSION (.env.<project>, optional): plan-v1 unless exactly a known version (TAM-95, fail-closed). */
const prompt = resolvePrompt(process.env["AI_PROMPT_VERSION"]);
let credential: ReturnType<typeof applicationDefault> | undefined;
const model: PlanModel | undefined = createPlanModel(process.env, {
  fetch: fetch as unknown as FetchLike,
  // Lazy: created on the first model call, not at module load (deploy analysis, tests).
  adcToken: async () => (await (credential ??= applicationDefault()).getAccessToken()).access_token,
});

function deps(): Deps {
  return {
    verifier: getAuth(),
    config: staticConfig,
    loadRuntime,
    loadLatestConsents,
    writeConsent,
    pepper: UID_PEPPER.value(),
    now: () => new Date(),
    model,
    prompt,
    reserveQuota,
    releaseQuota,
    releaseBusyQuota,
  };
}

const callableOptions = {
  region: REGION,
  maxInstances: 10,
  memory: "512MiB" as const,
  timeoutSeconds: 120,
  secrets: [UID_PEPPER],
};

export const generatePlan = onCall(
  { ...callableOptions, serviceAccount: serviceAccountFor("generatePlan") },
  (req: CallableRequest) => runGuarded("generatePlan", (ctx) => generatePlanCore(req, deps(), ctx)),
);

export const recordConsent = onCall(
  { ...callableOptions, serviceAccount: serviceAccountFor("recordConsent") },
  (req: CallableRequest) => runGuarded("recordConsent", (ctx) => recordConsentCore(req, deps(), ctx)),
);

export const deleteAccount = onCall(
  { ...callableOptions, serviceAccount: serviceAccountFor("deleteAccount") },
  (req: CallableRequest) => runGuarded("deleteAccount", (ctx) => deleteAccountCore(req, deps(), ctx)),
);

export const budgetGuard = onMessagePublished(
  {
    topic: "budget-alerts",
    region: REGION,
    maxInstances: 1,
    memory: "256MiB",
    serviceAccount: serviceAccountFor("budgetGuard"),
  },
  (event) =>
    runGuarded("budgetGuard", async () => {
      budgetGuardCore(event.data.message.json);
    }),
);
