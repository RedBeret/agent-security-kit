#!/usr/bin/env bash
# hermes-hook-audit: redacted JSONL audit logger for Hermes shell hooks.

set -euo pipefail

payload="$(cat -)"
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
LOG_FILE="${HERMES_HOOK_AUDIT_LOG:-$HERMES_HOME/logs/hook-audit.jsonl}"
MAX_CHARS="${HERMES_HOOK_AUDIT_MAX_CHARS:-300}"

mkdir -p "$(dirname "$LOG_FILE")"
chmod 700 "$(dirname "$LOG_FILE")" 2>/dev/null || true

if ! command -v jq >/dev/null 2>&1; then
  printf '{}\n'
  exit 0
fi

if ! printf '%s' "$payload" | jq -e . >/dev/null 2>&1; then
  printf '{}\n'
  exit 0
fi

redact() {
  sed -E \
    -e 's/sk-ant-[A-Za-z0-9_-]{20,}/[REDACTED]/g' \
    -e 's/sk-or-v1-[A-Za-z0-9_-]{20,}/[REDACTED]/g' \
    -e 's/nvapi-[A-Za-z0-9_-]{20,}/[REDACTED]/g' \
    -e 's/AKIA[0-9A-Z]{16}/[REDACTED]/g' \
    -e 's/ghp_[A-Za-z0-9]{36}/[REDACTED]/g' \
    -e 's/gho_[A-Za-z0-9]{36}/[REDACTED]/g' \
    -e 's/github_pat_[A-Za-z0-9_]{22,}/[REDACTED]/g' \
    -e 's/glpat-[A-Za-z0-9_-]{20,}/[REDACTED]/g' \
    -e 's/(Authorization:[[:space:]]*Bearer[[:space:]]+)[^[:space:]"'\'']+/\1[REDACTED]/Ig' \
    -e 's/(token|api[_-]?key|secret|password)=([^[:space:]&;]+)/\1=[REDACTED]/Ig'
}

hash_text() {
  if command -v sha256sum >/dev/null 2>&1; then
    printf '%s' "$1" | sha256sum | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    printf '%s' "$1" | shasum -a 256 | awk '{print $1}'
  else
    printf ''
  fi
}

truncate_preview() {
  local text="$1"
  local max="$2"
  printf '%s' "$text" | awk -v max="$max" '{ text = text $0 ORS } END { printf "%s", substr(text, 1, max) }'
}

ts="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
event="$(printf '%s' "$payload" | jq -r '.hook_event_name // .event // empty')"
tool_name="$(printf '%s' "$payload" | jq -r '.tool_name // empty')"
session_id="$(printf '%s' "$payload" | jq -r '.session_id // empty')"
cwd="$(printf '%s' "$payload" | jq -r '.cwd // empty')"
command_text="$(printf '%s' "$payload" | jq -r '.tool_input.command // .args.command // empty')"
result_text="$(printf '%s' "$payload" | jq -r '.result // empty')"

preview_source="$command_text"
preview_kind="command"
if [ -z "$preview_source" ] && [ -n "$result_text" ]; then
  preview_source="$result_text"
  preview_kind="result"
fi

preview="$(printf '%s' "$preview_source" | redact)"
preview="$(truncate_preview "$preview" "$MAX_CHARS")"
command_hash=""
if [ -n "$command_text" ]; then
  command_hash="$(hash_text "$command_text")"
fi
payload_bytes="$(printf '%s' "$payload" | wc -c | tr -d ' ')"

jq -nc \
  --arg ts "$ts" \
  --arg event "$event" \
  --arg tool_name "$tool_name" \
  --arg session_id "$session_id" \
  --arg cwd "$cwd" \
  --arg preview_kind "$preview_kind" \
  --arg preview "$preview" \
  --arg command_hash "$command_hash" \
  --argjson payload_bytes "$payload_bytes" \
  '{
    ts: $ts,
    event: $event,
    tool_name: $tool_name,
    session_id: $session_id,
    cwd: $cwd,
    payload_bytes: $payload_bytes,
    preview_kind: $preview_kind,
    preview: $preview,
    command_sha256: $command_hash
  }' >> "$LOG_FILE"

chmod 600 "$LOG_FILE" 2>/dev/null || true
printf '{}\n'
