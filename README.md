# Agent Security Kit

[![Smoke Test](https://github.com/RedBeret/agent-security-kit/actions/workflows/smoke-test.yml/badge.svg)](https://github.com/RedBeret/agent-security-kit/actions/workflows/smoke-test.yml)

Reusable guardrails for AI-assisted coding agents.

Agent Security Kit is a small component library for teams and solo builders who
use coding agents and want practical safety checks around secrets, destructive
commands, publish readiness, local agent memory, and commit hygiene.

It is organized as a kit, not a framework. Pick the pieces that match your
agent runtime, review the setup script for that component, and install only what
you need.

## What It Helps With

- block accidental API key, token, private key, credential, and PII leaks
- stop dangerous terminal commands before they run
- scan a workspace before sharing it or making it public
- run a release gate before publishing a repository
- keep secrets in OS keystores instead of plaintext `.env` files
- encrypt agent memory files at rest
- create sanitized backups of agent state
- block obvious AI-generated commit attribution/tell phrases
- add lightweight self-review and context-safety reminders to agent sessions

## Supported Targets

- Hermes
- OpenClaw
- Claude Code

The Hermes and OpenClaw components are parallel implementations. The Claude Code
kit contains Claude rules, hooks, and utility scripts.

## Quick Start

Clone the repository:

```bash
git clone https://github.com/RedBeret/agent-security-kit.git
cd agent-security-kit
```

Run the public-release check:

```bash
bash scripts/publish-check.sh
```

Install a single component:

```bash
cd components/hermes/hermes-egress-guard
bash setup.sh
```

Each component has its own README and setup script.

## Recommended Starter Set

For most users, start with these:

| Component | Why |
| --- | --- |
| `hermes-egress-guard` / `openclaw-egress-guard` | Blocks secrets and PII before tool output is written. |
| `hermes-safe-terminal` / `openclaw-safe-terminal` | Blocks destructive commands and credential dumps. |
| `hermes-publish-gate` / `openclaw-publish-gate` | Checks a repo before making it public. |
| `hermes-workspace-scanner` / `openclaw-workspace-scanner` | Scans an agent workspace for common security issues. |
| `hermes-secret-store` / `openclaw-secret-store` | Loads API keys from Keychain, libsecret, or `pass`. |
| `hermes-commit-guard` / `openclaw-commit-guard` | Adds commit policy and an optional commit-msg hook. |

## Components

### Hermes

| Component | Purpose |
| --- | --- |
| `components/hermes/hermes-egress-guard` | Blocks tool calls that try to write API keys, private keys, credentials, or PII. |
| `components/hermes/hermes-safe-terminal` | Blocks dangerous terminal commands such as destructive deletes, disk wipes, env dumps, and curl-to-shell. |
| `components/hermes/hermes-publish-gate` | Runs a 12-check public-release gate for secrets, PII, AI attribution, artifacts, licenses, and debug code. |
| `components/hermes/hermes-workspace-scanner` | Scans an agent workspace for leaked secrets, suspicious files, tracked secret files, and hardcoded user paths. |
| `components/hermes/hermes-staging-scan` | Moves inbound files through ClamAV-backed scanned/quarantine directories. |
| `components/hermes/hermes-secret-store` | Loads secrets from OS keystores instead of plaintext `.env` files. |
| `components/hermes/hermes-memory-encrypt` | Encrypts `MEMORY.md` and `USER.md` at rest with HMAC verification. |
| `components/hermes/hermes-brain-backup` | Creates sanitized backups of agent state while excluding credentials and sessions. |
| `components/hermes/hermes-commit-guard` | Injects commit policy and provides an optional commit-msg hook to block AI tell phrases. |
| `components/hermes/hermes-context-guard` | Adds context-handling rules for safer agent behavior. |
| `components/hermes/hermes-self-review` | Injects a final review checklist before delivery. |
| `components/hermes/hermes-hardened-skills` | Skill prompts for common software/security roles. |
| `components/hermes/hermes-smart-launcher` | Optional maintenance launcher for long-lived local agent environments. |

### OpenClaw

OpenClaw equivalents live under `components/openclaw/` with matching names.

### Claude Code

`components/claude-code/claude-code-security-kit` contains Claude Code rules,
hooks, and utility scripts for similar protections.

## Public-Release Safety

Before publishing a fork or derivative:

```bash
bash scripts/publish-check.sh
```

That runs:

- shell syntax checks
- core hook behavior checks
- fake-secret detection checks
- publish gate checks
- workspace scanner checks against this repository

Use `.security-allowlist` only for intentional fixtures or documentation
examples. Allowlist entries are regular expressions matched against scanner
output; keep them file-specific.

Running `components/hermes/hermes-workspace-scanner/scan-workspace.sh` without a
path scans `$HERMES_HOME` or `~/.hermes`. Use `.` when checking this repository.

This repository also has Mend Bolt enabled for dependency vulnerability
reporting.

## Requirements

- Bash
- `jq` for JSON hook payload parsing
- `git` for publish checks
- `openssl` for memory encryption
- Optional: `clamscan`, `pip-audit`, `npm`

## Repository Layout

```text
components/
  hermes/
  openclaw/
  claude-code/
docs/
scripts/
```

## Notes

Agent Security Kit is defensive tooling. It is not a substitute for code review,
secret scanning in CI, least-privilege credentials, or your organization's
security policies. Review every hook before enabling it in a production
workflow.

The local RedBeret profile staging folders, generated review documents, and
experimental private working copies are not part of this public kit.

## License

MIT. See `LICENSE`.
