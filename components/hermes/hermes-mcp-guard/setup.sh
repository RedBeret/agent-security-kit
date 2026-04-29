#!/usr/bin/env bash
set -euo pipefail

HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "hermes-mcp-guard setup"
echo "----------------------"

mkdir -p "$HERMES_HOME/security"
cp "$SCRIPT_DIR/mcp-guard.sh" "$HERMES_HOME/security/mcp-guard.sh"
chmod +x "$HERMES_HOME/security/mcp-guard.sh"

echo "Installed mcp-guard.sh to $HERMES_HOME/security/"
echo ""
echo "Usage:"
echo "  bash ~/.hermes/security/mcp-guard.sh"
echo "  MCP_GUARD_ALLOWED_HOSTS_CSV=\"github.com\" bash ~/.hermes/security/mcp-guard.sh"
