#!/usr/bin/env python3
"""Render App Store screenshots from raw simulator captures.

    python3 store/compose.py iphone69                # 1320x2868  (iPhone 6.9")
    python3 store/compose.py ipad13                  # 2064x2752  (iPad 13")
    python3 store/compose.py ipad13 --transparent    # same, alpha background

NOTE: --transparent is NOT for App Store Connect. Apple rejects screenshots
carrying an alpha channel (a hidden alpha passes a visual check and fails
Apple's parser), so upload the flattened set from out/ and keep the alpha
copies in out/transparent/ for other uses.

Reads store/raw/<device>/<file>.png if present (device-specific captures, e.g.
raw/ipad13/), else store/raw/<file>.png; writes store/out/<device>_NN.png via
headless Chrome. Edit SLIDES below —
(raw file, headline, sub) or (raw file, None, None) for a full-bleed slide.
Only the standard library is needed; Chrome does the rendering.
"""
import os, subprocess, sys

DEVICES = {
    "iphone69": (1320, 2868),   # App Store, iPhone 6.9"
    "ipad13": (2064, 2752),     # App Store, iPad 13"
    # In-app version-promo deck (splash). NOT an App Store size: it matches the
    # existing version_3.0_*.avif slides in the splash-sequences container.
    # Always rendered transparent — the deck composites slides over the app's
    # own Backgrounds.defaultHcBackground(), and there is no
    # version_3.0_background.avif, so any baked-in background would double up.
    # Slide 1 of the deck is the original welcome artwork
    # (mobile-app/images/promo/version_3.0_1.avif) and is NOT regenerated here:
    # raw/01_welcome_3_0.png is a screen CAPTURE of that slide, so composing it
    # would re-bake the background and the status bar. SLIDES[1:] therefore maps
    # to deck slides 2..N.
    "splash": (1170, 2532),
}
# Vertical composition, as a fraction of canvas height. Text starts at
# SAFE_TOP_FRAC; the device frame starts at PHONE_TOP_FRAC and runs off the
# bottom on purpose. Raise both together to move the whole composition down.
SAFE_TOP_FRAC = 0.105
PHONE_TOP_FRAC = 0.325
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
FONT_HEAVY = os.path.join(REPO, "mobile-app/fonts/AvenirNext-Heavy.ttf")
FONT_BOLD = os.path.join(REPO, "mobile-app/fonts/AvenirNext-Bold.ttf")
BG = os.path.join(REPO, "public-web/public/images/jungle_background.jpg")

SLIDES = [
    ("01_welcome_3_0.png", None, None),
    ("22_2108_list.png", "Watch the<br>pack live", "See where the pack is on the map in real time — and replay any run afterwards."),
    ("23_2108_photo_lightbox.png", "Meet the<br>Hash Flash", "Snap photos on trail. The best ones land on the map for the whole pack."),
    ("03_runs_list.png", "Every hash,<br>one app", "Runs near you, kennels you follow, and RSVP in a single tap."),
    ("25_explore_world.png", "Hash anywhere<br>on Earth", "Find a run around the corner or across the globe — instantly."),
    ("19_2108_rsvp.png", "Your run day,<br>sorted", "Check in as you arrive, see who's coming, chat with the pack."),
    ("06_history.png", "Your run counts,<br>kept safe", "Every kennel, every hare, every run — stored securely in the cloud."),
    ("07_songs.png", "Down downs,<br>digitised", "Songs picked for sinners. Charges made in the circle. Remembered forever."),
]


def raw_path(device, shot):
    """Device-specific capture (raw/<device>/<shot>) wins over the shared raw/<shot>."""
    specific = os.path.join(HERE, "raw", device, shot)
    return specific if os.path.exists(specific) else os.path.join(HERE, "raw", shot)


