#!/usr/bin/env python3
"""Print one Beta Testers case in full — paste its reference and get everything.

    python3 tools/beta_case.py BT-12        # or: 12
    python3 tools/beta_case.py BT-12 --json # the raw case file

A case reference is BT-<n>, where n is the room sequence number of the message
that opened the case (E18.F9; the cloud assistant puts it in the case email's
subject, at the top of the email, and in its closing reply in the room).

It prints, read-only:
  1. the CASE FILE the assistant keeps per case — every turn: what it decided,
     what it replied, every tool call it made (queries, files, logs) and what
     it cost; on close, the proposal. Stored in the API's storage account,
     container beta-cases, blob BT-<n>.json (api/Endpoints/BetaRoomAssistant.cs).
  2. the CONVERSATION as it is in the room now: the tester's messages from
     the opening one, and the assistant's replies to them, until the case
     closed (or now, if it is open).

Needs: the az CLI signed in (to read the storage connection string from the
API's app settings — never printed) and the SQL credentials in .env.
Cases opened before the case file existed (2026-10-15) print the room part only.
"""
import json, os, re, subprocess, sys, tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
APP, RG = "harriercentralpublicapi", "harriercentralpublicapi"
ROOM = 8


def env():
    e = dict(os.environ)
    p = ROOT / ".env"
    if p.exists():
        for line in p.read_text().splitlines():
            m = re.match(r"\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\s*$", line)
            if m and m.group(1) not in e:
                e[m.group(1)] = m.group(2).strip().strip('"').strip("'")
    return e


def case_file(ref: str):
    cs = subprocess.run(
        ["az", "functionapp", "config", "appsettings", "list", "--name", APP, "--resource-group", RG,
         "--query", "[?name=='AzureWebJobsStorage'].value | [0]", "-o", "tsv"],
        capture_output=True, text=True).stdout.strip()
    if not cs:
        return None, "could not read the storage connection (is `az login` current?)"
    with tempfile.TemporaryDirectory() as d:
        out = Path(d) / "case.json"
        r = subprocess.run(["az", "storage", "blob", "download", "--connection-string", cs,
                            "--container-name", "beta-cases", "--name", f"{ref}.json",
                            "--file", str(out), "--only-show-errors", "-o", "none"],
                           capture_output=True, text=True)
        if r.returncode != 0 or not out.exists():
            return None, "no case file (a case from before 2026-10-15, or a reference that does not exist)"
        return json.loads(out.read_text()), None


def sql(e, q: str):
    r = subprocess.run(["sqlcmd", "-S", e["HC_SQL_SERVER"], "-d", e["HC_SQL_DATABASE"], "-U", e["HC_SQL_USERNAME"],
                        "-P", e["HC_SQL_PASSWORD"], "-W", "-h", "-1", "-s", "\x1f", "-y", "0", "-Q", "SET NOCOUNT ON; " + q],
                       capture_output=True, text=True)
    return [line.split("\x1f") for line in r.stdout.splitlines() if line.strip()]


TAG = "Claude, for James:"


