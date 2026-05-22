# Testing SAD end-to-end (PowerShell)

> Concrete, copy-pasteable plan for exercising every advertised piece of the [SAD methodology kit](https://github.com/shoshain/sad) against this throwaway consuming project. Every section is independent; you can run sections out of order, but the lifecycle sections (§5–§10) chain.
>
> **Local layout:** methodology kit at **`C:\SAD`**, test target at **`C:\SAD-testing-repo`** (this file).
>
> **Shell:** Windows PowerShell 5.1+ or PowerShell 7+. All commands below are PowerShell — no Git Bash required.

## Two directories (do not mix them up)

| Path | Purpose |
|------|---------|
| **`C:\SAD`** | SAD methodology kit — `sad-init.ps1`, scripts, templates, evals |
| **`C:\SAD-testing-repo`** | Throwaway consuming project — **run all test commands here** |

## Session bootstrap (paste at the start of every new window)

```powershell
$SAD = "C:\SAD"
$REPO = "C:\SAD-testing-repo"
Set-Location $REPO
```

## Conventions used in this doc

- **Copy only the lines inside code blocks** — do not type `PS>` or prompt prefixes.
- Use **`;`** to chain commands on one line (not `&&`).
- Use **backslash paths** (`.\sad\scripts\doctor.ps1`) or **`Join-Path`** — not `/c/...` Git Bash paths.
- After `.ps1` / `node` / `python` / `git` commands, print the exit code on its **own line**:
  `Write-Output $LASTEXITCODE` — do **not** use `Write-Output $LASTEXITCODE` (some PSReadLine setups throw *illegal characters in path* when pasting that string).
- "the SAD kit" means **`C:\SAD`** (upstream: [shoshain/sad](https://github.com/shoshain/sad)).
- "this repo" means **`C:\SAD-testing-repo`** (upstream: [shoshain/sad-test-repo](https://github.com/shoshain/sad-test-repo)).

---

## 0. One-time setup

Confirm both local folders exist and are git checkouts:

```powershell
$SAD = "C:\SAD"
$REPO = "C:\SAD-testing-repo"
Test-Path $SAD, $REPO
# expect: True True

Set-Location $REPO
git status
Get-ChildItem $SAD\scripts\sad-init.ps1, $REPO\testing_sad.md
```

**Only if a folder is missing** — clone to these exact paths (siblings on `C:\`):

```powershell
git clone https://github.com/shoshain/sad.git C:\SAD
git clone https://github.com/shoshain/sad-test-repo.git C:\SAD-testing-repo
```

After §0, run **`Set-Location $REPO`** before every section unless a block already does so.

**Prereqs**

| Tool | Version | Why |
|---|---|---|
| `git` | any | clone + commit |
| `node` | ≥ 22.6 | eval harness uses `--experimental-strip-types`; toy project tests |
| `python` | ≥ 3.10 | reference MCP server skeleton; optional YAML check in §12 |
| PowerShell | 5.1+ or 7+ | run all SAD `.ps1` scripts |

---

## 0.5 Smoke-test the toy project (before SAD install)

This repo ships a minimal feature (`src/greeting.js`) with unit tests. Run them **before** installing SAD to confirm Node and the workspace are healthy.

```powershell
Set-Location $REPO
node --version          # must be >= 22.6
npm test                # runs: node --test src/greeting.test.js
# expect: all tests pass (happy path, boundaries, rejections)
```

Quick CLI smoke (no test runner):

```powershell
Set-Location $REPO
node src/greeting.js Sam
# expect: Hello, Sam.
node src/greeting.js ""
# expect: error message on stderr; exit code 1
```

**Pass condition.** `npm test` exits 0 with no failures (`$LASTEXITCODE -eq 0`).

---

## 1. Install SAD into this repo

The website promises: one command, five adapters auto-detected, optional `-Persistent` wiring, `-DryRun` and `-Minimal` flags.

### 1.1 Preview the install (no writes)

```powershell
Set-Location $REPO
& "$SAD\scripts\sad-init.ps1" -TargetDir $REPO -DryRun
# expect: [sad-init] DRY: ... for every file the installer would write; no actual mutation
git status
# expect: clean working tree
```

**Pass condition.** Output ends with `done. target: ...` and `git status` is **clean**.

### 1.2 Real install — full footprint, persistent

```powershell
Set-Location $REPO
& "$SAD\scripts\sad-init.ps1" -TargetDir $REPO -Persistent
```

**Pass conditions:**

- The installer prints `detected assistant: <name>` (or `none` on a bare repo).
- `.sad/`, `commands/`, `agents/`, `hooks/`, `evals/`, `examples/`, `reference/` all appear in this repo.
- `LIFECYCLE.md`, `CHEATSHEET.md`, `QUICKSTART.md`, `MATURITY.md`, `ROLES.md`, `MANIFESTO.md`, `NOVEL.md`, `GLOSSARY.md`, `DAEMON.md`, `ATTRIBUTION.md`, `SAD_USER_GUIDE.md` all land at this repo's root.
- `AGENTS.md` is written at the root with the declared-precedence block.
- If the adapter detected was `claude-code`, `.claude/settings.json` exists (Windows variant on Windows), `.claude/skills/sad/SKILL.md` exists, and `.claude/commands/sad-*.md` contains 21 pointer files.
- The installer ends by running `/sad-doctor` and prints its report.

### 1.3 Minimal install (alternative path — wipe and redo)

If you want to also test `-Minimal`, reset this repo first (§15), then:

```powershell
Set-Location $REPO
& "$SAD\scripts\sad-init.ps1" -TargetDir $REPO -Minimal
# expect: .sad/, methodology core docs, adapter, but NO commands/, agents/, hooks/, evals/, examples/
```

### 1.4 Verify cross-platform script parity

```powershell
Set-Location $REPO
Get-ChildItem .sad\scripts\ | Sort-Object Name | Format-Table Name
# expect both .sh and .ps1 for each of:
#   check-tier-approvals, create-feature, doctor, drift-scan, update-state, maturity-report
```

---

## 2. Run /sad-doctor (health check)

Website claim: 30-second health check, green/yellow/red, read-only, `-Json` and `-Quiet` flags.

### 2.1 Default (text)

```powershell
Set-Location $REPO
.\.sad\scripts\doctor.ps1
Write-Output $LASTEXITCODE
```

**Pass condition.** Output begins with `/sad-doctor — N green, N yellow, N red` and lists every check. Exit code 0 if no red findings; 1 if any. On a freshly-installed empty repo expect a couple of yellows (no features yet, stakeholders still have `[List people` placeholders) — that is normal.

### 2.2 JSON mode

```powershell
Set-Location $REPO
.\.sad\scripts\doctor.ps1 -Json | Out-File doctor.json -Encoding utf8
Get-Content doctor.json -TotalCount 20
# or validate structure:
.\.sad\scripts\doctor.ps1 -Json | ConvertFrom-Json | Select-Object -ExpandProperty summary
```

**Pass condition.** Output is valid JSON.

### 2.3 Quiet mode (CI use)

```powershell
Set-Location $REPO
.\.sad\scripts\doctor.ps1 -Quiet
Write-Output $LASTEXITCODE
# expect: no stdout; then Write-Output prints 0 or 1
```

---

## 3. Bootstrap the constitution

Website claim: `/sad-constitution --template <name>` skips the interactive starter selection; six starters available.

### 3.1 Pick a starter and copy it

This repo is a tiny library-style example; use the library starter:

```powershell
Set-Location $REPO
Copy-Item .sad\templates\constitutions\library.md .sad\memory\constitution.md -Force
```

### 3.2 Fill the placeholders

Open `.sad\memory\constitution.md` in your editor. Replace `[name]`, `[who]`, etc. For this test repo, use:

- **Project name:** `SAD-testing-repo`
- **Primary users:** `engineers testing SAD`
- **Risk class:** `low`
- **Maturity level (initial):** `Level 0` (solo SAD)

Resolve each tension at the bottom with one sentence; for this test feature just write "n/a — test repo".

### 3.3 Re-run /sad-doctor — constitution checks should turn green

```powershell
Set-Location $REPO
.\.sad\scripts\doctor.ps1 | Select-String '^\[OK\].*constitution'
# expect: [OK] constitution.identity, [OK] constitution.maturity
# (constitution.articles may stay yellow until you add A1..A3)
```

---

## 4. Fill the stakeholder tier files

```powershell
Set-Location $REPO
Get-ChildItem .sad\stakeholders\
# expect: non-technical.md  semi-technical.md  technical.md
```

Open each and replace `[List people, roles, ...]` with at least one name (use your own name across all three for this test — Solo SAD assumes that).

Re-run doctor:

```powershell
.\.sad\scripts\doctor.ps1 | Select-String stakeholders
# expect three [OK] rows
```

---

## 5. Scaffold a feature with `create-feature`

Website claim: `create-feature.ps1` scaffolds the full per-feature artifact set under `specs/<NNN>-<slug>/`.

```powershell
Set-Location $REPO
.\.sad\scripts\create-feature.ps1 001 personal-greeting
# expect: Scaffolded C:\SAD-testing-repo\specs\001-personal-greeting
```

**Pass condition.** `Get-ChildItem specs\001-personal-greeting\` shows:

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

Open `specs\001-personal-greeting\requirements.draft.md` and replace placeholders with:

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

Open `specs\001-personal-greeting\feature.spec.md`. Replace the template's `<feature name>` and add:

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

In `feature.plan.md`, in `data-model.md`, and in `contracts\example.md`, replace `<feature name>` and the example greeting fields with the same shape but referencing this repo's `src/greeting.js`.

### 6.4 Author the three walkthroughs (step 8, `/sad-walkthrough`)

Open each of:

- `walkthroughs\non-technical.md` — plain English, no code.
- `walkthroughs\semi-technical.md` — contracts table.
- `walkthroughs\technical.md` — reviewer rollup.

For each, replace `<name>, <date>` in the Approval line with your name and today's date, and tick the checkbox: `- [x]`.

Example:

```markdown
- [x] Non-technical reviewer: Jane Tester, 2026-05-22
```

### 6.5 Verify the tier-routed gate

This is the load-bearing test. The check-tier-approvals script must report all three approved.

```powershell
Set-Location $REPO
.\.sad\scripts\check-tier-approvals.ps1 specs\001-personal-greeting
Write-Output $LASTEXITCODE
# expect: 0
```

**Negative test (optional but recommended):**

1. Open `specs\001-personal-greeting\walkthroughs\non-technical.md`
2. Change `- [x]` to `- [ ]` on the Approval line; save.
3. Re-run the command above — `Write-Output $LASTEXITCODE` should print **`2`** and stderr names `Non-technical`.
4. Change back to `- [x]`; save; re-run — expect **`0`**.

### 6.6 Run /sad-doctor — feature should now have all artifacts

```powershell
Set-Location $REPO
.\.sad\scripts\doctor.ps1 | Select-String feature.001
# expect: [OK] feature.001-personal-greeting.artifacts -- has all required artifacts
```

---

## 7. Run the analysis + drift-scan

### 7.1 Drift scan

`drift-scan.ps1` checks that every folder under `specs/` has a `reconciliation.md` file. It does not parse file contents.

**Before** `reconciliation.md` exists (or if you delete it to test):

```powershell
Set-Location $REPO
.\.sad\scripts\drift-scan.ps1
Write-Output $LASTEXITCODE
# expect: 2 and MISSING_RECONCILIATION ... if the file is absent
```

After you fill `specs\001-personal-greeting\reconciliation.md` with a **coherent** verdict (replace stub placeholders; state that spec, plan, and `src/greeting.js` align):

```powershell
.\.sad\scripts\drift-scan.ps1
Write-Output $LASTEXITCODE
# expect: 0 (no output when all features have reconciliation.md)
```

### 7.2 Update the SAD state file

```powershell
Set-Location $REPO
.\.sad\scripts\update-state.ps1 -Feature 001-personal-greeting
.\.sad\scripts\update-state.ps1 -Phase walkthrough
.\.sad\scripts\update-state.ps1 -LastCommand /sad-walkthrough
Get-Content .sad\state\sad-state.md
# expect: Slug / Phase / Last command lines reflect the values above
```

---

## 8. Run the eval harness

Website claim: Node 22+ runner, no third-party dependencies, deterministic+LLM-judge+SME-calibrator graders, exit 0 if all pass.

### 8.0 Wire eval cases to your feature (one-time, after §6)

Stock kit evals ship with stub `PROMPT.md` files. After you fill `specs/001-personal-greeting/`, point each deterministic case at your artifacts via `ground-truth.json` → `input_path` (repo-relative). The harness loads that file instead of `PROMPT.md` when grading.

**Already wired in this test repo** (for reference):

| Case | `input_path` | Extra fields |
|------|----------------|--------------|
| `spec-conformance/case-001` | `specs/001-personal-greeting/feature.spec.md` | — |
| `stakeholder/semi-technical/case-001-contract-coverage` | `specs/001-personal-greeting/walkthroughs/semi-technical.md` | `changed_contracts` |
| `stakeholder/technical/case-001-reviewer-table` | `specs/001-personal-greeting/walkthroughs/technical.md` | `required_headers` |

`impl-correctness` and `stakeholder/non-technical` remain **stubs** (LLM-judge / hidden tests) — they do not fail the run.

If you reset the repo (§15) or scaffold a new feature slug, update `input_path` and contract/header lists to match.

### 8.1 Run the harness

```powershell
Set-Location $REPO\evals
npm run eval
# or directly:
node --experimental-strip-types run.mjs
Write-Output $LASTEXITCODE
Set-Location $REPO
```

**Pass conditions (after §8.0 wiring):**

- Output begins with `/sad-eval-harness — N pass · N fail · N error · N stub · N skip`.
- Deterministic cases: **3 pass** (`spec-conformance`, semi-technical contract coverage, technical reviewer table).
- Stub cases: **2 stub** (`impl-correctness`, non-technical LLM-judge) — stubs do **not** fail the run.
- **`Write-Output $LASTEXITCODE` prints `0`** (exit 1 only when any **fail** or **error**).

Before §8.0 wiring, expect **1 fail + 2 error + exit 1** — that is normal on a fresh install.

### 8.2 JSON mode

```powershell
Set-Location $REPO\evals
node --experimental-strip-types run.mjs --json | python -m json.tool
# expect: { "summary": {...}, "cases": [...] }
Set-Location $REPO
```

### 8.3 Verbose mode (per-case detail)

```powershell
Set-Location $REPO\evals
node --experimental-strip-types run.mjs --verbose
Set-Location $REPO
# expect: [OK] on three deterministic cases; [STUB] on two placeholder graders
```

---

## 9. Run the reference MCP server (legacy-context pattern)

Website claim: optional reference application; zero-deps; deterministic responses.

Happy path:

```powershell
Set-Location $REPO
'{"jsonrpc":"2.0","id":1,"method":"greet","params":{"name":"Sam"}}' | python reference/example-server/server.py
# expect: {"jsonrpc": "2.0", "id": 1, "result": {"greeting": "Hello, Sam."}}
```

Failure case (empty name):

```powershell
'{"jsonrpc":"2.0","id":2,"method":"greet","params":{"name":""}}' | python reference/example-server/server.py
# expect: "error": { "code": -32602, ... } with a length-validation message
```

Unknown method:

```powershell
'{"jsonrpc":"2.0","id":3,"method":"farewell","params":{}}' | python reference/example-server/server.py
# expect: error.code -32601 (unknown method)
```

Parse error:

```powershell
'not json' | python reference/example-server/server.py
# expect: error.code -32700 (parse error)
```

---

## 10. Run the maturity-readiness card

Website claim: `.sad\scripts\maturity-report.ps1` reads the level state + rollback log + survey files and emits a readiness card.

### 10.1 Default (text)

```powershell
Set-Location $REPO
.\.sad\scripts\maturity-report.ps1
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

### 10.2 JSON mode

```powershell
.\.sad\scripts\maturity-report.ps1 -Json
# expect: structured JSON with current_level, features_*, rollback_*, satisfaction_*
```

### 10.3 Simulate a stakeholder survey

```powershell
Set-Location $REPO
New-Item -ItemType Directory -Force -Path .sad\state\satisfaction\2026-05 | Out-Null
Copy-Item .sad\templates\stakeholder-satisfaction-survey.md .sad\state\satisfaction\2026-05\non-technical.md
```

Open the new file, set `Period: 2026-05`, fill the five Likert scores (4, 5, 4, 5, 5 → total 23 / 25 → 92%), and write a Satisfaction line: `**Satisfaction %:** 92`.

Re-run:

```powershell
.\.sad\scripts\maturity-report.ps1
# expect:
# Satisfaction avg %    : 92% (threshold >= 80) -> yes
```

### 10.4 Simulate a rollback

```powershell
Copy-Item .sad\templates\rollback-log.md .sad\state\rollback-log.md -Force
```

Add a real data row to the table — for example:

```markdown
| 2026-05-21 | `001-personal-greeting` | sev-3 | empty-string accepted | semi-technical | enforce min length 1 |
```

Re-run:

```powershell
.\.sad\scripts\maturity-report.ps1
# expect:
# Rollbacks since level : 1
# Rollback rate         : 1.000 (threshold <= 0.05) -> no
```

---

## 11. Verify all hook descriptors are valid JSON

Hook descriptors are installed into **this repo**; adapter settings templates live in the **SAD kit** (they are copied into `.claude/` or `.cursor/` only when an adapter is detected — your install reported `assistant: none`, so there is no `adapters\` folder here).

### 11.1 Hooks (consuming repo)

```powershell
Set-Location $REPO
Get-ChildItem hooks -Filter *.json | ForEach-Object {
  try {
    Get-Content $_.FullName -Raw | ConvertFrom-Json | Out-Null
    "ok  $($_.Name)"
  } catch {
    "FAIL  $($_.Name)  $_"
  }
}
# expect: 5 "ok  ..." lines, no errors
```

### 11.2 Adapter settings (SAD kit source templates)

Validate the Claude Code settings JSON shipped with the methodology kit:

```powershell
Get-ChildItem "$SAD\adapters\claude-code\settings*.json" | ForEach-Object {
  try {
    Get-Content $_.FullName -Raw | ConvertFrom-Json | Out-Null
    "ok  $($_.Name)"
  } catch {
    "FAIL  $($_.Name)  $_"
  }
}
# expect: 4 "ok" lines (settings.json, settings.persistent.json, settings.windows.json, settings.windows.persistent.json)
```

**Optional** — if you re-ran `sad-init` with `-Assistant claude-code`, also validate what landed in the consuming repo:

```powershell
if (Test-Path .claude\settings.json) {
  Get-Content .claude\settings.json -Raw | ConvertFrom-Json | Out-Null
  "ok  .claude\settings.json"
} else {
  "skip  .claude\settings.json (adapter not installed in this repo)"
}
```

---

## 12. CI workflows (GitHub Actions)

Four example workflows ship in the **SAD kit** at `$SAD\.github\workflows\`. `sad-init` does **not** copy them into the consuming repo — they are templates you add when you push to GitHub. For this test run, validate YAML in the kit; optionally copy into `$REPO` if you want CI on the test repo.

### 12.1 Validate workflow YAML (SAD kit)

```powershell
Get-ChildItem "$SAD\.github\workflows\*.yml" | ForEach-Object {
  python -c "import yaml, sys; yaml.safe_load(open(sys.argv[1]))" $_.FullName
  if ($LASTEXITCODE -eq 0) { "ok  $($_.Name)" } else { "FAIL  $($_.Name)" }
}
# expect: ok lines for sad-doctor.yml, sad-evals.yml, sad-spec-drift-scan.yml, sad-maturity-report.yml
```

If `yaml` isn't installed: `pip install pyyaml` first.

### 12.2 Optional — install workflows into the test repo

```powershell
Set-Location $REPO
New-Item -ItemType Directory -Force -Path .github\workflows | Out-Null
Copy-Item "$SAD\.github\workflows\*.yml" .github\workflows\
Get-ChildItem .github\workflows\*.yml | ForEach-Object {
  python -c "import yaml, sys; yaml.safe_load(open(sys.argv[1]))" $_.FullName
  if ($LASTEXITCODE -eq 0) { "ok  $($_.Name)" } else { "FAIL  $($_.Name)" }
}
```

Or skip local validation and rely on GitHub Actions after you push to a branch.

---

## 13. Exercise the requirements-progress script (optional, REQ-traceability projects only)

```powershell
# Skip unless you maintain a REQ-DOC mapping.
python "$SAD\scripts\sad_update_requirements_progress.py" --help
# expect: usage text listing --mapping, --specs-dir, --output-md, etc.
```

---

## 14. /sad-doctor — final green run

After §3, §4, §5, §6, §7 are all green:

```powershell
Set-Location $REPO
.\.sad\scripts\doctor.ps1
Write-Output $LASTEXITCODE
```

**Final pass condition.** Output:

- `0 red`
- `≤ 2 yellow` (acceptable: `constitution.articles` if you didn't add A1..A3).
- The feature you created appears as `[OK] feature.001-personal-greeting.artifacts`.
- Exit code 0.

---

## 15. Cleanup

To repeat the test from a clean slate, you can either:

```powershell
Set-Location $REPO

# Local reset (keep installed kit; throw out the test feature)
Remove-Item -Recurse -Force specs\001-personal-greeting -ErrorAction SilentlyContinue
Remove-Item -Force .sad\state\rollback-log.md -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force .sad\state\satisfaction -ErrorAction SilentlyContinue

# Or full reset (re-install the SAD kit from scratch)
git clean -fdx
git checkout .
& "$SAD\scripts\sad-init.ps1" -TargetDir $REPO -Persistent
```

---

## Test matrix at a glance

| # | What is tested | Script(s) exercised | Files inspected | Pass signal |
|---|---|---|---|---|
| 1 | Install (dry-run + real + minimal) | `sad-init.ps1` | `.sad/`, `commands/`, `agents/`, `hooks/`, `evals/`, `reference/`, root docs, adapter files | doctor green section, all listed dirs present |
| 2 | Doctor health-check (text / JSON / quiet) | `doctor.ps1` | reports stdout, JSON | exit 0 on a clean install |
| 3 | Constitution bootstrap with `--template` | manual copy + edit | `.sad/memory/constitution.md` | doctor's `constitution.identity` and `constitution.maturity` go green |
| 4 | Stakeholder tier files | n/a | `.sad/stakeholders/*.md` | doctor three green stakeholder rows |
| 5 | Per-feature scaffold | `create-feature.ps1` | `specs/001-personal-greeting/` | 12 templates + 4 subdirs present |
| 6 | Tier-routed approval gate | `check-tier-approvals.ps1` | three walkthrough files | exit 0 when all three checked; exit 2 when any unchecked |
| 7 | Drift scan + state update | `drift-scan.ps1`, `update-state.ps1` | `.sad/state/sad-state.md` | exit 0 once reconciliation exists; sad-state.md fields update |
| 8 | Eval harness | `evals/run.mjs` | `evals/**/EVAL.ts` | exit 0; structured JSON in `--json` mode |
| 9 | Reference MCP server | `reference/example-server/server.py` | JSON-RPC stdin/stdout | deterministic response on happy path; correct error codes on each failure mode |
| 10 | Maturity report | `maturity-report.ps1` | `.sad/state/maturity-level.json`, surveys, rollback log | thresholds computed correctly across simulated state |
| 11 | Hook JSON validity | `ConvertFrom-Json` | `hooks/*.json` (repo); `$SAD/adapters/claude-code/settings*.json` (kit) | all parse without error |
| 12 | CI workflow YAML | `python -c yaml.safe_load` | `$SAD/.github/workflows/*.yml` (kit templates) | all parse without error |
| 13 | Requirements progress (optional) | `sad_update_requirements_progress.py` | mapping markdown, specs | non-zero exit only when mapping is missing |
| 14 | Final doctor sweep | `doctor.ps1` | end-to-end repo state | 0 red, ≤ 2 yellow |

---

## Common failure modes and what they mean

| Symptom | Likely cause | Fix |
|---|---|---|
| `Cannot find path '...\sad-init.ps1'` | `$SAD` not set, or kit not at `C:\SAD` | Paste the session bootstrap lines; confirm `(Test-Path C:\SAD)` is `True` |
| `The token '&&' is not a valid statement separator` | Bash syntax pasted into PowerShell | Use `;` between commands; use this doc's PowerShell blocks only |
| PSReadLine: *Niedozwolone znaki w ścieżce* / *illegal characters in path* when checking exit code | Pasting `"exit=$LASTEXITCODE"` triggers a broken custom key handler | Use `Write-Output $LASTEXITCODE` on its own line instead |
| `Cannot find path 'C:\c\SAD-testing-repo'` | Git Bash path `/c/...` used in PowerShell | Use `C:\SAD-testing-repo` or `Set-Location $REPO` |
| `sad-init` says `detected assistant: none` | No `.claude/`, `.cursor/`, etc. in target | Pass `-Assistant claude-code` (or your tool) explicitly to `sad-init.ps1` |
| Doctor says `[FAIL] constitution.identity` | Placeholders `[name]` / `[who]` still in file | Edit `.sad\memory\constitution.md` and replace them |
| `check-tier-approvals` says `Tier approval not checked for 'X'` | Checkbox is `- [ ]` not `- [x]`, or label text changed | Match the template exactly: `- [x] X reviewer: <name>, <date>` |
| Eval runner says `experimental-strip-types` not recognized | Node < 22.6 | Upgrade Node |
| Reference server returns nothing on stdin | Empty input or process not reading stdin | Pipe a full JSON line with quotes as shown in §9 |
| Maturity report says `Satisfaction avg % : no surveys recorded yet` | No files under `.sad\state\satisfaction\<YYYY-MM>\` | Create at least one survey file from the template (§10.3) |
| Eval harness exits 1 with 1 fail + 2 error on fresh install | Eval `PROMPT.md` stubs not wired to `specs/` artifacts | Complete §8.0 (`ground-truth.json` → `input_path`); re-run — expect 3 pass · 2 stub · exit 0 |
| `Cannot find path '...\adapters\claude-code'` | Adapter templates are in **`C:\SAD`**, not copied to repo when `detected assistant: none` | Use §11.2: `"$SAD\adapters\claude-code\settings*.json"`; or re-run `sad-init.ps1 -Assistant claude-code` |
| `Cannot find path '...\.github\workflows'` | CI workflow templates are in **`C:\SAD\.github\workflows`**, not installed by `sad-init` | Use §12.1: `"$SAD\.github\workflows\*.yml"`; or copy with §12.2 |

---

## What this plan does NOT test

- Live LLM-judge graders (the harness's `stub` outcomes are deliberate — wire your own LLM).
- Production-grade `/sad-reconcile` against real codebase diffs (the example here has no drift).
- Hooks actually firing inside Claude Code / Cursor in interactive use (you have to drive an assistant session).
- The website itself (live at <https://sad.codes/>).

For those, see the SAD repo's own `ROADMAP.md` for known gaps and `SAD_USER_GUIDE.md` for production-scale guidance.

---

## Quick smoke test (5 minutes)

Paste the session bootstrap lines, then run sections **§0**, **§1.1**, **§1.2**, **§2.1**, **§5**, **§6.5**, **§8.0**, **§8.1**, **§9**, and **§14** in that order. That confirms install, health check, scaffold, tier gate, eval wiring + runner, reference server, and final doctor all work.
