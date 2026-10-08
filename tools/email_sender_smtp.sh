#!/usr/bin/env bash
# =====================================================================
# Switch the SendEmail Logic App (RG harrier) to send through an SMTP relay
# — Mailjet as noreply@harriercentral.com, or iCloud as james@jamesawhite.com
# — or back to the Outlook.com connector.
#
# Why: the Outlook.com connector sends from Microsoft's servers as
# gd@jamesawhite.com. jamesawhite.com publishes DMARC p=reject with SPF
# include:icloud.com and iCloud DKIM, so Gmail, Proton, GMX/web.de and any
# other provider that enforces DMARC silently drop every HC email — invite
# codes included (CERN H3 could not sign in, 2026-10-08). Changing only the
# From address on the Outlook connector would NOT fix it: the sending server
# has to be one the From domain authorises.
#
#   mailjet  in-v3.mailjet.com — harriercentral.com's SPF already includes
#            spf.mailjet.com and it has no DMARC reject. DKIM is added to
#            Azure DNS by tools/mailjet_domain_setup.sh.
#   icloud   smtp.mail.me.com — SPF-aligned and iCloud-DKIM-signed for
#            jamesawhite.com.
#
# Needs in .env (git-ignored):
#   mailjet: HC_MAILJET_API_KEY, HC_MAILJET_SECRET_KEY
#   icloud:  HC_ICLOUD_SMTP_USER, HC_ICLOUD_SMTP_PASSWORD (app-specific)
# Optional: HC_EMAIL_FROM (default per provider, below). It must be a
# validated sender on that provider.
#
# Usage:
#   tools/email_sender_smtp.sh apply mailjet|icloud
#   tools/email_sender_smtp.sh rollback        # restore the saved Outlook definition
#
# The pre-switch definition is saved to ~/HarrierCentral-builds/ before any
# change. Nothing in the API changes: it still POSTs {from,to,subject,body,
# attachment} to the same trigger URL.
# =====================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
set -a; source "$REPO_ROOT/.env"; set +a

RG=harrier
WF=SendEmail
LOC=northeurope
API_VER=2019-05-01
BACKUP_DIR="$HOME/HarrierCentral-builds"
BACKUP="$BACKUP_DIR/SendEmail-outlook-definition.json"

SUB=$(az account show --query id -o tsv)
WF_URL="https://management.azure.com/subscriptions/$SUB/resourceGroups/$RG/providers/Microsoft.Logic/workflows/$WF?api-version=$API_VER"
API_ID="/subscriptions/$SUB/providers/Microsoft.Web/locations/$LOC/managedApis/smtp"

case "${1:-}" in
apply)
    case "${2:-}" in
    mailjet)
        : "${HC_MAILJET_API_KEY:?set HC_MAILJET_API_KEY in .env}"
        : "${HC_MAILJET_SECRET_KEY:?set HC_MAILJET_SECRET_KEY in .env}"
        CONN=mailjet-smtp; HOST=in-v3.mailjet.com
        export SMTP_USER="$HC_MAILJET_API_KEY" SMTP_PASS="$HC_MAILJET_SECRET_KEY"
        FROM="${HC_EMAIL_FROM:-noreply@harriercentral.com}" ;;
    icloud)
        : "${HC_ICLOUD_SMTP_USER:?set HC_ICLOUD_SMTP_USER in .env}"
        : "${HC_ICLOUD_SMTP_PASSWORD:?set HC_ICLOUD_SMTP_PASSWORD in .env}"
        CONN=icloud-smtp; HOST=smtp.mail.me.com
        export SMTP_USER="$HC_ICLOUD_SMTP_USER" SMTP_PASS="$HC_ICLOUD_SMTP_PASSWORD"
        FROM="${HC_EMAIL_FROM:-james@jamesawhite.com}" ;;
    *) echo "usage: $0 apply mailjet|icloud"; exit 2 ;;
    esac
    CONN_ID="/subscriptions/$SUB/resourceGroups/$RG/providers/Microsoft.Web/connections/$CONN"
    CONN_URL="https://management.azure.com$CONN_ID?api-version=2016-06-01"
    mkdir -p "$BACKUP_DIR"
    TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

    # 1. Save the current (Outlook) workflow, once — a re-run must not
    #    overwrite the Outlook backup with the iCloud version.
    az rest --method get --url "$WF_URL" -o json > "$TMP/current.json"
    if [[ ! -f "$BACKUP" ]]; then
        cp "$TMP/current.json" "$BACKUP"
        echo "Saved the Outlook definition to $BACKUP"
    fi

    # 2. Create or refresh the SMTP connection. The password goes in a file
    #    readable only by us, never on a command line.
    python3 - "$TMP/conn.json" <<EOF
