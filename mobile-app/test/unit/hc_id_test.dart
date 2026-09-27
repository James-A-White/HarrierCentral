import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/util/hc_id.dart';

/// Ids are lowercase everywhere (James, 2026-09-27): an uppercase EventId in
/// a push payload opened no chat, and an uppercase runner id lost "you" on
/// the PackTrack map.
void main() {
  const String upper = 'F66CEFDF-23E0-43B6-88E9-90D4B9DA8487';
  const String lower = 'f66cefdf-23e0-43b6-88e9-90d4b9da8487';

  test('HcId lowercases and trims, so == and SQL agree', () {
    expect(HcId(upper), lower);
    expect(HcId(' $upper '), HcId(lower));
    expect(HcId(null), HcId.empty);
    expect('evt.eventId = "${HcId(upper)}"', 'evt.eventId = "$lower"');
  });

  test('tryParse and isValid reject empty and all-zero ids', () {
    expect(HcId.tryParse(null), isNull);
    expect(HcId.tryParse(''), isNull);
    expect(HcId.tryParse('00000000-0000-0000-0000-000000000000'), isNull);
    expect(HcId.tryParse(upper), lower);
  });

  test('looksLikeGuid is shape-only and cheap', () {
    expect(looksLikeGuid(upper), isTrue);
    expect(looksLikeGuid(lower), isTrue);
    expect(looksLikeGuid('Down Down'), isFalse);
    expect(looksLikeGuid('PHO::$upper'), isFalse);
    expect(looksLikeGuid('F66CEFDF23E043B688E990D4B9DA84871234'), isFalse);
  });

  test('lowerGuidsInPlace reaches every depth and touches nothing else', () {
    final dynamic json = <dynamic>[
      <dynamic>[
        <String, dynamic>{
          'eventId': upper,
          'eventName': 'ABCDEF Hash',
          'count': 3,
          'nested': <String, dynamic>{
            'ids': <dynamic>[upper, 'Mixed Case Text'],
          },
        },
      ],
    ];
    lowerGuidsInPlace(json);
    final Map<String, dynamic> row = json[0][0] as Map<String, dynamic>;
    expect(row['eventId'], lower);
    expect(row['eventName'], 'ABCDEF Hash');
    expect(row['count'], 3);
    expect((row['nested'] as Map)['ids'], <dynamic>[lower, 'Mixed Case Text']);
  });
}
