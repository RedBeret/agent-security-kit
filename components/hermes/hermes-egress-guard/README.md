# hermes-egress-guard

Shell hook that prevents AI agents from leaking API keys, private keys, passwords, PII, and connection strings through tool calls. Works as a `pre_tool_call` hook for Hermes Agent.

```
┌──────────────────────────────────────────────────────────────────┐
│                      How It Works                                │
│                                                                  │
│  Agent wants to run      Hook intercepts         Decision        │
│  ┌───────────────┐      ┌──────────────┐      ┌─────────────┐   │
│  │ terminal      │─────▶│ extract cmd  │─────▶│ scan for     │   │
│  │ write_file    │      │ or content   │      │ 20+ secret   │   │
│  │ patch         │      └──────────────┘      │ patterns     │   │
│  └───────────────┘                            └──────┬──────┘   │
│                                                ┌─────┴─────┐    │
│                                           clean│           │hit  │
│                                           ┌────▼──┐  ┌────▼───┐ │
│                                           │  {}   │  │ BLOCK  │ │
│                                           │ allow │  │ + why  │ │
│                                           └───────┘  └────────┘ │
└──────────────────────────────────────────────────────────────────┘
```

## What It Catches

| Category | Patterns | Count |
|----------|----------|-------|
| **AI/ML API keys** | Anthropic, OpenRouter, OpenAI, NVIDIA | 4 |
| **Cloud provider keys** | AWS `AKIA*`, Google `AIza*` | 2 |
| **Platform tokens** | GitHub (`ghp_`, `gho_`, PAT), GitLab (`glpat-`), Slack (`xox*`), Stripe, Twilio, SendGrid | 6 |
| **Cryptographic material** | RSA, EC, DSA, OPENSSH, PGP private keys | 5 |
| **Database credentials** | postgres://, mysql://, mongodb://, redis://, amqp://, mssql:// connection strings | 6 |
| **Hardcoded secrets** | `password=`, `secret=`, `passwd=`, `pwd=` | 4 |
| **PII** | SSN (###-##-####), credit card numbers | 2 |
| **Risky operations** | `git commit/push` with secret refs, `env`/`printenv` dumps | 2 |

**Total: 31 patterns** covering the most common secret leak vectors.

## Install

```bash
git clone https://github.com/RedBeret/hermes-egress-guard.git \
  ~/.hermes/projects/hermes-egress-guard
cd ~/.hermes/projects/hermes-egress-guard
bash setup.sh
```

Then add to `~/.hermes/config.yaml`:

```yaml
hooks:
  pre_tool_call:
    - matcher: "terminal|write_file|patch"
      command: "~/.hermes/agent-hooks/block-secrets.sh"
      timeout: 5
```

## How It Works

1. Hermes is about to execute a `terminal`, `write_file`, or `patch` tool call
2. The hook receives the tool name and input as JSON on stdin
3. It extracts the relevant content (command, file content, or patch diff)
4. It scans against 31 regex patterns covering keys, tokens, PII, and credentials
5. **Match found** → returns `{"decision":"block","reason":"..."}` → agent gets an error
6. **Clean** → returns `{}` → tool executes normally

## Testing

Test the hook manually without touching Hermes:

```bash
# Should block (Anthropic key)
echo '{"tool_name":"write_file","tool_input":{"content":"key = sk-ant-abc123def456ghi789"}}' | \
  bash block-secrets.sh

# Should pass (clean content)
echo '{"tool_name":"write_file","tool_input":{"content":"hello world"}}' | \
  bash block-secrets.sh
```

## Adding Custom Patterns

Edit `block-secrets.sh` to add your own:

```bash
# Block internal API patterns
echo "$content" | grep -qE 'mycompany-api-[a-zA-Z0-9]{20,}' && \
  _block "Internal API key detected."
```

## Pairs Well With

- **[hermes-safe-terminal](../hermes-safe-terminal)** — blocks destructive commands (`rm -rf /`, `DROP TABLE`)
- **[hermes-secret-store](../hermes-secret-store)** — stores the keys properly in OS keystore
- **[hermes-publish-gate](../hermes-publish-gate)** — scans repo history before going public

## Requirements

- Hermes Agent v0.11.0+ (shell hooks)
- `jq`

## License

MIT
