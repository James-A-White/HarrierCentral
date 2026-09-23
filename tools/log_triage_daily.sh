#!/usr/bin/env bash
# =====================================================================
# tools/log_triage_daily.sh — run log_triage.py and iMessage the result
#
# Run by launchd once a day (install: tools/install_log_triage_job.sh).
# Quiet days send nothing. A message goes out when triage finds something
# new, regressed or spiking (exit 1), or when triage could not run at all
# (exit 2) — silence must mean healthy, never "the checker was broken".
#
# The full report is kept in ~/Library/Logs/hc-log-triage/<date>.txt; the
# message carries a few lines and that path.
#
#   HC_TRIAGE_IMESSAGE_TO   (.env) phone number or Apple ID to message
#   --test                  send a test message and exit
# =====================================================================
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
set -a; # shellcheck disable=SC1091
source "$REPO_ROOT/.env"; set +a
TO="${HC_TRIAGE_IMESSAGE_TO:?HC_TRIAGE_IMESSAGE_TO not set in .env}"

LOG_DIR="$HOME/Library/Logs/hc-log-triage"
mkdir -p "$LOG_DIR"
REPORT="$LOG_DIR/$(date +%Y-%m-%d).txt"
BRIEF="$(mktemp)"; trap 'rm -f "$BRIEF"' EXIT

imessage() {  # $1 = text. Messages.app must be signed in to iMessage.
    osascript - "$1" "$TO" <<'OSA'
on run argv
    tell application "Messages"
        set svc to 1st account whose service type = iMessage
        send (item 1 of argv) to participant (item 2 of argv) of svc
    end tell
end run
OSA
}

if [[ "${1:-}" == "--test" ]]; then
    imessage "HC log triage: test message from $(hostname -s). Daily runs will only message you when something is new, regressed or spiking."
    exit $?
fi

# Two days, not one: a missed run (Mac asleep, launchd catches up on wake)
# must not leave a gap, and a NEW fingerprint should nag until baselined.
python3 "$REPO_ROOT/tools/log_triage.py" --days 2 --brief "$BRIEF" > "$REPORT" 2>&1
rc=$?

case $rc in
    0) exit 0 ;;
    1) imessage "$(cat "$BRIEF")
Full report: $REPORT" ;;
    *) imessage "HC log triage could not run (exit $rc): $(tail -1 "$REPORT")
Full output: $REPORT" ;;
esac
