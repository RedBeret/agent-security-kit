#!/usr/bin/env bash
# ============================================================
# OpenClaw Smart Launcher
# Full maintenance + startup for AI agent environments.
# Safe to run after weeks/months of being offline.
#
# 9-phase lifecycle:
#   0. Health check          5. Security scan
#   1. Environment/secrets   6. Log cleanup
#   2. System updates        7. Agent start + health
#   3. Ollama models         8. Memory decrypt
#   4. Agent updates         9. AV scan (background)
#
# Heavy maintenance (brew upgrade, model pulls, docker pulls,
# ClamAV scans) runs at most once per week via a stamp file.
# ============================================================

set -euo pipefail

# ── Configuration ─────────────────────────────────────────────
AGENT_NAME="${AGENT_NAME:-openclaw}"
AGENT_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
AGENT_CMD="${OPENCLAW_CMD:-openclaw gateway}"
AGENT_PORT="${OPENCLAW_PORT:-}"
AGENT_VENV="${OPENCLAW_VENV:-$AGENT_HOME/venv}"
LOG_DIR="$AGENT_HOME/logs"
STATE_DIR="$AGENT_HOME/state"
WEEKLY_STAMP="$STATE_DIR/launcher-heavy-maintenance.stamp"
HEAVY_WINDOW_SECS="${HEAVY_WINDOW_SECS:-604800}"   # 7 days

mkdir -p "$LOG_DIR" "$STATE_DIR"
LOG="$LOG_DIR/launcher-$(date +%Y-%m-%d).log"

# ── Activate virtual environment ─────────────────────────────
if [ -f "$AGENT_VENV/bin/activate" ]; then
  source "$AGENT_VENV/bin/activate"
fi

# ── Colors ────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'
BLUE='\033[0;34m'; NC='\033[0m'

log() { echo -e "$1" | tee -a "$LOG"; }

should_run_heavy() {
  [ ! -f "$WEEKLY_STAMP" ] && return 0
  local last now
  if [ "$(uname -s)" = "Darwin" ]; then
    last=$(stat -f %m "$WEEKLY_STAMP" 2>/dev/null || echo 0)
  else
    last=$(stat -c %Y "$WEEKLY_STAMP" 2>/dev/null || echo 0)
  fi
  now=$(date +%s)
  [ $((now - last)) -ge "$HEAVY_WINDOW_SECS" ]
}

mark_heavy() { touch "$WEEKLY_STAMP"; }

HEAVY=0
if should_run_heavy; then HEAVY=1; fi

log ""
log "${GREEN}═══════════════════════════════════════${NC}"
log "${GREEN}  Smart Launcher — $AGENT_NAME${NC}"
log "${GREEN}  $(date '+%Y-%m-%d %H:%M:%S')${NC}"
log "${GREEN}═══════════════════════════════════════${NC}"
[ "$HEAVY" -eq 1 ] && log "${BLUE}  heavy maintenance window: enabled${NC}" \
                    || log "${BLUE}  heavy maintenance: skipped (ran within $(( HEAVY_WINDOW_SECS / 86400 )) days)${NC}"

# ── Phase 0: Health Check ─────────────────────────────────────
log ""
log "${BLUE}[0/9] Health Check${NC}"

# On macOS, stop Docker Desktop if Colima is preferred
if [ "$(uname -s)" = "Darwin" ] && pgrep -f "Docker Desktop" &>/dev/null && command -v colima &>/dev/null; then
  log "  stopping Docker Desktop (Colima preferred)..."
  osascript -e 'quit app "Docker"' 2>/dev/null || true
  sleep 2
  pkill -f "Docker Desktop" 2>/dev/null || true
  log "  ${GREEN}ok${NC} Docker Desktop stopped"
fi
log "  ${GREEN}ok${NC} health check done"

# ── Phase 1: Environment / Secrets ────────────────────────────
log ""
log "${BLUE}[1/9] Environment${NC}"

# macOS: seed launchd env from Keychain
if [ "$(uname -s)" = "Darwin" ] && [ -x "$AGENT_HOME/seed-launchd-env.sh" ]; then
  "$AGENT_HOME/seed-launchd-env.sh" 2>/dev/null && \
    log "  ${GREEN}ok${NC} launchd env seeded from Keychain" || \
    log "  ${YELLOW}--${NC} seed-launchd-env.sh failed"
fi

# Source secrets loader
if [ -f "$AGENT_HOME/load-secrets.sh" ]; then
  OPENCLAW_QUIET_SECRETS=1 source "$AGENT_HOME/load-secrets.sh" 2>/dev/null || true
  log "  ${GREEN}ok${NC} secrets loaded from keystore"
