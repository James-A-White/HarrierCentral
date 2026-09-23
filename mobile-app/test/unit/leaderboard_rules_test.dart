import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/imports.dart';

/// The leaderboard's per-hasher aggregate, its sort, and the +/- search.
/// All three lived in a State until 2026-09-23.
void main() {
  LeaderboardModel lm(
    String name,
    String kennel, {
    int total = 0,
    int hared = 0,
    int ytd = 0,
    int rolling = 0,
    String? hasher,
  }) => LeaderboardModel(
    displayName: name,
    totalRunCount: total,
    totalHaringCount: hared,
    ytdTotalRunCount: ytd,
    ytdHaringCount: 0,
    rollingYearTotalRunCount: rolling,
    rollingYearHaringCount: 0,
    kennelId: kennel,
    hasherId: hasher ?? name.toLowerCase(),
    kennelCountTotal: 0,
    kennelCountYtd: 0,
    kennelCountRollingYear: 0,
    searchText: '',
  );

  final kennels = <String, Map<String, dynamic>>{
    'k1': {'searchText': 'barbados bh3', 'kennelShortName': 'BH3'},
    'k2': {'searchText': 'london lh3', 'kennelShortName': 'LH3'},
  };

  test('aggregateByHasher sums across kennels and counts kennels per span', () {
    final out = LeaderboardController.aggregateByHasher([
      lm('Opee', 'k1', total: 100, hared: 5, ytd: 10, rolling: 12),
      lm('Opee', 'k2', total: 20, hared: 1, ytd: 0, rolling: 3),
      lm('Bob', 'k1', total: 3),
    ], kennels);
    final opee = out.singleWhere((m) => m.hasherId == 'opee');
    expect(opee.totalRunCount, 120);
    expect(opee.totalHaringCount, 6);
    expect(opee.kennelCountTotal, 2);
    expect(opee.kennelCountRollingYear, 2);
    expect(opee.kennelCountYtd, 1, reason: 'no YTD runs at k2');
    expect(opee.searchText, contains('barbados'));
    expect(opee.searchText, contains('london'));
    expect(out.length, 2);
  });

  test('comparator: runs descending by default, name breaks ties', () {
    final rows = [
      lm('Zed', 'k1', total: 10),
      lm('Amy', 'k1', total: 10),
      lm('Max', 'k1', total: 50),
    ];
    rows.sort(
      LeaderboardController.comparator(
        0,
        LeaderboardController.TABINDEX_TOTAL,
        false,
      ),
    );
    expect(rows.map((m) => m.displayName).toList(), ['Max', 'Amy', 'Zed']);
  });

  test('comparator: the timespan picks the counts', () {
    final rows = [
      lm('A', 'k1', total: 1, rolling: 9),
      lm('B', 'k1', total: 9, rolling: 1),
    ];
    rows.sort(
      LeaderboardController.comparator(
        0,
        LeaderboardController.TABINDEX_365_DAYS,
        false,
      ),
    );
    expect(rows.first.displayName, 'A');
  });

  test('comparator: name column ascending, kennel breaks ties', () {
    final rows = [lm('b', 'k2'), lm('b', 'k1'), lm('a', 'k1')];
    rows.sort(LeaderboardController.comparator(2, 0, true));
    expect(rows.map((m) => '${m.displayName}${m.kennelId}').toList(), [
      'ak1',
      'bk1',
      'bk2',
    ]);
  });

  test('matches: minus terms exclude, plus terms include', () {
    final a = lm('Opee', 'k1')..searchText = ' opee, barbados bh3, ';
    expect(LeaderboardController.matches(a, ['opee'], []), isTrue);
    expect(LeaderboardController.matches(a, ['opee'], ['barbados']), isFalse);
    expect(LeaderboardController.matches(a, ['nobody'], []), isFalse);
  });
}
