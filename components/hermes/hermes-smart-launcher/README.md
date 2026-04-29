# hermes-smart-launcher

9-phase maintenance and startup script for AI agent environments. Keeps your agent updated, secure, and healthy — even after weeks of being untouched. Includes scheduled auto-maintenance via launchd (macOS) or systemd (Linux).

```
┌──────────────────────────────────────────────────────────────────┐
│                  The 9 Phases                                    │
│                                                                  │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐           │
│  │ 0.Health│  │ 1.Env   │  │ 2.System│  │ 3.Ollama│           │
│  │  check  │─▶│ secrets │─▶│ updates │─▶│ models  │           │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘           │
│       │                                       │                  │
│       ▼                                       ▼                  │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐           │
│  │ 4.Agent │  │ 5.Secur-│  │ 6.Clean-│  │ 7.Start │           │
│  │ updates │─▶│   ity   │─▶│   up    │─▶│ + health│           │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘           │
│                                               │                  │
│       ┌─────────┐  ┌─────────┐                │                  │
│       │ 8.Memory│  │ 9.ClamAV│◀───────────────┘                 │
│       │ decrypt │  │  (bg)   │                                   │
│       └─────────┘  └─────────┘                                   │
│                                                                  │
│  Heavy maintenance (brew upgrade, model pulls, AV scan)          │
│  runs at most once per 7 days via a stamp file.                  │
└──────────────────────────────────────────────────────────────────┘
```

## Why You Need This

AI agents rely on a stack: Ollama models, brew packages, the agent binary itself, API keys, memory files. If someone doesn't touch their agent for weeks, everything falls behind — outdated models, stale virus definitions, security vulnerabilities. This launcher brings everything current in one run.

## What Each Phase Does

| Phase | What | Heavy Only? |
|-------|------|-------------|
| **0. Health Check** | Stop Docker Desktop if Colima preferred | No |
| **1. Environment** | Load secrets from OS keystore, seed launchd env | No |
| **2. System Updates** | brew update/upgrade, apt upgrade, freshclam, macOS updates | Yes |
| **3. Ollama** | Start if not running, pull latest for all local models | Pull: Yes |
| **4. Agent Updates** | Update hermes (pip), openclaw (npm), claude-code, desktop apps | Yes |
| **5. Security** | Scan workspace for leaked API keys, fix .env permissions | No |
| **6. Cleanup** | Remove logs >30 days, temp files >7 days | No |
| **7. Agent Start** | Start gateway via launchd/direct, health check with retry | No |
| **8. Memory** | Decrypt memory files (if hermes-memory-encrypt installed) | No |
| **9. Antivirus** | ClamAV scan of workspace in background | Yes |

**Heavy maintenance** = brew upgrade, model pulls, agent updates, ClamAV scan. Runs at most once per 7 days (configurable). Light phases run every time.

## Install

```bash
git clone https://github.com/RedBeret/hermes-smart-launcher.git \
  ~/.hermes/projects/hermes-smart-launcher
cd ~/.hermes/projects/hermes-smart-launcher
bash setup.sh
```

Setup offers three options:
1. **macOS launchd** — weekly Sunday 4:00 AM auto-maintenance
2. **Linux systemd timer** — weekly Sunday 4:00 AM auto-maintenance
3. **Manual** — run it yourself when needed

## Usage

```bash
# Full launch (maintenance + start)
bash ~/.hermes/smart-launcher.sh

# Quick daily health check (no updates, just status)
bash ~/.hermes/daily-check.sh

# Manual trigger of scheduled maintenance (macOS)
launchctl start ai.hermes.maintenance

# Manual trigger (Linux)
systemctl --user start hermes-maintenance.service
```

## Configuration

Set these environment variables before running, or edit the script header:

| Variable | Default | Purpose |
|----------|---------|---------|
| `AGENT_NAME` | `hermes` | Your agent's name (used in logs) |
| `HERMES_HOME` | `~/.hermes` | Agent home directory |
| `HERMES_CMD` | `hermes gateway` | Command to start the agent |
| `HERMES_PORT` | (none) | Gateway port for health checks |
| `HEAVY_WINDOW_SECS` | `604800` (7 days) | Interval between heavy maintenance runs |
| `HEALTH_CHECK_URLS` | (none) | Comma-separated `name=url` pairs for service health |

### Example with full config:

```bash
export AGENT_NAME=hermes
export HERMES_PORT=18789
export HEALTH_CHECK_URLS="ollama=http://127.0.0.1:11434/,firecrawl=http://127.0.0.1:30025/"
bash ~/.hermes/smart-launcher.sh
```

## Auto-Encrypt on Exit

If you use `hermes-memory-encrypt`, set `LAUNCHER_WRAP=1` to run the agent in foreground with automatic encrypt-on-exit:

```bash
LAUNCHER_WRAP=1 bash ~/.hermes/smart-launcher.sh
# Agent runs in foreground. On exit, memories are encrypted automatically.
```

## Adapting for Other Agents

The launcher works with any agent. Set the right variables:

```bash
# OpenClaw
AGENT_NAME=openclaw HERMES_HOME=~/.openclaw HERMES_CMD="openclaw gateway" HERMES_PORT=18789 \
  bash ~/.hermes/smart-launcher.sh

# Custom agent
AGENT_NAME=myagent HERMES_HOME=~/myagent HERMES_CMD="./start.sh" \
  bash ~/.hermes/smart-launcher.sh
```

## Pairs Well With

- **[hermes-memory-encrypt](../hermes-memory-encrypt)** — decrypt on start, encrypt on exit
- **[hermes-secret-store](../hermes-secret-store)** — secrets loaded in Phase 1
- **[hermes-egress-guard](../hermes-egress-guard)** — secrets scanned in Phase 5

## Requirements

- bash 4+
- macOS or Linux
- Optional: `brew`, `ollama`, `clamscan`, `pip`, `npm`

## License

MIT