elif [ -f "$AGENT_HOME/.env" ]; then
  set -a; source "$AGENT_HOME/.env"; set +a
  log "  ${YELLOW}--${NC} loaded .env (consider migrating to openclaw-secret-store)"
else
  log "  ${YELLOW}--${NC} no secrets loader or .env found"
fi

# ── Phase 2: System Updates ───────────────────────────────────
log ""
log "${BLUE}[2/9] System Updates${NC}"

_os="$(uname -s)"

if [ "$HEAVY" -eq 1 ]; then
  # Homebrew (macOS/Linux)
  if command -v brew &>/dev/null; then
    log "  updating homebrew..."
    brew update 2>&1 | tail -1 | tee -a "$LOG"
    OUTDATED=$(brew outdated --quiet 2>/dev/null || true)
    if [ -n "$OUTDATED" ]; then
      log "  upgrading: $OUTDATED"
      brew upgrade 2>&1 | tail -3 | tee -a "$LOG"
    fi
    brew cleanup -s 2>/dev/null || true
    log "  ${GREEN}ok${NC} homebrew updated"
  fi

  # APT (Debian/Ubuntu)
  if command -v apt-get &>/dev/null && [ "$_os" = "Linux" ]; then
    log "  updating apt packages..."
    sudo apt-get update -qq 2>/dev/null && \
    sudo apt-get upgrade -y -qq 2>/dev/null && \
      log "  ${GREEN}ok${NC} apt packages updated" || \
      log "  ${YELLOW}--${NC} apt update failed (may need sudo)"
  fi

  # ClamAV definitions
  if command -v freshclam &>/dev/null; then
    log "  updating virus definitions..."
    freshclam --quiet 2>/dev/null && \
      log "  ${GREEN}ok${NC} virus definitions updated" || \
      log "  ${YELLOW}--${NC} freshclam failed"
  fi

  # macOS system updates (report only, don't force)
  if [ "$_os" = "Darwin" ]; then
    SWUPDATE=$(softwareupdate -l 2>&1 || true)
    if echo "$SWUPDATE" | grep -q "No new software available"; then
      log "  ${GREEN}ok${NC} macOS up to date"
    else
      log "  ${YELLOW}--${NC} macOS updates available (manual install recommended)"
    fi
  fi
else
  log "  ${GREEN}ok${NC} skipping system updates (not in heavy maintenance window)"
fi

# ── Phase 3: Ollama Model Refresh ─────────────────────────────
log ""
log "${BLUE}[3/9] Ollama${NC}"

if command -v ollama &>/dev/null; then
  # Start if not responding
  if curl -sf --max-time 2 http://127.0.0.1:11434/ >/dev/null 2>&1; then
    log "  ${GREEN}ok${NC} ollama already running on :11434"
  else
    log "  starting ollama..."
    if [ "$_os" = "Darwin" ]; then
      brew services start ollama 2>/dev/null || ollama serve &>/dev/null &
    else
      ollama serve &>/dev/null &
    fi
    sleep 3
    log "  ${GREEN}ok${NC} ollama started"
  fi

  # Update models during heavy maintenance
  if [ "$HEAVY" -eq 1 ]; then
    LOCAL_MODELS=$(ollama list 2>/dev/null | tail -n +2 | awk '{print $1}' || true)
    if [ -n "$LOCAL_MODELS" ]; then
      log "  refreshing local models..."
      for model in $LOCAL_MODELS; do
        log "    pulling $model..."
        ollama pull "$model" 2>&1 | grep -E "pulling|success|up to date" | tail -1 | tee -a "$LOG" || true
      done
      log "  ${GREEN}ok${NC} models refreshed"
    fi
  else
    log "  ${GREEN}ok${NC} skipping model refresh"
  fi
else
  log "  ${YELLOW}--${NC} ollama not installed"
fi

# ── Phase 4: Agent Updates ────────────────────────────────────
log ""
log "${BLUE}[4/9] Agent Updates${NC}"

