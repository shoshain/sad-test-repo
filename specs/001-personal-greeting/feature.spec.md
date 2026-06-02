# Feature: <name>

**Stage:** spec-first / spec-anchored / spec-as-source (per Tessl maturity ladder)
**Tier audience:** non-technical reviewer
**Status:** draft / in-clarification / approved / superseded

## 1. Business Intent
One paragraph. What user problem does this feature solve? Who is the user? What outcome do they get?

## 2. Capabilities
- C1. Save a greeting (1 to 140 characters).
- C2. Display the saved greeting on login.

## 3. Acceptance Criteria (EARS)
- AC1.1. WHEN a logged-in user submits a 1..140-char greeting THEN the system SHALL save it.
- AC1.2. WHEN a greeting exceeds 140 chars THEN the system SHALL reject it.
- AC2.1. WHEN a user logs in with a saved greeting THEN the system SHALL display it.

## 4. Out of Scope
Explicit list of things this feature does *not* do. Prevents scope creep.

## 5. Stakeholder Commitments
What promises does this feature imply to which stakeholders? (Used by `impact-forecaster`.)

## 6. Open Questions
Tracked here until resolved by `/sad-clarify`.

## 7. Approval
- [ ] Non-technical reviewer: <name>, <date>
