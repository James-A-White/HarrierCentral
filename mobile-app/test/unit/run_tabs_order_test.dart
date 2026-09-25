import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/imports.dart';

/// The run page decides which tab is showing by POSITION (RunTab ids), not by
/// reading a tab's label back: that read returned null once the labels became
/// `child:` widgets (28b89472), and the RSVP tab spun forever (2026-09-25).
/// This pins the one thing position-based lookup depends on — the tab list and
/// RunTab stay the same length and every id resolves.
void main() {
  test('every tab position maps to a RunTab, in order', () {
    expect(RunTabsController.tabs.length, RunTab.values.length);
    for (int i = 0; i < RunTabsController.tabs.length; i++) {
      expect(RunTab.fromId(i).id, i);
    }
    expect(RunTab.fromId(1), RunTab.rsvp);
    expect(RunTab.fromId(4), RunTab.chat);
  });
}
