#!/usr/bin/env bash
# hermes-context-scan: scan Hermes memory/context files for poisoning phrases.

set -euo pipefail

TARGET="${1:-${HERMES_HOME:-$HOME/.hermes}}"
ALLOWLIST_FILE="${ALLOWLIST_FILE:-$TARGET/.context-scan-allowlist}"

ISSUES=0
WARNINGS=0
TMP_FINDINGS="$(mktemp)"
trap 'rm -f "$TMP_FINDINGS"' EXIT

add_finding() {
  local path="$1"
  local line="$2"
  local reason="$3"
  printf '%s:%s:%s\n' "$path" "$line" "$reason" >> "$TMP_FINDINGS"
}

filter_allowlist() {
  local allow_tmp
  allow_tmp="$(mktemp)"
  if [ -f "$ALLOWLIST_FILE" ]; then
    grep -Ev '^[[:space:]]*(#|$)' "$ALLOWLIST_FILE" > "$allow_tmp" || true
  fi
  if [ -s "$allow_tmp" ]; then
    grep -Ev -f "$allow_tmp" || true
  else
    cat
  fi
  rm -f "$allow_tmp"
}

scan_file() {
  local file="$1"
  local line_no=0
  local line lower

  while IFS= read -r line || [ -n "$line" ]; do
    line_no=$((line_no + 1))
    lower="$(printf '%s' "$line" | tr '[:upper:]' '[:lower:]')"

    case "$lower" in
      *"ignore previous instructions"*|*"ignore all previous instructions"*|*"disregard previous instructions"*)
        add_finding "$file" "$line_no" "prompt override"
        ;;
    esac

    case "$lower" in
      *"do not tell the user"*|*"don't tell the user"*|*"do not reveal"*|*"keep this hidden from the user"*)
        add_finding "$file" "$line_no" "concealment instruction"
        ;;
    esac

    case "$lower" in
      *"send the api key"*|*"send api key"*|*"exfiltrate"*|*"leak the secret"*|*"upload secrets"*|*"send credentials"*)
        add_finding "$file" "$line_no" "secret exfiltration instruction"
        ;;
    esac

    case "$lower" in
      *"<system>"*|*"</system>"*|*"<developer>"*|*"</developer>"*|*"system:"*"ignore"*|*"developer:"*"ignore"*)
        add_finding "$file" "$line_no" "role tag injection"
        ;;
    esac

    case "$lower" in
      *"curl"*"|"*"bash"*|*"wget"*"|"*"sh"*|*"bash -c"*|*"sh -c"*)
        add_finding "$file" "$line_no" "shell execution instruction"
        ;;
    esac

    case "$lower" in
      *"base64"*"decode"*|*"eval("*|*"exec("*)
        add_finding "$file" "$line_no" "staged code execution phrase"
        ;;
    esac
  done < "$file"
}

echo ""
echo "Hermes Context Scan"
echo "Target: $TARGET"
echo "-------------------"

if [ ! -d "$TARGET" ]; then
  echo "PASS target directory does not exist"
  exit 0
fi

while IFS= read -r file; do
  scan_file "$file"
done < <(
  find "$TARGET" \( \
    -path '*/.git/*' -o \
    -path '*/node_modules/*' -o \
    -path '*/venv/*' -o \
    -path '*/.venv/*' \
  \) -prune -o -type f \( \
    -name 'MEMORY.md' -o \
    -name 'USER.md' -o \
    -path '*/memories/*.md' -o \
    -path '*/workspace/memory/*.md' -o \
    -path '*/context/*.md' \
  \) -print 2>/dev/null
)

FILTERED="$(filter_allowlist < "$TMP_FINDINGS")"

if [ -n "$FILTERED" ]; then
  echo "Findings:"
  while IFS= read -r finding; do
    [ -z "$finding" ] && continue
    printf '  %s\n' "$finding"
    ISSUES=$((ISSUES + 1))
  done <<< "$FILTERED"
else
  echo "PASS no context-poisoning patterns found"
fi

echo "-------------------"
if [ "$ISSUES" -gt 0 ]; then
  echo "Result: FAIL ($ISSUES finding(s), $WARNINGS warning(s))"
  exit 1
fi

echo "Result: PASS"
