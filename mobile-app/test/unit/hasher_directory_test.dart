import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/imports.dart';

/// Hasher search and By Hasher (E9.F1.S26 / E10.F1.S5, 2026-10-02).
void main() {
  group('DirectoryVisibility', () {
    test('compose keeps the real-name flag only with a scope', () {
      expect(
        DirectoryVisibility.compose(DirectoryVisibility.anyone, realName: true),
        19,
      );
      expect(
        DirectoryVisibility.compose(
          DirectoryVisibility.runTogether,
          realName: false,
        ),
        1,
      );
      // nobody means nobody: the switch is dropped
      expect(
        DirectoryVisibility.compose(DirectoryVisibility.nobody, realName: true),
        0,
      );
    });

    test('scope and real name read back', () {
      expect(
        DirectoryVisibility.scopeOf(18),
        DirectoryVisibility.kennelMembers,
      );
      expect(DirectoryVisibility.realNameOf(18), isTrue);
      expect(DirectoryVisibility.realNameOf(2), isFalse);
    });

    test('the approved wording, in the approved order', () {
      expect(
        DirectoryVisibility.scopes.map(DirectoryVisibility.label).toList(),
        <String>[
          'Anyone on Harrier Central',
          "Only hashers I've run with",
          'Only members of kennels I belong to',
          "Nobody. I don't want to be found",
        ],
      );
    });
  });

  group('HasherSummary', () {
    final HasherSummary tuna = HasherSummary.fromJson(<String, dynamic>{
      'PublicHasherId': 'D0B7EF01-C6E3-4723-9D2F-2AE864A59F1A',
      'DisplayName': 'Tuna Melt 🐟',
      'HomeKennelShortName': 'City H3',
      'HomeKennelName': 'City Hash House Harriers',
      'RunsTogether': 493,
      'LastTogether': '2026-10-01T17:45:00+00:00',
    });

    test('parses, with the id lowercased', () {
      expect(tuna.publicHasherId, 'd0b7ef01-c6e3-4723-9d2f-2ae864a59f1a');
      expect(tuna.runsTogether, 493);
      expect(tuna.lastTogether, isNotNull);
    });

    test('local search matches the shown name and home kennel only', () {
      expect(tuna.matches('tuna'), isTrue);
      expect(tuna.matches('city'), isTrue);
      expect(tuna.matches('house harriers'), isTrue);
      expect(tuna.matches('melissa'), isFalse); // a real name she does not show
      expect(tuna.matches(''), isTrue);
    });

    test('round-trips through the offline cache', () {
      final HasherSummary back = HasherSummary.fromJson(tuna.toJson());
      expect(back.publicHasherId, tuna.publicHasherId);
      expect(back.displayName, tuna.displayName);
      expect(back.runsTogether, 493);
    });
  });

  test('SharedRun keeps the run\'s own wall-clock date', () {
    final SharedRun r = SharedRun.fromJson(<String, dynamic>{
      'EventId': '35DE3C4A-EA2D-4B89-85F3-203C8645611C',
      'EventNumber': 62,
      'EventName': 'Run #62 - Shoreditch High Street',
      'EventStartLocal': '2026-10-01T18:45:00',
      'KennelShortName': 'EELS H3',
      'MeHare': 0,
      'ThemHare': 1,
    });
    expect(r.eventId, '35de3c4a-ea2d-4b89-85f3-203c8645611c');
    expect(r.startLocal, DateTime(2026, 10, 1, 18, 45));
    expect(r.meHare, isFalse);
    expect(r.themHare, isTrue);
  });

  group('By Hasher small line', () {
    test('since + mostly', () {
      final HasherSummary h = HasherSummary.fromJson(<String, dynamic>{
        'PublicHasherId': 'D0B7EF01-C6E3-4723-9D2F-2AE864A59F1A',
        'DisplayName': 'Tuna Melt',
        'HomeKennelShortName': 'City H3',
        'FirstTogether': '2013-09-19T12:00:00+00:00',
        'MostlyKennelShortName': 'EELS H3',
      });
      expect(byHasherLine(h), 'since Sep 2013 · mostly EELS H3');
      expect(
        HasherSummary.fromJson(h.toJson()).mostlyKennelShortName,
        'EELS H3',
      );
    });

    test('falls back to the home kennel on an older server', () {
      const HasherSummary h = HasherSummary(
        publicHasherId: HcId.empty,
        displayName: 'Tuna Melt',
        homeKennelShortName: 'City H3',
      );
      expect(byHasherLine(h), 'City H3');
    });
  });
}
