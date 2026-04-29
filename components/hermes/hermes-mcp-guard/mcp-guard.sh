#!/usr/bin/env bash
# hermes-mcp-guard: offline MCP configuration review for Hermes.

set -euo pipefail

STRICT=0
CONFIG=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --strict) STRICT=1 ;;
    -h|--help)
      echo "usage: bash mcp-guard.sh [--strict] [config.yaml]"
      exit 0
      ;;
    *)
      if [ -n "$CONFIG" ]; then
        echo "usage: bash mcp-guard.sh [--strict] [config.yaml]" >&2
        exit 2
      fi
      CONFIG="$1"
      ;;
  esac
  shift
done

CONFIG="${CONFIG:-${HERMES_CONFIG:-${HERMES_HOME:-$HOME/.hermes}/config.yaml}}"
ALLOWED_HOSTS_CSV="${MCP_GUARD_ALLOWED_HOSTS_CSV:-}"

PASS=0
WARN=0
FAIL=0

pass() { printf '  PASS %s\n' "$1"; PASS=$((PASS + 1)); }
warn() { printf '  WARN line %s: %s\n' "$1" "$2"; WARN=$((WARN + 1)); }
fail() { printf '  FAIL line %s: %s\n' "$1" "$2"; FAIL=$((FAIL + 1)); }

is_allowed_host() {
  local host="$1"
  local item
  IFS=',' read -r -a hosts <<< "$ALLOWED_HOSTS_CSV"
  for item in "${hosts[@]}"; do
    item="$(printf '%s' "$item" | tr '[:upper:]' '[:lower:]' | xargs)"
    [ "$host" = "$item" ] && return 0
  done
  return 1
}

is_private_or_local_host() {
  local host="$1"
  case "$host" in
    localhost|*.localhost|127.*|10.*|192.168.*|172.16.*|172.17.*|172.18.*|172.19.*|172.20.*|172.21.*|172.22.*|172.23.*|172.24.*|172.25.*|172.26.*|172.27.*|172.28.*|172.29.*|172.30.*|172.31.*|169.254.*|::1)
      return 0
      ;;
  esac
  return 1
}

extract_host() {
  local url="$1"
  url="${url#*://}"
  url="${url%%/*}"
  url="${url%%:*}"
  printf '%s' "$url" | tr '[:upper:]' '[:lower:]'
}

strip_value() {
  local value="$1"
  value="${value#*:}"
  value="${value%%#*}"
  value="$(printf '%s' "$value" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//; s/^["'\'']//; s/["'\'']$//')"
  printf '%s' "$value"
}

finish_server() {
  local server="$1"
  local line="$2"
  local enabled="$3"
  local has_filter="$4"
  local has_sampling="$5"
  local has_allowed_models="$6"

  [ -z "$server" ] && return 0
  [ "$enabled" = "false" ] && return 0

  if [ "$has_filter" -eq 0 ]; then
    warn "$line" "MCP server '$server' exposes all tools; prefer tools.include or tools.exclude."
  fi

  if [ "$has_sampling" -eq 1 ] && [ "$has_allowed_models" -eq 0 ]; then
    warn "$line" "MCP server '$server' enables sampling without an allowed_models limit."
  fi
}

echo ""
echo "Hermes MCP Guard"
echo "Config: $CONFIG"
echo "----------------"

if [ ! -f "$CONFIG" ]; then
  pass "No Hermes config file found."
  exit 0
fi

MCP_BLOCK="$(awk '
  /^[^[:space:]]/ {
    in_mcp = ($1 == "mcp_servers:")
  }
  in_mcp {
    print NR ":" $0
  }
' "$CONFIG")"

if [ -z "$MCP_BLOCK" ]; then
  pass "No mcp_servers block found."
  exit 0
fi

current_server=""
current_server_line=0
current_enabled="true"
current_tool_filter=0
current_sampling=0
current_allowed_models=0
in_sampling=0

