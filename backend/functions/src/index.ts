import { getApps, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { defineSecret } from "firebase-functions/params";
import { onCall, type CallableRequest } from "firebase-functions/v2/https";
import { onMessagePublished } from "firebase-functions/v2/pubsub";
import { stubModel } from "./ai.js";
import {
  assertStartupConfig,
  parseStaticConfig,
  SAFE_RUNTIME_DEFAULTS,
  type RuntimeConfig,
} from "./config.js";
import type { ConsentType, ConsentWriter, LatestConsent, LatestConsents } from "./consents.js";
import { budgetGuardCore, deleteAccountCore, generatePlanCore, recordConsentCore, type Deps } from "./endpoints.js";
import { runGuarded } from "./handler.js";

const REGION = "europe-west4";
const UID_PEPPER = defineSecret("UID_HASH_PEPPER");

// Fail-closed startup (Aneks A pkt 3 (i)): throws on prod + App Check off + real data allowed.
const staticConfig = parseStaticConfig(process.env);
assertStartupConfig(staticConfig);

if (getApps().length === 0) initializeApp();

async function loadRuntime(): Promise<RuntimeConfig> {
  const snap = await getFirestore().doc("config/runtime").get();
  const d = snap.data();
  if (!d) return SAFE_RUNTIME_DEFAULTS;
  return {
    aiEnabled: d["aiEnabled"] === true,
    allowRealData: d["allowRealData"] === true,
    testUids: Array.isArray(d["testUids"]) ? d["testUids"].filter((x): x is string => typeof x === "string") : [],
    perUserDailyLimit: Number.isInteger(d["perUserDailyLimit"]) ? d["perUserDailyLimit"] : 5,
    globalDailyLimit: Number.isInteger(d["globalDailyLimit"]) ? d["globalDailyLimit"] : 50,
    // Raw strings; format checked fail-closed in consents.currentVersionNumbers (ADR-0012 pkt 4).
    policyVersionCurrent: typeof d["policyVersionCurrent"] === "string" ? d["policyVersionCurrent"] : undefined,
    aiConsentVersionCurrent: typeof d["aiConsentVersionCurrent"] === "string" ? d["aiConsentVersionCurrent"] : undefined,
  };
}

/** Latest record of one type; uses the existing index (type ASC, receivedAt DESC). ADR-0012 pkt 3. */
async function latestConsent(uid: string, type: ConsentType): Promise<LatestConsent | undefined> {
  const snap = await getFirestore()
    .collection(`users/${uid}/consents`)
    .where("type", "==", type)
    .orderBy("receivedAt", "desc")
    .limit(1)
    .get();
  const d = snap.docs[0]?.data();
  if (!d || typeof d["granted"] !== "boolean" || typeof d["policyVersion"] !== "string") return undefined;
  return { granted: d["granted"], policyVersion: d["policyVersion"] };
}

async function loadLatestConsents(uid: string): Promise<LatestConsents> {
  const privacy = await latestConsent(uid, "privacy_policy");
  const ai = await latestConsent(uid, "ai_processing");
  return { privacy, ai };
}

/**
 * P3-04: idempotent create by consentId in a transaction. An existing document is never overwritten
 * (first write wins); the stored receivedAt is returned so a retry gets the same answer.
 */
const writeConsent: ConsentWriter = async (uid, consentId, doc) => {
  const db = getFirestore();
  const ref = db.doc(`users/${uid}/consents/${consentId}`);
  return db.runTransaction(async (tx) => {
    const existing = await tx.get(ref);
    if (existing.exists) {
      const at = existing.get("receivedAt") as unknown;
      return { receivedAt: at instanceof Timestamp ? at.toDate() : doc.receivedAt };
    }
    tx.create(ref, {
      ...doc,
      clientAt: Timestamp.fromDate(doc.clientAt),
      receivedAt: Timestamp.fromDate(doc.receivedAt),
    });
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

export const generatePlan = onCall(callableOptions, (req: CallableRequest) =>
  runGuarded("generatePlan", (ctx) => generatePlanCore(req, deps(), ctx)),
);

export const recordConsent = onCall(callableOptions, (req: CallableRequest) =>
  runGuarded("recordConsent", (ctx) => recordConsentCore(req, deps(), ctx)),
);

export const deleteAccount = onCall(callableOptions, (req: CallableRequest) =>
  runGuarded("deleteAccount", (ctx) => deleteAccountCore(req, deps(), ctx)),
);

export const budgetGuard = onMessagePublished(
  { topic: "budget-alerts", region: REGION, maxInstances: 1, memory: "256MiB" },
  (event) =>
    runGuarded("budgetGuard", async () => {
      budgetGuardCore(event.data.message.json);
    }),
);
