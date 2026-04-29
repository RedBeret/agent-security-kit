#!/usr/bin/env bash
# hermes-egress-guard: pre_tool_call hook
# Blocks tool calls that would write API keys, private keys, PII, or passwords.
# Intercepts: terminal, write_file, patch
#
# Exit codes: 0 always (hook protocol). Decision in JSON stdout.
# Test mode: EGRESS_GUARD_TEST=1 bash block-secrets.sh < payload.json

set -euo pipefail

payload="$(cat -)"
tool_name=$(echo "$payload" | jq -r '.tool_name // empty' 2>/dev/null)

# Extract content to scan based on tool type
content=""
case "$tool_name" in
  terminal)
    content=$(echo "$payload" | jq -r '.tool_input.command // empty' 2>/dev/null) ;;
  write_file)
    content=$(echo "$payload" | jq -r '.tool_input.content // empty' 2>/dev/null) ;;
  patch)
    content=$(echo "$payload" | jq -r '.tool_input.patch // .tool_input.new_content // empty' 2>/dev/null) ;;
  *)
    printf '{}\n'; exit 0 ;;
esac

[ -z "$content" ] && { printf '{}\n'; exit 0; }

_block() {
  printf '{"decision":"block","reason":"BLOCKED: %s"}\n' "$1"
  exit 0
}

# ── API key patterns (broad coverage) ─────────────────────────────────

# Anthropic
echo "$content" | grep -qE 'sk-ant-[a-zA-Z0-9_-]{20,}' && \
  _block "Anthropic API key detected in $tool_name. Store in OS keystore."

# OpenRouter
echo "$content" | grep -qE 'sk-or-v1-[a-zA-Z0-9_-]{20,}' && \
  _block "OpenRouter API key detected. Store in OS keystore."

# OpenAI
echo "$content" | grep -qE 'sk-[a-zA-Z0-9]{20,}T3BlbkFJ' && \
  _block "OpenAI API key detected. Store in OS keystore."

# NVIDIA
echo "$content" | grep -qE 'nvapi-[a-zA-Z0-9_-]{20,}' && \
  _block "NVIDIA API key detected. Store in OS keystore."

# AWS
echo "$content" | grep -qE 'AKIA[0-9A-Z]{16}' && \
  _block "AWS access key detected. Use IAM roles or Secrets Manager."

# GitHub tokens
echo "$content" | grep -qE '(ghp_[a-zA-Z0-9]{36}|gho_[a-zA-Z0-9]{36}|github_pat_[a-zA-Z0-9_]{22,})' && \
  _block "GitHub token detected. Use credential helpers or keystore."

# GitLab tokens
echo "$content" | grep -qE 'glpat-[a-zA-Z0-9_-]{20,}' && \
  _block "GitLab token detected. Store in OS keystore."

# Google / GCP
echo "$content" | grep -qE 'AIza[0-9A-Za-z_-]{35}' && \
  _block "Google API key detected. Use Application Default Credentials."

# Slack tokens
echo "$content" | grep -qE 'xox[bpors]-[0-9a-zA-Z-]{10,}' && \
  _block "Slack token detected. Store in OS keystore."

# Stripe
echo "$content" | grep -qE '(sk_live_|rk_live_)[a-zA-Z0-9]{20,}' && \
  _block "Stripe secret key detected. Use environment variables."

# Twilio
echo "$content" | grep -qE 'SK[0-9a-fA-F]{32}' && \
  _block "Possible Twilio API key detected. Use environment variables."

# SendGrid
echo "$content" | grep -qE 'SG\.[a-zA-Z0-9_-]{22}\.[a-zA-Z0-9_-]{43}' && \
  _block "SendGrid API key detected. Store in OS keystore."

# ── Private keys ─────────────────────────────────────────────────────

echo "$content" | grep -qE -e '-----BEGIN[[:space:]]+(RSA|EC|DSA|OPENSSH|PGP|ENCRYPTED)?[[:space:]]*PRIVATE KEY-----' && \
  _block "Private key detected. Never commit private keys."

# ── Connection strings with credentials ───────────────────────────────

echo "$content" | grep -qE '(postgres|mysql|mongodb|redis|amqp|mssql)://[^:]+:[^@]+@' && \
  _block "Database connection string with credentials. Use environment variables."

# ── Hardcoded passwords ──────────────────────────────────────────────

echo "$content" | grep -qiE "(password|passwd|pwd|secret)\s*[=:]\s*[\"'][^\s\"']{4,}" && \
  _block "Hardcoded password/secret detected. Use OS keystore."

# ── PII patterns ─────────────────────────────────────────────────────

# SSN
echo "$content" | grep -qE '\b[0-9]{3}-[0-9]{2}-[0-9]{4}\b' && \
  _block "Possible SSN pattern detected. Remove PII before committing."

# Credit card (basic Luhn-candidate patterns)
echo "$content" | grep -qE '\b[0-9]{4}[- ]?[0-9]{4}[- ]?[0-9]{4}[- ]?[0-9]{4}\b' && \
  _block "Possible credit card number detected. Never store card numbers in code."

# ── Git operations with secrets ───────────────────────────────────────

if echo "$content" | grep -qE 'git\s+(commit|push|add)' && \
   echo "$content" | grep -qiE '(api.key|token|secret|password|\.env)'; then
  _block "Git operation may expose secrets. Review staged content first."
fi

# ── Environment variable dump ─────────────────────────────────────────

echo "$content" | grep -qE '^\s*(env|printenv|export\s+-p)\s*(\||>|$)' && \
  _block "Environment dump could expose all API keys. Access specific variables instead."

# ── Network exfiltration patterns ─────────────────────────────────────

echo "$content" | grep -qiE '(curl|wget).*(-d|--data|--data-binary|--form|-F|--upload-file|-T)[[:space:]]+@?([^[:space:]]*/)?(\.env|credentials|secrets?\.json|\.netrc|id_rsa|id_ed25519|[^[:space:]]+\.(pem|key))' && \
  _block "Network upload of a credential-like file detected. Review data flow before sending."

echo "$content" | grep -qiE '(env|printenv|export[[:space:]]+-p|cat[[:space:]]+([^[:space:]]*/)?(\.env|credentials|secrets?\.json|\.netrc))[[:space:]]*\|[[:space:]]*(curl|wget|nc|ncat|socat)' && \
  _block "Credential or environment output piped to a network client."

echo "$content" | grep -qiE 'https?://[^[:space:]"'\''<>]+[?&](token|api[_-]?key|key|secret|password)=' && \
  _block "Secret-like query parameter in URL. Use headers or keystore-backed auth."

echo "$content" | grep -qiE 'Authorization:[[:space:]]*Bearer[[:space:]]+[^[:space:]"'\''$][^[:space:]"'\'']{8,}' && \
  _block "Literal bearer token detected. Use environment interpolation or OS keystore."

# All clear
printf '{}\n'
