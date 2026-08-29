#!/bin/zsh
# simtap.sh <px_x> <px_y> — tap the booted Simulator at device-PIXEL coords (the
# coordinate space of `xcrun simctl io booted screenshot`). Posts a real mouse
# down/up through Quartz, so the terminal app needs Accessibility rights
# (System Settings → Privacy & Security → Accessibility). Works with the
# Simulator window at any zoom; assumes Window → Show Device Bezels is OFF
# unless SIM_INSETS is set (left,top,right,bottom in window points — the
# iPhone 17 Pro Max at 100% with bezels on is "27,35,27,35").
set -e
DIR=${0:A:h}; source "$DIR/simenv.sh"
read PW PH <<< "$(sim_screen_px)"
read WX WY WW WH <<< "$(sim_window)"
IFS=, read IL IT IR IB <<< "${SIM_INSETS:-0,0,0,0}"
CW=$(( WW - IL - IR )); CH=$(( WH - 28 - IT - IB ))          # 28 = macOS title bar
X=$(( WX + IL + $1 * CW / PW )); Y=$(( WY + 28 + IT + $2 * CH / PH ))
"$PY" - "$X" "$Y" <<'PY'
import sys, time, Quartz
x, y = float(sys.argv[1]), float(sys.argv[2])
def ev(t): Quartz.CGEventPost(Quartz.kCGHIDEventTap, Quartz.CGEventCreateMouseEvent(None, t, (x, y), 0))
ev(Quartz.kCGEventMouseMoved); time.sleep(0.05); ev(Quartz.kCGEventLeftMouseDown); time.sleep(0.08); ev(Quartz.kCGEventLeftMouseUp)
PY
echo "tap px($1,$2) -> screen($X,$Y)"
