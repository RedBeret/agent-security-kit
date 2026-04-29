# hermes-workspace-scanner

7-check security scanner for AI agent workspaces. Finds leaked secrets, suspicious files, PII in memory, tracked credentials, bad permissions, and hardcoded paths.

```
┌──────────────────────────────────────────────────────────────────┐
│                    The 7 Scans                                   │
│                                                                  │
│  [1] Leaked secrets      API keys, tokens in source files       │
│  [2] Suspicious execs    .exe, .scr, .bat, .dll, .msi           │
│  [3] Double extensions   report.pdf.exe (social engineering)     │
│  [4] PII in memory       SSN, passport, credit card in .md      │
│  [5] Git tracked secrets .env, .key, .pem committed             │
│  [6] File permissions    World-readable .env or .key files       │
│  [7] Hardcoded paths     /Users/someone/ in scripts             │
│                                                                  │
│  Result: ✓ Clean | ⚠ Warnings | ✗ Critical issues              │
└──────────────────────────────────────────────────────────────────┘
```

## Install

```bash
git clone https://github.com/RedBeret/hermes-workspace-scanner.git \
  ~/.hermes/projects/hermes-workspace-scanner
cd ~/.hermes/projects/hermes-workspace-scanner
bash setup.sh
```

## Usage

```bash
bash ~/.hermes/scan-workspace.sh              # scan ~/.hermes/
bash ~/.hermes/scan-workspace.sh ~/projects/  # scan specific directory
```

## Pairs Well With

- **[hermes-smart-launcher](../hermes-smart-launcher)** — runs security scan as Phase 5
- **[hermes-publish-gate](../hermes-publish-gate)** — repo-specific checks before going public
- **[hermes-egress-guard](../hermes-egress-guard)** — real-time blocking at tool call level

## Requirements

- bash, grep, find (standard on macOS/Linux)

## License

MIT
