#!/usr/bin/env python3
"""Replace the App Store screenshots on the app's editable version.

    python3 store/asc_upload.py            # dry run: show what would change
    python3 store/asc_upload.py --apply    # delete existing sets, upload out/

Uploads out/iphone69_*.png and out/ipad13_*.png to the version currently in an
editable state (PREPARE_FOR_SUBMISSION / DEVELOPER_REJECTED / REJECTED etc.).
The live version's screenshots are untouched — each appStoreVersion owns its own.

Needs `pyjwt` + `cryptography` and the same App Store Connect key that ships
builds (~/.appstoreconnect/private_keys/AuthKey_7YDRYBL5KS.p8).

Display-type gotcha (cost a 409 the first time, 2026-08-29):
  * There is NO 'APP_IPHONE_69'. The 6.9" set — 1320x2868 — goes into
    'APP_IPHONE_67'.
  * There is NO 'APP_IPAD_13'. The 13" set — 2064x2752 — goes into
    'APP_IPAD_PRO_3GEN_129'.
  * A localization holds at most ONE set per display type, so an occupied slot
    must be deleted before a new set of that type can be created.
Ask the API for the current list by POSTing a bogus screenshotDisplayType: the
409 body enumerates every valid value.
"""
import hashlib, json, os, sys, time, urllib.error, urllib.request
import jwt

KEY_ID = "7YDRYBL5KS"
ISSUER = "69a6de72-4b20-47e3-e053-5b8c7c11a4d1"
KEY_PATH = "~/.appstoreconnect/private_keys/AuthKey_7YDRYBL5KS.p8"
BUNDLE_ID = "com.harriercentral.app"
BASE = "https://api.appstoreconnect.apple.com"
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "out")
EDITABLE = {"PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED",
            "METADATA_REJECTED", "INVALID_BINARY", "WAITING_FOR_REVIEW"}
# (local glob prefix, display type, expected WxH)
SETS = [("iphone69", "APP_IPHONE_67", (1320, 2868)),
        ("ipad13", "APP_IPAD_PRO_3GEN_129", (2064, 2752))]


def token():
    key = open(os.path.expanduser(KEY_PATH)).read()
    return jwt.encode({"iss": ISSUER, "exp": int(time.time()) + 900,
                       "aud": "appstoreconnect-v1"}, key,
                      algorithm="ES256", headers={"kid": KEY_ID, "typ": "JWT"})


def api(method, path, body=None):
    url = path if path.startswith("http") else BASE + path
    headers = {"Authorization": "Bearer " + token()}
    data = None
    if body is not None:
        data = json.dumps(body).encode(); headers["Content-Type"] = "application/json"
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as r:
            payload = r.read()
            return json.loads(payload) if payload else None
    except urllib.error.HTTPError as e:
        sys.exit(f"{method} {path} -> {e.code}\n{e.read().decode()[:800]}")


def upload_set(lid, prefix, display_type, files):
    st = api("POST", "/v1/appScreenshotSets", {"data": {
        "type": "appScreenshotSets",
        "attributes": {"screenshotDisplayType": display_type},
        "relationships": {"appStoreVersionLocalization": {
            "data": {"type": "appStoreVersionLocalizations", "id": lid}}}}})
    sid = st["data"]["id"]
    ordered = []
    for path in files:
        name = os.path.basename(path)
        blob = open(path, "rb").read()
        res = api("POST", "/v1/appScreenshots", {"data": {
            "type": "appScreenshots",
            "attributes": {"fileName": name, "fileSize": len(blob)},
            "relationships": {"appScreenshotSet": {
                "data": {"type": "appScreenshotSets", "id": sid}}}}})
        shot_id = res["data"]["id"]
        for op in res["data"]["attributes"]["uploadOperations"]:
            chunk = blob[op["offset"]:op["offset"] + op["length"]]
            hdrs = {h["name"]: h["value"] for h in op.get("requestHeaders", [])}
            urllib.request.urlopen(urllib.request.Request(
                op["url"], data=chunk, headers=hdrs, method=op["method"])).read()
        api("PATCH", f"/v1/appScreenshots/{shot_id}", {"data": {
            "type": "appScreenshots", "id": shot_id,
            "attributes": {"uploaded": True,
                           "sourceFileChecksum": hashlib.md5(blob).hexdigest()}}})
        ordered.append(shot_id)
        print(f"    uploaded {name} ({len(blob) // 1024} KB)")
    # Without this the carousel order is whatever the API felt like.
    api("PATCH", f"/v1/appScreenshotSets/{sid}/relationships/appScreenshots",
        {"data": [{"type": "appScreenshots", "id": i} for i in ordered]})
    print(f"    order locked ({len(ordered)} screenshots)")


def main():
    apply = "--apply" in sys.argv
    app = api("GET", f"/v1/apps?filter[bundleId]={BUNDLE_ID}")["data"][0]
    versions = api("GET", f"/v1/apps/{app['id']}/appStoreVersions?limit=10")["data"]
    editable = [v for v in versions if v["attributes"]["appStoreState"] in EDITABLE]
    if not editable:
        sys.exit("No editable App Store version — create one in App Store Connect first.")
    ver = editable[0]
    print(f"app: {app['attributes']['name']}   version: "
          f"{ver['attributes']['versionString']} ({ver['attributes']['appStoreState']})")

    locs = api("GET", f"/v1/appStoreVersions/{ver['id']}/appStoreVersionLocalizations")["data"]
    for loc in locs:
        lid, locale = loc["id"], loc["attributes"]["locale"]
        existing = api("GET", f"/v1/appStoreVersionLocalizations/{lid}/appScreenshotSets")["data"]
        print(f"\n{locale}: {len(existing)} existing set(s) "
              f"{[s['attributes']['screenshotDisplayType'] for s in existing]}")
        for prefix, display_type, (w, h) in SETS:
            files = sorted(f"{OUT}/{prefix}_{i:02d}.png" for i in range(1, 11)
                           if os.path.exists(f"{OUT}/{prefix}_{i:02d}.png"))
            print(f"  {display_type} <- {len(files)} x {prefix}_*.png ({w}x{h})")
        if not apply:
            print("  (dry run — pass --apply to delete the existing sets and upload)")
            continue
        for s in existing:
            api("DELETE", f"/v1/appScreenshotSets/{s['id']}")
            print(f"  deleted {s['attributes']['screenshotDisplayType']}")
        for prefix, display_type, _ in SETS:
            files = sorted(f"{OUT}/{prefix}_{i:02d}.png" for i in range(1, 11)
                           if os.path.exists(f"{OUT}/{prefix}_{i:02d}.png"))
            if not files:
                print(f"  skip {display_type}: no {prefix}_*.png in out/"); continue
            print(f"  {display_type}:")
            upload_set(lid, prefix, display_type, files)


if __name__ == "__main__":
    main()
