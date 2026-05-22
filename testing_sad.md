# Testing SAD end-to-end

> Concrete, copy-pasteable plan for exercising every advertised piece of the [SAD methodology kit](https://github.com/shoshain/sad) against this throwaway consuming project. Every section is independent; you can run sections out of order, but the lifecycle sections (§5–§10) chain.

## Conventions used in this doc

- `$ ...` — POSIX (bash, macOS / Linux / WSL / Git Bash).
- `PS> ...` — Windows native PowerShell.
- Where both work, the POSIX form is shown; PowerShell siblings are noted inline.
- "the SAD kit" means `https://github.com/shoshain/sad`, cloned next to this repo.
- "this repo" means `sad-test-repo` (where this file lives).

---

## 0. One-time setup

```bash
# Choose a workspace folder.
$ mkdir -p ~/sad-workspace && cd ~/sad-workspace

# Clone the methodology kit and the test repo as siblings.
$ git clone https://github.com/shoshain/sad.git
$ git clone https://github.com/shoshain/sad-test-repo.git

# Confirm both are present.
$ ls -la
# drwxr-xr-x  sad
# drwxr-xr-x  sad-test-repo
```

PowerShell:

```powershell
PS> mkdir $HOME\sad-workspace; cd $HOME\sad-workspace
PS> git clone https://github.com/shoshain/sad.git
PS> git clone https://github.com/shoshain/sad-test-repo.git
PS> Get-ChildItem
```

**Prereqs**

| Tool | Version | Why |
|---|---|---|
| `git` | any | clone + commit |
| `node` | ≥ 22.6 | eval harness uses `--experimental-strip-types`; toy project tests |
| `python` | ≥ 3.10 | reference MCP server skeleton |
| `bash` **or** `pwsh` | any | run the SAD scripts |

---

## 0.5 Smoke-test the toy project (before SAD install)

This repo ships a minimal feature (`src/greeting.js`) with unit tests. Run them **before** installing SAD to confirm Node and the workspace are healthy.

```bash
$ cd ~/sad-workspace/sad-test-repo
$ node --version          # must be >= 22.6
$ npm test                # runs: node --test src/greeting.test.js
# expect: all tests pass (happy path, boundaries, rejections)
```

PowerShell:

```powershell
PS> cd $HOME\sad-workspace\sad-test-repo
PS> node --version
PS> npm test
```

Quick CLI smoke (no test runner):

```bash
$ node src/greeting.js Sam
# expect: Hello, Sam.
$ node src/greeting.js "" ; echo "exit=$?"
# expect: error message on stderr; exit=1
```

**Pass condition.** `npm test` exits 0 with no failures.

---

## 1. Install SAD into this repo

The website promises: one command, five adapters auto-detected, optional `--persistent` wiring, `--dry-run` and `--minimal` flags.

### 1.1 Preview the install (no writes)

```bash
$ cd ~/sad-workspace/sad-test-repo
$ ../sad/scripts/sad-init.sh --dry-run .
# expect: [sad-init] DRY: ... for every file the installer would write; no actual mutation
```

PowerShell:

```powershell
PS> cd $HOME\sad-workspace\sad-test-repo
PS> ..\sad\scripts\sad-init.ps1 -TargetDir . -DryRun
```

**Pass condition.** Output ends with `done. target: ...` and the working tree (`git status`) is **clean**.

### 1.2 Real install — full footprint, persistent

```bash
$ ../sad/scripts/sad-init.sh --persistent .
```

PowerShell:

```powershell
PS> ..\sad\scripts\sad-init.ps1 -TargetDir . -Persistent
```

**Pass conditions:**

- The installer prints `detected assistant: <name>` (or `none` on a bare repo).
- `.sad/`, `commands/`, `agents/`, `hooks/`, `evals/`, `examples/`, `reference/` all appear in this repo.
- `LIFECYCLE.md`, `CHEATSHEET.md`, `QUICKSTART.md`, `MATURITY.md`, `ROLES.md`, `MANIFESTO.md`, `NOVEL.md`, `GLOSSARY.md`, `DAEMON.md`, `ATTRIBUTION.md`, `SAD_USER_GUIDE.md` all land at this repo's root.
- `AGENTS.md` is written at the root with the declared-precedence block.
- If the adapter detected was `claude-code`, `.claude/settings.json` exists (Windows variant on Windows; POSIX variant on macOS/Linux), `.claude/skills/sad/SKILL.md` exists, and `.claude/commands/sad-*.md` contains 21 pointer files.
- The installer ends by running `/sad-doctor` and prints its report.

### 1.3 Minimal install (alternative path — wipe and redo)

If you want to also test `--minimal`, in a **fresh clone** of `sad-test-repo`:

```bash
$ ../sad/scripts/sad-init.sh --minimal .
# expect: .sad/, methodology core docs, adapter, but NO commands/, agents/, hooks/, evals/, examples/
```

### 1.4 Verify cross-platform script parity

```bash
$ ls -la .sad/scripts/
# expect both .sh and .ps1 for each of:
#   check-tier-approvals, create-feature, doctor, drift-scan, update-state, maturity-report
```

---

## 2. Run /sad-doctor (health check)

Website claim: 30-second health check, green/yellow/red, read-only, `--json` and `--quiet` flags.

### 2.1 Default (text)

```bash
$ bash .sad/scripts/doctor.sh
```

PowerShell:

```powershell
PS> .\.sad\scripts\doctor.ps1
```

**Pass condition.** Output begins with `/sad-doctor — N green, N yellow, N red` and lists every check. Exit code 0 if no red findings; 1 if any. On a freshly-installed empty repo expect a couple of yellows (no features yet, stakeholders still have `[List people` placeholders) — that is normal.

### 2.2 JSON mode

```bash
$ bash .sad/scripts/doctor.sh --json > doctor.json && cat doctor.json | head -20
```

**Pass condition.** Output is valid JSON; pipe through `jq .summary` or `python -m json.tool` to confirm.

### 2.3 Quiet mode (CI use)

```bash
$ bash .sad/scripts/doctor.sh --quiet ; echo "exit=$?"
# expect: no stdout; "exit=0" or "exit=1"
```

---

## 3. Bootstrap the constitution

Website claim: `/sad-constitution --template <name>` skips the interactive starter selection; six starters available.

### 3.1 Pick a starter and copy it

```bash
# This repo is a tiny library-style example; use the library starter.
$ cp .sad/templates/constitutions/library.md .sad/memory/constitution.md
```

PowerShell:

```powershell
PS> Copy-Item .sad\templates\constitutions\library.md .sad\memory\constitution.md -Force
```

### 3.2 Fill the placeholders

Open `.sad/memory/constitution.md` in your editor. Replace `[name]`, `[who]`, etc. For this test repo, use:

- **Project name:** `sad-test-repo`
- **Primary users:** `engineers testing SAD`
- **Risk class:** `low`
- **Maturity level (initial):** `Level 0` (solo SAD)

Resolve each tension at the bottom with one sentence; for this test feature just write "n/a — test repo".

### 3.3 Re-run /sad-doctor — constitution checks should turn green

```bash
$ bash .sad/scripts/doctor.sh | grep -E '^\[OK\] constitution'
# expect: [OK]  constitution.identity, [OK]  constitution.maturity (constitution.articles may stay yellow until you add A1..A3)
```

---

## 4. Fill the stakeholder tier files

```bash
$ ls .sad/stakeholders/
# non-technical.md  semi-technical.md  technical.md
```

Open each and replace `[List people, roles, ...]` with at least one name (use your own name across all three for this test — Solo SAD assumes that).

Re-run doctor:

```bash
$ bash .sad/scripts/doctor.sh | grep stakeholders
# expect three green rows
```

---

## 5. Scaffold a feature with `create-feature`

Website claim: `create-feature.{sh,ps1}` scaffolds the full per-feature artifact set under `specs/<NNN>-<slug>/`.

```bash
$ bash .sad/scripts/create-feature.sh 001 personal-greeting
# expect: Scaffolded /path/to/sad-test-repo/specs/001-personal-greeting
```

PowerShell:

```powershell
PS> .\.sad\scripts\create-feature.ps1 001 personal-greeting
```

**Pass condition.** `ls specs/001-personal-greeting/` shows:

```
feature.spec.md
feature.plan.md
tasks.md
impact-forecast.md
reconciliation.md
requirements.draft.md           ← new in v0.1.1
data-model.md                   ← new in v0.1.1
research.md                     ← new in v0.1.1
analysis.md                     ← new in v0.1.1
walkthroughs/non-technical.md
walkthroughs/semi-technical.md
walkthroughs/technical.md
contracts/example.md            ← new in v0.1.1
demo/
stories/
evals/
```

---

## 6. Walk the per-feature lifecycle (truncated to the minimum gate)

This section exercises steps 3–8 from `LIFECYCLE.md`, with the tier-routed approval gate at step 8 as the real test.

### 6.1 Fill the requirements draft (step 3, `/sad-brainstorm`)

Open `specs/001-personal-greeting/requirements.draft.md` and replace placeholders with:

```markdown
## Problem
Returning users want a sense of continuity — recognition by the app at login.

## Smallest viable scope
- One short personal greeting per user.

## Bounds
- Length 1..140 characters.
- Plain text; no markdown, no emoji.

## Out of scope
- Multiple greetings, sharing, rich formatting.
```

### 6.2 Fill the spec (step 4, `/sad-specify`)

Open `specs/001-personal-greeting/feature.spec.md`. Replace the template's `<feature name>` and add:

```markdown
## 2. Capabilities
- C1. Save a greeting (1 to 140 characters).
- C2. Display the saved greeting on login.

## 3. Acceptance Criteria (EARS)
- AC1.1. WHEN a logged-in user submits a 1..140-char greeting THEN the system SHALL save it.
- AC1.2. WHEN a greeting exceeds 140 chars THEN the system SHALL reject it.
- AC2.1. WHEN a user logs in with a saved greeting THEN the system SHALL display it.
```

### 6.3 Fill the plan + data-model + contracts (step 7, `/sad-plan`)

In `feature.plan.md`, in `data-model.md`, and in `contracts/example.md`, replace `<feature name>` and the example greeting fields with the same shape but referencing this repo's `src/greeting.js`.

### 6.4 Author the three walkthroughs (step 8, `/sad-walkthrough`)

Open each of:

- `walkthroughs/non-technical.md` — plain English, no code.
- `walkthroughs/semi-technical.md` — contracts table.
- `walkthroughs/technical.md` — reviewer rollup.

For each, replace `<name>, <date>` in the Approval line with your name and today's date, and tick the checkbox: `- [x]`.

### 6.5 Verify the tier-routed gate

This is the load-bearing test. The check-tier-approvals script must report all three approved.

```bash
$ bash .sad/scripts/check-tier-approvals.sh specs/001-personal-greeting ; echo "exit=$?"
# expect: exit=0
```

PowerShell:

```powershell
PS> .\.sad\scripts\check-tier-approvals.ps1 specs\001-personal-greeting; "exit=$LASTEXITCODE"
# expect: exit=0
```

**Pass conditions:**

- All three approval checkboxes are detected (`exit=0`).
- Untick one checkbox and re-run: `exit=2`. Re-tick and confirm 0 again.

### 6.6 Run /sad-doctor — feature should now have all artifacts

```bash
$ bash .sad/scripts/doctor.sh | grep feature.001
# expect: [OK]  feature.001-personal-greeting.artifacts -- has all required artifacts
```

---

## 7. Run the analysis + drift-scan

### 7.1 Drift scan (no reconciliation yet → should flag the feature)

```bash
$ bash .sad/scripts/drift-scan.sh ; echo "exit=$?"
# expect (because reconciliation.md is still a stub): exit=2 unless you filled it
```

After you fill `reconciliation.md` with a "coherent" verdict:

```bash
$ bash .sad/scripts/drift-scan.sh ; echo "exit=$?"
# expect: exit=0
```

### 7.2 Update the SAD state file

```bash
$ bash .sad/scripts/update-state.sh --feature 001-personal-greeting
$ bash .sad/scripts/update-state.sh --phase walkthrough
$ bash .sad/scripts/update-state.sh --last-command /sad-walkthrough
$ cat .sad/state/sad-state.md
# expect: the Slug/Phase/Last command lines now reflect the values above
```

PowerShell:

```powershell
PS> .\.sad\scripts\update-state.ps1 -Feature 001-personal-greeting
PS> .\.sad\scripts\update-state.ps1 -Phase walkthrough
PS> .\.sad\scripts\update-state.ps1 -LastCommand /sad-plan
PS> Get-Content .sad\state\sad-state.md
```

---

## 8. Run the eval harness

Website claim: Node 22+ runner, no third-party dependencies, deterministic+LLM-judge+SME-calibrator graders, exit 0 if all pass.

```bash
$ cd evals
$ npm run eval
# or directly:
$ node --experimental-strip-types run.mjs
```

**Pass conditions:**

- Output begins with `/sad-eval-harness — N pass · N fail · N error · N stub · N skip`.
- Stubs do **not** fail the run (exit 0).

### 8.1 JSON mode

```bash
$ node --experimental-strip-types run.mjs --json | python -m json.tool
# expect: { "summary": {...}, "cases": [...] }
```

### 8.2 Verbose mode (per-case detail)

```bash
$ node --experimental-strip-types run.mjs --verbose
```

---

## 9. Run the reference MCP server (legacy-context pattern)

Website claim: optional reference application; zero-deps; deterministic responses.

```bash
$ echo '{"jsonrpc":"2.0","id":1,"method":"greet","params":{"name":"Sam"}}' \
    | python reference/example-server/server.py
# expect: {"jsonrpc": "2.0", "id": 1, "result": {"greeting": "Hello, Sam."}}
```

Failure case:

```bash
$ echo '{"jsonrpc":"2.0","id":2,"method":"greet","params":{"name":""}}' \
    | python reference/example-server/server.py
# expect: an "error": { "code": -32602, ... } envelope with a length-validation message
```

Unknown method:

```bash
$ echo '{"jsonrpc":"2.0","id":3,"method":"farewell","params":{}}' \
    | python reference/example-server/server.py
# expect: error.code -32601 (unknown method)
```

Parse error:

```bash
$ echo 'not json' | python reference/example-server/server.py
# expect: error.code -32700 (parse error)
```

---

## 10. Run the maturity-readiness card

Website claim: `.sad/scripts/maturity-report.{sh,ps1}` reads the level state + rollback log + survey files and emits a readiness card.

### 10.1 Default (text)

```bash
$ bash .sad/scripts/maturity-report.sh
# expect:
# /sad-maturity-report
# ------------------------------------------------------------
# Current level         : 0
# Level started         : 2026-05-21
# Features total        : 1
# Features since level  : 1
# Rollbacks since level : 0
# Rollback rate         : 0.000 (threshold <= 0.05) -> yes
# Satisfaction avg %    : no surveys recorded yet
```

PowerShell:

```powershell
PS> .\.sad\scripts\maturity-report.ps1
```

### 10.2 JSON mode

```bash
$ bash .sad/scripts/maturity-report.sh --json
# expect: structured JSON with current_level, features_*, rollback_*, satisfaction_*
```

### 10.3 Simulate a stakeholder survey

```bash
$ mkdir -p .sad/state/satisfaction/2026-05
$ cp .sad/templates/stakeholder-satisfaction-survey.md \
     .sad/state/satisfaction/2026-05/non-technical.md
```

Open the new file, set `Period: 2026-05`, fill the five Likert scores (4, 5, 4, 5, 5 → total 23 / 25 → 92%), and write a Satisfaction line: `**Satisfaction %:** 92`.

Re-run:

```bash
$ bash .sad/scripts/maturity-report.sh
# expect:
# Satisfaction avg %    : 92% (threshold >= 80) -> yes
```

### 10.4 Simulate a rollback

```bash
$ cp .sad/templates/rollback-log.md .sad/state/rollback-log.md
```

Add a real data row to the table — for example:

```markdown
| 2026-05-21 | `001-personal-greeting` | sev-3 | empty-string accepted | semi-technical | enforce min length 1 |
```

Re-run:

```bash
$ bash .sad/scripts/maturity-report.sh
# expect:
# Rollbacks since level : 1
# Rollback rate         : 1.000 (threshold <= 0.05) -> no
```

---

## 11. Verify all hook descriptors are valid JSON

```bash
$ for f in hooks/*.json; do node -e "JSON.parse(require('fs').readFileSync('$f'))" && echo "ok  $f"; done
# expect: 5 "ok  hooks/..." lines, no errors
```

PowerShell:

```powershell
PS> Get-ChildItem hooks -Filter *.json | ForEach-Object {
PS>   try { Get-Content $_.FullName -Raw | ConvertFrom-Json | Out-Null; "ok  $($_.Name)" }
PS>   catch { "FAIL  $($_.Name)  $_" }
PS> }
```

Same for the adapter settings:

```bash
$ for f in adapters/claude-code/settings*.json; do node -e "JSON.parse(require('fs').readFileSync('$f'))" && echo "ok  $f"; done
# expect: 4 "ok" lines (settings.json, settings.persistent.json, settings.windows.json, settings.windows.persistent.json)
```

---

## 12. CI workflows (GitHub Actions)

Four workflows ship under `.github/workflows/`. They run on GitHub when this repo is pushed; locally you only verify YAML validity.

```bash
$ for f in .github/workflows/*.yml; do python -c "import yaml,sys; yaml.safe_load(open('$f'))" && echo "ok  $f"; done
# expect: ok lines for sad-doctor.yml, sad-evals.yml, sad-spec-drift-scan.yml, sad-maturity-report.yml
```

(If `yaml` isn't installed, `pip install pyyaml` first, or skip to GitHub-side validation by pushing to a branch.)

---

## 13. Exercise the requirements-progress script (optional, REQ-traceability projects only)

```bash
# Skip unless you maintain a REQ-DOC mapping.
$ python ../sad/scripts/sad_update_requirements_progress.py --help
# expect: usage text listing --mapping, --specs-dir, --output-md, etc.
```

---

## 14. /sad-doctor — final green run

After §3, §4, §5, §6, §7 are all green:

```bash
$ bash .sad/scripts/doctor.sh
```

**Final pass condition.** Output:

- `0 red`
- `≤ 2 yellow` (acceptable: `constitution.articles` if you didn't add A1..A3; `features.any` once you have at least one feature it should be `[OK]`).
- The feature you created appears as `[OK]  feature.001-personal-greeting.artifacts`.
- Exit code 0.

---

## 15. Cleanup

To repeat the test from a clean slate, you can either:

```bash
# Local reset (keep installed kit; throw out the test feature)
$ rm -rf specs/001-personal-greeting
$ rm -f .sad/state/rollback-log.md
$ rm -rf .sad/state/satisfaction/

# Or full reset (re-install the SAD kit from scratch)
$ git clean -fdx
$ git checkout .
$ ../sad/scripts/sad-init.sh --persistent .
```

---

## Test matrix at a glance

| # | What is tested | Script(s) exercised | Files inspected | Pass signal |
|---|---|---|---|---|
| 1 | Install (dry-run + real + minimal) | `sad-init.{sh,ps1}` | `.sad/`, `commands/`, `agents/`, `hooks/`, `evals/`, `reference/`, root docs, adapter files | doctor green section, all listed dirs present |
| 2 | Doctor health-check (text / JSON / quiet) | `doctor.{sh,ps1}` | reports stdout, JSON | exit 0 on a clean install |
| 3 | Constitution bootstrap with `--template` | `sad-constitution` prompt | `.sad/memory/constitution.md` | doctor's `constitution.identity` and `constitution.maturity` go green |
| 4 | Stakeholder tier files | n/a | `.sad/stakeholders/*.md` | doctor three green stakeholder rows |
| 5 | Per-feature scaffold | `create-feature.{sh,ps1}` | `specs/001-personal-greeting/` | 12 templates + 4 subdirs present |
| 6 | Tier-routed approval gate | `check-tier-approvals.{sh,ps1}` | three walkthrough files | exit 0 when all three checked; exit 2 when any unchecked |
| 7 | Drift scan + state update | `drift-scan.{sh,ps1}`, `update-state.{sh,ps1}` | `.sad/state/sad-state.md` | exit 0 once reconciliation exists; sad-state.md fields update |
| 8 | Eval harness | `evals/run.mjs` | `evals/**/EVAL.ts` | exit 0; structured JSON in --json mode |
| 9 | Reference MCP server | `reference/example-server/server.py` | JSON-RPC stdin/stdout | deterministic response on happy path; correct error codes on each failure mode |
| 10 | Maturity report | `maturity-report.{sh,ps1}` | `.sad/state/maturity-level.json`, surveys, rollback log | thresholds computed correctly across simulated state |
| 11 | Hook JSON validity | `node` / `ConvertFrom-Json` | `hooks/*.json`, `adapters/claude-code/settings*.json` | all parse without error |
| 12 | CI workflow YAML | `python -c yaml.safe_load` | `.github/workflows/*.yml` | all parse without error |
| 13 | Requirements progress (optional) | `sad_update_requirements_progress.py` | mapping markdown, specs | non-zero exit only when mapping is missing |
| 14 | Final doctor sweep | `doctor.{sh,ps1}` | end-to-end repo state | 0 red, ≤ 2 yellow |

---

## Common failure modes and what they mean

| Symptom | Likely cause | Fix |
|---|---|---|
| `sad-init` says `detected assistant: none` | No `.claude/`, `.cursor/`, etc. in target | Pass `--assistant claude-code` (or your tool) explicitly |
| Doctor says `[FAIL] constitution.identity` | Placeholders `[name]` / `[who]` still in file | Edit `.sad/memory/constitution.md` and replace them |
| `check-tier-approvals` says `Tier approval not checked for 'X'` | Checkbox is `- [ ]` not `- [x]`, or label text changed | Match the template exactly: `- [x] X reviewer: <name>, <date>` |
| Eval runner says `experimental-strip-types` not recognized | Node < 22.6 | Upgrade Node or use vitest/jest |
| Reference server returns nothing on stdin | Empty input or process not reading stdin | Echo full JSON line with newline before piping |
| Maturity report says `Satisfaction avg % : no surveys recorded yet` | No files under `.sad/state/satisfaction/<YYYY-MM>/` | Create at least one survey file from the template |
| Hooks fail to fire in Claude Code on Windows | POSIX settings.json was installed instead of Windows variant | Re-run `sad-init.ps1` (PowerShell installer auto-selects the Windows variant); confirm `.claude/settings.json` content references `powershell -File .sad/scripts/*.ps1` |

---

## What this plan does NOT test

- Live LLM-judge graders (the harness's `stub` outcomes are deliberate — wire your own LLM).
- Production-grade `/sad-reconcile` against real codebase diffs (the example here has no drift).
- Hooks actually firing inside Claude Code / Cursor in interactive use (you have to drive an assistant session).
- The website itself (live at <https://sad.codes/>).

For those, see the SAD repo's own `ROADMAP.md` for known gaps and `SAD_USER_GUIDE.md` for production-scale guidance.

---

## Quick smoke test (5 minutes)

If you only have five minutes, run sections **§1.1**, **§1.2**, **§2.1**, **§5**, **§6.5**, **§8**, **§9**, and **§14** in that order. That confirms install, health check, scaffold, tier gate, eval runner, reference server, and final doctor all work.