while IFS= read -r record; do
  [ -z "$record" ] && continue
  line_no="${record%%:*}"
  line="${record#*:}"

  if printf '%s\n' "$line" | grep -Eq '^  [A-Za-z0-9_.-]+:[[:space:]]*$'; then
    finish_server "$current_server" "$current_server_line" "$current_enabled" "$current_tool_filter" "$current_sampling" "$current_allowed_models"
    current_server="$(printf '%s' "$line" | sed -E 's/^  ([A-Za-z0-9_.-]+):[[:space:]]*$/\1/')"
    current_server_line="$line_no"
    current_enabled="true"
    current_tool_filter=0
    current_sampling=0
    current_allowed_models=0
    in_sampling=0
    continue
  fi

  if printf '%s\n' "$line" | grep -Eq '^[[:space:]]+enabled:[[:space:]]*false[[:space:]]*$'; then
    current_enabled="false"
  fi

  if printf '%s\n' "$line" | grep -Eq '^[[:space:]]+tools:[[:space:]]*.*(include|exclude):'; then
    current_tool_filter=1
  elif printf '%s\n' "$line" | grep -Eq '^[[:space:]]+(include|exclude):'; then
    current_tool_filter=1
  fi

  if printf '%s\n' "$line" | grep -Eq '^[[:space:]]+sampling:[[:space:]]*$'; then
    current_sampling=1
    in_sampling=1
  elif [ "$in_sampling" -eq 1 ] && printf '%s\n' "$line" | grep -Eq '^[[:space:]]{4}[A-Za-z0-9_.-]+:'; then
    in_sampling=0
  fi

  if [ "$in_sampling" -eq 1 ] && printf '%s\n' "$line" | grep -Eq 'allowed_models:[[:space:]]*\[[^]]+[^[:space:]]\]'; then
    current_allowed_models=1
  fi

  if printf '%s\n' "$line" | grep -Eqi '(sk-ant-[A-Za-z0-9_-]{20,}|sk-or-v1-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{22,}|glpat-[A-Za-z0-9_-]{20,})'; then
    fail "$line_no" "literal credential pattern in MCP config; move it to a keystore or environment interpolation."
  fi

  if printf '%s\n' "$line" | grep -Eqi 'Authorization:[[:space:]]*["'\'']?Bearer[[:space:]]+' && ! printf '%s\n' "$line" | grep -q '\${'; then
    fail "$line_no" "literal bearer token in MCP header; use Bearer \${ENV_VAR}."
  fi

  if printf '%s\n' "$line" | grep -Eqi '[A-Z0-9_]*(API_KEY|TOKEN|SECRET|PASSWORD)[A-Z0-9_]*:[[:space:]]*["'\'']?[^"$\{[:space:]#][^#]{7,}'; then
    fail "$line_no" "literal secret-like env value in MCP config; use keystore-backed environment interpolation."
  fi

  if printf '%s\n' "$line" | grep -Eqi '^[[:space:]]+url:'; then
    url="$(strip_value "$line")"
    host="$(extract_host "$url")"
    case "$url" in
      http://*)
        fail "$line_no" "MCP endpoint uses http://; use HTTPS or a trusted local stdio server."
        ;;
      https://*)
        if is_private_or_local_host "$host"; then
          warn "$line_no" "MCP endpoint resolves to a local/private-looking host; verify it is intentional."
        elif ! is_allowed_host "$host"; then
          warn "$line_no" "remote MCP host '$host' is not in MCP_GUARD_ALLOWED_HOSTS_CSV."
        fi
        ;;
    esac
  fi

  if printf '%s\n' "$line" | grep -Eqi '^[[:space:]]+command:[[:space:]]*["'\'']?(curl|wget)\b'; then
    fail "$line_no" "MCP stdio command starts with a downloader."
  fi

  if printf '%s\n' "$line" | grep -Eqi '(curl|wget).*\|[[:space:]]*(ba)?sh|[[:space:]](ba)?sh[[:space:]]+-c|[[:space:]]zsh[[:space:]]+-c'; then
    fail "$line_no" "MCP stdio command shells remote or dynamic code."
  fi

  if printf '%s\n' "$line" | grep -Eqi '^[[:space:]]+command:[[:space:]]*["'\'']?(npx|uvx|pipx)["'\'']?[[:space:]]*$'; then
    warn "$line_no" "MCP stdio launcher should use pinned packages or a reviewed local executable."
  fi

  if printf '%s\n' "$line" | grep -Eqi '@[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+["'\'',[:space:]]*$'; then
    warn "$line_no" "scoped MCP package appears unpinned; prefer an explicit package version."
  fi
done <<< "$MCP_BLOCK"

finish_server "$current_server" "$current_server_line" "$current_enabled" "$current_tool_filter" "$current_sampling" "$current_allowed_models"

if [ "$PASS" -eq 0 ] && [ "$WARN" -eq 0 ] && [ "$FAIL" -eq 0 ]; then
  pass "MCP config reviewed with no findings."
fi

echo "----------------"
if [ "$FAIL" -gt 0 ]; then
  echo "Result: FAIL ($FAIL fail, $WARN warn, $PASS pass)"
  exit 1
fi

if [ "$WARN" -gt 0 ]; then
  echo "Result: PASS with warnings ($WARN warn, $PASS pass)"
  if [ "$STRICT" -eq 1 ]; then
    exit 1
  fi
  exit 0
fi

echo "Result: PASS ($PASS pass)"