if [ "$HEAVY" -eq 1 ]; then
  # OpenClaw (npm-based)
  if command -v openclaw &>/dev/null; then
    CUR_VER=$(openclaw --version 2>/dev/null | head -1 || echo "unknown")
    log "  openclaw: $CUR_VER"
    npm update -g openclaw 2>/dev/null && \
      log "  ${GREEN}ok${NC} openclaw updated" || \
      log "  ${YELLOW}--${NC} openclaw update failed"
  fi

  # Claude Code CLI
  if command -v claude &>/dev/null; then
    CUR_VER=$(claude --version 2>/dev/null | head -1 || echo "unknown")
    log "  claude-code: $CUR_VER"
    claude update 2>/dev/null && \
      log "  ${GREEN}ok${NC} claude-code updated" || \
      log "  ${YELLOW}--${NC} claude-code update skipped"
  fi

  # Desktop app auto-update (macOS Sparkle)
  if [ "$_os" = "Darwin" ]; then
    for app_id in "com.anthropic.claudefordesktop" "com.openai.codex"; do
      if defaults read "$app_id" 2>/dev/null | grep -q "." 2>/dev/null; then
        defaults write "$app_id" SUAutomaticallyUpdate -bool true 2>/dev/null
        defaults write "$app_id" SUEnableAutomaticChecks -bool true 2>/dev/null
      fi
    done
    log "  ${GREEN}ok${NC} desktop app auto-update enabled"
  fi
else
  log "  ${GREEN}ok${NC} skipping agent updates"
fi

# ── Phase 5: Security Scan ────────────────────────────────────
log ""
log "${BLUE}[5/9] Security${NC}"

# Scan workspace for leaked secrets
SCAN_DIRS=("$AGENT_HOME")
SECRETS_FOUND=0

for dir in "${SCAN_DIRS[@]}"; do
  [ ! -d "$dir" ] && continue
  HITS=$(grep -rlE '(sk-ant-[a-zA-Z0-9_-]{20,}|nvapi-[a-zA-Z0-9_-]{20,}|AKIA[0-9A-Z]{16}|ghp_[a-zA-Z0-9]{36})' \
    --include="*.py" --include="*.js" --include="*.sh" --include="*.yaml" --include="*.json" \
    "$dir" 2>/dev/null | grep -v "SKILL.md\|block-secrets.sh\|README.md\|\.git/" || true)
  if [ -n "$HITS" ]; then
    log "  ${RED}!! SECRETS DETECTED:${NC}"
    echo "$HITS" | while read -r f; do log "    $f"; done
    SECRETS_FOUND=1
  fi
done

if [ "$SECRETS_FOUND" -eq 0 ]; then
  log "  ${GREEN}ok${NC} no leaked secrets found"
fi

# Check .env permissions
if [ -f "$AGENT_HOME/.env" ]; then
  if [ "$_os" = "Darwin" ]; then
    PERMS=$(stat -f "%Lp" "$AGENT_HOME/.env" 2>/dev/null || echo "unknown")
  else
    PERMS=$(stat -c "%a" "$AGENT_HOME/.env" 2>/dev/null || echo "unknown")
  fi
  if [ "$PERMS" != "600" ] && [ "$PERMS" != "unknown" ]; then
    chmod 600 "$AGENT_HOME/.env"
    log "  ${YELLOW}→${NC} fixed .env permissions ($PERMS → 600)"
  else
    log "  ${GREEN}ok${NC} .env permissions: $PERMS"
  fi
fi

# ── Phase 6: Cleanup ─────────────────────────────────────────
log ""
log "${BLUE}[6/9] Cleanup${NC}"

# Remove old logs (>30 days)
OLD_LOGS=$(find "$LOG_DIR" -name "*.log" -mtime +30 2>/dev/null | wc -l | tr -d ' ')
if [ "$OLD_LOGS" -gt 0 ]; then
  find "$LOG_DIR" -name "*.log" -mtime +30 -delete 2>/dev/null || true
  log "  ${GREEN}ok${NC} removed $OLD_LOGS old log files"
else
  log "  ${GREEN}ok${NC} no old logs to clean"
fi

# Remove temp files
find /tmp -maxdepth 1 -name "${AGENT_NAME}-*" -mtime +7 -delete 2>/dev/null || true
log "  ${GREEN}ok${NC} temp files cleaned"

# ── Phase 7: Agent Start + Health ─────────────────────────────
log ""
log "${BLUE}[7/9] Agent Start${NC}"

# Check if agent has a gateway port to health-check
if [ -n "$AGENT_PORT" ]; then
  if curl -sf --max-time 3 "http://127.0.0.1:$AGENT_PORT/" >/dev/null 2>&1; then
    log "  ${GREEN}ok${NC} $AGENT_NAME already healthy on :$AGENT_PORT"
  else
    log "  starting $AGENT_NAME..."
    if [ "$_os" = "Darwin" ] && launchctl list 2>/dev/null | grep -q "ai.${AGENT_NAME}"; then
      launchctl kickstart "gui/$(id -u)/ai.${AGENT_NAME}.gateway" 2>/dev/null || \
      launchctl start "ai.${AGENT_NAME}.gateway" 2>/dev/null || true
    else
      eval "$AGENT_CMD" &>/dev/null &
    fi

    # Wait for health
    for i in $(seq 1 15); do
      if curl -sf --max-time 2 "http://127.0.0.1:$AGENT_PORT/" >/dev/null 2>&1; then
        log "  ${GREEN}ok${NC} $AGENT_NAME responding on :$AGENT_PORT"
        break
      fi
      sleep 2
    done
  fi
