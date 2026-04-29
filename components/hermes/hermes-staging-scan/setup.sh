#!/usr/bin/env bash
set -euo pipefail
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "hermes-staging-scan setup"
echo "─────────────────────────"

mkdir -p "$HERMES_HOME/staging/inbound" "$HERMES_HOME/staging/scanned" "$HERMES_HOME/staging/quarantine"
cp "$SCRIPT_DIR/staging-scan.sh" "$HERMES_HOME/staging-scan.sh"
chmod +x "$HERMES_HOME/staging-scan.sh"
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
echo "  Drop files into: ~/.hermes/staging/inbound/"
echo "  Scan: bash ~/.hermes/staging-scan.sh"
echo "  Clean files → staging/scanned/"
echo "  Infected → staging/quarantine/"
