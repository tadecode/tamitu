/**
 * SEC-20 / ADR-0002 Aneks A pkt 6: every function runs as its own least-privilege service account,
 * never as the default compute account. Accounts are created per project in P3-03
 * (`.farm/runbooks/P3-03-firebase.md`, etap 5); `fn-ai` was renamed to `fn-ai-plan` (Google requires
 * 6-30 characters, open question O2).
 */
export const SERVICE_ACCOUNTS = {
  generatePlan: "fn-ai-plan",
  recordConsent: "fn-consent",
  deleteAccount: "fn-account",
  budgetGuard: "fn-budget",
} as const;

export type FunctionName = keyof typeof SERVICE_ACCOUNTS;

/** Google project id rule: 6-30 chars, lowercase letters, digits, hyphens, starts with a letter. */
const PROJECT_ID = /^[a-z][a-z0-9-]{4,28}[a-z0-9]$/;

/**
 * Value for the `serviceAccount` function option: the full e-mail
 * `<name>@<projectId>.iam.gserviceaccount.com`.
 *
 * TAM-86: the `<name>@` shorthand is expanded by the Firebase CLI for the function itself, but NOT
 * when it grants the account access to a secret (`secrets: [UID_HASH_PEPPER]`), which failed with
 * `setIamPolicy ... 400, Invalid service account (fn-consent@)`. Hence the full address.
 *
 * The project id comes from `GCLOUD_PROJECT`, which the Firebase CLI sets from `--project` both when
 * it analyses the source (discovery) and in the deployed function's environment (also in the
 * emulator), so the same code serves `tamitu-dev-tadecode` and `tamitu-prod-tadecode`.
 * `projectID` from `firebase-functions/params` is not used: it is an Expression and cannot be
 * concatenated with the account name into one string option.
 *
 * Fail-closed: no (or malformed) project id throws instead of falling back to the default
 * compute account.
 */
export function serviceAccountFor(fn: FunctionName, env: NodeJS.ProcessEnv = process.env): string {
  const projectId = env.GCLOUD_PROJECT;
  if (projectId === undefined || !PROJECT_ID.test(projectId)) {
    throw new Error(`serviceAccountFor(${fn}): GCLOUD_PROJECT missing or invalid; refusing default account`);
  }
  return `${SERVICE_ACCOUNTS[fn]}@${projectId}.iam.gserviceaccount.com`;
}
