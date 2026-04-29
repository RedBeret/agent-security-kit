#!/usr/bin/env bash
set -euo pipefail

HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "hermes-context-scan setup"
echo "-------------------------"

mkdir -p "$HERMES_HOME/security"
cp "$SCRIPT_DIR/context-scan.sh" "$HERMES_HOME/security/context-scan.sh"
chmod +x "$HERMES_HOME/security/context-scan.sh"

if [ ! -f "$HERMES_HOME/.context-scan-allowlist" ]; then
  cp "$SCRIPT_DIR/.context-scan-allowlist.example" "$HERMES_HOME/.context-scan-allowlist"
fi

echo "Installed context-scan.sh to $HERMES_HOME/security/"
echo "Usage: bash ~/.hermes/security/context-scan.sh"
