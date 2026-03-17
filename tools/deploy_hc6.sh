#!/usr/bin/env bash
# =============================================================================
# deploy_hc6.sh — Deploy HC6 stored procedures to Azure SQL
#
# Usage:
#   1. Copy .env.example → .env and fill in your connection details
#   2. chmod +x tools/deploy_hc6.sh   (first time only)
#   3. ./tools/deploy_hc6.sh
#
# What this deploys:
#   1. HC6 schema (CREATE SCHEMA if not exists)
#   2. HC6.ValidatePortalAuth helper SP  ← must be first; called by all portal SPs
#   3. All HC6.hcportal_* portal SPs
#
# What this does NOT deploy:
#   - Table DDL (HC.* tables are shared with HC5 and already exist)
#   - DB functions in schema/functions/ (already deployed with HC5, use CREATE
#     not CREATE OR ALTER — re-running would fail)
#   - The API shim (deploy that via VS Code → Azure Functions extension)
# =============================================================================

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SP_DIR="$REPO_ROOT/db/hc6/portal"

# ── Load .env ─────────────────────────────────────────────────────────────────
if [[ -f "$REPO_ROOT/.env" ]]; then
    # shellcheck disable=SC1091
    set -a
    source "$REPO_ROOT/.env"
    set +a
fi

# ── Validate connection settings ──────────────────────────────────────────────
missing=0
for var in HC_SQL_SERVER HC_SQL_DATABASE HC_SQL_USERNAME HC_SQL_PASSWORD; do
    if [[ -z "${!var:-}" ]]; then
        echo "ERROR: $var is not set. Copy .env.example → .env and fill it in."
        missing=1
    fi
done
[[ $missing -eq 1 ]] && exit 1

# ── Check sqlcmd is available ─────────────────────────────────────────────────
if ! command -v sqlcmd &> /dev/null; then
    echo "ERROR: sqlcmd not found. Install it with:"
    echo "  brew install sqlcmd"
    exit 1
fi

# ── Helpers ───────────────────────────────────────────────────────────────────
PASS=0
FAIL=0

_sqlcmd() {
    sqlcmd \
        -S "$HC_SQL_SERVER" \
        -d "$HC_SQL_DATABASE" \
        -U "$HC_SQL_USERNAME" \
        -P "$HC_SQL_PASSWORD" \
        -b \
        "$@"
}

run_file() {
    local label="$1"
    local file="$2"
    printf "  %-52s" "$label"
    local output
    if output=$(_sqlcmd -i "$file" 2>&1); then
        echo "✓"
        PASS=$((PASS + 1))
    else
        echo "FAILED"
        FAIL=$((FAIL + 1))
        echo "$output" | sed 's/^/    /'
        exit 1
    fi
}

run_query() {
    local label="$1"
    local sql="$2"
    printf "  %-52s" "$label"
    local output
    if output=$(_sqlcmd -Q "$sql" 2>&1); then
        echo "✓"
        PASS=$((PASS + 1))
    else
        echo "FAILED"
        FAIL=$((FAIL + 1))
        echo "$output" | sed 's/^/    /'
        exit 1
    fi
}

# ── Deploy ────────────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════════════"
printf   "  HC6 Deploy → %s on %s\n" "$HC_SQL_DATABASE" "$HC_SQL_SERVER"
echo "══════════════════════════════════════════════════════════════"
echo ""

echo "── Step 1: Schema ───────────────────────────────────────────"
run_query "HC6 schema" \
    "IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'HC6') EXEC('CREATE SCHEMA HC6');"

echo ""
echo "── Step 2: Helper SP (must precede all portal SPs) ──────────"
run_file "HC6.ValidatePortalAuth" \
    "$SP_DIR/HC6.ValidatePortalAuth.StoredProcedure.sql"

echo ""
echo "── Step 3: Portal SPs ───────────────────────────────────────"
for file in "$SP_DIR"/HC6.hcportal_*.StoredProcedure.sql; do
    name="$(basename "$file" .StoredProcedure.sql)"
    run_file "$name" "$file"
done

echo ""
echo "══════════════════════════════════════════════════════════════"
echo "  Done.  $PASS deployed,  $FAIL failed."
echo "══════════════════════════════════════════════════════════════"
echo ""
