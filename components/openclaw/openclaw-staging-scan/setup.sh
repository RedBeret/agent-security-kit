#!/usr/bin/env bash
set -euo pipefail
OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "openclaw-staging-scan setup"
echo "─────────────────────────"

mkdir -p "$OPENCLAW_HOME/staging/inbound" "$OPENCLAW_HOME/staging/scanned" "$OPENCLAW_HOME/staging/quarantine"
cp "$SCRIPT_DIR/staging-scan.sh" "$OPENCLAW_HOME/staging-scan.sh"
chmod +x "$OPENCLAW_HOME/staging-scan.sh"
echo "✓ Installed staging-scan.sh"
echo "✓ Created staging directories"

if command -v clamscan &>/dev/null; then
  echo "✓ ClamAV found"
else
  echo "⚠ ClamAV not installed (optional but recommended)"
  echo "  macOS: brew install clamav && freshclam"
  echo "  Linux: sudo apt install clamav && sudo freshclam"
fi

echo ""
echo "Usage:"
echo "  Drop files into: ~/.openclaw/staging/inbound/"
echo "  Scan: bash ~/.openclaw/staging-scan.sh"
echo "  Clean files → staging/scanned/"
echo "  Infected → staging/quarantine/"
