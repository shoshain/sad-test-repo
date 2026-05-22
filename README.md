# sad-test-repo

> Throwaway consuming project used to test the [SAD methodology kit](https://github.com/shoshain/sad).
>
> Read [`testing_sad.md`](testing_sad.md) for the full end-to-end test plan. Every command in that file runs against **this** repo as the target.

## First-time push to `shoshain/sad-test-repo`

```powershell
# Windows PowerShell
.\scripts\push-to-shoshain.ps1
# if your global git is signed in as a different account, pass a PAT for this push only:
.\scripts\push-to-shoshain.ps1 -Token ghp_xxxxxxxxxxxxxxxxxxxx
```

```bash
# POSIX
./scripts/push-to-shoshain.sh
# with a PAT:
./scripts/push-to-shoshain.sh --token ghp_xxxxxxxxxxxxxxxxxxxx
```

Both scripts: `git init -b main`, pin local identity to `shoshain`, commit, wire the remote at `https://github.com/shoshain/sad-test-repo.git`, and push. A PAT (if supplied) is embedded in the remote URL **only for the push** and stripped immediately after.

## What this repo contains

A deliberately tiny "real" project — one source file, one test, one README — so the SAD lifecycle has something concrete to act on without the noise of a large codebase.

```
sad-test-repo/
├── README.md              ← you are here
├── testing_sad.md         ← test plan (run these commands top-to-bottom)
├── .gitignore
├── package.json           ← Node project metadata
├── scripts/
│   ├── push-to-shoshain.sh    ← one-shot init + commit + push (POSIX)
│   └── push-to-shoshain.ps1   ← same, for Windows PowerShell
└── src/
    ├── greeting.js        ← the toy feature SAD will spec, plan, build, reconcile
    └── greeting.test.js   ← node --test cases (happy + boundaries + failures)
```

## What it does NOT contain

- No `.sad/`, no `specs/`, no `agents/`, no `commands/`, no `hooks/`. SAD installs those.
- No CI workflow specific to this repo. SAD ships its own under `.github/workflows/` on install.

## Run order

1. Clone SAD into a sibling directory: `git clone https://github.com/shoshain/sad.git ../sad`
2. Run the installer from this repo's parent: `../sad/scripts/sad-init.sh --persistent .` (or the PowerShell equivalent)
3. Open [`testing_sad.md`](testing_sad.md) and follow it section by section.

That's it. The test plan does the rest.
