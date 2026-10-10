#!/usr/bin/env python3
"""Give every kennel its own ACS sender username, so a run email arrives in the
inbox as "<KENNEL> via Harrier Central" instead of "Harrier Central".

ACS keeps the display name on the sender username (a name inside the address is
refused with a 400), so each kennel gets `runs-<slug>` on harriercentral.com with
display name "<KennelShortName> via Harrier Central". The API sends from
runs-<slug>@ and falls back to runs@ for any kennel that has no username yet
(HcListMail.SendAsync), so running this is never urgent — just what makes the
sender line say the kennel.

Idempotent: a username that already exists with the right display name is left
alone; a changed KennelShortName updates the display name. Nothing is deleted.

    python3 tools/acs_kennel_senders.py            # every live kennel with a slug
    python3 tools/acs_kennel_senders.py --active   # only kennels with a run in the last year
    python3 tools/acs_kennel_senders.py --dry-run  # say what would change

Needs: az CLI logged in, the `communication` extension, and .env (SQL).
"""
import argparse, json, os, re, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EMAIL_SERVICE, RG, DOMAIN = "harriercentral-email", "harrier", "harriercentral.com"


def env():
    vals = {}
    with open(os.path.join(ROOT, ".env")) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                vals[k.strip()] = v.strip().strip('"').strip("'")
    return vals


def kennels(active):
    e = env()
    where = "ISNULL(k.deleted,0)=0 AND ISNULL(k.KennelUniqueShortName,'')<>''"
    if active:
        where += " AND EXISTS (SELECT 1 FROM HC.Event ev WHERE ev.KennelId=k.id AND ev.deleted=0 AND ev.EventStartLocal > DATEADD(YEAR,-1,GETDATE()))"
    q = f"SET NOCOUNT ON; SELECT k.KennelUniqueShortName + '|' + k.KennelShortName FROM HC.Kennel k WHERE {where} ORDER BY 1;"
    out = subprocess.run(["sqlcmd", "-S", e["HC_SQL_SERVER"], "-d", e["HC_SQL_DATABASE"], "-U", e["HC_SQL_USERNAME"],
                          "-P", e["HC_SQL_PASSWORD"], "-C", "-h", "-1", "-W", "-Q", q], capture_output=True, text=True, check=True).stdout
    rows = []
    for line in out.splitlines():
        if "|" in line:
            slug, short = line.strip().split("|", 1)
            rows.append((slug, short))
    return rows


def local_part(slug):
    """Same rule as HcListMail.KennelSender: lower-case, letters/digits/hyphen only."""
    return "runs-" + re.sub(r"[^a-z0-9-]", "", slug.lower()).strip("-")


def clean_name(short):
    return re.sub(r'[<>"\r\n]', "", short).strip()


def az(*args):
    r = subprocess.run(["az", "communication", "email", "domain", "sender-username", *args,
                        "--email-service-name", EMAIL_SERVICE, "-g", RG, "--domain-name", DOMAIN, "-o", "json"],
                       capture_output=True, text=True)
    if r.returncode:
        raise RuntimeError(r.stderr.strip().splitlines()[-1] if r.stderr.strip() else "az failed")
    return json.loads(r.stdout) if r.stdout.strip() else None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--active", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()

    existing = {u["username"]: u.get("displayName") for u in az("list")}
    rows = kennels(a.active)
    created = updated = same = failed = 0
    for slug, short in rows:
        user = local_part(slug)
        name = f"{clean_name(short)} via Harrier Central"
        if user == "runs-" or not name.strip():
            print(f"skip   {slug!r}: no usable address")
            continue
        if user in existing:
            if existing[user] == name:
                same += 1
                continue
            action = "update"
        else:
            action = "create"
        print(f"{action:6} {user}@{DOMAIN}  \"{name}\"")
        if a.dry_run:
            continue
        try:
            az(action, "--sender-username", user, "--username", user, "--display-name", name)
            if action == "create":
                created += 1
            else:
                updated += 1
        except Exception as ex:  # one bad kennel must not stop the rest
            failed += 1
            print(f"  FAILED: {ex}")
    print(f"\n{len(rows)} kennels: {created} created, {updated} updated, {same} already right, {failed} failed")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
