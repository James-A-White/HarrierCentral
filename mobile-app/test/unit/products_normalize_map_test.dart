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
    'pricingJson': '{"mode":"fixed","price":20,"unitCost":12}',
    'productDetailsJson': '{"photos":[],"sizes":["S","M"]}',
    'isActive': 1,
    'sortOrder': 20,
    'removed': 0,
    'updatedAt': '2026-09-13 13:00:00.000000',
    // Not sent by the server and never should be — supplier detail.
    'sourceJson': '{"supplier":"Example Print Co"}',
  };

  test('keeps every column the phone actually has', () {
    final Map<String, dynamic> out = helper.normalizeMap(wireRow());
    expect(out['productId'], 'b3b779a0-ffdb-43f0-b703-16a16dfe1805');
    expect(out['name'], 'Hash Shirt');
    expect(out['pricingJson'], '{"mode":"fixed","price":20,"unitCost":12}');
    expect(out['isActive'], 1);
    expect(out['updatedAt'], '2026-09-13 13:00:00.000000');
    expect(out.length, 11);
  });

  test('keeps both JSON fields — the phone needs them for a shop', () {
    final Map<String, dynamic> out = helper.normalizeMap(wireRow());
    expect(out.containsKey('pricingJson'), isTrue);
    expect(out.containsKey('productDetailsJson'), isTrue);
  });

  test('never lets supplier detail onto the phone', () {
    final Map<String, dynamic> out = helper.normalizeMap(wireRow());
    expect(out.containsKey('sourceJson'), isFalse);
  });

  test('drops the price columns that no longer exist', () {
    final Map<String, dynamic> out = helper.normalizeMap(<String, dynamic>{
      'productId': 'x',
      'priceCharged': 20.0,
      'runCount': 11,
    });
    expect(out.containsKey('priceCharged'), isFalse);
    expect(out.containsKey('runCount'), isFalse);
  });

  test('is not the empty map — the bug this guards against', () {
    expect(helper.normalizeMap(wireRow()), isNotEmpty);
  });

  test('a short row from an older server does not invent keys', () {
    final Map<String, dynamic> out = helper.normalizeMap(<String, dynamic>{
      'productId': 'x',
      'name': 'Y',
    });
    expect(out.keys.toSet(), <String>{'productId', 'name'});
  });
}
