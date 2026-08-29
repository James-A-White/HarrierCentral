import Foundation
import CoreGraphics
// usage: pinch cx cy startOffset endOffset  — Simulator pinch: Option held while dragging
let a = CommandLine.arguments
let cx = Double(a[1])!, cy = Double(a[2])!, s = Double(a[3])!, e = Double(a[4])!
let opt: CGEventFlags = .maskAlternate
func post(_ t: CGEventType, _ p: CGPoint) {
  let ev = CGEvent(mouseEventSource: nil, mouseType: t, mouseCursorPosition: p, mouseButton: .left)!
  ev.flags = opt; ev.post(tap: .cghidEventTap)
}
// press Option (virtual keycode 58)
let kd = CGEvent(keyboardEventSource: nil, virtualKey: 58, keyDown: true)!; kd.flags = opt; kd.post(tap: .cghidEventTap)
usleep(200000)
post(.mouseMoved, CGPoint(x: cx + s, y: cy + s)); usleep(300000)
post(.leftMouseDown, CGPoint(x: cx + s, y: cy + s)); usleep(150000)
let steps = 30
for i in 1...steps {
  let f = Double(i) / Double(steps); let o = s + (e - s) * f
  post(.leftMouseDragged, CGPoint(x: cx + o, y: cy + o)); usleep(30000)
}
post(.leftMouseUp, CGPoint(x: cx + e, y: cy + e)); usleep(150000)
let ku = CGEvent(keyboardEventSource: nil, virtualKey: 58, keyDown: false)!; ku.post(tap: .cghidEventTap)
