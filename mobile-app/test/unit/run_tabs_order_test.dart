import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/imports.dart';

/// The run page decides which tab is showing by POSITION (RunTab tabIndex),
/// not by reading a tab's label back: that read returned null once the labels
/// became `child:` widgets (28b89472), and the RSVP tab spun forever
/// (2026-09-25). This pins the one thing position-based lookup depends on —
/// every tab position resolves to a RunTab, in order.
///
/// RunTab.chat is not a tab since 2026-10-11: the chat opens over the page
/// from the app bar, so it has no position and the bar has one fewer tab.
void main() {
  test('every tab position maps to a RunTab, in order', () {
    final List<RunTab> tabbed = RunTab.values
        .where((RunTab t) => t.tabIndex != null)
        .toList();
    expect(RunTabsController.tabs.length, tabbed.length);
    for (int i = 0; i < RunTabsController.tabs.length; i++) {
      expect(RunTab.fromIndex(i).tabIndex, i);
    }
    expect(RunTab.fromIndex(1), RunTab.rsvp);
    expect(RunTab.fromIndex(4), RunTab.photos);
  });

  test('the chat has no tab position', () {
    expect(RunTab.chat.tabIndex, isNull);
    expect(() => RunTab.fromIndex(5), throwsArgumentError);
  });
}
