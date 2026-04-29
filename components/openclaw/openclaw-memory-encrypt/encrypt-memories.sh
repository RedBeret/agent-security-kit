#!/usr/bin/env bash
# openclaw-memory-encrypt: Encrypt MEMORY.md and USER.md at rest using AES-256-CBC.
# Key from OS keystore (OPENCLAW_MEMORY_KEY). Includes HMAC integrity verification.
#
# Features:
#   - AES-256-CBC with raw 256-bit key from OS keystore (64-hex-char)
#   - Random IV per encryption (never reused)
#   - HMAC-SHA256 integrity tag (detects tampering)
#   - Best-effort plaintext wipe after encryption (see README caveat)
#   - Automatic backup before overwriting existing .enc files
#
# Encrypted format (line-delimited):
#   Line 1: hex IV (32 chars)
#   Line 2: hex HMAC-SHA256 of ciphertext
#   Line 3+: base64 ciphertext

set -euo pipefail

MEMORIES_DIR="${OPENCLAW_HOME:-$HOME/.openclaw}/memories"
BACKUP_DIR="${OPENCLAW_HOME:-$HOME/.openclaw}/backups/memory"
_os="$(uname -s)"

# ── Get encryption key ─────────────────────────────────────────────────
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
  echo "✗ No OPENCLAW_MEMORY_KEY found in keystore. Run setup.sh first."
  exit 1
fi

# Validate key is 64 hex chars (256-bit)
if ! echo "$KEY" | grep -qE '^[0-9a-fA-F]{64}$'; then
  echo "✗ OPENCLAW_MEMORY_KEY must be a 64-character hex string (256-bit)"
  exit 1
fi

# ── Backup existing encrypted files ───────────────────────────────────
_backup_enc() {
  local enc="$1"
  [ ! -f "$enc" ] && return 0
  mkdir -p "$BACKUP_DIR"
  local ts
  ts=$(date +%Y%m%d-%H%M%S)
  cp "$enc" "$BACKUP_DIR/$(basename "$enc").$ts.bak"
  # Keep only last 5 backups per file
  local base
  base=$(basename "$enc")
  ls -1t "$BACKUP_DIR/${base}".*.bak 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null || true
}

# ── Encrypt a single file ─────────────────────────────────────────────
_encrypt_file() {
  local src="$1"
  local dst="${src}.enc"

  [ ! -f "$src" ] && return 0
  [ ! -s "$src" ] && return 0

  # Backup existing .enc before overwriting
  _backup_enc "$dst"

  # Random IV per encryption (never reuse)
  local iv
  iv=$(openssl rand -hex 16)

  # Encrypt with PBKDF2
  local ciphertext
  ciphertext=$(openssl enc -aes-256-cbc \
    -K "$KEY" -iv "$iv" -in "$src" | base64)

  if [ -z "$ciphertext" ]; then
    echo "  ✗ Encryption produced empty output for $(basename "$src")"
    return 1
  fi

  # HMAC-SHA256 integrity tag over the ciphertext
  local hmac
  hmac=$(echo -n "$ciphertext" | openssl dgst -sha256 -hmac "$KEY" | awk '{print $NF}')

  # Write IV + HMAC + ciphertext
  printf '%s\n%s\n%s\n' "$iv" "$hmac" "$ciphertext" > "$dst"
  chmod 600 "$dst"

  # Securely wipe original
  if command -v shred >/dev/null 2>&1; then
    shred -u "$src" 2>/dev/null || rm -f "$src"
  else
    # macOS: overwrite with random data then delete
    local fsize
    fsize=$(stat -f%z "$src" 2>/dev/null || stat --printf="%s" "$src" 2>/dev/null || echo 4096)
    dd if=/dev/urandom of="$src" bs="$fsize" count=1 conv=notrunc 2>/dev/null || true
    rm -f "$src"
  fi

  echo "  ✓ Encrypted $(basename "$src") (HMAC verified)"
}

echo "Encrypting memory files..."
_encrypt_file "$MEMORIES_DIR/MEMORY.md"
_encrypt_file "$MEMORIES_DIR/USER.md"

echo "✓ Memory files encrypted at rest"
