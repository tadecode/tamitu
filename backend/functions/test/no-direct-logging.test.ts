import { readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";

// Aneks A pkt 2: console.* and the platform logger are allowed only in src/logger.ts.
describe("logging is centralised", () => {
  const src = join(__dirname, "..", "src");
  // Recursive (P3-05 adds src/prompt/).
  const files = (readdirSync(src, { recursive: true }) as string[])
    .map((f) => f.replace(/\\/g, "/"))
    .filter((f) => f.endsWith(".ts") && f !== "logger.ts");

  it("covers subdirectories", () => {
    expect(files).toContain("prompt/plan-v2.ts");
  });

  it.each(files)("%s has no console.* or direct logger import", (f) => {
    const text = readFileSync(join(src, f), "utf8");
    expect(text).not.toMatch(/\bconsole\./);
    expect(text).not.toMatch(/firebase-functions\/logger/);
  });
});

describe("firestore rules", () => {
  it("are deny-all", () => {
    const rules = readFileSync(join(__dirname, "..", "..", "firestore.rules"), "utf8");
    const code = rules.replace(/\/\/.*$/gm, "");
    expect(code).toMatch(/allow read, write: if false;/);
    expect(code).not.toMatch(/if true|request\.auth/);
  });
});
