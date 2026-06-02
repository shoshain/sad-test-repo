# Technical Plan: personal-greeting

**Tier audience:** semi-technical reviewer
**Status:** draft

## 1. Summary

This feature delivers a single library function, `buildGreeting`, in `src/greeting.js` that
turns a user's display name into a deterministic personal greeting string. The name is
validated against length and format rules before formatting; invalid input throws typed
errors so callers can reject bad data at the boundary.

The implementation already exists as the toy baseline in this repo. SAD walkthrough and
reconciliation will treat that file as the source of truth for C1 (validate and accept
1..140-character names) and C2 (produce the greeting string returned to the caller on
"login" — modeled here as a successful function return rather than persistence).

## 2. Scope mapping

| Capability | Deliverable | Notes |
|------------|-------------|-------|
| C1. Save a greeting (1..140 chars) | `buildGreeting(name)` accepts valid names | "Save" is modeled as accept-and-retain in memory for the call; no DB in this toy repo |
| C2. Display saved greeting on login | Return value `Hello, ${name}.` | Caller displays the returned string; CLI smoke: `node src/greeting.js Sam` |
| AC1.2 rejection | `RangeError` when length ∉ [1, 140] | Covered by `src/greeting.test.js` |
| Newline / type guards | `Error` / `TypeError` for invalid input | Beyond EARS minimum; existing tests lock behavior |

## 3. Design

- **Key flow:** caller passes `name` → `buildGreeting` validates type, length, single-line → returns formatted string or throws.
- **Data model:** see `data-model.md` — input name string, output greeting string, exported bounds constants.
- **Contract:** see `contracts/example.md` — module-level contract for `buildGreeting(name)`.

No sequence diagrams required; single synchronous call with no I/O.

## 4. Dependencies & integration

- **Runtime:** Node.js ≥ 22.6 (ES modules, built-in test runner).
- **Upstream:** none — zero runtime dependencies.
- **Downstream:** `src/greeting.test.js`, CLI entry in `greeting.js`, optional future HTTP wrapper (out of scope).
- **Feature flags / migration:** none — additive export on a greenfield toy module.

## 5. Risks & mitigations

| Risk | Mitigation |
|------|------------|
| Spec implies persistence; code is stateless | Document in reconciliation that "save/display" maps to validate + return for this test repo |
| Unicode / emoji edge cases | Plain-text bounds only; emoji not explicitly rejected unless length exceeded |
| Breaking public API | Semver patch; constants `GREETING_MIN` / `GREETING_MAX` are part of the contract |

## 6. Verification strategy

- **Unit tests:** `npm test` — happy path, boundaries (1, 140, 141), empty, newline, non-string, exported constants.
- **CLI smoke:** `node src/greeting.js Sam` → `Hello, Sam.`; empty arg → stderr + exit 1.
- **Evals:** feature eval folder under `specs/001-personal-greeting/evals/` when wired.
- **Manual:** semi-technical walkthrough scenario table matches contract status codes (mapped to throw types).

## 7. Approval

- [ ] Semi-technical reviewer: <name>, <date>
