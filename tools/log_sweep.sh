#!/usr/bin/env bash
# =====================================================================
# tools/log_sweep.sh — production health sweep for a mobile rollout
#
# Usage:  ./tools/log_sweep.sh [SINCE] [OUT_DIR]
#         SINCE    ISO date/time (UTC) to sweep from; default = 3 days ago
#         OUT_DIR  where the raw client logs are dumped; default = /tmp
#
# Reads HC.Device / HC.ErrorLog / HC.ClientErrorLog via sqlcmd using the
# credentials in .env (same as deploy_hc6.sh). Read-only.
#
# See .claude/commands/hc-monitoring.md for how to interpret the output.
# =====================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SINCE="${1:-$(date -u -v-3d +%Y-%m-%d 2>/dev/null || date -u -d '3 days ago' +%Y-%m-%d)}"
OUT_DIR="${2:-/tmp}"

if [[ -f "$REPO_ROOT/.env" ]]; then
    set -a; # shellcheck disable=SC1091
    source "$REPO_ROOT/.env"; set +a
fi
for var in HC_SQL_SERVER HC_SQL_DATABASE HC_SQL_USERNAME HC_SQL_PASSWORD; do
    [[ -n "${!var:-}" ]] || { echo "ERROR: $var not set (see .env.example)"; exit 1; }
done
command -v sqlcmd >/dev/null || { echo "ERROR: sqlcmd not found (brew install sqlcmd)"; exit 1; }

q() {  # tabular query
    sqlcmd -S "$HC_SQL_SERVER" -d "$HC_SQL_DATABASE" -U "$HC_SQL_USERNAME" \
           -P "$HC_SQL_PASSWORD" -C -W -s '|' -w 400 -Q "SET NOCOUNT ON; $1"
}
raw() {  # unformatted, for NVARCHAR(MAX) dumps
    sqlcmd -S "$HC_SQL_SERVER" -d "$HC_SQL_DATABASE" -U "$HC_SQL_USERNAME" \
           -P "$HC_SQL_PASSWORD" -C -y 0 -Q "SET NOCOUNT ON; $1"
}

echo "################ Sweep since $SINCE (UTC) ################"
echo
echo "== 1. Adoption: devices by version (LastLogin >= $SINCE). OperatingSystem NULL = Android =="
q "SELECT Version, BuildNumber, ISNULL(OperatingSystem,'Android/other') os, COUNT(*) n
   FROM HC.Device WHERE removed=0 AND LastLogin >= '$SINCE'
   GROUP BY Version, BuildNumber, OperatingSystem
   ORDER BY Version DESC, BuildNumber DESC, os"

echo
echo "== 2. Server-side HC.ErrorLog since $SINCE, grouped =="
q "SELECT HcVersion, ProcName, ErrorName, LEFT(ErrorDescription,120) descr, COUNT(*) n, MAX(createdAt) last
   FROM HC.ErrorLog WHERE createdAt >= '$SINCE'
   GROUP BY HcVersion, ProcName, ErrorName, LEFT(ErrorDescription,120)
   ORDER BY n DESC"

echo
echo "== 3. Client logs: rows per build (LEN 38 = STARTUP-only, i.e. a clean session) =="
echo "   build = BuildNumber stored with the log (clients from 3.0.13); '?'-suffixed = device's current build (older rows)"
q "SELECT ISNULL(c.BuildNumber, ISNULL(d.BuildNumber,'?') + '?') build, COUNT(*) sessions,
          SUM(CASE WHEN LEN(c.ErrorLog) <= 38 THEN 1 ELSE 0 END) clean,
          SUM(CASE WHEN c.ErrorLog LIKE '%[[]ERROR]%' THEN 1 ELSE 0 END) with_errors
   FROM HC.ClientErrorLog c LEFT JOIN HC.Device d ON d.id = c.DeviceId
   WHERE c.LoggedAt >= '$SINCE'
   GROUP BY ISNULL(c.BuildNumber, ISNULL(d.BuildNumber,'?') + '?') ORDER BY build DESC"

ALL="$OUT_DIR/client_logs_since_${SINCE//[^0-9]/}.txt"
raw "SELECT '#### ' + CONVERT(varchar(30), c.LoggedAt, 120)
            + ' build=' + ISNULL(c.BuildNumber, ISNULL(d.BuildNumber,'?') + '?')
            + ' dev='   + CONVERT(varchar(36), c.DeviceId) + CHAR(10) + c.ErrorLog + CHAR(10)
     FROM HC.ClientErrorLog c LEFT JOIN HC.Device d ON d.id = c.DeviceId
     WHERE c.LoggedAt >= '$SINCE' ORDER BY c.LoggedAt DESC" > "$ALL"

echo
echo "== 4. Client [ERROR] lines by build (count | build | message) — raw dump: $ALL =="
awk '/^#### /{b=$5}
     /\[ERROR\]/{ s=$0; sub(/^\[[^]]*\] /,"",s)
        sub(/uri = https:\/\/harriercentral.blob.core.windows.net\/profile-photos\/.*/,"profile-photo 404",s)
        print b " | " substr(s,1,120) }' "$ALL" | sort | uniq -c | sort -k2,2r -k1,1rn

echo
echo "== 5. App errors as the dashboard counts them (HC6.ClientLogAppError), per build =="
q "SELECT ISNULL(c.BuildNumber, ISNULL(d.BuildNumber,'?') + '?') build, LEFT(x.appError, 110) error, COUNT(*) n
   FROM HC.ClientErrorLog c LEFT JOIN HC.Device d ON d.id = c.DeviceId
   CROSS APPLY (SELECT HC6.ClientLogAppError(c.ErrorLog) AS appError) x
   WHERE c.LoggedAt >= '$SINCE'
     AND (c.ErrorLog LIKE '%[[]ERROR][[]%' OR c.ErrorLog LIKE '[[]METRICKIT]%')
     AND x.appError IS NOT NULL
   GROUP BY ISNULL(c.BuildNumber, ISNULL(d.BuildNumber,'?') + '?'), LEFT(x.appError, 110)
   ORDER BY build DESC, n DESC" 2>/dev/null || echo "   (HC6.ClientLogAppError not deployed yet)"

echo
echo "== 5b. Dart exceptions with stack (ASYNC/FLUTTER, not HTTP), in full =="
awk '/^#### /{h=$0}
     /\[ERROR\]\[(ASYNC|FLUTTER)\]/ && !/HttpException/ {p=1; print h}
     p && /^===/ {p=0; print "---"}
     p {print substr($0,1,300)}' "$ALL"

echo
echo "== 6. MetricKit diagnostics (crash/hang kinds; 'metric' is routine) =="
grep -o '"kind":"[a-z]*"' "$ALL" | sort | uniq -c

echo
echo "== 7. Device metrics: LAST [METRICS] line per session = that session's summary (build | uptime fg/bg | memory | network | battery) =="
awk '/^#### /{ if (last != "") print last; b=$5; last="" }
     /\[METRICS\]/{ s=$0; sub(/^\[[^]]*\] \[METRICS\] /,"",s); last=b " | " s }
     END{ if (last != "") print last }' "$ALL" | sort -k1,1r | head -60
echo "   (rss/peak = this process; avail = OS headroom; app_* = our API traffic; dev_* = Android TrafficStats for the process, n/a on iOS;"
echo "    batt/drain = the DEVICE battery over the unplugged stretch, not the app's share — read against fg/bg and the PackTrack breadcrumbs)"
