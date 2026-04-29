#!/usr/bin/env bash
# openclaw-smart-launcher: Daily health check
# Lightweight check suitable for running every session start.
# Reports issues, doesn't fix them (except .env permissions).

set -euo pipefail

AGENT_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
_os="$(uname -s)"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ISSUES=0

echo ""
echo "Daily Health Check — $(date '+%Y-%m-%d %H:%M')"
echo "════════════════════════════════════════════════"

# 1. Agent running?
if [ -n "${OPENCLAW_PORT:-}" ]; then
  if curl -s --max-time 2 "http://127.0.0.1:$OPENCLAW_PORT/" >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Agent gateway running on :$OPENCLAW_PORT"
  else
    echo -e "${YELLOW}→${NC} Agent gateway not responding"
    ISSUES=$((ISSUES+1))
  fi
fi

# 2. .env permissions
if [ -f "$AGENT_HOME/.env" ]; then
  if [ "$_os" = "Darwin" ]; then
    PERMS=$(stat -f "%Lp" "$AGENT_HOME/.env" 2>/dev/null || echo "?")
  else
    PERMS=$(stat -c "%a" "$AGENT_HOME/.env" 2>/dev/null || echo "?")
  fi
  if [ "$PERMS" = "600" ]; then
    echo -e "${GREEN}✓${NC} .env permissions: 600"
  else
    chmod 600 "$AGENT_HOME/.env" 2>/dev/null
    echo -e "${YELLOW}→${NC} Fixed .env permissions ($PERMS → 600)"
    ISSUES=$((ISSUES+1))
  fi
fi

# 3. Secret scan
LEAKED=$(grep -rn --include="*.py" --include="*.js" --include="*.sh" --include="*.json" \
  -E "(sk-ant-[a-zA-Z0-9_-]{20,}|nvapi-[a-zA-Z0-9_-]{20,}|AKIA[0-9A-Z]{16})" \
  "$AGENT_HOME/" 2>/dev/null | grep -v "SKILL.md\|block-secrets.sh\|README.md\|\.git/" || true)
if [ -n "$LEAKED" ]; then
  echo -e "${RED}⚠${NC} Possible secrets in workspace!"
  echo "$LEAKED" | head -5
  ISSUES=$((ISSUES+1))
else
  echo -e "${GREEN}✓${NC} No leaked secrets"
fi

# 4. Ollama
if command -v ollama &>/dev/null; then
  if curl -s --max-time 2 http://127.0.0.1:11434/ >/dev/null 2>&1; then
    MODEL_COUNT=$(curl -s http://127.0.0.1:11434/api/tags 2>/dev/null | \
      python3 -c "import sys,json; print(len(json.load(sys.stdin).get('models',[])))" 2>/dev/null || echo "?")
    echo -e "${GREEN}✓${NC} Ollama: $MODEL_COUNT models"
  else
    echo -e "${YELLOW}→${NC} Ollama not running"
    ISSUES=$((ISSUES+1))
  fi
fi

# 5. Memory file size
if [ -f "$AGENT_HOME/memories/MEMORY.md" ]; then
  MEM_SIZE=$(wc -c < "$AGENT_HOME/memories/MEMORY.md" | tr -d ' ')
  if [ "$MEM_SIZE" -gt 5000 ]; then
    echo -e "${YELLOW}→${NC} MEMORY.md is ${MEM_SIZE} chars (target: <5000)"
    ISSUES=$((ISSUES+1))
  else
    echo -e "${GREEN}✓${NC} MEMORY.md: ${MEM_SIZE} chars"
  fi
fi

# 6. ClamAV definitions freshness
if command -v freshclam &>/dev/null; then
  DB_AGE=$(find /opt/homebrew/share/clamav /var/lib/clamav -name "*.cvd" -mtime +7 2>/dev/null | head -1 || true)
  if [ -n "$DB_AGE" ]; then
    echo -e "${YELLOW}→${NC} ClamAV definitions >7 days old"
    ISSUES=$((ISSUES+1))
  else
    echo -e "${GREEN}✓${NC} ClamAV definitions current"
  fi
fi

# 7. Disk space
AVAIL=$(df -h "$HOME" 2>/dev/null | tail -1 | awk '{print $4}')
echo -e "  Disk available: $AVAIL"

# Summary
echo ""
if [ "$ISSUES" -eq 0 ]; then
  echo -e "${GREEN}All clear. Agent environment healthy.${NC}"
else
  echo -e "${YELLOW}$ISSUES issue(s) found — see above.${NC}"
fi
echo ""
