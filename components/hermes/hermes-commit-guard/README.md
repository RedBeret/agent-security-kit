# hermes-commit-guard

Context injection hook + skill for enforcing commit hygiene every turn. Secret scanning, PII prevention, PR splitting, and git identity rules — injected into the LLM context so the agent never forgets them.

```
┌──────────────────────────────────────────────────────────────────┐
│                   Two-Layer Enforcement                          │
│                                                                  │
│  Layer 1: pre_llm_call Hook (EVERY turn)                        │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ "[Commit Policy] Never include API keys, tokens, or PII   │  │
│  │  in code or commits. Use OS keystore. All repos private    │  │
│  │  by default. No AI attribution. Run publish-gate first."   │  │
│  └────────────────────────────────────────────────────────────┘  │
│                          ▼                                       │
│  Layer 2: SKILL.md (loaded for git tasks)                       │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ Pre-commit checks · Blocked patterns · Commit style        │  │
│  │ Branch workflow · PR splitting · Publish-gate checklist     │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
│  Hook = "always remember"     Skill = "here's exactly how"      │
└──────────────────────────────────────────────────────────────────┘
```

## Why Two Layers?

Skills tell the agent what to do — but they're guidance, not enforcement. In long sessions, the agent can forget them. The `pre_llm_call` hook injects the commit policy into every turn as fresh context, ensuring the rules never drift out of the attention window.

## Install

```bash
git clone https://github.com/RedBeret/hermes-commit-guard.git \
  ~/.hermes/projects/hermes-commit-guard
cd ~/.hermes/projects/hermes-commit-guard
bash setup.sh
```

Add to `~/.hermes/config.yaml`:

```yaml
hooks:
  pre_llm_call:
    - command: "~/.hermes/agent-hooks/inject-commit-policy.sh"
      timeout: 3
```

Optional per-repo commit-message hook:

```bash
cp ~/.hermes/agent-hooks/block-ai-attribution.sh .git/hooks/commit-msg
```

That hook blocks obvious AI attribution/tell phrases such as generated-by
footers, AI co-author lines, and "as an AI language model" text before they
enter git history.

## What Gets Enforced

### Blocked Content in Commits

| Pattern | Risk |
|---------|------|
| API keys (`sk-ant-*`, `nvapi-*`, `AKIA*`, `ghp_*`) | Credential leak |
| Passwords in code (`password = "..."`) | Account compromise |
| Private keys (`-----BEGIN RSA PRIVATE KEY-----`) | Full system access |
| Connection strings (`postgres://user:pass@host`) | Database exposure |
| PII (SSN, phone numbers) | Privacy violation |
| Debug credentials (`admin/admin`) | Default cred exposure |

### Commit Style

- Lowercase, imperative mood, under 50 chars
- No AI attribution (`Co-Authored-By: Claude`)
- Optional commit-msg hook blocks generated-by/co-authored-by AI tell phrases
- Git identity uses configured username, never real names

### PR Splitting Convention

1. Scaffolding and dependencies
2. Core data models
3. Main feature
4. Tests
5. Error handling
6. Docs and README

## Pairs Well With

- **[hermes-publish-gate](../hermes-publish-gate)** — runs all 12 checks before going public
- **[hermes-egress-guard](../hermes-egress-guard)** — blocks secrets at the tool level
- **[hermes-self-review](../hermes-self-review)** — code quality review before delivery

## Requirements

- Hermes Agent v0.11.0+

## License

MIT
