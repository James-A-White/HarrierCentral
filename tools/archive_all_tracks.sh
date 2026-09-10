#!/usr/bin/env bash
# =====================================================================
# tools/archive_all_tracks.sh — run the PackTrack archive sweep NOW instead
# of waiting for tonight (E5.F6.S4).
#
# The ArchiveTracksNightly Azure Function (03:30 UTC) copies every finished
# trail out of Table Storage onto its runner's HC.HasherEventMap row as
# TrackGzip. This script asks the ArchiveTrack function to run that same
# sweep on demand — for the first pass over the history, or to check a fix.
# The server builds the worklist (rows with a track and no archive, quiet
# for 30 minutes), reads each run's partition once, and archives every runner
# on it — under an 8-minute budget inside the 10-minute function timeout.
# This script asks for ALL tracked runs (allRuns), not just recent ones, so a
# runner on an old run who never had an attendance row is found and given
# one (nonApi_ensureTrackAttendance) before being archived. Nothing is
# scanned or written from here.
#
# Idempotent: an archived row drops out of the worklist, so a re-run
# continues where the last one stopped. Safe while runs are live.
#
# Usage:  tools/archive_all_tracks.sh
# Needs: curl, jq, sqlcmd, .env, the deployed ArchiveTrack function, and the
# GetPositions key (read from mobile-app/lib/util/constants.dart, never printed).
# =====================================================================
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
set -a; # shellcheck disable=SC1091
source "$REPO_ROOT/.env"; set +a
KEY=$(grep -A1 "GET_POSITIONS_API_KEY =" "$REPO_ROOT/mobile-app/lib/util/constants.dart" | tail -1 | tr -d " ';")
[ -n "$KEY" ] || { echo "no GetPositions key"; exit 1; }
URL="https://harriercentralpublicapi.azurewebsites.net/api/ArchiveTrack"

body=$(curl -sS --max-time 600 -X POST "$URL" -H "Content-Type: application/json" -H "X-Api-Key: $KEY" -d '{"allRuns":true}')
echo "$body" | jq -e . >/dev/null 2>&1 || { echo "no/invalid response: ${body:0:200}"; exit 1; }

echo "$body" | jq -r '
  "runs: \(.runsDone)/\(.runsInWorklist) in \(.elapsedSeconds)s (left \(.runsLeft))  tracks archived: \(.archived|length)  skipped: \(.skipped|length)  failed: \(.failed)  attendance rows created: \(.rowsCreated)",
  (.archived[] | "  ok     \(.eventId) \(.userId) — \(.points) pts → \(.bytes) B"),
  (.skipped[]  | "  skip   \(.eventId) \(.userId) — \(.reason)")'
echo "$body" | jq -r 'if .runsLeft > 0 then "note: \(.runsLeft) run(s) left over from the time budget — run again for the rest" else empty end'

sqlcmd -S "$HC_SQL_SERVER" -d "$HC_SQL_DATABASE" -U "$HC_SQL_USERNAME" -P "$HC_SQL_PASSWORD" -C -W -h -1 -Q "SET NOCOUNT ON;
SELECT 'rows with track' AS what, COUNT(*) AS n FROM HC.HasherEventMap WHERE TrackPointCount > 0
UNION ALL SELECT 'archived', COUNT(*) FROM HC.HasherEventMap WHERE TrackGzip IS NOT NULL
UNION ALL SELECT 'still unarchived', COUNT(*) FROM HC.HasherEventMap WHERE TrackPointCount > 0 AND TrackGzip IS NULL
UNION ALL SELECT 'archive KB total', ISNULL(SUM(DATALENGTH(TrackGzip)), 0) / 1024 FROM HC.HasherEventMap;" | tr -d '\r'
