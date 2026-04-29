# openclaw-workspace-scanner

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
git clone https://github.com/RedBeret/openclaw-workspace-scanner.git \
  ~/.openclaw/projects/openclaw-workspace-scanner
cd ~/.openclaw/projects/openclaw-workspace-scanner
bash setup.sh
```

## Usage

```bash
bash ~/.openclaw/scan-workspace.sh              # scan ~/.openclaw/
bash ~/.openclaw/scan-workspace.sh ~/projects/  # scan specific directory
```

## Pairs Well With

- **[openclaw-smart-launcher](../openclaw-smart-launcher)** — runs security scan as Phase 5
- **[openclaw-publish-gate](../openclaw-publish-gate)** — repo-specific checks before going public
- **[openclaw-egress-guard](../openclaw-egress-guard)** — real-time blocking at tool call level

## Requirements

- bash, grep, find (standard on macOS/Linux)

## License

MIT
