import { getApps, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { defineSecret } from "firebase-functions/params";
import { onCall, type CallableRequest } from "firebase-functions/v2/https";
import { onMessagePublished } from "firebase-functions/v2/pubsub";
import { stubModel } from "./ai.js";
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

function deps(): Deps {
  return {
    verifier: getAuth(),
    config: staticConfig,
    loadRuntime,
    loadLatestConsents,
    writeConsent,
    pepper: UID_PEPPER.value(),
    now: () => new Date(),
    model: stubModel,
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
