import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The run editor's save bar is a bottomNavigationBar, which is given
/// unbounded height. On 2026-10-09 a Center inside it filled the screen and
/// the editor vanished behind a yellow wall with two buttons. This pins the
/// shape of the fix: the bar must size to its content.
Widget bar(bool twoButtons) => Container(
  constraints: const BoxConstraints(minHeight: 70.0),
  color: Colors.yellow[100],
  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
  child: Column(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: <Widget>[
      twoButtons
          ? Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: <Widget>[
                ElevatedButton(onPressed: () {}, child: const Text('Save')),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.send),
                  label: const Text('Save and send'),
                ),
              ],
            )
          : SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: () {}, child: const Text('Next')),
            ),
    ],
  ),
);

void main() {
  for (final bool two in <bool>[true, false]) {
    testWidgets('save bar (${two ? 'two buttons' : 'one'}) leaves the editor on screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Center(child: Text('editor')),
            bottomNavigationBar: bar(two),
          ),
        ),
      );
      final Size barSize = tester.getSize(find.byType(Container).first);
      expect(barSize.height, lessThan(140));
      expect(barSize.height, greaterThanOrEqualTo(70));
      expect(find.text('editor'), findsOneWidget);
    });
  }
}
