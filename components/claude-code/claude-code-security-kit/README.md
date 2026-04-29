# claude-code-security-kit

Security rules, hooks, deny lists, and utility scripts for Claude Code workspaces. Drop into any project to harden your Claude Code agent against secret leaks, bad commits, and unsafe commands.

```
┌──────────────────────────────────────────────────────────────────┐
│                  What's Included                                 │
│                                                                  │
│  .claude/settings.json                                          │
│  ├── deny rules (block .env reads, env dumps, rm -rf)           │
│  └── hooks (PreToolUse secret scanning)                         │
│                                                                  │
│  .claude/rules/                                                  │
│  ├── commit-guard.md    (commit hygiene, PR splitting)           │
│  ├── self-review.md     (code review before delivery)           │
│  ├── context-guard.md   (context management)                    │
│  ├── egress-guard.md    (never leak secrets)                    │
│  └── publish-gate.md    (12-check pre-publish gate)             │
│                                                                  │
│  scripts/                                                        │
│  ├── scan-workspace.sh  (7-check security scan)                 │
│  ├── publish-gate.sh    (automated 12-check gate)               │
│  ├── backup-brain.sh    (workspace state backup)                │
│  └── staging-scan.sh    (ClamAV file scanning)                  │
│                                                                  │
│  CLAUDE.md              (project-level instructions)             │
└──────────────────────────────────────────────────────────────────┘
```

## How Claude Code Security Differs

Claude Code has its own security model:

| Feature | Hermes/OpenClaw | Claude Code |
|---------|----------------|-------------|
| Config | config.yaml / openclaw.json | .claude/settings.json |
| Skills | SKILL.md files | .claude/rules/*.md |
| Hooks | pre_tool_call shell hooks | PreToolUse / PostToolUse hooks |
| Deny rules | Not built-in | First-class: deny specific tool+path combos |
| Scope | Global (~/.hermes/) | Per-project or global (~/.claude/) |

Claude Code's **deny rules** are more powerful than hooks — they make files invisible to the agent entirely, which is stronger than blocking after access.

## Install

```bash
git clone https://github.com/RedBeret/claude-code-security-kit.git
cd claude-code-security-kit
bash setup.sh
```

Choose between project-local or global installation.

## What Each Rule Does

### commit-guard.md
Pre-commit scanning, commit style (lowercase imperative), PR splitting convention, blocked content patterns.

### self-review.md
6-step code review before delivery: run it, test bad input, scan for secrets, verify imports, run tests, match style.

### context-guard.md
Context health monitoring, compaction triggers, memory checkpointing, session load order.

### egress-guard.md
Never-leak list covering API keys, private keys, connection strings, passwords, PII. Safe alternatives using OS keystore.

### publish-gate.md
12-check gate: 5 critical (secrets, PII, keys, .env), 4 high (authors, AI attribution, README, LICENSE), 3 advisory (artifacts, CVEs, debug code).

## Deny Rules

The included `settings.json` blocks:

```
.env files           — secrets never readable
credentials/         — OAuth tokens hidden
env/printenv/export  — no environment dumps
curl | sh            — no remote code execution
rm -rf / or ~        — no filesystem destruction
chmod 777            — no world-writable files
dd to block devices  — no disk wipes
```

## Requirements

- Claude Code CLI
- Optional: `jq` (for hooks), `clamscan` (for staging-scan)

## License

MIT
