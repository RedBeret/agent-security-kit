#!/usr/bin/env bash
# hermes-secret-store: Store a key in OS keystore
# Usage: bash store-key.sh KEY_NAME [value]
# If value is omitted, prompts interactively (safer — no shell history).

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: bash store-key.sh KEY_NAME [value]"
  echo ""
  echo "Examples:"
  echo "  bash store-key.sh ANTHROPIC_API_KEY          # prompts for value"
  echo "  bash store-key.sh ANTHROPIC_API_KEY sk-ant-...  # inline (less safe)"
  exit 1
fi

KEY_NAME="$1"
_os="$(uname -s)"

if [ $# -ge 2 ]; then
  KEY_VALUE="$2"
  echo "⚠ Value passed on command line — it may appear in shell history."
  echo "  Consider: bash store-key.sh $KEY_NAME  (prompts securely)"
else
  echo -n "Enter value for $KEY_NAME: "
  read -rs KEY_VALUE
  echo ""
  if [ -z "$KEY_VALUE" ]; then
    echo "✗ Empty value — nothing stored."
    exit 1
  fi
fi

case "$_os" in
  Darwin)
    security add-generic-password -U -a "$USER" -s "$KEY_NAME" -w "$KEY_VALUE"
    ;;
  Linux)
    if command -v secret-tool >/dev/null 2>&1; then
      echo -n "$KEY_VALUE" | secret-tool store --label="Hermes: $KEY_NAME" service hermes key "$KEY_NAME"
    elif command -v pass >/dev/null 2>&1; then
      echo "$KEY_VALUE" | pass insert -e "hermes/$KEY_NAME"
    else
      echo "✗ No secret store found. Install: sudo apt install libsecret-tools"
      exit 1
    fi
    ;;
  *)
    echo "✗ Unsupported OS: $_os"
    exit 1
    ;;
esac

echo "✓ Stored $KEY_NAME in $_os keystore"
