import { describe, expect, it } from "vitest";
import { AppError, classifyError } from "../src/errors.js";

const withCode = (code: unknown, ctor: new (m: string) => Error = Error): Error =>
  Object.assign(new ctor("secret message"), { code });

describe("classifyError (SEC-19)", () => {
  it("AppError -> contract code", () => {
    expect(classifyError(new AppError("limit_exceeded"))).toEqual({ errorClass: "AppError", errorCode: "limit_exceeded" });
  });

  it.each([
    ["auth/id-token-revoked"],
    ["ECONNRESET"],
    ["permission-denied"],
    ["storage.objects:get"],
    ["a".repeat(60)],
  ])("keeps allowed library code %s", (code) => {
    expect(classifyError(withCode(code)).errorCode).toBe(code);
  });

  it("keeps finite numeric codes (gRPC)", () => {
    expect(classifyError(withCode(5)).errorCode).toBe("5");
  });

  it.each([
    ["contains space", "bad input Lizbona"],
    ["contains quote", 'x"y'],
    ["too long (not truncated)", "a".repeat(61)],
    ["empty", ""],
    ["unicode", "zażółć"],
    ["newline", "a\nb"],
    ["NaN", Number.NaN],
    ["Infinity", Number.POSITIVE_INFINITY],
    ["object", { nested: "x" }],
    ["missing", undefined],
  ])("maps disallowed code (%s) to unknown", (_n, code) => {
    expect(classifyError(withCode(code)).errorCode).toBe("unknown");
  });

  it("keeps built-in and custom class names", () => {
    expect(classifyError(new TypeError("x")).errorClass).toBe("TypeError");
    class FirebaseAuthError extends Error {}
    expect(classifyError(new FirebaseAuthError("x")).errorClass).toBe("FirebaseAuthError");
  });

  it("non-Error values use typeof", () => {
    expect(classifyError("some string with content")).toEqual({ errorClass: "string", errorCode: "unknown" });
    expect(classifyError(null)).toEqual({ errorClass: "object", errorCode: "unknown" });
  });

  it("maps a class name outside the allow-list to unknown", () => {
    const e = new Error("x");
    Object.defineProperty(e, "constructor", { value: { name: "Bad Name with input" } });
    expect(classifyError(e).errorClass).toBe("unknown");
    const long = new Error("x");
    Object.defineProperty(long, "constructor", { value: { name: "A".repeat(61) } });
    expect(classifyError(long).errorClass).toBe("unknown");
  });

  it("never includes the message", () => {
    expect(JSON.stringify(classifyError(withCode("bad input secret message")))).not.toContain("secret");
  });
});
