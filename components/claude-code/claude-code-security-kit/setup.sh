#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "┌──────────────────────────────────────────┐"
echo "│   Claude Code Security Kit Setup         │"
echo "└──────────────────────────────────────────┘"
echo ""

# Copy CLAUDE.md to project root or ~/.claude/
echo "Where to install?"
echo "  1) Current project (./CLAUDE.md + .claude/)"
echo "  2) Global (~/.claude/)"
echo ""
read -rp "Choice [1/2]: " choice

case "$choice" in
  1)
    TARGET="."
    ;;
  2)
    TARGET="$HOME/.claude"
    mkdir -p "$TARGET"
    ;;
  *)
    TARGET="."
    ;;
esac

# Copy rules
mkdir -p "$TARGET/.claude/rules" "$TARGET/.claude/hooks"
cp "$SCRIPT_DIR/.claude/rules/"*.md "$TARGET/.claude/rules/" 2>/dev/null || true
cp "$SCRIPT_DIR/.claude/hooks/"*.sh "$TARGET/.claude/hooks/" 2>/dev/null || true
chmod +x "$TARGET/.claude/hooks/"*.sh 2>/dev/null || true
echo "✓ Installed rules and hooks"

# Copy settings.json (merge if exists)
if [ ! -f "$TARGET/.claude/settings.json" ]; then
  cp "$SCRIPT_DIR/.claude/settings.json" "$TARGET/.claude/settings.json"
  echo "✓ Installed settings.json"
else
  echo "⚠ settings.json already exists — review and merge manually:"
  echo "  $SCRIPT_DIR/.claude/settings.json"
fi

# Copy scripts
mkdir -p "$TARGET/scripts"
cp "$SCRIPT_DIR/scripts/"*.sh "$TARGET/scripts/" 2>/dev/null || true
chmod +x "$TARGET/scripts/"*.sh 2>/dev/null || true
echo "✓ Installed utility scripts"

# Copy CLAUDE.md
if [ "$TARGET" = "." ]; then
  if [ ! -f "CLAUDE.md" ]; then
    cp "$SCRIPT_DIR/CLAUDE.md" ./CLAUDE.md
    echo "✓ Installed CLAUDE.md"
  else
    echo "⚠ CLAUDE.md already exists — review and merge manually"
  fi
fi

echo ""
echo "Done! Security rules, hooks, and scripts are installed."
echo ""
echo "Key features:"
echo "  • Deny rules block direct access to .env and credentials"
echo "  • PreToolUse hook scans for API key leaks"
echo "  • 5 security rules auto-loaded every session"
echo "  • Utility scripts for scanning, publishing, and backups"