def page(device, shot, headline, sub, transparent=False):
    W, H = DEVICES[device]
    raw = raw_path(device, shot)
    if headline is None:
        return (f'<!doctype html><html><head><meta charset="utf-8"><style>html,body{{margin:0;width:{W}px;height:{H}px;'
                f'overflow:hidden;background:{"transparent" if transparent else "#0c2a0e"}}}'
                f'img{{width:{W}px;height:{H}px;display:block}}</style></head>'
                f'<body><img src="file://{raw}"></body></html>')
    # Scale every metric off the iPhone 6.9" design. Width-scaling alone
    # overflows the headline block on the squarer iPad canvas (the sub-line
    # ended up hidden behind the device frame), so cap by height too —
    # iPhone stays exactly k=1.
    k = min(W / 1320, H / 2868 * 1.25)
    # Vertical safe area. The headline used to start at 5% of the height, which
    # sits in the band the App Store can crop when it scales one screenshot set
    # across device classes — and it simply reads as jammed against the top
    # edge. Keep all TEXT inside the middle of the canvas; the device frame is
    # deliberately allowed to bleed off the bottom (nothing readable is there).
    safe_top = int(H * SAFE_TOP_FRAC)
    frame_w, frame_top = int(W * 0.864), int(H * PHONE_TOP_FRAC)
    # iPad corners are much tighter relative to the screen than an iPhone's.
    r_outer, r_inner = (int(170 * k), int(146 * k)) if device == "iphone69" else (int(110 * k), int(90 * k))
    return f"""<!doctype html><html><head><meta charset="utf-8"><style>
@font-face{{font-family:AvH;src:url(file://{FONT_HEAVY})}} @font-face{{font-family:AvB;src:url(file://{FONT_BOLD})}}
html,body{{margin:0;width:{W}px;height:{H}px;overflow:hidden}}
body{{background:{"transparent" if transparent else f"#0c2a0e url(file://{BG})"};background-size:{int(720*k)}px;position:relative;font-family:AvB,system-ui,sans-serif;color:#fff}}
.shade{{position:absolute;inset:0;background:linear-gradient(180deg,rgba(0,0,0,.30) 0%,rgba(0,0,0,0) 32%,rgba(0,0,0,0) 70%,rgba(0,0,0,.45) 100%)}}
.head{{position:absolute;top:{safe_top}px;left:{int(80*k)}px;right:{int(80*k)}px;text-align:center}}
.h1{{font-family:AvH;font-size:{int(122*k)}px;line-height:1.0;letter-spacing:-1px;text-transform:uppercase;
  background:linear-gradient(180deg,#ffd76a 0%,#f5a623 55%,#e0651e 100%);-webkit-background-clip:text;color:transparent;
  filter:drop-shadow(0 {int(8*k)}px 0 rgba(0,0,0,.55)) drop-shadow(0 {int(18*k)}px {int(30*k)}px rgba(0,0,0,.5));transform:rotate(-3deg);padding:10px 0}}
.sub{{margin:{int(40*k)}px {int(40*k)}px 0;font-size:{int(50*k)}px;line-height:1.25;text-shadow:0 4px 14px rgba(0,0,0,.85)}}
.phone{{position:absolute;left:50%;top:{frame_top}px;transform:translateX(-50%);width:{frame_w}px;height:{H}px;border-radius:{r_outer}px;
  background:#111;padding:{int(26*k)}px;box-sizing:border-box;box-shadow:0 60px 120px rgba(0,0,0,.7),inset 0 0 0 4px #3a3a3a}}
.screen{{width:100%;height:100%;border-radius:{r_inner}px;overflow:hidden;background:#000}}
.screen img{{width:100%;height:auto;display:block}}
</style></head><body>{"" if transparent else '<div class="shade"></div>'}
<div class="head"><div class="h1">{headline}</div><div class="sub">{sub}</div></div>
<div class="phone"><div class="screen"><img src="file://{raw}"></div></div>
</body></html>"""


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("-")]
    device = args[0] if args else "iphone69"
    # The splash deck is transparent by definition, not by flag.
    transparent = "--transparent" in sys.argv or device == "splash"
    W, H = DEVICES[device]
    if device == "splash":
        out_dir = os.path.join(HERE, "out", "splash")
    elif transparent:
        out_dir = os.path.join(HERE, "out", "transparent")
    else:
        out_dir = os.path.join(HERE, "out")
    os.makedirs(os.path.join(HERE, "html"), exist_ok=True); os.makedirs(out_dir, exist_ok=True)
    for i, (shot, h, s) in enumerate(SLIDES, 1):
        if device == "splash" and i == 1:
            print("skip 1: deck slide 1 is the original welcome art "
                  "(images/promo/version_3.0_1.avif), not recomposed"); continue
        if not os.path.exists(raw_path(device, shot)):
            print(f"skip {i}: raw/{shot} missing"); continue
        suffix = "_alpha" if transparent else ""
        html = os.path.join(HERE, "html", f"{device}_{i:02d}{suffix}.html")
        open(html, "w").write(page(device, shot, h, s, transparent))
        out = os.path.join(out_dir, f"{device}_{i:02d}.png")
        cmd = [CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=1",
               f"--window-size={W},{H}", f"--screenshot={out}", f"file://{html}"]
        if transparent:
            # Chrome paints white behind the page unless told the default
            # background is fully transparent (RRGGBBAA).
            cmd.insert(1, "--default-background-color=00000000")
        subprocess.run(cmd, capture_output=True)
        print("rendered", os.path.relpath(out, HERE))


if __name__ == "__main__":
    main()
