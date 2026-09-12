import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/pages/menu_pages/import_gpx_page.dart';
import 'package:harrier_central/services/import/track_import_service.dart';

/// 3.0.29 shipped this card with the buttons off screen and the text rendering
/// one character per line: a Column with CrossAxisAlignment.stretch sat
/// directly in a Row, which lays non-flexible children out with unbounded
/// width, so stretch had nothing finite to resolve against.
void main() {
  Widget host(Widget child, {double width = 400}) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(width: width, child: child),
      ),
    ),
  );

  PreviousUploadCard card() => PreviousUploadCard(
    job: TrackImportJob(
      jobId: 'a',
      fileName: 'export_136212686.zip',
      status: 2,
      kind: 0,
      nextIndex: 0,
      activities: const <ImportActivity>[],
      uploadedAt: DateTime.utc(2026, 9, 11, 9, 48),
      activityCount: 249,
      importedCount: 1,
      heldCount: 4,
    ),
    busy: false,
    onReimport: () {},
    onDelete: () {},
  );

  testWidgets('both buttons are laid out inside a phone-width card', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(host(card()));
    await tester.pumpAndSettle();

    expect(find.text('Re-import'), findsOneWidget);
    expect(find.text('Remove'), findsOneWidget);

    final double cardRight = tester
        .getBottomRight(find.byType(PreviousUploadCard))
        .dx;
    for (final String label in <String>['Re-import', 'Remove']) {
      final Rect r = tester.getRect(find.text(label));
      expect(r.width, greaterThan(20), reason: '$label was squeezed flat');
      expect(
        r.right,
        lessThanOrEqualTo(cardRight + 0.5),
        reason: '$label was pushed outside the card',
      );
    }

    // The file name must have room to read across, not one letter per line.
    expect(
      tester.getRect(find.text('export_136212686.zip')).width,
      greaterThan(80),
    );
  });

  testWidgets('it still lays out at a very narrow width', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(host(card(), width: 320));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Remove'), findsOneWidget);
  });
}
