# hermes-secret-store

OS-native secret management for AI agents. API keys live in your OS keystore — never plaintext in `.env`.

```
┌──────────────────────────────────────────────────────────────────┐
│                        Secret Flow                               │
│                                                                  │
│  ┌────────────┐     source load-secrets.sh     ┌──────────────┐ │
│  │  macOS     │────────────────────────────────▶│              │ │
│  │  Keychain  │     _kc("API_KEY") → value     │  $ENV vars   │ │
│  ├────────────┤                                 │  in memory   │ │
│  │  Linux     │────────────────────────────────▶│  (never on   │ │
│  │  libsecret │     secret-tool lookup → val   │   disk)      │ │
│  ├────────────┤                                 │              │ │
│  │  Linux     │────────────────────────────────▶│              │ │
│  │  pass/GPG  │     pass show → val             └──────────────┘ │
│  └────────────┘                                                  │
│                                                                  │
│  .env file holds ONLY non-secret config (timeouts, image names)  │
└──────────────────────────────────────────────────────────────────┘
```

## Why Not `.env`?

Your `.env` file sits on disk in plaintext. Anyone who accesses your filesystem — a backup, a shared machine, a compromised process — gets every API key. macOS Keychain is backed by the Secure Enclave. Linux `secret-tool` uses the kernel keyring. Both are encrypted at rest.

## Install

```bash
git clone https://github.com/RedBeret/hermes-secret-store.git \
  ~/.hermes/projects/hermes-secret-store
cd ~/.hermes/projects/hermes-secret-store
bash setup.sh
```

## Storing Keys

Use the included helper (prompts securely, no shell history exposure):

```bash
bash store-key.sh ANTHROPIC_API_KEY
bash store-key.sh OPENROUTER_API_KEY
bash store-key.sh TAVILY_API_KEY
```

Or store directly:

```bash
# macOS
security add-generic-password -U -a "$USER" -s "ANTHROPIC_API_KEY" -w "your-key"

# Linux (secret-tool)
secret-tool store --label="Hermes: Anthropic" service hermes key ANTHROPIC_API_KEY <<< "your-key"

# Linux (pass)
pass insert hermes/ANTHROPIC_API_KEY
```

## Loading Keys

Source the loader before running your agent:

```bash
source ~/.hermes/load-secrets.sh
hermes gateway
```

Or add to `~/.zshrc` / `~/.bashrc`:

```bash
[ -f ~/.hermes/load-secrets.sh ] && source ~/.hermes/load-secrets.sh
```

Silent mode (no output, good for scripts):

```bash
HERMES_QUIET_SECRETS=1 source ~/.hermes/load-secrets.sh
```

## What Goes Where

| Location | Contents | Example |
|----------|----------|---------|
| **OS Keystore** (secrets) | API keys, tokens, passwords | `ANTHROPIC_API_KEY`, `HERMES_GATEWAY_TOKEN` |
| **`.env`** (non-secrets) | Timeouts, image names, feature flags | `TERMINAL_TIMEOUT=60`, `BROWSER_SESSION_TIMEOUT=300` |

## Adding Your Own Keys

1. Store it: `bash store-key.sh MY_CUSTOM_KEY`
2. Edit `load-secrets.sh`, add: `_load MY_CUSTOM_KEY`
3. Source again: `source ~/.hermes/load-secrets.sh`

## Requirements

- macOS Keychain (built in) **or** Linux `secret-tool` (`sudo apt install libsecret-tools`) **or** `pass` (`sudo apt install pass`)

## License

MIT
