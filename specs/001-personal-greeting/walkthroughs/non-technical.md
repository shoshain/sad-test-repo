# Non-Technical Walkthrough: personal-greeting

> Designed for stakeholders who do not read code. Per Virk & Liu (arXiv 2508.06484), non-programmers miss critical flaws in AI-generated artifacts even with structured explanations. This template uses step-decomposition with alternatives-per-decision to mitigate.

## What we built (one paragraph, plain English)

When someone returns to the app, they should feel recognized. This feature lets each user
set a short personal greeting — their name or a friendly phrase up to 140 characters — and
see it displayed when they sign in. The app checks that the greeting is not empty, not too
long, and plain text only, then shows a simple welcome line like "Hello, Sam."

## Who this is for

Returning users who want continuity and a personal touch at login. Product and support
stakeholders who need confidence that greetings are bounded, safe plain text, and rejected
when invalid.

## Scenario walk-through

### Scenario 1 — Happy path: set and see a greeting

1. **What the user does.** Sam signs in and enters "Sam" as a personal greeting (within the
   1–140 character limit).
2. **What the system does in response.** The system accepts the greeting, validates length
   and format, and prepares the welcome message.
3. **What the user sees.** On the next login, Sam sees: "Hello, Sam."

#### Decision: how to format the welcome line

- **Alternatives considered:** free-form template chosen by the user; fixed prefix only
  ("Welcome back"); full sentence with the user's text embedded.
- **Choice we made:** fixed pattern — "Hello, " + the user's name + "."
- **Why:** predictable, readable, and easy to verify in acceptance tests without rich
  formatting or markdown.

### Scenario 2 — Greeting too long

1. **What the user does.** Alex pastes a greeting longer than 140 characters.
2. **What the system does in response.** The system rejects the input before saving.
3. **What the user sees.** An error indicating the greeting must be between 1 and 140
   characters; nothing is saved.

#### Decision: reject vs truncate

- **Alternatives considered:** silently truncate to 140 chars; warn but save partial text.
- **Choice we made:** reject entirely.
- **Why:** avoids surprising the user with a shortened message they did not intend (AC1.2).

### Scenario 3 — Empty greeting

1. **What the user does.** Jordan submits a blank greeting.
2. **What the system does in response.** The system rejects the empty input.
3. **What the user sees.** An error; no greeting is stored or displayed.

## Demo artifacts

No GIFs recorded for this SAD test run. Evidence is via the acceptance table below and
manual CLI check: run `node src/greeting.js Sam` from the repo root — expect
`Hello, Sam.`

## Acceptance criteria coverage

| Criterion | Evidence |
| --- | --- |
| AC1.1 | Scenario 1 — valid 1..140-char greeting accepted and displayed as "Hello, Sam." |
| AC1.2 | Scenario 2 — input over 140 chars rejected with clear error |
| AC2.1 | Scenario 1 — returned welcome line shown on successful validation (display step) |

## Things that did not change

- No multiple greetings per user, sharing, emoji, or rich formatting.
- No database or account persistence in this toy repo — behavior is validated per request.
- No changes to unrelated repo files outside the greeting feature scope.

## Approval

- [x] Non-technical reviewer: Jane Tester, 2026-05-22
- Comments: Scenarios cover intent and EARS criteria; persistence deferred per test-repo scope.
