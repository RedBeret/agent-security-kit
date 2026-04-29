#!/usr/bin/env bash
# Claude Code PreToolUse hook — blocks secret leaks
# Receives JSON on stdin with tool_name and tool_input

set -euo pipefail

input="$(cat -)"
content=$(echo "$input" | jq -r '.tool_input // empty' 2>/dev/null)

[ -z "$content" ] && exit 0

# Check for API key patterns
if echo "$content" | grep -qE '(sk-ant-[a-zA-Z0-9_-]{20,}|sk-or-v1-[a-zA-Z0-9_-]{20,}|nvapi-[a-zA-Z0-9_-]{20,}|AKIA[0-9A-Z]{16}|ghp_[a-zA-Z0-9]{36}|sk_live_[a-zA-Z0-9]{20,})'; then
  echo "BLOCKED: API key detected. Store secrets in OS keystore, not in code."
  exit 1
fi

# Check for private keys
if echo "$content" | grep -qE -e '-----BEGIN.*PRIVATE KEY-----'; then
  echo "BLOCKED: Private key detected. Never commit private keys."
  exit 1
fi

# Check for connection strings
if echo "$content" | grep -qE '(postgres|mysql|mongodb)://[^:]+:[^@]+@'; then
  echo "BLOCKED: Database credentials in connection string. Use environment variables."
  exit 1
fi

exit 0
