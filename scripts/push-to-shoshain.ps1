#requires -Version 5.1
<#
.SYNOPSIS
  One-shot: init this repo, commit, and push to shoshain/sad-test-repo as shoshain.

.DESCRIPTION
  Runs from the test repo root. Configures local user.name/user.email to shoshain
  for this repo only (does not touch your global git config). Pushes via HTTPS;
  the actual auth uses whatever credential helper your machine has configured for
  github.com. If you're signed in as a different account globally, use one of:

    1. gh auth switch     (GitHub CLI; preferred)
    2. -Token <PAT>       (pass a personal-access token at the prompt)
    3. -SshRemote         (swap to git@github.com SSH form if your shoshain key is loaded)

.PARAMETER Token
  Optional GitHub personal-access token. Embedded in the remote URL for this push
  only (HTTP basic auth: user=shoshain, password=<token>). The token is NOT saved
  to disk; the remote URL is rewritten back to the tokenless HTTPS form after push.

.PARAMETER SshRemote
  Use git@github.com:shoshain/sad-test-repo.git instead of HTTPS. Requires your
  shoshain SSH key to be loaded in the local agent.

.EXAMPLE
  .\scripts\push-to-shoshain.ps1

.EXAMPLE
  .\scripts\push-to-shoshain.ps1 -Token ghp_xxxxxxxxxxxxxxxxxxxx

.EXAMPLE
  .\scripts\push-to-shoshain.ps1 -SshRemote
#>
[CmdletBinding()]
param(
    [string]$Token,
    [switch]$SshRemote,
    [string]$Branch = 'main',
    [string]$CommitMessage = 'Initial commit: sad-test-repo scaffold + testing_sad.md'
)

$ErrorActionPreference = 'Stop'

# Work from this script's parent directory (= repo root) regardless of cwd.
$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $repoRoot

function Run([string]$Label, [scriptblock]$Block) {
    Write-Output "[push] $Label"
    & $Block
    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
        throw "step '$Label' exited $LASTEXITCODE"
    }
}

# --- 1. init (idempotent) ---
if (-not (Test-Path (Join-Path $repoRoot '.git'))) {
    Run 'git init' { git init -b $Branch }
} else {
    Run 'git init (already initialized; skip)' { Write-Output '   .git exists' }
}

# --- 2. set local identity ---
Run 'configure local identity = shoshain' {
    git config user.name  'shoshain'
    git config user.email 'shoshain@users.noreply.github.com'
}

# --- 3. stage + commit (only if there is anything to commit) ---
git add -A
$staged = git diff --cached --name-only
if ($null -ne $staged -and $staged.Length -gt 0) {
    Run 'git commit' { git commit -m $CommitMessage }
} else {
    Write-Output "[push] nothing to commit (working tree clean)"
}

# --- 4. wire the remote ---
$remoteHttps = 'https://github.com/shoshain/sad-test-repo.git'
$remoteSsh   = 'git@github.com:shoshain/sad-test-repo.git'

$existing = git remote
if ($existing -notcontains 'origin') {
    if ($SshRemote) {
        Run 'git remote add origin (ssh)'   { git remote add origin $remoteSsh }
    } else {
        Run 'git remote add origin (https)' { git remote add origin $remoteHttps }
    }
} else {
    if ($SshRemote) {
        Run 'git remote set-url origin (ssh)'   { git remote set-url origin $remoteSsh }
    } else {
        Run 'git remote set-url origin (https)' { git remote set-url origin $remoteHttps }
    }
}

# --- 5. push, optionally embedding a token for this push only ---
$pushedWithToken = $false
try {
    if ($Token) {
        $tokenUrl = "https://shoshain:$Token@github.com/shoshain/sad-test-repo.git"
        Run 'git push (with PAT)' { git remote set-url origin $tokenUrl; git push -u origin $Branch }
        $pushedWithToken = $true
    } else {
        Run 'git push (using configured credentials)' { git push -u origin $Branch }
    }
}
finally {
    if ($pushedWithToken) {
        # Strip the token from the saved remote URL.
        if ($SshRemote) {
            git remote set-url origin $remoteSsh   | Out-Null
        } else {
            git remote set-url origin $remoteHttps | Out-Null
        }
        Write-Output "[push] token stripped from saved remote URL"
    }
}

Write-Output "[push] done. Remote tip:"
git log -1 --format='%h %an <%ae> %s'
