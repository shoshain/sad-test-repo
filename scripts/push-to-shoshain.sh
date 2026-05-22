#!/usr/bin/env bash
set -euo pipefail

# push-to-shoshain.sh — one-shot: init, commit, push to shoshain/sad-test-repo.
#
# Run from anywhere; the script cds to its own repo root.
#
# Usage:
#   ./scripts/push-to-shoshain.sh                     # use configured credentials
#   ./scripts/push-to-shoshain.sh --token <PAT>       # embed PAT for this push only
#   ./scripts/push-to-shoshain.sh --ssh               # use git@github.com SSH form
#   ./scripts/push-to-shoshain.sh --branch trunk      # push a different branch
#   ./scripts/push-to-shoshain.sh --message "Initial" # custom commit message

TOKEN=""
USE_SSH=0
BRANCH="main"
MESSAGE="Initial commit: sad-test-repo scaffold + testing_sad.md"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --token)   TOKEN="$2"; shift 2 ;;
    --ssh)     USE_SSH=1; shift ;;
    --branch)  BRANCH="$2"; shift 2 ;;
    --message) MESSAGE="$2"; shift 2 ;;
    -h|--help) sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)         echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

REMOTE_HTTPS="https://github.com/shoshain/sad-test-repo.git"
REMOTE_SSH="git@github.com:shoshain/sad-test-repo.git"

say() { echo "[push] $*"; }

if [[ ! -d .git ]]; then
  say "git init -b ${BRANCH}"
  git init -b "${BRANCH}"
else
  say "git init (already initialized; skip)"
fi

say "configure local identity = shoshain"
git config user.name  "shoshain"
git config user.email "shoshain@users.noreply.github.com"

git add -A
if git diff --cached --quiet; then
  say "nothing to commit (working tree clean)"
else
  say "git commit"
  git commit -m "${MESSAGE}"
fi

if ! git remote | grep -qx 'origin'; then
  if [[ "${USE_SSH}" -eq 1 ]]; then
    say "git remote add origin (ssh)"
    git remote add origin "${REMOTE_SSH}"
  else
    say "git remote add origin (https)"
    git remote add origin "${REMOTE_HTTPS}"
  fi
else
  if [[ "${USE_SSH}" -eq 1 ]]; then
    say "git remote set-url origin (ssh)"
    git remote set-url origin "${REMOTE_SSH}"
  else
    say "git remote set-url origin (https)"
    git remote set-url origin "${REMOTE_HTTPS}"
  fi
fi

PUSHED_WITH_TOKEN=0
trap '
  if [[ "${PUSHED_WITH_TOKEN}" -eq 1 ]]; then
    if [[ "${USE_SSH}" -eq 1 ]]; then
      git remote set-url origin "'"${REMOTE_SSH}"'" >/dev/null
    else
      git remote set-url origin "'"${REMOTE_HTTPS}"'" >/dev/null
    fi
    echo "[push] token stripped from saved remote URL"
  fi
' EXIT

if [[ -n "${TOKEN}" ]]; then
  TOKEN_URL="https://shoshain:${TOKEN}@github.com/shoshain/sad-test-repo.git"
  say "git push (with PAT)"
  git remote set-url origin "${TOKEN_URL}"
  PUSHED_WITH_TOKEN=1
  git push -u origin "${BRANCH}"
else
  say "git push (using configured credentials)"
  git push -u origin "${BRANCH}"
fi

say "done. Remote tip:"
git log -1 --format='%h %an <%ae> %s'
