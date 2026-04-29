#!/usr/bin/env bash
# openclaw-memory-encrypt: Decrypt MEMORY.md and USER.md for OpenClaw to read.
# Verifies HMAC-SHA256 integrity before decrypting (detects tampering).
# Call before starting OpenClaw. Skips if plaintext already exists.

set -euo pipefail

MEMORIES_DIR="${OPENCLAW_HOME:-$HOME/.openclaw}/memories"
_os="$(uname -s)"

_get_key() {
  if [ -n "${OPENCLAW_MEMORY_KEY:-}" ]; then
    echo "$OPENCLAW_MEMORY_KEY"
    return 0
  fi
  case "$_os" in
    Darwin)
      security find-generic-password -a "$USER" -s "OPENCLAW_MEMORY_KEY" -w 2>/dev/null
      ;;
    Linux)
      if command -v secret-tool >/dev/null 2>&1; then
        secret-tool lookup service openclaw key OPENCLAW_MEMORY_KEY 2>/dev/null
      elif command -v pass >/dev/null 2>&1; then
        pass show openclaw/OPENCLAW_MEMORY_KEY 2>/dev/null | head -1
      fi
      ;;
  esac
}

KEY="$(_get_key)"
if [ -z "$KEY" ]; then
  echo "✗ No OPENCLAW_MEMORY_KEY found — memories stay encrypted"
  exit 1
fi

_decrypt_file() {
  local enc="$1"
  local dst="${enc%.enc}"

  [ ! -f "$enc" ] && return 0
  [ -f "$dst" ] && [ -s "$dst" ] && return 0  # plaintext exists, skip

  # Detect format: 3-line (new with HMAC) or 2-line (legacy)
  local line_count
  line_count=$(wc -l < "$enc" | tr -d ' ')

  local iv ciphertext

  if [ "$line_count" -ge 3 ]; then
    # New format: IV + HMAC + ciphertext
    iv=$(sed -n '1p' "$enc")
    local stored_hmac
    stored_hmac=$(sed -n '2p' "$enc")
    ciphertext=$(sed -n '3,$p' "$enc")

    # Verify HMAC integrity
    local computed_hmac
    computed_hmac=$(echo -n "$ciphertext" | openssl dgst -sha256 -hmac "$KEY" | awk '{print $NF}')

    if [ "$stored_hmac" != "$computed_hmac" ]; then
      echo "  ✗ HMAC mismatch for $(basename "$enc") — file may be tampered!"
      echo "    Expected: $stored_hmac"
      echo "    Got:      $computed_hmac"
      return 1
    fi
  else
    # Legacy 2-line format (IV + ciphertext, no HMAC)
    iv=$(head -1 "$enc")
    ciphertext=$(tail -n +2 "$enc")
    echo "  ⚠ Legacy format (no HMAC) for $(basename "$enc") — re-encrypt to upgrade"
  fi

  if echo "$ciphertext" | base64 -d 2>/dev/null | \
    openssl enc -aes-256-cbc -d \
    -K "$KEY" -iv "$iv" > "$dst" 2>/dev/null; then
    chmod 600 "$dst"
    echo "  ✓ Decrypted $(basename "$dst")"
  else
    echo "  ✗ Failed to decrypt $(basename "$enc") — wrong key?"
    rm -f "$dst"
    return 1
  fi
}

echo "Decrypting memory files..."
_decrypt_file "$MEMORIES_DIR/MEMORY.md.enc"
_decrypt_file "$MEMORIES_DIR/USER.md.enc"

echo "✓ Memory files ready for session"
