#!/usr/bin/env bash
# openclaw-staging-scan: Scan inbound files with ClamAV before they enter workspace.
# Clean files move to scanned/, infected to quarantine/.
#
# Usage:
#   bash staging-scan.sh              # scan default inbound/
#   bash staging-scan.sh /path/file   # scan specific file
#   bash staging-scan.sh /path/dir    # scan directory

set -euo pipefail

AGENT_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
STAGING="$AGENT_HOME/staging"
INBOUND="$STAGING/inbound"
SCANNED="$STAGING/scanned"
QUARANTINE="$STAGING/quarantine"
LOG_DIR="$AGENT_HOME/logs"
LOG="$LOG_DIR/staging-scan.log"
_os="$(uname -s)"

mkdir -p "$INBOUND" "$SCANNED" "$QUARANTINE" "$LOG_DIR"

TARGET="${1:-$INBOUND}"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$TIMESTAMP] scanning: $TARGET" >> "$LOG"

# Check if ClamAV is available
if ! command -v clamscan &>/dev/null; then
  echo "⚠ ClamAV not installed. Moving files without scan."
  echo "  Install: brew install clamav (macOS) or sudo apt install clamav (Linux)"
  echo "[$TIMESTAMP] clamav not installed, moving files unscanned" >> "$LOG"
  if [ -f "$TARGET" ]; then
    mv "$TARGET" "$SCANNED/"
    echo "  Moved 1 file to scanned/ (unscanned)"
  elif [ -d "$TARGET" ]; then
    COUNT=$(find "$TARGET" -type f 2>/dev/null | wc -l | tr -d ' ')
    find "$TARGET" -type f -exec mv {} "$SCANNED/" \;
    echo "  Moved $COUNT file(s) to scanned/ (unscanned)"
  fi
  exit 0
fi

INFECTED=0
CLEAN=0

scan_file() {
  local f="$1"
  local base
  base=$(basename "$f")

  # Run ClamAV
  if clamscan --no-summary "$f" 2>/dev/null | grep -q "FOUND"; then
    local quarantine_name="${base}.$(date +%s).QUARANTINED"
    mv "$f" "$QUARANTINE/$quarantine_name"
    echo "[$TIMESTAMP] QUARANTINED: $base → $quarantine_name" >> "$LOG"
    echo "  ✗ QUARANTINED: $base"
    INFECTED=$((INFECTED + 1))
  else
    mv "$f" "$SCANNED/"
    echo "  ✓ Clean: $base"
    CLEAN=$((CLEAN + 1))
  fi
}

echo ""
echo "Staging Scan — $(date '+%Y-%m-%d %H:%M')"
echo "════════════════════════════════════════"

if [ -f "$TARGET" ]; then
  scan_file "$TARGET"
elif [ -d "$TARGET" ]; then
  FILE_COUNT=$(find "$TARGET" -type f 2>/dev/null | wc -l | tr -d ' ')
  if [ "$FILE_COUNT" -eq 0 ]; then
    echo "  No files to scan in $TARGET"
  else
    echo "  Scanning $FILE_COUNT file(s)..."
    while IFS= read -r f; do
      scan_file "$f"
    done < <(find "$TARGET" -type f)
  fi
else
  echo "  ✗ Target not found: $TARGET"
  exit 1
fi

echo ""
echo "[$TIMESTAMP] done: $CLEAN clean, $INFECTED quarantined" >> "$LOG"
echo "Result: $CLEAN clean, $INFECTED quarantined"

# Desktop notification for quarantined files (macOS)
if [ "$INFECTED" -gt 0 ] && [ "$_os" = "Darwin" ]; then
  osascript -e "display notification \"$INFECTED file(s) quarantined. Check staging/quarantine/\" with title \"Agent Security\"" 2>/dev/null || true
fi

[ "$INFECTED" -gt 0 ] && exit 1 || exit 0
