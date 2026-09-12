import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/widgets/sweep_message.dart';

/// 3.0.31 shipped this state hugging the left edge. A Column takes the width
/// of its widest child rather than filling, so inside a Padding it sits on the
/// left and its crossAxisAlignment centres the children against each other
/// instead of against the screen.
void main() {
  const double screenWidth = 400;

  Widget host(Widget child) => MaterialApp(
    home: Scaffold(
      body: SizedBox(width: screenWidth, height: 800, child: child),
    ),
  );

  testWidgets('the text is centred on the screen, not on itself', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      host(const SweepMessage(text: 'Looking through your photos…')),
    );
    await tester.pumpAndSettle();

    final Rect r = tester.getRect(find.text('Looking through your photos…'));
    expect(
      r.center.dx,
      closeTo(screenWidth / 2, 1),
      reason: 'the message drifted off centre',
    );
  });

  testWidgets('the spinner sits on the same centre line as the text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      host(const SweepMessage(text: 'Checking your runs…', spinner: true)),
    );
    await tester.pump(const Duration(milliseconds: 50));

    final Rect spinner = tester.getRect(
      find.byType(CircularProgressIndicator),
    );
    final Rect text = tester.getRect(find.text('Checking your runs…'));
    expect(spinner.center.dx, closeTo(screenWidth / 2, 1));
    expect(text.center.dx, closeTo(screenWidth / 2, 1));
    expect(
      spinner.bottom,
      lessThan(text.top),
      reason: 'the spinner belongs above the message',
    );
  });

  testWidgets('a long message wraps inside the screen rather than overflowing',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      host(
        const SweepMessage(
          text:
              'No photos from your camera roll match this run. A photo has to '
              'carry a location as well as a time — one without a location '
              'cannot be placed on the trail, so it is left alone.',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final Rect r = tester.getRect(find.byType(Text).first);
    expect(r.left, greaterThanOrEqualTo(0));
    expect(r.right, lessThanOrEqualTo(screenWidth));
  });
}
