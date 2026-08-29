# Shared by the sim*.sh helpers. Needs a venv with pyobjc-framework-Quartz:
#   python3 -m venv store/venv && store/venv/bin/pip install pyobjc-framework-Quartz
PY="${SIM_PY:-${0:A:h}/venv/bin/python}"
sim_window() { osascript -e 'tell application "System Events" to tell process "Simulator" to get {position, size} of window 1' | tr -d ','; }
sim_screen_px() { xcrun simctl io "${SIM_UDID:-booted}" screenshot /tmp/_simsz.png >/dev/null 2>&1; sips -g pixelWidth -g pixelHeight /tmp/_simsz.png | awk '/pixel/ {printf "%s ", $2}'; echo; }
