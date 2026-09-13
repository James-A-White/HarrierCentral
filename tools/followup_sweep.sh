#!/bin/bash
# Follow-up sweep: run the usual log sweep, then answer the specific questions
# a release is waiting on. Written 2026-09-13 because the in-session scheduler
# cannot persist a job past the session, and this can.
#
#   ./tools/followup_sweep.sh [SINCE] [OUT_DIR]
#
# Defaults to the day the fixes shipped.
set -uo pipefail
cd "$(dirname "$0")/.."

SINCE="${1:-2026-09-13}"
OUT="${2:-/tmp/hc_followup_$(date +%Y%m%d)}"
mkdir -p "$OUT"          # the sweep fails SILENTLY on a missing dir

echo "################ Follow-up sweep since $SINCE ################"
./tools/log_sweep.sh "$SINCE" "$OUT"

DUMP="$OUT/client_logs_since_$(echo "$SINCE" | tr -d '-').txt"
[[ -f "$DUMP" ]] || { echo "No client dump at $DUMP — nothing further to check."; exit 0; }

echo
echo "################ The questions this sweep exists to answer ################"

echo
echo "== Q1. Did the run-list crash stop? =="
echo "   Weekend baseline: 61 occurrences on build 1327, 5 devices."
echo "   The fix ships in 1356 (3.0.36) and 1357 (3.1.0) and was NEVER REPRODUCED,"
echo "   so this is the only real evidence either way."
grep -c "Null check operator used on a null value" "$DUMP" 2>/dev/null \
  | sed 's/^/   total occurrences: /'
echo "   by build:"
grep -B 40 "Null check operator used on a null value" "$DUMP" 2>/dev/null \
  | grep -oE "build=[0-9?]+" | sort | uniq -c | sed 's/^/     /' || echo "     none"
echo "   sessions per build (absence across few sessions proves NOTHING):"
grep -oE "^#### .*build=[0-9?]+" "$DUMP" 2>/dev/null \
  | grep -oE "build=[0-9?]+" | sort | uniq -c | sed 's/^/     /'

echo
echo "== Q2. Barbados — failed calls and the empty award list =="
echo "   kennel b78e1136-733f-4838-83ab-fa16dc862b06"
echo "   queryTypes on failed requests, whole fleet:"
grep -A 1 -E "\[ERROR\]\[HTTP\] (599|500|transport failure|Retry)" "$DUMP" 2>/dev/null \
  | grep -oE '"queryType":"[a-zA-Z]+"' | sort | uniq -c | sort -rn | head -8 | sed 's/^/     /'

echo
echo "== Q3. The official window (API 1.0.48 invalidates its cache) =="
grep -oE '"queryType":"(storePositions|deletePositions|getPositions)"' "$DUMP" 2>/dev/null \
  | sort | uniq -c | sed 's/^/     /' || echo "     no positions traffic in this window"

echo
echo "== Q4. Crashes. Weekend baseline: 2 MetricKit diagnostics =="
grep -o '"kind":"[a-z]*"' "$DUMP" 2>/dev/null | sort | uniq -c | sed 's/^/     /'
echo "   termination details:"
grep -oE '"(exceptionType|signal)":[^,}]{0,40}' "$DUMP" 2>/dev/null \
  | sort | uniq -c | sed 's/^/     /' || echo "     none"

echo
echo "################ Verdict is a JUDGEMENT, not a grep ################"
echo "Ready for full production only if the crash is absent across a decent"
echo "number of sessions on 1356 from MORE THAN A COUPLE OF DEVICES. Say the"
echo "sample size out loud. Absence on three sessions is not evidence."
