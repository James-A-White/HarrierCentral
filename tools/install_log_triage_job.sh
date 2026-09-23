#!/usr/bin/env bash
# =====================================================================
# tools/install_log_triage_job.sh — install/refresh the daily launchd job
#
# Runs tools/log_triage_daily.sh at 08:00 local every day. If the Mac is
# asleep at 08:00, launchd runs it once on wake. Re-run this script after
# moving the repo; --uninstall removes the job.
# =====================================================================
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LABEL="com.harriercentral.logtriage"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
DOMAIN="gui/$(id -u)"

launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true
if [[ "${1:-}" == "--uninstall" ]]; then
    rm -f "$PLIST"; echo "Removed $LABEL"; exit 0
fi

mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs/hc-log-triage"
cat > "$PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$REPO_ROOT/tools/log_triage_daily.sh</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict><key>Hour</key><integer>8</integer><key>Minute</key><integer>0</integer></dict>
    <key>StandardOutPath</key><string>$HOME/Library/Logs/hc-log-triage/launchd.log</string>
    <key>StandardErrorPath</key><string>$HOME/Library/Logs/hc-log-triage/launchd.log</string>
</dict>
</plist>
PLIST
launchctl bootstrap "$DOMAIN" "$PLIST"
echo "Installed $LABEL → $PLIST (daily 08:00). Run now: launchctl kickstart $DOMAIN/$LABEL"
