// Types for vertex-fake.mjs (TAM-89), so TypeScript tests can import it.
export type Scenario =
  | "valid"
  | "invalid"
  | "blocked"
  | "busy"
  | "server_error"
  | "bad_body"
  | "timeout"
  | "config_error";

export const SCENARIOS: readonly Scenario[];
export const EXPECTED_TOKEN: string;

export interface FakeCall {
  n: number;
  scenario: Scenario;
  /** HTTP status sent; 0 = no answer (timeout scenario). */
  status: number;
  location: string;
  model: string;
  /** The request carried previousAttemptErrors (retry after an invalid answer). */
  hints: boolean;
}

export interface VertexFake {
  readonly url: string;
  readonly port: number;
  readonly calls: FakeCall[];
  readonly queue: Scenario[];
  setDefault(s: Scenario): void;
  enqueue(...s: Scenario[]): void;
  reset(): void;
  close(): Promise<void>;
}

export function startVertexFake(opts?: { port?: number; defaultScenario?: Scenario }): Promise<VertexFake>;
export function validPlan(dayTargets: unknown[], language: "pl" | "en"): unknown;
