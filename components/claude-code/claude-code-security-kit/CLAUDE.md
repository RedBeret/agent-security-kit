# Security Kit for Claude Code

This workspace includes security rules, hooks, and scripts hardened for safe agent operation.

## Rules

Rules in `.claude/rules/` are automatically loaded. They cover:
- **commit-guard.md** — commit hygiene, secret scanning, PII prevention
- **self-review.md** — code review checklist before delivering
- **context-guard.md** — context management for long sessions
- **egress-guard.md** — never leak secrets through code or commands
- **publish-gate.md** — 12-check quality gate before going public

## Scripts

Run security scripts directly:
- `bash scripts/scan-workspace.sh` — 7-check workspace security scan
- `bash scripts/publish-gate.sh .` — pre-publish quality gate
- `bash scripts/backup-brain.sh` — backup workspace state
- `bash scripts/staging-scan.sh` — ClamAV scan inbound files

## Key Rules

- Never include API keys, tokens, or passwords in code or commits
- All secrets belong in OS keystore (macOS Keychain / Linux secret-tool)
- All repos are private by default — run publish-gate before going public
- No AI attribution in commits (no Co-Authored-By: Claude)
- Review your own code before delivering: run it, test edge cases, verify imports
