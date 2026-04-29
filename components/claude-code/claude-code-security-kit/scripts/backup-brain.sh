#!/usr/bin/env bash
# hermes-brain-backup: Create timestamped archive of agent state.
# Includes: config, skills, scripts, hooks, memories (encrypted if available).
# Excludes: .env, credentials, session logs, API keys.
#
# Usage: bash backup-brain.sh [backup_dir]

set -euo pipefail

AGENT_HOME="${CLAUDE_CODE_HOME:-$HOME/.claude}"
BACKUP_DIR="${1:-$AGENT_HOME/backups}"
AGENT_NAME="${AGENT_NAME:-hermes}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="$BACKUP_DIR/${AGENT_NAME}-brain-$TIMESTAMP.tar.gz"
MAX_BACKUPS="${MAX_BACKUPS:-5}"

mkdir -p "$BACKUP_DIR"

echo ""
echo "┌────────────────────────────────────┐"
echo "│   Agent Brain Backup               │"
echo "│   $(date '+%Y-%m-%d %H:%M:%S')            │"
echo "└────────────────────────────────────┘"
echo ""

# Build the list of directories/files to include (only those that exist)
INCLUDE_ARGS=()
for item in \
  "memories" \
  "skills" \
  "agent-hooks" \
  "projects" \
  "config.yaml" \
  "smart-launcher.sh" \
  "daily-check.sh" \
  "encrypt-memories.sh" \
  "decrypt-memories.sh" \
  "load-secrets.sh" \
  "scan-workspace.sh" \
  "publish-gate.sh"
do
  if [ -e "$AGENT_HOME/$item" ]; then
    INCLUDE_ARGS+=("$item")
  fi
done

if [ ${#INCLUDE_ARGS[@]} -eq 0 ]; then
  echo "✗ Nothing to backup in $AGENT_HOME"
  exit 1
fi

# Create archive
tar -czf "$BACKUP_FILE" \
  --exclude='.env' \
  --exclude='*.env' \
  --exclude='credentials' \
  --exclude='auth-profiles.json' \
  --exclude='sessions' \
  --exclude='*.jsonl' \
  --exclude='.git' \
  --exclude='node_modules' \
  --exclude='__pycache__' \
  --exclude='.venv' \
  -C "$AGENT_HOME" \
  "${INCLUDE_ARGS[@]}" \
  2>/dev/null

SIZE=$(du -sh "$BACKUP_FILE" 2>/dev/null | cut -f1 || echo "?")
echo "✓ Backup saved: $BACKUP_FILE ($SIZE)"
echo ""
echo "What's included:"
for item in "${INCLUDE_ARGS[@]}"; do
  echo "  ✓ $item"
done
echo ""
echo "What's excluded (never backup):"
echo "  ✗ .env files (API keys — use OS keystore)"
echo "  ✗ credentials/ (OAuth tokens)"
echo "  ✗ sessions/ (conversation logs)"
echo "  ✗ .git/ node_modules/ __pycache__/"
echo ""

# Rotate: keep only last N backups
BACKUP_COUNT=$(ls -1 "$BACKUP_DIR"/${AGENT_NAME}-brain-*.tar.gz 2>/dev/null | wc -l | tr -d ' ')
if [ "$BACKUP_COUNT" -gt "$MAX_BACKUPS" ]; then
  ls -1t "$BACKUP_DIR"/${AGENT_NAME}-brain-*.tar.gz | tail -n +$((MAX_BACKUPS+1)) | xargs rm -f
  echo "✓ Rotated old backups (keeping last $MAX_BACKUPS)"
fi

echo ""
echo "To restore:"
echo "  tar -xzf $BACKUP_FILE -C $AGENT_HOME"
echo "  Then re-run setup scripts and restore secrets to keystore"
