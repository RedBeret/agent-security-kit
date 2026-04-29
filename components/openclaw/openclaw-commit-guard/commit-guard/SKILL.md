---
name: commit-guard
description: Git commit hygiene enforcer — secret scanning, PII prevention, publish-gate, identity rules, and PR conventions. Use this skill whenever the user works with git, commits, pushes, PRs, or prepares a repo for release. Triggers on mentions of git, commit, push, pull request, PR, merge, branch, publish, release, deploy, or version control.
---

# Commit Guard Skill

You enforce strict commit hygiene. Every commit, push, and PR must pass security checks before execution.

## Pre-Commit Checks (MANDATORY)

Before every `git add`, `git commit`, or `git push`:

```bash
# 1. Review staged changes
git diff --staged

# 2. Scan for leaked credentials
git diff --staged | grep -iE "(nvapi-|sk-ant-|sk-or-|AKIA|password\s*=|api_key\s*=|token\s*=)" && echo "BLOCKED: Secret detected" && exit 1

# 3. Scan for PII patterns
git diff --staged | grep -iE "(\d{3}-\d{2}-\d{4}|\d{9}|SSN)" && echo "BLOCKED: PII detected"

# 4. Verify .env is gitignored
grep -q "\.env" .gitignore || echo "WARNING: .env not in .gitignore"
```

## Blocked Patterns

| Pattern | Example | Risk |
|---------|---------|------|
| API keys | `nvapi-`, `sk-ant-`, `sk-or-v1-`, `AKIA` | Credential leak |
| Passwords in code | `password = "..."` | Account compromise |
| Private keys | `-----BEGIN RSA PRIVATE KEY-----` | Full system compromise |
| Connection strings | `postgres://user:pass@host/db` | Database access |
| PII | SSN, phone numbers, real addresses | Privacy violation |
| Debug credentials | `admin/admin`, `test/test123` | Default cred exposure |

## Commit Style

- Lowercase, imperative mood, under 50 chars
- No AI attribution — no `Co-Authored-By: Claude` or similar
- No em dashes

```
Good: fix race condition in session handler
Good: add vpc endpoint for s3 access
Bad:  This commit implements the new authentication flow
Bad:  Update code
```

## Branch Workflow

Never commit directly to main. Every change goes through a branch + PR:

```bash
git checkout -b feat/descriptive-name
# ... make changes ...
git add . && git commit -m "add user auth endpoint"
git push -u origin feat/descriptive-name
```

## PR Splitting Convention

Break work into focused, reviewable PRs:
- PR 1: scaffolding and dependencies
- PR 2: core data models and migrations
- PR 3: main feature implementation
- PR 4: tests (unit + integration)
- PR 5: error handling and edge cases
- PR 6: docs and README updates

## Publish-Gate (Before Going Public)

All repos start PRIVATE. Before making any repo public, verify ALL of these:

1. Secret scan on entire git history: `git log -p | grep -iE "(sk-ant-|nvapi-|AKIA|password\s*=)"`
2. Check git author/committer for PII: `git log --format='%an %ae' | sort -u`
3. README is complete and useful
4. `pip-audit` / `npm audit` clean — no known CVEs
5. LICENSE file present
6. No `__pycache__`, `node_modules`, `.env`, or `.terraform` tracked
7. No hardcoded IPs, hostnames, or internal URLs

## Egress Protection

- NEVER include passwords, API keys, tokens in cloud API calls
- Before sending file contents to a cloud model, strip PII and credentials
- Default is private. Only share content explicitly marked for release.
- Block shell commands that dump env: `env`, `printenv`, `set`, `export -p`
