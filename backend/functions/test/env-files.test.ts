import { readFileSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";
import { ALLOWED_AI_LOCATIONS, ALLOWED_MODEL_IDS } from "../src/ai";

// TAM-117 (plan wydania, sekcja 4.5): guards the committed prod environment file. Values are not secrets.
function parseEnv(file: string): Map<string, string> {
  const text = readFileSync(join(__dirname, "..", file), "utf8");
  const vars = new Map<string, string>();
  for (const raw of text.split(/\r?\n/)) {
    const line = raw.trim();
    if (!line || line.startsWith("#")) continue;
    const eq = line.indexOf("=");
    expect(eq, `malformed line in ${file}: ${line}`).toBeGreaterThan(0);
    const key = line.slice(0, eq).trim();
    expect(vars.has(key), `duplicate ${key} in ${file}`).toBe(false);
    vars.set(key, line.slice(eq + 1).trim());
  }
  return vars;
}

describe(".env.tamitu-prod-tadecode", () => {
  const env = parseEnv(".env.tamitu-prod-tadecode");

  it("is the prod environment with App Check enforced", () => {
    expect(env.get("ENVIRONMENT")).toBe("prod");
    expect(env.get("ENFORCE_APP_CHECK")).toBe("true");
  });

  it("uses an allowed AI model and location (never global)", () => {
    expect(ALLOWED_MODEL_IDS as readonly string[]).toContain(env.get("AI_MODEL_ID"));
    expect(ALLOWED_AI_LOCATIONS as readonly string[]).toContain(env.get("AI_LOCATION"));
  });

  it("sets ALLOW_REAL_DATA explicitly (O-TAM116-1, O-TAM116-8)", () => {
    expect(env.get("ALLOW_REAL_DATA")).toBe("true");
  });

  it.each(["AI_ENDPOINT_OVERRIDE", "AI_ATTEMPT_TIMEOUT_MS", "AI_PROMPT_VERSION"])("has no %s", (key) => {
    expect(env.has(key)).toBe(false);
  });

  it("contains only the expected keys", () => {
    expect([...env.keys()].sort()).toEqual(
      ["AI_LOCATION", "AI_MODEL_ID", "ALLOW_REAL_DATA", "ENFORCE_APP_CHECK", "ENVIRONMENT"],
    );
  });
});
