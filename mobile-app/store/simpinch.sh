#!/bin/zsh
# simpinch.sh <px_x> <px_y> <start> <end> — pinch on the booted Simulator at
# device-PIXEL coords (same space as simtap.sh). Holds Option and drags one
# finger from centre+start to centre+end, which the Simulator mirrors into a
# two-finger pinch: start>end zooms OUT, start<end zooms IN. Offsets are Mac
# screen points; 220→30 is roughly "city to whole world", 30→150 one level in.
# Needs a real CGEvent source with the modifier flag set on the mouse events —
# pyobjc/Quartz drops it (see README) — so this compiles a tiny Swift helper
# on first use. Assumes Show Device Bezels is OFF, like simtap.sh.
set -e
DIR=${0:A:h}; source "$DIR/simenv.sh"
[[ -x "$DIR/venv/simpinch" ]] || swiftc -O -o "$DIR/venv/simpinch" "$DIR/simpinch.swift"
read PW PH <<< "$(sim_screen_px)"
read WX WY WW WH <<< "$(sim_window)"
IFS=, read IL IT IR IB <<< "${SIM_INSETS:-0,0,0,0}"
CW=$(( WW - IL - IR )); CH=$(( WH - 28 - IT - IB ))
X=$(( WX + IL + $1 * CW / PW )); Y=$(( WY + 28 + IT + $2 * CH / PH ))
osascript -e 'tell application "Simulator" to activate' >/dev/null; sleep 0.5
"$DIR/venv/simpinch" "$X" "$Y" "$3" "$4"
echo "pinch px($1,$2) $3->$4"
