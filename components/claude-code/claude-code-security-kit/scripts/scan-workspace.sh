#!/usr/bin/env bash
# claude-code-security-kit: Comprehensive security scan of agent workspace
# Checks: leaked secrets, suspicious executables, double extensions,
#          PII in memory, tracked .env files, file permission issues.
#
# Usage: bash scan-workspace.sh [directory]
# Default: scans $CLAUDE_CODE_HOME (or ~/.claude)

set -euo pipefail

TARGET="${1:-${CLAUDE_CODE_HOME:-$HOME/.claude}}"
ALLOWLIST_FILE="${ALLOWLIST_FILE:-$TARGET/.security-allowlist}"
_os="$(uname -s)"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

echo ""
echo "Workspace Security Scan — $(date '+%Y-%m-%d %H:%M')"
echo "Target: $TARGET"
echo "════════════════════════════════════════════════════"
echo ""

ISSUES=0
WARNINGS=0

_pass() { echo -e "${GREEN}✓${NC} $1"; }
_warn() { echo -e "${YELLOW}⚠${NC} $1"; WARNINGS=$((WARNINGS+1)); }
_fail() { echo -e "${RED}✗${NC} $1"; ISSUES=$((ISSUES+1)); }

_filter_allowlist() {
  local allow_tmp
  allow_tmp=$(mktemp)
  if [ -f "$ALLOWLIST_FILE" ]; then
    grep -Ev '^[[:space:]]*(#|$)' "$ALLOWLIST_FILE" > "$allow_tmp" || true
  fi
  if [ -s "$allow_tmp" ]; then
    grep -Ev -f "$allow_tmp" || true
  else
    cat
  fi
  rm -f "$allow_tmp"
}

# ── 1. Leaked Secrets ────────────────────────────────────────
echo "[1/7] Scanning for leaked secrets..."
SECRETS=$(grep -rnl \
  --include="*.py" --include="*.js" --include="*.ts" --include="*.sh" \
  --include="*.yaml" --include="*.yml" --include="*.json" --include="*.env" \
  --include="*.cfg" --include="*.ini" --include="*.toml" \
  -E "(sk-ant-[a-zA-Z0-9_-]{20,}|sk-or-v1-[a-zA-Z0-9_-]{20,}|nvapi-[a-zA-Z0-9_-]{20,}|AKIA[0-9A-Z]{16}|ghp_[a-zA-Z0-9]{36}|gho_[a-zA-Z0-9]{36}|glpat-[a-zA-Z0-9_-]{20,}|sk_live_[a-zA-Z0-9]{20,})" \
  "$TARGET" 2>/dev/null | grep -v "SKILL.md\|block-secrets.sh\|README.md\|\.git/" | _filter_allowlist || true)

if [ -n "$SECRETS" ]; then
  _fail "SECRETS FOUND in:"
  echo "$SECRETS" | while read -r f; do echo "    $f"; done
else
  _pass "No leaked secrets"
fi
echo ""

# ── 2. Suspicious executables ─────────────────────────────────
echo "[2/7] Checking for suspicious executables..."
EXECS=$(find "$TARGET" -type f \( \
  -name "*.exe" -o -name "*.scr" -o -name "*.bat" -o -name "*.cmd" \
  -o -name "*.com" -o -name "*.ps1" -o -name "*.vbs" -o -name "*.hta" \
  -o -name "*.dll" -o -name "*.msi" \) 2>/dev/null || true)

if [ -n "$EXECS" ]; then
  _warn "Executable files found:"
  echo "$EXECS" | while read -r f; do echo "    $f"; done
else
  _pass "No suspicious executables"
fi
echo ""

# ── 3. Double extensions (social engineering) ─────────────────
echo "[3/7] Checking for suspicious double extensions..."
DOUBLES=$(find "$TARGET" -type f -name "*.*.*" 2>/dev/null | \
  grep -iE "\.(pdf|doc|xls|jpg|png|txt)\.(exe|scr|bat|cmd|html|js|vbs|ps1)$" || true)

