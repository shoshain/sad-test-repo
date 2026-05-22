// Node 22+ built-in test runner. Run with: node --test src/greeting.test.js
import { test } from "node:test";
import assert from "node:assert/strict";
import { buildGreeting, GREETING_MIN, GREETING_MAX } from "./greeting.js";

test("happy path", () => {
  assert.equal(buildGreeting("Sam"), "Hello, Sam.");
});

test("min length boundary", () => {
  assert.equal(buildGreeting("A"), "Hello, A.");
});

test("max length boundary", () => {
  const name = "x".repeat(GREETING_MAX);
  assert.equal(buildGreeting(name), `Hello, ${name}.`);
});

test("rejects empty", () => {
  assert.throws(() => buildGreeting(""), RangeError);
});

test("rejects too long", () => {
  assert.throws(() => buildGreeting("x".repeat(GREETING_MAX + 1)), RangeError);
});

test("rejects newline", () => {
  assert.throws(() => buildGreeting("Sam\nSmith"), /single line/);
});

test("rejects non-string", () => {
  assert.throws(() => buildGreeting(42), TypeError);
});

test("constants exported", () => {
  assert.equal(GREETING_MIN, 1);
  assert.equal(GREETING_MAX, 140);
});
