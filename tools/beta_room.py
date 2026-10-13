#!/usr/bin/env python3
"""Beta Testers room (E18.F9) — read it, and answer in it as James's assistant.

The room is an ordinary platform chat room (HC6.ChatRoomCatalog row 8, gated
on the beta cohort). This tool talks to it the way a phone does: through the
app API shim as a DEVICE registered under James's account, so pushes, badges
and sequence numbers behave and the audit trail names the device. Nothing
here touches the database directly.

Rules it enforces (James, 2026-10-13):
  * every reply opens with the tag "Claude, for James:" — never pass as James
  * the only write is `send`: one reply into the room. No other side effects.

Credentials come from the environment (a .env at the repo root is read if
present, never overriding variables already set):
  HC_AGENT_USER_ID        James's HC.Hasher.id
  HC_AGENT_DEVICE_ID      the assistant's HC.Device.id (from `register`)
  HC_AGENT_DEVICE_SECRET  its DeviceSecret
  HC_AGENT_TIME_WINDOW    its TimeWindow (seconds)
  HC_API_URL              optional; defaults to the production app shim
  HC_BETA_ROOM_TYPE       optional; defaults to 8

Commands
  register --user-id <id> [--name <text>]   mint the device (prints the env lines; writes nothing)
  rooms                                      the rooms this device may enter (auth check)
  poll [--since N | --all] [--state FILE]    messages newer than the watermark, as JSON
  send <text> [--reply-to <messageId>]       post one tagged reply
  mark-read                                  clear the room's badge for this account

`poll` keeps its watermark (the newest sequence seen) in --state, default
~/.hc_beta_room_state.json, and reports for each message whether it is
"answered": a later message by this account exists. Use --all to see the
last 50 regardless.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
import time
import urllib.error
import urllib.request
import uuid
from pathlib import Path

TAG = "Claude, for James:"
GUID_EMPTY = "00000000-0000-0000-0000-000000000000"
TOKEN_EPOCH = 743612400  # 1993-07-25 15:00:00 UTC — never changes
DEFAULT_API = "https://harriercentralpublicapi.azurewebsites.net/api/AppApiHC6"
MAX_MESSAGE = 4000  # hcapp_sendRoomMessage refuses longer
REPO_ROOT = Path(__file__).resolve().parent.parent


# ----------------------------------------------------------------- env

def load_dotenv() -> None:
    env = REPO_ROOT / ".env"
    if not env.is_file():
        return
    for raw in env.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        if line.startswith("export "):
            line = line[7:]
        k, v = line.split("=", 1)
        k, v = k.strip(), v.strip().strip('"').strip("'")
        os.environ.setdefault(k, v)


def need(name: str) -> str:
    v = os.environ.get(name, "").strip()
    if not v:
        sys.exit(f"{name} is not set (see .env.example)")
    return v


# --------------------------------------------------------------- tokens

def hc_token(user_id: str, proc_name: str, param: str | None = None,
             time_window: int = 30) -> str:
    """UPPER(userId#procName#timeBlocks[#param]) → SHA-256 hex, upper.
    The same recipe as the app and the web (see /hc-access-tokens)."""
    blocks = int((time.time() - TOKEN_EPOCH) // time_window)
    s = f"{user_id}#{proc_name}#{blocks}"
    if param:
        s += f"#{param}"
    return hashlib.sha256(s.upper().encode("utf-8")).hexdigest().upper()


# ------------------------------------------------------------------ api

class ApiError(RuntimeError):
    pass


def call_api(body: dict) -> list[list[dict]]:
    url = os.environ.get("HC_API_URL", DEFAULT_API)
    data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(url, data=data, method="POST",
                                 headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            text = resp.read().decode("utf-8")
    except urllib.error.HTTPError as e:
        raise ApiError(f"{body.get('queryType')}: HTTP {e.code} {e.read()[:300]!r}") from None
    rowsets = json.loads(text) if text.strip() else []
    # Error envelope: rowset 0 carries errorId / errorCode (see CLAUDE.md).
    if rowsets and rowsets[0] and isinstance(rowsets[0][0], dict):
        first = rowsets[0][0]
        if "errorId" in first or "errorCode" in first:
            raise ApiError(f"{body.get('queryType')}: {json.dumps(first)}")
        if first.get("success") == 0 or first.get("Success") == 0:
            raise ApiError(f"{body.get('queryType')}: {json.dumps(first)}")
    return rowsets


class Device:
    def __init__(self) -> None:
        self.user_id = need("HC_AGENT_USER_ID").lower()
        self.device_id = need("HC_AGENT_DEVICE_ID").lower()
        self.secret = need("HC_AGENT_DEVICE_SECRET")
        self.time_window = int(need("HC_AGENT_TIME_WINDOW"))
        self.room_type = int(os.environ.get("HC_BETA_ROOM_TYPE", "8"))

    def call(self, query_type: str, **params) -> list[list[dict]]:
        body = {
            "queryType": query_type,
            "deviceId": self.device_id,
            "accessToken": hc_token(self.user_id, f"hcapp_{query_type}",
                                    self.secret, self.time_window),
        }
        body.update({k: v for k, v in params.items() if v is not None})
        return call_api(body)


# ------------------------------------------------------------- commands

def cmd_register(args: argparse.Namespace) -> int:
    device_id = str(uuid.uuid4())
    device_data = {
        "systemName": "agent",
        "deviceName": args.name,
        "model": "Claude Code",
        "purpose": "beta-room assistant (E18.F9)",
    }
    rowsets = call_api({
        "queryType": "authorizeDevice",
        "deviceId": device_id,
        "accessToken": hc_token(GUID_EMPTY, "hcapp_authorizeDevice"),
        "hcVersion": "agent",
        "userId": args.user_id.lower(),
        "deviceData": json.dumps(device_data),
        "isMobile": 0,
        "deviceType": "agent",
        "deviceName": args.name,
        "systemName": "agent",
        "systemVersion": "1",
        "manufacturer": "Anthropic",
    })
    row = next((r for rs in rowsets for r in rs if "deviceSecret" in r), None)
    if row is None:
        print(json.dumps(rowsets, indent=1, default=str))
        sys.exit("no deviceSecret in the reply — see the rowsets above")
    print("# add to .env (never commit):")
    print(f"HC_AGENT_USER_ID={args.user_id.lower()}")
    print(f"HC_AGENT_DEVICE_ID={device_id}")
    print(f"HC_AGENT_DEVICE_SECRET={row['deviceSecret']}")
    print(f"HC_AGENT_TIME_WINDOW={row['timeWindow']}")
    return 0


def cmd_rooms(_: argparse.Namespace) -> int:
    d = Device()
    rowsets = d.call("getChatRooms", includeOptedOut=1)
    rooms = rowsets[1] if len(rowsets) > 1 else (rowsets[0] if rowsets else [])
    print(json.dumps(rooms, indent=1, default=str))
    return 0


def read_state(path: Path) -> dict:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return {}


def cmd_poll(args: argparse.Namespace) -> int:
    d = Device()
    state_path = Path(os.path.expanduser(args.state))
    state = read_state(state_path)
    since = None if args.all else (args.since if args.since is not None
                                   else state.get("lastSeq"))
    rowsets = d.call("getRoomMessages", roomType=d.room_type,
                     sinceSequenceCount=since, markRead=0)
    # Rowset 0 is the envelope / room header; the messages are the rowset
    # whose rows carry sequenceCount.
    msgs = next((rs for rs in rowsets if rs and "sequenceCount" in rs[0]), [])
    msgs = sorted(msgs, key=lambda m: m.get("sequenceCount") or 0)
    if args.all:
        msgs = msgs[-50:]
    me = d.user_id
    # authorId is the PublicHasherId, not the account id; "ours" is a reply
    # that carries the tag, which is the only thing this tool ever writes.
    last_ours_seq = max((m["sequenceCount"] for m in msgs
                         if str(m.get("text", "")).startswith(TAG)), default=None)
    out = []
    for m in msgs:
        out.append({
            "seq": m.get("sequenceCount"),
            "id": str(m.get("id", "")).lower(),
            "at": time.strftime("%Y-%m-%d %H:%M:%SZ",
                                time.gmtime((m.get("createdAt") or 0) / 1000)),
            "author": m.get("authorFirstName"),
            "authorPublicId": str(m.get("authorId", "")).lower(),
            "ours": str(m.get("text", "")).startswith(TAG),
            "answered": bool(last_ours_seq and m["sequenceCount"] <= last_ours_seq),
            "replyTo": (str(m.get("replyToMessageId")).lower()
                        if m.get("replyToMessageId") else None),
            "kind": m.get("messageKind"),
            "text": m.get("text"),
        })
    print(json.dumps({"roomType": d.room_type, "since": since,
                      "count": len(out), "messages": out},
                     indent=1, ensure_ascii=False, default=str))
    if msgs and not args.no_advance:
        state["lastSeq"] = max(state.get("lastSeq") or 0,
                               max(m["sequenceCount"] for m in msgs))
        state_path.write_text(json.dumps(state), encoding="utf-8")
    _ = me
    return 0


def cmd_send(args: argparse.Namespace) -> int:
    d = Device()
    text = args.text.strip()
    if not text.startswith(TAG):
        text = f"{TAG} {text}"
    if len(text) > MAX_MESSAGE:
        sys.exit(f"reply is {len(text)} characters; the room takes {MAX_MESSAGE}")
    rowsets = d.call("sendRoomMessage", roomType=d.room_type,
                     messageId=str(uuid.uuid4()), messageContent=text,
                     messageKind=0,
                     replyToMessageId=(args.reply_to.lower() if args.reply_to else None))
    sent = next((r for rs in rowsets for r in rs if "sequenceCount" in r), None)
    print(json.dumps({"sent": True, "seq": sent.get("sequenceCount") if sent else None,
                      "chars": len(text)}, default=str))
    return 0


def cmd_mark_read(_: argparse.Namespace) -> int:
    d = Device()
    d.call("getRoomMessages", roomType=d.room_type, markRead=1)
    print(json.dumps({"markedRead": True}))
    return 0


def main(argv: list[str]) -> int:
    load_dotenv()
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)
    r = sub.add_parser("register"); r.add_argument("--user-id", required=True)
    r.add_argument("--name", default="Claude beta-room assistant"); r.set_defaults(fn=cmd_register)
    sub.add_parser("rooms").set_defaults(fn=cmd_rooms)
    po = sub.add_parser("poll"); po.add_argument("--since", type=int)
    po.add_argument("--all", action="store_true")
    po.add_argument("--state", default="~/.hc_beta_room_state.json")
    po.add_argument("--no-advance", action="store_true",
                    help="do not move the watermark")
    po.set_defaults(fn=cmd_poll)
    s = sub.add_parser("send"); s.add_argument("text"); s.add_argument("--reply-to")
    s.set_defaults(fn=cmd_send)
    sub.add_parser("mark-read").set_defaults(fn=cmd_mark_read)
    args = p.parse_args(argv)
    try:
        return args.fn(args)
    except ApiError as e:
        sys.exit(f"API refused: {e}")


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
