# openclaw-smart-launcher

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
| **4. Agent Updates** | Update openclaw (npm), claude-code, desktop apps | Yes |
| **5. Security** | Scan workspace for leaked API keys, fix .env permissions | No |
| **6. Cleanup** | Remove logs >30 days, temp files >7 days | No |
| **7. Agent Start** | Start gateway via launchd/direct, health check with retry | No |
| **8. Memory** | Decrypt memory files (if openclaw-memory-encrypt installed) | No |
| **9. Antivirus** | ClamAV scan of workspace in background | Yes |

**Heavy maintenance** = brew upgrade, model pulls, agent updates, ClamAV scan. Runs at most once per 7 days (configurable). Light phases run every time.

## Install

```bash
git clone https://github.com/RedBeret/openclaw-smart-launcher.git \
  ~/.openclaw/projects/openclaw-smart-launcher
cd ~/.openclaw/projects/openclaw-smart-launcher
bash setup.sh
```

Setup offers three options:
1. **macOS launchd** — weekly Sunday 4:00 AM auto-maintenance
2. **Linux systemd timer** — weekly Sunday 4:00 AM auto-maintenance
3. **Manual** — run it yourself when needed

## Usage

```bash
# Full launch (maintenance + start)
bash ~/.openclaw/smart-launcher.sh

# Quick daily health check (no updates, just status)
bash ~/.openclaw/daily-check.sh

# Manual trigger of scheduled maintenance (macOS)
launchctl start ai.openclaw.maintenance

# Manual trigger (Linux)
systemctl --user start openclaw-maintenance.service
```

## Configuration

Set these environment variables before running, or edit the script header:

| Variable | Default | Purpose |
|----------|---------|---------|
| `AGENT_NAME` | `openclaw` | Your agent's name (used in logs) |
| `OPENCLAW_HOME` | `~/.openclaw` | Agent home directory |
| `OPENCLAW_CMD` | `openclaw gateway` | Command to start the agent |
| `OPENCLAW_PORT` | (none) | Gateway port for health checks |
| `HEAVY_WINDOW_SECS` | `604800` (7 days) | Interval between heavy maintenance runs |
| `HEALTH_CHECK_URLS` | (none) | Comma-separated `name=url` pairs for service health |

### Example with full config:

```bash
export AGENT_NAME=openclaw
export OPENCLAW_PORT=18789
export HEALTH_CHECK_URLS="ollama=http://127.0.0.1:11434/,firecrawl=http://127.0.0.1:30025/"
bash ~/.openclaw/smart-launcher.sh
```

## Auto-Encrypt on Exit

If you use `openclaw-memory-encrypt`, set `LAUNCHER_WRAP=1` to run the agent in foreground with automatic encrypt-on-exit:

```bash
LAUNCHER_WRAP=1 bash ~/.openclaw/smart-launcher.sh
# Agent runs in foreground. On exit, memories are encrypted automatically.
```

## Adapting for Other Agents

The launcher works with any agent. Set the right variables:

```bash
# OpenClaw
AGENT_NAME=openclaw OPENCLAW_HOME=~/.openclaw OPENCLAW_CMD="openclaw gateway" OPENCLAW_PORT=18789 \
  bash ~/.openclaw/smart-launcher.sh

# Custom agent
AGENT_NAME=myagent OPENCLAW_HOME=~/myagent OPENCLAW_CMD="./start.sh" \
  bash ~/.openclaw/smart-launcher.sh
```

## Pairs Well With

- **[openclaw-memory-encrypt](../openclaw-memory-encrypt)** — decrypt on start, encrypt on exit
- **[openclaw-secret-store](../openclaw-secret-store)** — secrets loaded in Phase 1
- **[openclaw-egress-guard](../openclaw-egress-guard)** — secrets scanned in Phase 5

## Requirements

- bash 4+
- macOS or Linux
- Optional: `brew`, `ollama`, `clamscan`, `pip`, `npm`

## License

MIT
