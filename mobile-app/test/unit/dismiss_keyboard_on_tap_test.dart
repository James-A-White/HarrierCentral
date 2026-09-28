import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/widgets/dismiss_keyboard_on_tap.dart';

/// Payment options' top up held the keyboard up with no way down (Kilty as
/// Charged, 2026-09-28). A tap on empty space must put it away; a tap on a
/// button or the field itself must not.
void main() {
  late FocusNode node;
  var pressed = 0;

  Future<void> pump(WidgetTester tester) async {
    node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => DismissKeyboardOnTap(child: child!),
      home: Scaffold(
        body: Column(children: [
          TextField(focusNode: node, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          ElevatedButton(onPressed: () => pressed++, child: const Text('Save')),
          const SizedBox(height: 300, width: 300, key: Key('empty')),
        ]),
      ),
    ));
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(node.hasFocus, isTrue);
  }

  testWidgets('a tap on empty space puts the keyboard away', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('empty')));
    await tester.pump();
    expect(node.hasFocus, isFalse);
  });

  testWidgets('a button still works and the field keeps focus', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(pressed, greaterThan(0));
    expect(node.hasFocus, isTrue);
  });

  testWidgets('tapping the field itself keeps the keyboard', (tester) async {
    await pump(tester);
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(node.hasFocus, isTrue);
  });
}
