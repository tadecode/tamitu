import js from "@eslint/js";
import tseslint from "typescript-eslint";

// ADR-0002 Aneks A pkt 2: no console.* and no direct functions logger outside src/logger.ts.
const noDirectLogging = {
  "no-console": "error",
  "no-restricted-imports": [
    "error",
    {
      paths: [
        { name: "firebase-functions/logger", message: "Use src/logger.ts (allow-listed fields only)." },
        { name: "firebase-functions/logger/compat", message: "Use src/logger.ts." },
      ],
    },
  ],
};

export default tseslint.config(
  { ignores: ["lib/**", "node_modules/**"] },
  js.configs.recommended,
  ...tseslint.configs.recommended,
  { rules: noDirectLogging },
  { files: ["src/logger.ts", "test/**"], rules: { "no-restricted-imports": "off", "no-console": "off" } },
  // TAM-89: plain-JS emulator helpers (test/emulator/*.mjs) run on Node 22, whose web globals are built in.
  {
    files: ["test/**/*.mjs"],
    languageOptions: { globals: { fetch: "readonly", URL: "readonly", Buffer: "readonly", process: "readonly" } },
  },
);
