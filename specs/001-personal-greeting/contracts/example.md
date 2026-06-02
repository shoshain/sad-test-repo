---
contract: buildGreeting
kind: module
status: proposed
bc: additive
owner: sad-test-repo
---

# Contract: buildGreeting(name)

> Module contract for `src/greeting.js`. Maps spec capabilities C1/C2 to the exported API in this toy library.

## Intent

`buildGreeting` is the sole public behavior for personal-greeting: given a user's display
name, validate it and return a single-line greeting string. Callers (tests, CLI, or a
future HTTP adapter) use this function as the boundary for AC1.1, AC1.2, and AC2.1.

## Request

- **Module:** `src/greeting.js`
- **Export:** `buildGreeting(name: string): string`
- **Parameters:**

```json
{
  "name": "string (1..140 chars, plain text, single line, no newlines)"
}
```

- **Related exports:** `GREETING_MIN` (1), `GREETING_MAX` (140)

## Response

| Outcome | Result | When |
|---|---|---|
| Success | `"Hello, ${name}."` | `name` is a string, length 1..140, no `\n` or `\r` |
| Failure | `RangeError` | Empty string or length > 140 |
| Failure | `TypeError` | `name` is not a string |
| Failure | `Error` ("name must be a single line") | `name` contains newline characters |

Example success:

```javascript
buildGreeting("Sam")  // => "Hello, Sam."
```

Example failure (AC1.2):

```javascript
buildGreeting("x".repeat(141))  // throws RangeError
```

## Idempotency

- Idempotent? yes — same `name` always yields the same string.
- Replay safe? yes — no side effects or stored state.

## Backward compatibility

- Verdict: **additive** (new export; no existing client breaks).
- Consumers affected: none yet — greenfield toy module.
- Migration: none.

## Failure modes

- Validation: enforced in `buildGreeting` before string formatting.
- Persistence: none in this repo.
- Observability: callers log at their boundary; this module does not log.

## Test points

Implemented in `src/greeting.test.js`:

- Length 0, 1, 140, 141 — boundary tests.
- Newline in name — rejected.
- Non-string input — `TypeError`.
- Exported constants match 1 and 140.

CLI smoke (`node src/greeting.js <name>`) mirrors success and stderr-on-failure paths.

## Related artifacts

- Spec: `feature.spec.md` — AC1.1, AC1.2, AC2.1
- Plan: `feature.plan.md` — §3 Design
- Data model: `data-model.md` — GreetingInput, GreetingOutput, GreetingBounds
