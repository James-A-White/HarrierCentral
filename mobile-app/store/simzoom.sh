#!/bin/zsh
# simzoom.sh <out|in> [ticks] — zoom a Google Map in the Simulator with scroll-wheel
# events at the window centre. (Option-drag pinch does NOT work through Quartz —
# the modifier isn't honoured and the gesture becomes a pan.)
DIR=${0:A:h}; source "$DIR/simenv.sh"
read WX WY WW WH <<< "$(sim_window)"
"$PY" - "$1" "${2:-10}" "$(( WX + WW / 2 ))" "$(( WY + WH / 2 ))" <<'PY'
import sys, time, Quartz
mode, n, cx, cy = sys.argv[1], int(sys.argv[2]), float(sys.argv[3]), float(sys.argv[4])
Quartz.CGEventPost(Quartz.kCGHIDEventTap, Quartz.CGEventCreateMouseEvent(None, Quartz.kCGEventMouseMoved, (cx, cy), 0)); time.sleep(0.3)
for _ in range(n):
    Quartz.CGEventPost(Quartz.kCGHIDEventTap, Quartz.CGEventCreateScrollWheelEvent(None, Quartz.kCGScrollEventUnitLine, 1, -3 if mode == "out" else 3)); time.sleep(0.08)
PY
