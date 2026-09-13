import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/data/hc3_services/products/products_service.dart';

/// BaseTableHelper.normalizeMap returns an EMPTY map. A helper that forgets to
/// override it inserts every synced row stripped to nothing, silently. Products
/// shipped that way on 2026-09-13; these tests stop it coming back.
void main() {
  final ProductsTableHelper helper = ProductsTableHelper();

  Map<String, dynamic> wireRow() => <String, dynamic>{
    'productId': 'b3b779a0-ffdb-43f0-b703-16a16dfe1805',
    'kennelId': 'ef20cb1f-3e47-46d2-902b-5fad69f19f9d',
    'productType': 3,
    'name': 'Hash Shirt',
    'description': 'Cotton hash shirt',
    'priceCharged': 20.0,
    'promotionalCredit': 0.0,
    'unitCost': 12.0,
    'runCount': null,
    'isActive': 1,
    'sortOrder': 20,
    'removed': 0,
    'updatedAt': '2026-09-13 13:00:00.000000',
    // Sent by the server, no column on the phone yet:
    'productDetailsJson': '{"sizes":["S","M"]}',
    'photoUrls': 'a.jpg|b.jpg',
  };

  test('keeps every column the phone actually has', () {
    final Map<String, dynamic> out = helper.normalizeMap(wireRow());
    expect(out['productId'], 'b3b779a0-ffdb-43f0-b703-16a16dfe1805');
    expect(out['name'], 'Hash Shirt');
    expect(out['priceCharged'], 20.0);
    expect(out['isActive'], 1);
    expect(out['updatedAt'], '2026-09-13 13:00:00.000000');
    expect(out.length, 13);
  });

  test('drops wire fields the phone has no column for', () {
    final Map<String, dynamic> out = helper.normalizeMap(wireRow());
    expect(out.containsKey('productDetailsJson'), isFalse);
    expect(out.containsKey('photoUrls'), isFalse);
  });

  test('is not the empty map — the bug this guards against', () {
    expect(helper.normalizeMap(wireRow()), isNotEmpty);
  });

  test('a null runCount is kept, not silently dropped', () {
    final Map<String, dynamic> out = helper.normalizeMap(wireRow());
    expect(out.containsKey('runCount'), isTrue);
    expect(out['runCount'], isNull);
  });

  test('a short row from an older server does not invent keys', () {
    final Map<String, dynamic> out = helper.normalizeMap(<String, dynamic>{
      'productId': 'x',
      'name': 'Y',
    });
    expect(out.keys.toSet(), <String>{'productId', 'name'});
  });
}
