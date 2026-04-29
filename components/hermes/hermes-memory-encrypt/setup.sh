#!/usr/bin/env bash
# hermes-memory-encrypt: One-shot setup
# Generates 256-bit encryption key, stores in OS keystore, installs scripts.

set -euo pipefail

HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_os="$(uname -s)"

echo ""
echo "┌─────────────────────────────────────┐"
echo "│   hermes-memory-encrypt setup       │"
echo "└─────────────────────────────────────┘"
echo ""

# 1. Check dependencies
if ! command -v openssl >/dev/null 2>&1; then
  echo "✗ openssl not found — please install it"
  exit 1
fi
echo "✓ openssl $(openssl version 2>/dev/null | head -1)"

# 2. Generate + store key
_has_key() {
  [ -n "${HERMES_MEMORY_KEY:-}" ] && return 0
  case "$_os" in
    Darwin) security find-generic-password -a "$USER" -s "HERMES_MEMORY_KEY" -w >/dev/null 2>&1 ;;
    Linux)
      if command -v secret-tool >/dev/null 2>&1; then
        secret-tool lookup service hermes key HERMES_MEMORY_KEY >/dev/null 2>&1
      elif command -v pass >/dev/null 2>&1; then
        pass show hermes/HERMES_MEMORY_KEY >/dev/null 2>&1
      else return 1; fi ;;
    *) return 1 ;;
  esac
}

if _has_key; then
  echo "✓ HERMES_MEMORY_KEY already available"
else
  KEY=$(openssl rand -hex 32)
  case "$_os" in
    Darwin)
      security add-generic-password -U -a "$USER" -s "HERMES_MEMORY_KEY" -w "$KEY"
      ;;
    Linux)
      if command -v secret-tool >/dev/null 2>&1; then
        echo -n "$KEY" | secret-tool store --label="Hermes: Memory Encryption Key" service hermes key HERMES_MEMORY_KEY
      elif command -v pass >/dev/null 2>&1; then
        echo "$KEY" | pass insert -e hermes/HERMES_MEMORY_KEY
      else
        echo "✗ No secret store found on Linux."
        echo "  Install one: sudo apt install libsecret-tools"
        echo "  Or: sudo apt install pass && gpg --gen-key && pass init YOUR_GPG_ID"
        exit 1
      fi
      ;;
    *)
      echo "✗ Unsupported OS: $_os"
      exit 1
      ;;
  esac
  echo "✓ Generated and stored 256-bit encryption key"
fi

# 3. Create directories
mkdir -p "$HERMES_HOME/memories"
mkdir -p "$HERMES_HOME/backups/memory"
echo "✓ Created memories and backup directories"

# 4. Install scripts
cp "$SCRIPT_DIR/encrypt-memories.sh" "$HERMES_HOME/encrypt-memories.sh"
cp "$SCRIPT_DIR/decrypt-memories.sh" "$HERMES_HOME/decrypt-memories.sh"
chmod 700 "$HERMES_HOME/encrypt-memories.sh" "$HERMES_HOME/decrypt-memories.sh"
echo "✓ Installed encrypt/decrypt scripts to $HERMES_HOME/"

echo ""
echo "┌─ Setup complete ─────────────────────┐"
echo "│                                       │"
echo "│  Encrypt: bash ~/.hermes/encrypt-memories.sh  │"
echo "│  Decrypt: bash ~/.hermes/decrypt-memories.sh  │"
echo "│                                       │"
echo "│  Or add to your launcher for auto:    │"
echo "│    decrypt on start, encrypt on exit  │"
echo "└───────────────────────────────────────┘"
