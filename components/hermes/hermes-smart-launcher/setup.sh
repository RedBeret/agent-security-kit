#!/usr/bin/env bash
# hermes-smart-launcher: Setup script
# Installs the launcher, daily check, and optionally the cron job (launchd/systemd).

set -euo pipefail

AGENT_HOME="${HERMES_HOME:-$HOME/.hermes}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_os="$(uname -s)"

echo ""
echo "┌──────────────────────────────────────────┐"
echo "│   hermes-smart-launcher setup            │"
echo "└──────────────────────────────────────────┘"
echo ""

# 1. Install scripts
mkdir -p "$AGENT_HOME/logs" "$AGENT_HOME/state"

cp "$SCRIPT_DIR/smart-launcher.sh" "$AGENT_HOME/smart-launcher.sh"
chmod +x "$AGENT_HOME/smart-launcher.sh"
echo "✓ Installed smart-launcher.sh"

cp "$SCRIPT_DIR/daily-check.sh" "$AGENT_HOME/daily-check.sh"
chmod +x "$AGENT_HOME/daily-check.sh"
echo "✓ Installed daily-check.sh"

# 2. Ask about scheduled maintenance
echo ""
echo "Install scheduled maintenance (auto-updates even when untouched)?"
echo "  1) macOS launchd (weekly Sunday 4:00 AM)"
echo "  2) Linux systemd timer (weekly Sunday 4:00 AM)"
echo "  3) Skip — I'll run it manually"
echo ""
read -rp "Choice [1/2/3]: " choice

case "$choice" in
  1)
    if [ "$_os" != "Darwin" ]; then
      echo "✗ launchd is macOS only. Use option 2 for Linux."
      exit 1
    fi
    PLIST_DIR="$HOME/Library/LaunchAgents"
    PLIST_FILE="$PLIST_DIR/ai.hermes.maintenance.plist"
    mkdir -p "$PLIST_DIR"

    sed -e "s|AGENT_HOME_PLACEHOLDER|$AGENT_HOME|g" \
      "$SCRIPT_DIR/templates/ai.hermes.maintenance.plist" > "$PLIST_FILE"

    launchctl unload "$PLIST_FILE" 2>/dev/null || true
    launchctl load "$PLIST_FILE"
    echo "✓ Installed launchd job: ai.hermes.maintenance"
    echo "  Schedule: every Sunday at 4:00 AM"
    echo "  Manual run: launchctl start ai.hermes.maintenance"
    ;;
  2)
    if [ "$_os" != "Linux" ]; then
      echo "✗ systemd is Linux only. Use option 1 for macOS."
      exit 1
    fi
    SYSTEMD_DIR="$HOME/.config/systemd/user"
    mkdir -p "$SYSTEMD_DIR"

    sed -e "s|AGENT_HOME_PLACEHOLDER|$AGENT_HOME|g" \
        -e "s|HOME_PLACEHOLDER|$HOME|g" \
      "$SCRIPT_DIR/templates/hermes-maintenance.service" > "$SYSTEMD_DIR/hermes-maintenance.service"

    sed -e "s|AGENT_HOME_PLACEHOLDER|$AGENT_HOME|g" \
      "$SCRIPT_DIR/templates/hermes-maintenance.timer" > "$SYSTEMD_DIR/hermes-maintenance.timer"

    systemctl --user daemon-reload
    systemctl --user enable hermes-maintenance.timer
    systemctl --user start hermes-maintenance.timer
    echo "✓ Installed systemd timer: hermes-maintenance"
    echo "  Schedule: every Sunday at 4:00 AM"
    echo "  Status: systemctl --user status hermes-maintenance.timer"
    echo "  Manual run: systemctl --user start hermes-maintenance.service"
    ;;
  3|*)
    echo "✓ Skipped. Run manually: bash ~/.hermes/smart-launcher.sh"
    ;;
esac

echo ""
echo "┌─ Setup complete ──────────────────────────┐"
echo "│                                            │"
echo "│  Full launch: bash ~/.hermes/smart-launcher.sh   │"
echo "│  Quick check: bash ~/.hermes/daily-check.sh      │"
echo "│                                            │"
echo "│  Configure in the script:                  │"
echo "│    AGENT_NAME  — your agent's name         │"
echo "│    HERMES_PORT — gateway port for health    │"
echo "│    HEAVY_WINDOW_SECS — maintenance interval │"
echo "└────────────────────────────────────────────┘"
