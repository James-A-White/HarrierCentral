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

# Only when mobile Dart files are part of what is about to be committed.
changed="$(git -C "$root" status --porcelain -- mobile-app/lib 2>/dev/null | grep -E '\.dart"?$' || true)"
[ -n "$changed" ] || exit 0

report=""
for scan in button_text_scan.py id_case_scan.py; do
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
    echo "touches mobile-app Dart code (.claude/rules/flutter.md)."
    echo
    printf '%s' "$report"
    echo
    echo "Fix each finding, or run 'python3 tools/button_text_scan.py --fix' for"
    echo "button labels, then commit again. A deliberate id upper-case carries"
    echo "'// id-case-ok: <why>'."
} >&2
exit 2
