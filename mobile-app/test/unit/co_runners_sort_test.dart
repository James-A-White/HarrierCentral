import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/imports.dart';

/// Run Counts › By Hasher: most runs together first, then display name A–Z
/// ignoring case (James, 2026-10-05).
void main() {
  HasherSummary h(String name, int together) => HasherSummary(
        publicHasherId: HcId('00000000-0000-0000-0000-${together.toString().padLeft(4, '0')}${name.length.toString().padLeft(8, '0')}'),
        displayName: name,
        runsTogether: together,
      );

  test('sorts by runs together descending, then display name ascending', () {
    final List<HasherSummary> out = HistoryListController.byRunsTogether(<HasherSummary>[
      h('zebra', 2),
      h('Apple', 2),
      h('Mango', 5),
      h('banana', 2),
      h('Kiwi', 1),
    ]);
    expect(out.map((HasherSummary e) => e.displayName).toList(),
        <String>['Mango', 'Apple', 'banana', 'zebra', 'Kiwi']);
  });
}
