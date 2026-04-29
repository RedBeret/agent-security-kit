#!/usr/bin/env bash
# Run every component setup script in an isolated fake home directory.
#
# This catches installer regressions without touching the caller's real
# ~/.hermes, ~/.openclaw, or ~/.claude directories.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/ask-isolated.XXXXXX")"
KEEP_TMP=0
STRICT_KEYSTORE=0

for arg in "$@"; do
  case "$arg" in
    --keep-tmp) KEEP_TMP=1 ;;
    --strict-keystore) STRICT_KEYSTORE=1 ;;
    *)
      echo "usage: bash scripts/test-components-isolated.sh [--keep-tmp] [--strict-keystore]" >&2
      exit 2
      ;;
  esac
done

cleanup() {
  if [ "$KEEP_TMP" -eq 1 ]; then
    echo "kept temp root: $TMP_ROOT"
  else
    rm -rf "$TMP_ROOT"
  fi
}
trap cleanup EXIT

mkdir -p "$TMP_ROOT/logs"

ok_count=0
skip_count=0
fail_count=0
failed=""

ok() {
  ok_count=$((ok_count + 1))
  printf 'ok isolated setup %s\n' "$1"
}

skip() {
  skip_count=$((skip_count + 1))
  printf 'skip isolated setup %s (%s)\n' "$1" "$2"
}

fail() {
  fail_count=$((fail_count + 1))
  failed="${failed}${1}\n"
  printf 'fail isolated setup %s (log: %s)\n' "$1" "$2" >&2
}

has_linux_keystore() {
  command -v secret-tool >/dev/null 2>&1 || command -v pass >/dev/null 2>&1
}

should_skip() {
  local setup="$1"
  case "$(uname -s):$setup" in
    Linux:*secret-store/setup.sh)
      if [ "$STRICT_KEYSTORE" -ne 1 ] && ! has_linux_keystore; then
        echo "no Linux secret store backend available"
        return 0
      fi
      ;;
  esac
  return 1
}

run_setup() {
  local setup="$1"
  local safe_name fake_home hermes_home openclaw_home project_dir log input reason

  reason="$(should_skip "$setup" || true)"
  if [ -n "$reason" ]; then
    skip "$setup" "$reason"
    return 0
  fi

  safe_name="$(printf '%s' "$setup" | tr '/ ' '__')"
  fake_home="$TMP_ROOT/$safe_name/home"
  hermes_home="$fake_home/.hermes"
  openclaw_home="$fake_home/.openclaw"
  project_dir="$fake_home/project"
  log="$TMP_ROOT/logs/$safe_name.log"

  mkdir -p "$hermes_home" "$openclaw_home" "$project_dir"

  input=""
  case "$setup" in
    *claude-code*) input="2\n" ;;
    *smart-launcher*) input="3\n" ;;
  esac

  if (
    cd "$project_dir"
    if [ -n "$input" ]; then
      printf '%b' "$input" | env -i \
        PATH="${PATH:-/usr/bin:/bin}" \
        HOME="$fake_home" \
        USER="agent-security-kit-test" \
        SHELL="${SHELL:-/bin/sh}" \
        TERM="${TERM:-dumb}" \
        HERMES_HOME="$hermes_home" \
        OPENCLAW_HOME="$openclaw_home" \
        HERMES_MEMORY_KEY="test-hermes-memory-key-000000000000000000000000" \
        OPENCLAW_MEMORY_KEY="test-openclaw-memory-key-0000000000000000000000" \
        bash "$ROOT/$setup"
    else
      env -i \
        PATH="${PATH:-/usr/bin:/bin}" \
        HOME="$fake_home" \
        USER="agent-security-kit-test" \
        SHELL="${SHELL:-/bin/sh}" \
        TERM="${TERM:-dumb}" \
        HERMES_HOME="$hermes_home" \
        OPENCLAW_HOME="$openclaw_home" \
        HERMES_MEMORY_KEY="test-hermes-memory-key-000000000000000000000000" \
        OPENCLAW_MEMORY_KEY="test-openclaw-memory-key-0000000000000000000000" \
        bash "$ROOT/$setup"
    fi
  ) >"$log" 2>&1; then
    if find "$fake_home" -mindepth 1 -print -quit | grep -q .; then
      ok "$setup"
    else
      fail "$setup" "$log"
    fi
  else
    fail "$setup" "$log"
  fi
}

while IFS= read -r setup; do
  run_setup "$setup"
done < <(cd "$ROOT" && find components -mindepth 3 -maxdepth 3 -name setup.sh -type f | sort)

printf 'isolated setup summary: %s ok, %s skipped, %s failed\n' "$ok_count" "$skip_count" "$fail_count"

if [ "$fail_count" -gt 0 ]; then
  printf 'failed setup scripts:\n%b' "$failed" >&2
  exit 1
fi