import json, os, sys
json.dump({
  "location": "$LOC",
  "properties": {
    "displayName": "$CONN ($FROM)",
    "api": {"id": "$API_ID"},
    "parameterValues": {
      "serverAddress": "$HOST",
      "port": 587,
      "enableSSL": True,
      "userName": os.environ["SMTP_USER"],
      "password": os.environ["SMTP_PASS"],
    },
  },
}, open(sys.argv[1], "w"))
EOF
    chmod 600 "$TMP/conn.json"
    az rest --method put --url "$CONN_URL" --body @"$TMP/conn.json" -o none
    echo "Connection $CONN created/refreshed"

    # 3. Repoint both send actions (with and without attachment) at SMTP.
    python3 - "$TMP/current.json" "$TMP/new.json" "$CONN_ID" "$API_ID" "$FROM" "$CONN" <<'EOF'
import json, sys
src, dst, conn_id, api_id, sender, conn_name = sys.argv[1:7]
wf = json.load(open(src))
props = wf["properties"]
cond = props["definition"]["actions"]["Condition"]
html = "<p class=\"editor-paragraph\">@{triggerBody()?['body']}</p>"
def send(attach):
    body = {
        "From": sender,
        "To": "@triggerBody()?['to']",
        "Subject": "@triggerBody()?['subject']",
        "Body": html,
        "Importance": "Normal",
    }
    if attach:
        body["Attachments"] = [{
            "FileName": "@{triggerBody()?['attachment']?['filename']}",
            "ContentData": "@{triggerBody()?['attachment']?['contentBytes']}",
            "ContentType": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        }]
    return {
        "type": "ApiConnection",
        "inputs": {
            "host": {"connection": {"name": "@parameters('$connections')['smtp']['connectionId']"}},
            "method": "post",
            "path": "/SendEmailV3",
            "body": body,
        },
    }
cond["actions"] = {"Send_email_smtp": send(False)}
cond["else"]["actions"] = {"Send_email_smtp_attachment": send(True)}
conns = props.setdefault("parameters", {}).setdefault("$connections", {}).setdefault("value", {})
conns["smtp"] = {"connectionId": conn_id, "connectionName": conn_name, "id": api_id}
out = {"location": wf["location"], "properties": {
    "state": props["state"], "definition": props["definition"], "parameters": props["parameters"]}}
if "tags" in wf: out["tags"] = wf["tags"]
json.dump(out, open(dst, "w"))
EOF
    az rest --method put --url "$WF_URL" --body @"$TMP/new.json" -o none
    echo "SendEmail now sends through $HOST as $FROM"
    ;;
rollback)
    [[ -f "$BACKUP" ]] || { echo "No backup at $BACKUP"; exit 1; }
    TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
    python3 - "$BACKUP" "$TMP/old.json" <<'EOF'
import json, sys
wf = json.load(open(sys.argv[1])); p = wf["properties"]
out = {"location": wf["location"], "properties": {
    "state": p["state"], "definition": p["definition"], "parameters": p["parameters"]}}
if "tags" in wf: out["tags"] = wf["tags"]
json.dump(out, open(sys.argv[2], "w"))
EOF
    az rest --method put --url "$WF_URL" --body @"$TMP/old.json" -o none
    echo "SendEmail restored to the Outlook.com connector"
    ;;
*)
    echo "usage: $0 apply mailjet|icloud | rollback"; exit 2 ;;
esac
