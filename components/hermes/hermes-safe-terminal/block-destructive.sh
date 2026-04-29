#!/usr/bin/env bash
# hermes-safe-terminal: pre_tool_call hook
# Blocks dangerous terminal commands that could cause data loss or compromise.
# Covers: filesystem destruction, SQL drops, permission escalation,
#         fork bombs, disk wipes, supply chain attacks, and credential exfil.

set -euo pipefail

payload="$(cat -)"
tool_name=$(echo "$payload" | jq -r '.tool_name // empty' 2>/dev/null)

# Only check terminal commands
[ "$tool_name" != "terminal" ] && { printf '{}\n'; exit 0; }

cmd=$(echo "$payload" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$cmd" ] && { printf '{}\n'; exit 0; }

_block() {
  printf '{"decision":"block","reason":"BLOCKED: %s"}\n' "$1"
  exit 0
}

# ── Destructive filesystem ────────────────────────────────────────────

# rm -rf targeting root, home, or wildcard
echo "$cmd" | grep -qE 'rm\s+(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r)\s+(/|~|\$HOME|\*)' && \
  _block "Recursive forced delete targeting root/home/wildcard."

# rm -rf with no path guard (just 'rm -rf' could be dangerous in wrong cwd)
echo "$cmd" | grep -qE 'rm\s+-rf\s+\.\s*$' && \
  _block "rm -rf . in current directory — too risky without path confirmation."

# ── SQL destruction ───────────────────────────────────────────────────

echo "$cmd" | grep -qiE 'DROP\s+(TABLE|DATABASE|SCHEMA|INDEX)\s' && \
  _block "DROP statement detected. Use a migration with backup."

echo "$cmd" | grep -qiE 'TRUNCATE\s+TABLE\s' && \
  _block "TRUNCATE TABLE detected. Use a migration with backup."

echo "$cmd" | grep -qiE 'DELETE\s+FROM\s+\S+\s*;?\s*$' && \
  _block "DELETE FROM without WHERE clause. Add a WHERE condition."

# ── Permission escalation ────────────────────────────────────────────

echo "$cmd" | grep -qE 'chmod\s+(777|a\+rwx)' && \
  _block "chmod 777 makes files world-writable. Use specific permissions (644, 755)."

echo "$cmd" | grep -qE 'chmod\s+[0-7]*[4567][0-7][0-7]\s+/' && \
  _block "Changing permissions on system root paths. Too dangerous."

echo "$cmd" | grep -qE 'chown\s+-R\s+.*\s+/' && \
  _block "Recursive chown on root paths. Too dangerous."

# ── Process bombs ─────────────────────────────────────────────────────

echo "$cmd" | grep -qE ':\(\)\{.*\|.*&.*\}' && \
  _block "Fork bomb detected."

echo "$cmd" | grep -qE 'while\s+true.*fork\|while\s+:.*do' && \
  _block "Infinite loop pattern that could exhaust resources."

# ── Disk wipe ─────────────────────────────────────────────────────────

echo "$cmd" | grep -qE '(mkfs|dd\s+if=)\s*.*/dev/(sd|nvme|disk|vd)' && \
  _block "Disk formatting/wiping command targeting system device."

echo "$cmd" | grep -qE 'dd\s+.*of=/dev/(sd|nvme|disk|vd)' && \
  _block "Writing directly to block device. Potential disk wipe."

# ── Credential exfiltration ───────────────────────────────────────────

echo "$cmd" | grep -qE '^\s*(env|printenv|export\s+-p|set)\s*$' && \
  _block "Environment dump exposes API keys and secrets. Access specific variables."

echo "$cmd" | grep -qE 'cat\s+.*(\.env|credentials|\.netrc|\.aws/credentials)' && \
  _block "Reading credential files directly. Use OS keystore instead."

echo "$cmd" | grep -qE 'cat\s+.*(/etc/shadow|/etc/passwd)' && \
  _block "Reading system auth files. Not appropriate for agent operations."

# ── Supply chain ──────────────────────────────────────────────────────

echo "$cmd" | grep -qE '(curl|wget)\s+.*\|\s*(ba)?sh' && \
  _block "Piping remote script to shell — supply chain risk. Download and review first."

echo "$cmd" | grep -qE '(curl|wget)\s+.*\|\s*(python|node|ruby|perl)' && \
  _block "Piping remote code to interpreter — supply chain risk. Download and review first."

# ── System modification ──────────────────────────────────────────────

echo "$cmd" | grep -qE 'systemctl\s+(disable|mask|stop)\s+(firewalld|ufw|iptables)' && \
  _block "Disabling firewall services. Security boundary violation."

echo "$cmd" | grep -qE '(iptables|nft)\s+.*-F' && \
  _block "Flushing firewall rules. Security boundary violation."

echo "$cmd" | grep -qE 'setenforce\s+0|selinux.*disabled' && \
  _block "Disabling SELinux. Security boundary violation."

# All clear
printf '{}\n'
