# Data model: personal-greeting

> Output of `/sad-plan` (semi-technical tier). Documents the persistence and in-memory shapes the feature touches.
> Reviewed alongside `feature.plan.md` and `contracts/`.

**Tier audience:** semi-technical reviewer

## Entities added or changed

This toy repo has no database. Shapes are in-memory only, defined in `src/greeting.js`.

| Entity | Field | Type | Nullable | Default | Notes |
|---|---|---|---|---|---|
| GreetingInput | name | string (UTF-16 code units) | no | — | Caller-supplied display name; 1..140 chars |
| GreetingOutput | text | string | no | — | Always `Hello, ${name}.` on success |
| GreetingBounds | GREETING_MIN | number (const) | — | 1 | Exported; public contract |
| GreetingBounds | GREETING_MAX | number (const) | — | 140 | Exported; public contract |

**Validation rules on `GreetingInput.name`:**

- Must be typeof `string` (not coerced).
- Length must satisfy `GREETING_MIN ≤ length ≤ GREETING_MAX`.
- Must not contain `\n` or `\r` (single-line plain text).

## Relationships

None — stateless function. No foreign keys, no per-user storage in this test repo.
A production app would map `GreetingInput.name` to a `users.greeting` column; that persistence layer is out of scope here.

## Migration plan

- **Direction:** additive (new module exports).
- **Backward compatible at runtime?** yes — new file; no existing consumers.
- **Rollback:** remove `src/greeting.js` and tests; no data to migrate.
- **Lock or downtime expected?** none.

## Invariants

- On success, `buildGreeting(name)` always returns exactly `Hello, ${name}.` with no trimming or casing change.
- Valid names never mutate; output length is `name.length + 8` (`"Hello, "` + name + `"."`).
- Invalid names never return a partial greeting; they always throw before formatting.

## Open questions

- None for merge — persistence and HTTP layering deferred to a future feature if this repo grows beyond the toy scope.
