import 'dart:convert';

/// One entry in a kennel's catalogue, as the portal holds it (3.1).
///
/// Hand-written rather than freezed, matching NewsflashAdminModel: the shape
/// is owned by one SP rowset and nothing else constructs it.
class ProductModel {
  const ProductModel({
    required this.productId,
    required this.publicKennelId,
    required this.productType,
    required this.name,
    this.description,
    this.priceCharged = 0,
    this.promotionalCredit = 0,
    this.unitCost = 0,
    this.margin = 0,
    this.runCount,
    this.productDetailsJson,
    this.photoUrls,
    this.sourceJson,
    this.isActive = true,
    this.sortOrder = 0,
    this.unitsSold = 0,
  });

  factory ProductModel.fromJson(Map<String, dynamic> j) {
    double num2d(Object? v) => (v as num?)?.toDouble() ?? 0;
    return ProductModel(
      productId: ((j['productId'] as String?) ?? '').toLowerCase(),
      publicKennelId: ((j['publicKennelId'] as String?) ?? '').toLowerCase(),
      productType: (j['productType'] as num?)?.toInt() ?? 0,
      name: (j['name'] as String?) ?? '',
      description: j['description'] as String?,
      priceCharged: num2d(j['priceCharged']),
      promotionalCredit: num2d(j['promotionalCredit']),
      unitCost: num2d(j['unitCost']),
      margin: num2d(j['margin']),
      runCount: (j['runCount'] as num?)?.toInt(),
      productDetailsJson: j['productDetailsJson'] as String?,
      photoUrls: j['photoUrls'] as String?,
      sourceJson: j['sourceJson'] as String?,
      // IsActive is SMALLINT, so it arrives as a number. The `== true` guard
      // is there only in case the column is ever changed to BIT, which the
      // API shim would then serialise as a JSON boolean.
      isActive: j['isActive'] == true || (j['isActive'] as num?)?.toInt() == 1,
      sortOrder: (j['sortOrder'] as num?)?.toInt() ?? 0,
      unitsSold: (j['unitsSold'] as num?)?.toInt() ?? 0,
    );
  }

  final String productId;
  final String publicKennelId;
  final int productType;
  final String name;
  final String? description;

  /// What the hasher pays.
  final double priceCharged;

  /// Credit granted on top of the cash. A package is "pay 70, get 7".
  final double promotionalCredit;

  /// What it costs the kennel to supply.
  final double unitCost;

  /// priceCharged minus unitCost, computed by the SP so every surface agrees.
  final double margin;

  /// Runs a package is worth. Null for anything not counted in runs.
  final int? runCount;

  /// Per-type display detail, e.g. `{"sizes":["S","M","L"]}`.
  final String? productDetailsJson;

  /// Pipe-delimited photo URLs. Never comma-delimited: a URL may contain a
  /// comma, and splitting on one would cut it in half.
  final String? photoUrls;

  /// Supplier detail. Portal only, never sent to the app.
  final String? sourceJson;

  /// On sale. NOT the same as removed. A product that has sold is never
  /// removed, or the sync would delete it from every phone and orphan the
  /// payments made against it.
  final bool isActive;

  final int sortOrder;

  /// Non-removed payments against this product.
  final int unitsSold;

  /// True once anyone has bought one, which is the point of no return for
  /// deleting it.
  bool get hasBeenSold => unitsSold > 0;

  List<String> get photoUrlList => (photoUrls ?? '')
      .split('|')
      .map((String s) => s.trim())
      .where((String s) => s.isNotEmpty)
      .toList(growable: false);

  /// Sizes out of [productDetailsJson], empty when the item has none or the
  /// JSON is not the shape we expect. Never throws: a malformed blob must not
  /// take the whole catalogue screen down.
  List<String> get sizes {
    final String raw = productDetailsJson ?? '';
    if (raw.trim().isEmpty) return const <String>[];
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return const <String>[];
      final Object? s = decoded['sizes'];
      if (s is! List) return const <String>[];
      return s
          .map((Object? e) => e?.toString() ?? '')
          .where((String e) => e.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const <String>[];
    }
  }
}

/// Product types, matching HC.Payment.ProductType and the mobile app's enums.
///
/// Type 1, a single run, is deliberately absent: a run's price lives on its
/// event and is not a catalogue entry.
const Map<int, String> productTypeLabels = <int, String>{
  4: 'Run package',
  2: 'Membership',
  3: 'Haberdashery',
  5: 'Away weekend',
};

String productTypeLabel(int value) => productTypeLabels[value] ?? 'Other';
