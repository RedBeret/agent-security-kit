# hermes-brain-backup

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
│  config.yaml  (agent config)        .git/        (history)      │
│  scripts      (launcher, scanner)   node_modules/               │
│  projects/    (skill repos)         __pycache__/                │
│                                                                  │
│  Output: hermes-brain-20260425-143022.tar.gz                    │
│  Rotation: keeps last 5, deletes older                          │
└──────────────────────────────────────────────────────────────────┘
```

## Install

```bash
git clone https://github.com/RedBeret/hermes-brain-backup.git \
  ~/.hermes/projects/hermes-brain-backup
cd ~/.hermes/projects/hermes-brain-backup
bash setup.sh
```

## Usage

```bash
bash ~/.hermes/backup-brain.sh                    # default: saves to ~/.hermes/backups/
bash ~/.hermes/backup-brain.sh ~/Dropbox/backups  # custom backup location
```

## Restore

```bash
tar -xzf hermes-brain-20260425-143022.tar.gz -C ~/.hermes/
# Then re-store your API keys in the OS keystore
# And re-run any setup.sh scripts for hooks
```

## Scheduling (Optional)

Add to your smart-launcher or cron:

```bash
# Daily at 3:00 AM (macOS launchd or crontab)
0 3 * * * /bin/bash ~/.hermes/backup-brain.sh
```

## Configuration

| Variable | Default | Purpose |
|----------|---------|---------|
| `HERMES_HOME` | `~/.hermes` | Agent home to backup |
| `AGENT_NAME` | `hermes` | Prefix for backup filenames |
| `MAX_BACKUPS` | `5` | How many to keep before rotating |

## Requirements

- bash, tar (standard on macOS/Linux)

## License

MIT
