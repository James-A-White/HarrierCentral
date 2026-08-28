#!/Users/jawDev/.playstore/venv/bin/python
"""Upload an Android App Bundle to a Google Play testing track.

The Android equivalent of `xcrun altool` in the iOS dance. Uses the
play-publisher service account (invited to Play Console with "Release apps
to testing tracks" on Harrier Central).

Usage:
    tools/play_upload.py --validate
        Auth round-trip only: opens and abandons an edit. Proves the key
        and Play Console invite work without touching anything.

    tools/play_upload.py --aab path/to/app-release.aab \
        [--track internal] [--notes "What changed"]
        Uploads the bundle, assigns it to the track as a completed rollout,
        and commits. Prints the versionCode Play extracted from the bundle.

    tools/play_upload.py --send-for-review [--track internal] [--version-code N]
        Submits a staged ("not sent for review") release for review by
        re-applying the track release and committing normally. As of
        2026-08-28 Play REFUSES this for Harrier Central (400 "Changes
        cannot be sent for review automatically") — submission is
        Console-only: Publishing overview → "Send changes for review".
        Kept as the cheap way to re-check whether that ever changes.

Credentials: ~/.playstore/play-publisher.json (chmod 600, never in git).
Interpreter: the shebang pins the venv at ~/.playstore/venv, which holds
google-api-python-client — run the script directly, not via bare python3.
"""

import argparse
import sys

from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from googleapiclient.http import MediaFileUpload

PACKAGE = "com.harriercentral.app"
KEY_PATH = "/Users/jawDev/.playstore/play-publisher.json"
SCOPES = ["https://www.googleapis.com/auth/androidpublisher"]


def service():
    creds = service_account.Credentials.from_service_account_file(
        KEY_PATH, scopes=SCOPES
    )
    return build("androidpublisher", "v3", credentials=creds)


def validate() -> int:
    svc = service()
    edit = svc.edits().insert(packageName=PACKAGE, body={}).execute()
    edit_id = edit["id"]
    tracks = (
        svc.edits()
        .tracks()
        .list(packageName=PACKAGE, editId=edit_id)
        .execute()
    )
    names = [t.get("track") for t in tracks.get("tracks", [])]
    svc.edits().delete(packageName=PACKAGE, editId=edit_id).execute()
    print(f"AUTH OK — edit opened and abandoned. Tracks visible: {names}")
    return 0


def upload(aab: str, track: str, notes: str | None) -> int:
    svc = service()
    edit_id = svc.edits().insert(packageName=PACKAGE, body={}).execute()["id"]
    print(f"edit {edit_id} opened; uploading {aab} …")

    media = MediaFileUpload(
        aab,
        mimetype="application/octet-stream",
        chunksize=8 * 1024 * 1024,
        resumable=True,
    )
    request = (
        svc.edits()
        .bundles()
        .upload(packageName=PACKAGE, editId=edit_id, media_body=media)
    )
    response = None
    while response is None:
        status, response = request.next_chunk()
        if status:
            print(f"  {int(status.progress() * 100)}%", flush=True)
    version_code = response["versionCode"]
    print(f"uploaded — Play reports versionCode {version_code}")

    release = {
        "versionCodes": [str(version_code)],
        "status": "completed",
    }
    if notes:
        release["releaseNotes"] = [{"language": "en-GB", "text": notes}]
    svc.edits().tracks().update(
        packageName=PACKAGE,
        editId=edit_id,
        track=track,
        body={"track": track, "releases": [release]},
    ).execute()

    try:
        committed = (
            svc.edits().commit(packageName=PACKAGE, editId=edit_id).execute()
        )
        print(
            f"COMMITTED — versionCode {version_code} live on the '{track}' "
            f"track (edit {committed['id']})."
        )
    except HttpError as e:
        # Play refuses auto-submission while the app has an outstanding
        # console task (e.g. missing privacy policy). Commit WITHOUT sending
        # for review — the release then waits in the Console for a manual
        # "send for review" once the task is cleared. Without this retry the
        # edit is abandoned and the upload silently lands nowhere.
        if "changesNotSentForReview" not in str(e):
            raise
        committed = (
            svc.edits()
            .commit(
                packageName=PACKAGE,
                editId=edit_id,
                changesNotSentForReview=True,
            )
            .execute()
        )
        print(
            f"COMMITTED (not sent for review) — versionCode {version_code} "
            f"staged on the '{track}' track (edit {committed['id']}). "
            f"Send for review manually in the Play Console."
        )
    return 0


def send_for_review(track: str, version_code: int | None) -> int:
    """Submit a previously staged ("not sent for review") release for review.

    Play has no "submit" call — review submission is a side effect of
    committing an edit WITHOUT changesNotSentForReview. An empty edit can't be
    committed, so re-apply the track's current release (optionally pinned to
    one versionCode) and commit normally. If the Console still has an
    outstanding task, Play refuses with the same error the upload path sees;
    the message names the task and the release stays staged.
    """
    svc = service()
    edit_id = svc.edits().insert(packageName=PACKAGE, body={}).execute()["id"]
    current = (
        svc.edits()
        .tracks()
        .get(packageName=PACKAGE, editId=edit_id, track=track)
        .execute()
    )
    releases = current.get("releases", [])
    if version_code is not None:
        releases = [
            r for r in releases if str(version_code) in r.get("versionCodes", [])
        ]
    if not releases:
        svc.edits().delete(packageName=PACKAGE, editId=edit_id).execute()
        print(
            f"nothing to submit — no release on '{track}' "
            f"{'for versionCode ' + str(version_code) if version_code else ''}",
            file=sys.stderr,
        )
        return 1
    codes = [c for r in releases for c in r.get("versionCodes", [])]
    svc.edits().tracks().update(
        packageName=PACKAGE,
        editId=edit_id,
        track=track,
        body={"track": track, "releases": releases},
    ).execute()
    committed = svc.edits().commit(packageName=PACKAGE, editId=edit_id).execute()
    print(
        f"SENT FOR REVIEW — versionCode(s) {codes} on the '{track}' track "
        f"(edit {committed['id']})."
    )
    return 0


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--validate", action="store_true")
    p.add_argument("--aab")
    p.add_argument("--track", default="internal")
    p.add_argument("--notes")
    p.add_argument(
        "--send-for-review",
        action="store_true",
        help="Submit the track's staged release for review (no upload).",
    )
    p.add_argument(
        "--version-code",
        type=int,
        help="With --send-for-review: only this versionCode's release.",
    )
    args = p.parse_args()

    try:
        if args.validate:
            return validate()
        if args.send_for_review:
            return send_for_review(args.track, args.version_code)
        if not args.aab:
            p.error("--aab required unless --validate/--send-for-review")
        return upload(args.aab, args.track, args.notes)
    except HttpError as e:
        print(f"Play API error: {e.status_code} — {e.reason}", file=sys.stderr)
        if e.status_code == 401 or e.status_code == 403:
            print(
                "Check the Play Console invite: Users and permissions → the "
                "service account needs 'Release apps to testing tracks' on "
                "Harrier Central.",
                file=sys.stderr,
            )
        return 1


if __name__ == "__main__":
    sys.exit(main())
