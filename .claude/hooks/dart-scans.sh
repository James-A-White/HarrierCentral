#!/usr/bin/env bash
# =====================================================================
# .claude/hooks/dart-scans.sh — PreToolUse hook on Bash
#
# .claude/rules/flutter.md says two scans "MUST print nothing" before a
# commit that touches mobile Dart code. This makes that a mechanism:
# when Claude is about to run `git commit` and the working tree has
# changed .dart files under mobile-app/lib, both scans run first.
#
#   clean            exit 0, silent — the commit goes ahead
#   a scan prints    exit 2 — the commit is blocked and the findings
#                    are handed back to Claude to fix
#
# Every other Bash command leaves on the first test, with no Python
# started, so this costs nothing outside a commit. A scan that cannot
# run at all also blocks: silence must mean clean, never "the checker
# was broken".
#
# Wired up in .claude/settings.json. Test by hand with:
#   echo '{"tool_input":{"command":"git commit -m x"},"cwd":"'"$PWD"'"}' \
#     | .claude/hooks/dart-scans.sh; echo "exit $?"
# =====================================================================
set -uo pipefail

input="$(cat)"
case "$input" in
    *"git commit"*) ;;
    *) exit 0 ;;
esac

# Resolve the checkout the commit is happening in (a worktree has its own).
cwd="$(printf '%s' "$input" | python3 -c 'import json,sys
try:
    print(json.load(sys.stdin).get("cwd") or "")
except Exception:
    print("")' 2>/dev/null)"
[ -n "$cwd" ] && [ -d "$cwd" ] || cwd="${CLAUDE_PROJECT_DIR:-$PWD}"
root="$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)" || exit 0

report=""

# Stored procedures (CLAUDE.md "Idempotent writes" and "TRY/CATCH is
# mandatory", 2026-10-14): when db/hc6 SQL is part of the commit, every write
# procedure must declare how it is safe to arrive twice, no check-then-insert
# may run unlocked, and every CATCH must leave an HC.ErrorLog row.
sql_changed="$(git -C "$root" status --porcelain -- db/hc6 2>/dev/null | grep -E '\.sql"?$' || true)"
if [ -n "$sql_changed" ]; then
    for scan in idempotency_scan.py catch_log_scan.py; do
        [ -f "$root/tools/$scan" ] || continue
        out="$(python3 "$root/tools/$scan" 2>&1)"
        rc=$?
        if [ -n "$out" ] || [ "$rc" -ne 0 ]; then
            report+="── tools/$scan (exit $rc) ──"$'\n'"${out:-<no output>}"$'\n'
        fi
    done
fi

# API endpoints and public-web routes (CLAUDE.md "A GET never acts",
# 2026-10-14): a GET handler that can write, send or consume a token is
# acted on by mail scanners and link previews.
web_changed="$(git -C "$root" status --porcelain -- api/Endpoints public-web/app/api 2>/dev/null | grep -E '\.(cs|ts)"?$' || true)"
if [ -n "$web_changed" ] && [ -f "$root/tools/get_write_scan.py" ]; then
    out="$(python3 "$root/tools/get_write_scan.py" 2>&1)"
    rc=$?
    if [ -n "$out" ] || [ "$rc" -ne 0 ]; then
        report+="── tools/get_write_scan.py (exit $rc) ──"$'\n'"${out:-<no output>}"$'\n'
    fi
fi

# Only when mobile Dart files are part of what is about to be committed.
changed="$(git -C "$root" status --porcelain -- mobile-app/lib 2>/dev/null | grep -E '\.dart"?$' || true)"
[ -n "$changed" ] || { [ -n "$report" ] || exit 0; }

for scan in button_text_scan.py id_case_scan.py; do
    [ -n "$changed" ] || break
    [ -f "$root/tools/$scan" ] || continue
    out="$(python3 "$root/tools/$scan" 2>&1)"
    rc=$?
    if [ -n "$out" ] || [ "$rc" -ne 0 ]; then
        report+="── tools/$scan (exit $rc) ──"$'\n'"${out:-<no output>}"$'\n'
    fi
done
[ -n "$report" ] || exit 0

{
    echo "Commit blocked: these scans must print nothing before a commit that"
    echo "touches mobile-app Dart code (.claude/rules/flutter.md) or HC6 stored"
    echo "procedures (CLAUDE.md \"Idempotent writes\", \"TRY/CATCH is mandatory\")."
    echo
    printf '%s' "$report"
    echo
    echo "A write SP needs a '-- Idempotency: <pattern> — <why>' header line and"
    echo "a locked check-then-insert (see tools/idempotency_scan.py)."
    echo "Fix each finding, or run 'python3 tools/button_text_scan.py --fix' for"
    echo "button labels, then commit again. A deliberate id upper-case carries"
    echo "'// id-case-ok: <why>'."
} >&2
exit 2
