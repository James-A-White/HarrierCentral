import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/imports.dart';

/// The one search-box rule behind the kennel list, the run list and the map.
void main() {
  // Shaped like QueryKennels.searchKennelsField's output.
  const String cityHash =
      '~ city hash house harriers ch3 london london england eng '
      'united kingdom gb europe ~';
  const String brewCity =
      '~ brew city hash house harriers bch3 milwaukee wisconsin wi '
      'united states us north america ~';
  const String zurich = '~ zürich hash house harriers zh3 zürich switzerland ~';

  bool m(String query, String text) => SearchQuery(query).matches(text);

  test('every space-separated word must match — the newcomer search', () {
    expect(m('City Hash London', cityHash), isTrue);
    expect(m('City Hash London', brewCity), isFalse);
    // The words need not be adjacent or in order.
    expect(m('london city', cityHash), isTrue);
  });

  test('a comma still narrows', () {
    expect(m('city hash, london', cityHash), isTrue);
    expect(m('city hash, london', brewCity), isFalse);
  });

  test('+ offers alternatives', () {
    expect(m('milwaukee + london', cityHash), isTrue);
    expect(m('milwaukee + london', brewCity), isTrue);
    expect(m('milwaukee + paris', cityHash), isFalse);
  });

  test('not excludes', () {
    expect(m('hash, not london', cityHash), isFalse);
    expect(m('hash, not london', brewCity), isTrue);
  });

  test('a word matches the start of a word, not the middle', () {
    expect(m('lon', cityHash), isTrue);
    expect(m('ondon', cityHash), isFalse);
  });

  test('accents are optional on either side', () {
    expect(m('zurich', zurich), isTrue);
    expect(m('zürich', zurich), isTrue);
    expect(m('zürich', '~ zurich h3 ~'), isTrue);
  });

  test('blank queries match everything; missing text matches nothing', () {
    expect(SearchQuery('').isEmpty, isTrue);
    expect(SearchQuery(' , + ').isEmpty, isTrue);
    expect(m('', cityHash), isTrue);
    expect(SearchQuery('london').matches(null), isFalse);
  });

  test('case does not matter', () {
    expect(m('LONDON', cityHash), isTrue);
  });

  test('the run filter hands back a list the run page can put markers in', () {
    // The run list inserts int section markers (future_run_list_controller)
    // into what the filter returns. A List<RunDetailsAggregate> throws there
    // — it did, on the emulator, 2026-09-25.
    for (final String query in <String>['', 'london']) {
      final List<dynamic> out = QueryRuns.doRunsSearchTextFilter(
        query,
        <RunDetailsAggregate>[],
      );
      expect(() => out.insert(0, 1), returnsNormally, reason: 'query "$query"');
    }
  });
}