def build_cases(e):
    """The same grouping as BetaRoomAssistant.BuildCases: a tester's message goes
    to the case it was merged into ('join'), else the case of the message it
    replies to (whoever sent it — the room is public), else the author's own
    open case, else a new case BT-<seq>. 'closed' rows close a case."""
    msgs = sql(e, f"""SELECT m.MessageSequenceCount, CONVERT(VARCHAR(16), m.createdAt, 120),
          LOWER(CAST(h.PublicHasherId AS NVARCHAR(40))), h.DisplayName, LOWER(CAST(m.id AS NVARCHAR(40))),
          ISNULL(LOWER(CAST(m.ReplyToMessageId AS NVARCHAR(40))), ''), m.MessageKind,
          REPLACE(REPLACE(m.MessageContent, CHAR(13), ' '), CHAR(10), ' ⏎ ')
        FROM HC.EventMessage m JOIN HC.Hasher h ON h.id = m.UserId
        WHERE m.EventId IS NULL AND m.KennelId IS NULL AND m.ThreadId IS NULL
          AND m.MessageType = {ROOM} AND m.Removed = 0 ORDER BY m.MessageSequenceCount""")
    events = []
    for who, ev, data in sql(e, "SELECT StrParam1, Message, Data FROM LOG.GeneralLog WHERE LogSource = N'beta-room' ORDER BY idx"):
        m = re.match(r"seq=(\d+)(?:\s+(BT-\d+))?", data or "")
        if m:
            events.append((ev, who, int(m.group(1)), m.group(2)))
    joins = {seq: ref for ev, _, seq, ref in events if ev == "join" and ref}
    closes = {}
    for ev, _, seq, ref in events:
        if ev == "closed":
            closes.setdefault(seq, []).append(ref)
    cases, by_ref, case_of = [], {}, {}
    for seq, at, author, name, mid, reply_to, kind, text in msgs:
        seq = int(seq)
        line = (seq, at, name, kind, text)
        if text.startswith(TAG):
            if reply_to in case_of:
                case_of[reply_to]["msgs"].append(line + ("ASSISTANT",)); case_of[mid] = case_of[reply_to]
            continue
        target = None
        if seq in joins and joins[seq] in by_ref and not by_ref[joins[seq]]["closed"]:
            target = by_ref[joins[seq]]
        if target is None and reply_to in case_of and not case_of[reply_to]["closed"]:
            target = case_of[reply_to]
        if target is None:
            target = next((c for c in reversed(cases) if not c["closed"] and author in c["people"]), None)
        if target is None:
            target = {"ref": f"BT-{seq}", "people": {}, "msgs": [], "closed": False}
            cases.append(target); by_ref[target["ref"]] = target
        target["msgs"].append(line + (name,)); target["people"][author] = name; case_of[mid] = target
        for ref in closes.get(seq, []):
            (by_ref.get(ref) if ref else target)["closed"] = True
    return by_ref


def conversation(e, ref: str):
    c = build_cases(e).get(ref)
    if not c:
        return None, False, []
    convo = [f"[{seq}] {at} {who}{' [photo]' if kind == '1' else ''}: {text}"
             for seq, at, name, kind, text, who in sorted(c["msgs"])]
    return ", ".join(c["people"].values()), c["closed"], convo


def main(argv):
    if not argv or argv[0] in ("-h", "--help"):
        print(__doc__); return 0
    m = re.match(r"(?i)^(?:BT-?)?(\d+)$", argv[0].strip())
    if not m:
        sys.exit("A case reference looks like BT-12.")
    n = int(m.group(1)); ref = f"BT-{n}"
    e = env()
    file, why = case_file(ref)
    if "--json" in argv:
        print(json.dumps(file, indent=1, ensure_ascii=False) if file else why); return 0
    name, closed, convo = conversation(e, ref)
    print(f"═══ Case {ref} ═══")
    if file:
        print(f"People: {', '.join(file.get('participants') or [file.get('reporter')])}   status: {file.get('status')}   opened: {file.get('openedAt')}"
              f"   total cost: US${file.get('totalCostUsd', 0):.3f}")
        print(f"Tester hasher id: {file.get('reporterUserId')}   public id: {file.get('reporterPublicId')}")
    else:
        print(f"People: {name or '?'}   ({why})")
    print("\n── Conversation (from the room) ──")
    print("\n".join(convo) if convo else "(no messages found for that reference)")
    if not closed:
        print("(case still open)")
    if file:
        p = file.get("proposal")
        if p:
            print("\n── Proposal ──")
            for k in ("title", "problem", "evidence", "likely_cause", "suggested_fix", "confidence", "unknowns", "related_backlog"):
                if p.get(k):
                    print(f"{k.replace('_', ' ').upper()}: {p[k]}")
        if file.get("addendumTo"):
            print(f"\n(This case is an ADDENDUM to {file['addendumTo']} — run beta_case.py {file['addendumTo']} too.)")
        for a in file.get("addenda", []):
            print(f"\n── Addendum {a.get('case')} ({a.get('at')}) ──")
            for line in a.get("messages", []):
                print("  " + line)
            for k, v in (a.get("proposal") or {}).items():
                if v and k != "addendum_to":
                    print(f"  {k.replace('_', ' ').upper()}: {v}")
        print("\n── Turns (what the assistant did) ──")
        for i, t in enumerate(file.get("turns", []), 1):
            print(f"\n#{i} {t.get('at')}  action={t.get('action')}  calls={t.get('modelCalls')}  US${t.get('costUsd', 0):.3f}")
            if t.get("answering"):
                print(f"  answering [{t.get('answeringSeq')}]: {t['answering'][:300]}")
            if t.get("reply"):
                print(f"  replied: {t['reply']}")
            for tool in t.get("toolLog", []):
                print(f"  · {tool}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
