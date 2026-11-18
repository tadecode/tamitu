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

/**
 * Value for the `serviceAccount` function option. The trailing `@` is the Firebase CLI shorthand:
 * at deploy time it appends `<projectId>.iam.gserviceaccount.com` of the target project
 * (`--project dev|prod`), so the same code deploys to `tamitu-dev-tadecode` and
 * `tamitu-prod-tadecode` without hard-coding a project id.
 */
export function serviceAccountFor(fn: FunctionName): string {
  return `${SERVICE_ACCOUNTS[fn]}@`;
}
