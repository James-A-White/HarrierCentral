import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/widgets/kennel_logo.dart';

/// A generic coin is blank artwork: the kennel's short name written on it IS
/// the logo. Coins arrive as bundle://C-NNN (older rows) or, since
/// 2026-09-28, as the stored image URL …/generic-logos/C-NNN.png — and the
/// URL form showed a blank coin until KennelLogo learned it (James: "when a
/// coin is used it should overlay the kennel short name").
void main() {
  Future<void> pump(WidgetTester tester, String url) => tester.pumpWidget(
    MaterialApp(
      home: Center(
        child: KennelLogo(kennelLogoUrl: url, kennelShortName: 'BDH3', logoHeight: 80),
      ),
    ),
  );

  testWidgets('a coin given as a URL is drawn locally with the short name', (tester) async {
    await pump(tester, 'https://harriercentral.blob.core.windows.net/harrier/generic-logos/C-030.png');
    expect(find.text('BDH3'), findsOneWidget);
    final Image img = tester.widget<Image>(find.byType(Image));
    expect((img.image as AssetImage).assetName, 'images/generic_logos/C-030.png');
  });

  testWidgets('a bundle:// coin still carries the short name', (tester) async {
    await pump(tester, 'bundle://C-300');
    expect(find.text('BDH3'), findsOneWidget);
    final Image img = tester.widget<Image>(find.byType(Image));
    expect((img.image as AssetImage).assetName, 'images/generic_logos/C-300.png');
  });

  testWidgets("a kennel's own logo gets no text", (tester) async {
    await pump(tester, 'https://harriercentral.blob.core.windows.net/harrier/kennel-logos/lh3.png');
    expect(find.text('BDH3'), findsNothing);
  });
}