else
  log "  ${GREEN}ok${NC} no gateway port configured — start $AGENT_NAME manually"
  log "    run: $AGENT_CMD"
fi

# Service health checks (if configured)
if [ -n "${HEALTH_CHECK_URLS:-}" ]; then
  log ""
  log "${BLUE}[7b] Service Health${NC}"
  IFS=',' read -ra URLS <<< "$HEALTH_CHECK_URLS"
  for entry in "${URLS[@]}"; do
    name="${entry%%=*}"
    url="${entry#*=}"
    code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 4 "$url" 2>/dev/null || echo "000")
    if [ "$code" = "200" ]; then
      log "  ${GREEN}ok${NC} $name"
    else
      log "  ${YELLOW}--${NC} $name ($code)"
    fi
  done
fi

# ── Phase 8: Memory Decrypt ───────────────────────────────────
log ""
log "${BLUE}[8/9] Memory${NC}"

if [ -x "$AGENT_HOME/decrypt-memories.sh" ]; then
  bash "$AGENT_HOME/decrypt-memories.sh" 2>&1 | tee -a "$LOG"
else
  log "  ${GREEN}ok${NC} no memory encryption configured"
fi

# Check memory file size
if [ -f "$AGENT_HOME/memories/MEMORY.md" ]; then
  MEM_SIZE=$(wc -c < "$AGENT_HOME/memories/MEMORY.md" | tr -d ' ')
  if [ "$MEM_SIZE" -gt 5000 ]; then
    log "  ${YELLOW}→${NC} MEMORY.md is ${MEM_SIZE} chars (consider pruning, target <5000)"
  else
    log "  ${GREEN}ok${NC} MEMORY.md: ${MEM_SIZE} chars"
  fi
fi

# ── Phase 9: AV Scan (Background) ────────────────────────────
log ""
log "${BLUE}[9/9] Antivirus${NC}"

if command -v clamscan &>/dev/null && [ "$HEAVY" -eq 1 ]; then
  CLAM_LOG="$LOG_DIR/clamscan-$(date +%Y-%m-%d).log"
  log "  starting ClamAV scan in background..."
  (
    clamscan -r --infected \
      --exclude-dir=".git" \
      --exclude-dir="node_modules" \
      --exclude-dir=".venv" \
      --exclude-dir="__pycache__" \
      "$AGENT_HOME/" \
      > "$CLAM_LOG" 2>&1

    INFECTED=$(grep "Infected files:" "$CLAM_LOG" 2>/dev/null | awk '{print $NF}' || echo "0")
    if [ "$INFECTED" != "0" ] && [ -n "$INFECTED" ]; then
      # macOS notification
      osascript -e "display notification \"ClamAV: $INFECTED infected file(s)\" with title \"$AGENT_NAME Launcher\"" 2>/dev/null || true
    fi
  ) &
  log "  ${GREEN}ok${NC} scan running in background (PID $!)"
elif command -v clamscan &>/dev/null; then
  log "  ${GREEN}ok${NC} skipping ClamAV scan (not heavy maintenance)"
else
  log "  ${YELLOW}--${NC} clamav not installed (optional: brew install clamav)"
fi

# ── Finalize ──────────────────────────────────────────────────
[ "$HEAVY" -eq 1 ] && mark_heavy

log ""
log "${GREEN}═══════════════════════════════════════${NC}"
log "${GREEN}  Launcher complete — $AGENT_NAME ready${NC}"
log "${GREEN}  Log: $LOG${NC}"
log "${GREEN}═══════════════════════════════════════${NC}"
log ""

# ── Encrypt on exit (always runs — even on Ctrl+C or crash) ──
_cleanup() {
  local exit_code=$?
  if [ -x "$AGENT_HOME/encrypt-memories.sh" ]; then
    echo "Re-encrypting memories on exit..."
    bash "$AGENT_HOME/encrypt-memories.sh" || true
  fi
  exit $exit_code
}
trap _cleanup EXIT INT TERM HUP

# If the script is used as a wrapper (agent runs in foreground)
if [ "${LAUNCHER_WRAP:-0}" = "1" ]; then
  eval "$AGENT_CMD"
fi
