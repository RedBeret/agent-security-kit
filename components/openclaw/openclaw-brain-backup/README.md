# openclaw-brain-backup

Timestamped backups of your AI agent's brain — config, skills, hooks, memory files, and scripts. Excludes secrets, credentials, and session logs. Keeps last 5 backups with automatic rotation.

```
┌──────────────────────────────────────────────────────────────────┐
│                   What Gets Backed Up                            │
│                                                                  │
│  ✓ INCLUDED                         ✗ EXCLUDED                  │
│  ──────────                         ──────────                  │
│  memories/    (encrypted if avail)  .env         (API keys)     │
│  skills/      (all custom skills)   credentials/ (OAuth)        │
│  agent-hooks/ (security hooks)      sessions/    (chat logs)    │
│  openclaw.json  (agent config)        .git/        (history)      │
│  scripts      (launcher, scanner)   node_modules/               │
│  projects/    (skill repos)         __pycache__/                │
│                                                                  │
│  Output: openclaw-brain-20260425-143022.tar.gz                    │
│  Rotation: keeps last 5, deletes older                          │
└──────────────────────────────────────────────────────────────────┘
```

## Install

```bash
git clone https://github.com/RedBeret/openclaw-brain-backup.git \
  ~/.openclaw/projects/openclaw-brain-backup
cd ~/.openclaw/projects/openclaw-brain-backup
bash setup.sh
```

## Usage

```bash
bash ~/.openclaw/backup-brain.sh                    # default: saves to ~/.openclaw/backups/
bash ~/.openclaw/backup-brain.sh ~/Dropbox/backups  # custom backup location
```

## Restore

```bash
tar -xzf openclaw-brain-20260425-143022.tar.gz -C ~/.openclaw/
# Then re-store your API keys in the OS keystore
# And re-run any setup.sh scripts for hooks
```

## Scheduling (Optional)

Add to your smart-launcher or cron:

```bash
# Daily at 3:00 AM (macOS launchd or crontab)
0 3 * * * /bin/bash ~/.openclaw/backup-brain.sh
```

## Configuration

| Variable | Default | Purpose |
|----------|---------|---------|
| `OPENCLAW_HOME` | `~/.openclaw` | Agent home to backup |
| `AGENT_NAME` | `openclaw` | Prefix for backup filenames |
| `MAX_BACKUPS` | `5` | How many to keep before rotating |

## Requirements

- bash, tar (standard on macOS/Linux)

## License

MIT