if [ -n "$DOUBLES" ]; then
  _fail "DOUBLE EXTENSION FILES (possible social engineering):"
  echo "$DOUBLES" | while read -r f; do echo "    $f"; done
else
  _pass "No suspicious double extensions"
fi
echo ""

# ── 4. PII in memory files ────────────────────────────────────
echo "[4/7] Auditing memory files for PII..."
MEM_DIR="$TARGET/memories"
[ ! -d "$MEM_DIR" ] && MEM_DIR="$TARGET/workspace/memory"

if [ -d "$MEM_DIR" ]; then
  MEM_COUNT=$(find "$MEM_DIR" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  MEM_SIZE=$(du -sh "$MEM_DIR" 2>/dev/null | cut -f1 || echo "?")
  echo "  Memory files: $MEM_COUNT | Size: $MEM_SIZE"

  PII=$(grep -rnl --include="*.md" -iE \
    "(social security|ssn|\b[0-9]{3}-[0-9]{2}-[0-9]{4}\b|passport|credit card|bank account)" \
    "$MEM_DIR" 2>/dev/null | _filter_allowlist || true)

  if [ -n "$PII" ]; then
    _fail "POSSIBLE PII in memory files:"
    echo "$PII" | while read -r f; do echo "    $f"; done
  else
    _pass "No PII detected in memory"
  fi
else
  echo "  No memory directory found"
fi
echo ""

# ── 5. Git repos with tracked secrets ─────────────────────────
echo "[5/7] Checking git repos for tracked secret files..."
GIT_ISSUES=0
while IFS= read -r gitdir; do
  [ -z "$gitdir" ] && continue
  REPO_DIR=$(dirname "$gitdir")
  TRACKED=$(cd "$REPO_DIR" && git ls-files 2>/dev/null | grep -E "\.env$|credentials|secrets\.json|\.key$|\.pem$" || true)
  if [ -n "$TRACKED" ]; then
    _fail "Tracked secret files in $(basename "$REPO_DIR"): $TRACKED"
    GIT_ISSUES=1
  fi
done < <(find "$TARGET" -maxdepth 4 -name ".git" -type d 2>/dev/null)

[ "$GIT_ISSUES" -eq 0 ] && _pass "No tracked secret files in git repos"
echo ""

# ── 6. File permissions ───────────────────────────────────────
echo "[6/7] Checking file permissions..."
WORLD_READABLE=$(find "$TARGET" -maxdepth 2 \( -name "*.env" -o -name "*.key" -o -name "*.pem" \) \
  -perm -004 2>/dev/null || true)

if [ -n "$WORLD_READABLE" ]; then
  _warn "World-readable sensitive files:"
  echo "$WORLD_READABLE" | while read -r f; do echo "    $f ($(ls -la "$f" | awk '{print $1}'))"; done
else
  _pass "No world-readable sensitive files"
fi
echo ""

# ── 7. Hardcoded paths ────────────────────────────────────────
echo "[7/7] Scanning for hardcoded user paths..."
HARDCODED=$(grep -rnl --include="*.sh" --include="*.py" --include="*.yaml" \
  -E "/Users/[a-zA-Z]+/|/home/[a-zA-Z]+/" \
  "$TARGET" 2>/dev/null | grep -v "README.md\|\.git/\|SKILL.md\|node_modules" | _filter_allowlist | head -10 || true)

if [ -n "$HARDCODED" ]; then
  _warn "Hardcoded user paths found (may break on other machines):"
  echo "$HARDCODED" | while read -r f; do echo "    $f"; done
else
  _pass "No hardcoded user paths"
fi
echo ""

# ── Summary ───────────────────────────────────────────────────
echo "════════════════════════════════════════════════════"
if [ "$ISSUES" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
  echo -e "${GREEN}Workspace is clean. No issues found.${NC}"
elif [ "$ISSUES" -eq 0 ]; then
  echo -e "${YELLOW}$WARNINGS warning(s), no critical issues.${NC}"
else
  echo -e "${RED}$ISSUES critical issue(s), $WARNINGS warning(s) — review above.${NC}"
  exit 1
fi
echo ""
