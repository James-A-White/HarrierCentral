import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/imports.dart';

/// The History tab's By Country merge: HC-counted runs plus the historical
/// (pre-app) counts, combined per country, zero-run countries dropped, sorted
/// by runs descending. Lived in a State until 2026-09-23.
void main() {
  Map<String, dynamic> row(String id, int runs, int hares, {String name = ''}) =>
      <String, dynamic>{
        'runCount': runs,
        'hareCount': hares,
        'countryName': name.isEmpty ? id : name,
        'flagFile': '$id.png',
        'countryId': id.toUpperCase(),
      };

  test('merges HC and historical counts per country', () {
    final out = HistoryListController.mergeCountryStats(
      [row('gb', 10, 2), row('bb', 3, 0)],
      [row('gb', 100, 7), row('de', 5, 1)],
    );
    final byId = {for (final c in out) c.countryId: c};
    expect(byId['gb']?.runCount, 110);
    expect(byId['gb']?.hareCount, 9);
    expect(byId['bb']?.runCount, 3);
    expect(byId['de']?.runCount, 5);
  });

  test('sorts by runs descending and drops zero-run countries', () {
    final out = HistoryListController.mergeCountryStats(
      [row('bb', 3, 0), row('zz', 0, 0)],
      [row('gb', 100, 7), row('de', 5, 1), row('us', 0, 0)],
    );
    expect(out.map((c) => c.countryId).toList(), ['gb', 'de', 'bb']);
  });

  test('country ids are normalised to lowercase so the two sources meet', () {
    final out = HistoryListController.mergeCountryStats(
      [row('GB', 1, 0)],
      [row('gb', 1, 0)],
    );
    expect(out.length, 1);
    expect(out.single.runCount, 2);
  });
}
