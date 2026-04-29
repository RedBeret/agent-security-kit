#!/usr/bin/env bash
# hermes-secret-store: Load API keys from OS keystore into environment variables.
# Supports macOS Keychain, Linux secret-tool (libsecret), and pass (GPG).
#
# Usage: source ~/.hermes/load-secrets.sh
# Silent: HERMES_QUIET_SECRETS=1 source ~/.hermes/load-secrets.sh

# This file is meant to be sourced, so do not enable strict shell options here.

_os="$(uname -s)"
_loaded=0
_missing=0

_kc() {
  local key="$1"
  local val=""
  case "$_os" in
    Darwin)
      val=$(security find-generic-password -a "$USER" -s "$key" -w 2>/dev/null) ;;
    Linux)
      if command -v secret-tool >/dev/null 2>&1; then
        val=$(secret-tool lookup service hermes key "$key" 2>/dev/null)
      elif command -v pass >/dev/null 2>&1; then
        val=$(pass show "hermes/$key" 2>/dev/null | head -1)
      fi ;;
  esac
  echo "$val"
}

_load() {
  local name="$1"
  local required="${2:-false}"
  local val
  val=$(_kc "$name")
  if [ -n "$val" ]; then
    export "$name=$val"
    _loaded=$((_loaded + 1))
  elif [ "$required" = "true" ]; then
    _missing=$((_missing + 1))
    [ "${HERMES_QUIET_SECRETS:-0}" != "1" ] && echo "  ⚠ Missing required key: $name" >&2
  fi
}

# ── Core API Keys (customize this list) ────────────────────────────────
_load ANTHROPIC_API_KEY
_load OPENROUTER_API_KEY
_load TAVILY_API_KEY
_load MOONSHOT_API_KEY
_load KIMI_API_KEY

# ── Gateway / Infrastructure ──────────────────────────────────────────
_load OPENCLAW_TOKEN
_load HERMES_GATEWAY_TOKEN
_load HERMES_MEMORY_KEY
_load MACMINI_API_KEY
_load WINDOWS_PC_API_KEY

if [ -z "${HERMES_GATEWAY_TOKEN:-}" ] && [ -n "${OPENCLAW_TOKEN:-}" ]; then
  export HERMES_GATEWAY_TOKEN="$OPENCLAW_TOKEN"
fi

# ── Messaging Platforms ───────────────────────────────────────────────
_load TELEGRAM_BOT_TOKEN
_load TELEGRAM_ALLOWED_USERS
_load SIGNAL_ACCOUNT
_load SIGNAL_ALLOWED_USERS

# ── Add your own keys below ───────────────────────────────────────────
# _load GITLAB_TOKEN
# _load XAI_API_KEY
# _load BRAVE_API_KEY
# _load GROQ_API_KEY
# _load OPENAI_API_KEY

# ── Status ────────────────────────────────────────────────────────────
if [ "${HERMES_QUIET_SECRETS:-0}" != "1" ]; then
  if [ "$_loaded" -gt 0 ]; then
    echo "✓ Loaded $_loaded secret(s) from $_os keystore"
  else
    echo "✗ No API keys found in keystore — run setup.sh or store keys manually (see README)"
  fi
  [ "$_missing" -gt 0 ] && echo "  $_missing required key(s) missing"
fi

true
