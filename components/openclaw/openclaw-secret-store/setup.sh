#!/usr/bin/env bash
# openclaw-secret-store: Setup script
# Installs the secret loader and cleans plaintext keys from .env

set -euo pipefail

OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_os="$(uname -s)"

echo "openclaw-secret-store setup"
echo "─────────────────────────"

# 1. Check keystore availability
case "$_os" in
  Darwin) echo "✓ macOS Keychain available" ;;
  Linux)
    if command -v secret-tool >/dev/null 2>&1; then
      echo "✓ secret-tool (libsecret) available"
    elif command -v pass >/dev/null 2>&1; then
      echo "✓ pass (GPG) available"
    else
      echo "✗ No secret store found. Install one:"
      echo "  Debian/Ubuntu: sudo apt install libsecret-tools"
      echo "  Fedora: sudo dnf install libsecret"
      echo "  Or: sudo apt install pass && gpg --gen-key && pass init YOUR_GPG_ID"
      exit 1
    fi ;;
esac

# 2. Install loader script
mkdir -p "$OPENCLAW_HOME"
if [ -f "$OPENCLAW_HOME/load-secrets.sh" ]; then
  cp "$OPENCLAW_HOME/load-secrets.sh" "$OPENCLAW_HOME/load-secrets.sh.bak.$(date +%Y%m%d-%H%M%S)"
fi
cp "$SCRIPT_DIR/load-secrets.sh" "$OPENCLAW_HOME/load-secrets.sh"
chmod 700 "$OPENCLAW_HOME/load-secrets.sh"
echo "✓ Installed load-secrets.sh to $OPENCLAW_HOME/"

# 3. Check if .env has plaintext keys
if [ -f "$OPENCLAW_HOME/.env" ]; then
  LEAKED=$(grep -cE "^(ANTHROPIC_API_KEY|OPENROUTER_API_KEY|TAVILY_API_KEY|MOONSHOT_API_KEY|KIMI_API_KEY)=.{10,}" "$OPENCLAW_HOME/.env" 2>/dev/null || echo 0)
  if [ "$LEAKED" -gt 0 ]; then
    echo ""
    echo "⚠ Found $LEAKED plaintext API key(s) in $OPENCLAW_HOME/.env"
    echo "  Migrate them to your keystore, then remove from .env."
    echo ""
    echo "  macOS example:"
    echo "    security add-generic-password -U -a \"\$USER\" -s \"ANTHROPIC_API_KEY\" -w \"your-key\""
    echo ""
    echo "  Linux example:"
    echo "    secret-tool store --label=\"OpenClaw: Anthropic\" service openclaw key ANTHROPIC_API_KEY <<< \"your-key\""
  else
    echo "✓ No plaintext API keys in .env"
  fi
fi

# 4. Suggest shell integration
echo ""
echo "Done! Add to your ~/.zshrc or ~/.bashrc:"
echo "  [ -f ~/.openclaw/load-secrets.sh ] && source ~/.openclaw/load-secrets.sh"
