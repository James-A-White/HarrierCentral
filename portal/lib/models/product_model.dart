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
    this.pricingJson,
    this.productDetailsJson,
    this.sourceJson,
    this.isActive = true,
    this.sortOrder = 0,
    this.unitsSold = 0,
  });

  factory ProductModel.fromJson(Map<String, dynamic> j) {
    return ProductModel(
      productId: ((j['productId'] as String?) ?? '').toLowerCase(),
      publicKennelId: ((j['publicKennelId'] as String?) ?? '').toLowerCase(),
      productType: (j['productType'] as num?)?.toInt() ?? 0,
      name: (j['name'] as String?) ?? '',
      description: j['description'] as String?,
      pricingJson: j['pricingJson'] as String?,
      productDetailsJson: j['productDetailsJson'] as String?,
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

  /// How this product is priced, as JSON. See product_schema.dart for the
  /// modes. Nothing sums the catalogue, so this being JSON costs nothing: the
  /// accounting sums HC.Payment, whose amount columns are still typed.
  final String? pricingJson;

  /// The product group's own rules, as JSON: photos always, plus sizes,
  /// colours, dates and so on depending on the group.
  final String? productDetailsJson;

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

  // ---------------------------------------------------------------------------
  // Pricing, out of PricingJson
  // ---------------------------------------------------------------------------

  Map<String, dynamic> get pricing => _decode(pricingJson);

  String get pricingMode => (pricing['mode'] as String?) ?? 'fixed';

  double? _money(Map<String, dynamic> m, String key) {
    final Object? v = m[key];
    if (v is num) return v.toDouble();
    return double.tryParse('${v ?? ''}');
  }

  /// A single headline price, where the mode has one. Null for a mode that
  /// genuinely has none — a collection offering a choice of amounts has no
  /// price, and printing a number there would be an invention.
  double? get headlinePrice => switch (pricingMode) {
    'fixed' => _money(pricing, 'price'),
    'memberTiered' => _money(pricing, 'memberPrice'),
    'deposit' => _money(pricing, 'total'),
    'perVariant' => _money(pricing, 'default'),
    _ => null,
  };

  double get unitCost => _money(pricing, 'unitCost') ?? 0;

  double get promotionalCredit => _money(pricing, 'promotionalCredit') ?? 0;

  int? get runsIncluded {
    final Object? v = pricing['runsIncluded'];
    if (v is num) return v.toInt();
    return int.tryParse('${v ?? ''}');
  }

  /// What the kennel keeps, where there is a single price to keep it from.
  double? get margin {
    final double? p = headlinePrice;
    return p == null ? null : p - unitCost;
  }

  /// The non-member price, for the mode that has one.
  double? get nonMemberPrice => _money(pricing, 'nonMemberPrice');

  // ---------------------------------------------------------------------------
  // The rules, out of ProductDetailsJson
  //
  // Generic accessors keyed by the field names in product_schema.dart, so a new
  // rule needs no change here. Every one is total: a malformed blob, a wrong
  // type or a missing key returns the empty value rather than throwing, because
  // one bad product must not take the whole catalogue screen down.
  // ---------------------------------------------------------------------------

  /// [productDetailsJson] decoded, or an empty map.
  Map<String, dynamic> get details => _decode(productDetailsJson);

  static Map<String, dynamic> _decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const <String, dynamic>{};
    try {
      final Object? d = jsonDecode(raw);
      return d is Map<String, dynamic> ? d : const <String, dynamic>{};
    } catch (_) {
      return const <String, dynamic>{};
    }
  }

  List<String> textList(String key) {
    final Object? v = details[key];
    if (v is! List) return const <String>[];
    return v
        .map((Object? e) => (e?.toString() ?? '').trim())
        .where((String e) => e.isNotEmpty)
        .toList(growable: false);
  }

  List<double> moneyList(String key) {
    final Object? v = details[key];
    if (v is! List) return const <double>[];
    return v
        .map((Object? e) => e is num ? e.toDouble() : double.tryParse('$e'))
        .whereType<double>()
        .where((double d) => d > 0)
        .toList(growable: false);
  }

  bool boolFor(String key) => details[key] == true;

  String? textFor(String key) {
    final Object? v = details[key];
    final String s = (v?.toString() ?? '').trim();
    return s.isEmpty ? null : s;
  }

  int? intFor(String key) {
    final Object? v = details[key];
    if (v is num) return v.toInt();
    return int.tryParse('${v ?? ''}');
  }

  double? moneyFor(String key) {
    final Object? v = details[key];
    if (v is num) return v.toDouble();
    return double.tryParse('${v ?? ''}');
  }

  // Convenience wrappers over the generic accessors, for the keys the UI names
  // directly. They exist so call sites read as English, not as map lookups.

  /// Photos, a JSON array. Was a pipe-delimited string until 2026-09-13; a URL
  /// can contain almost any punctuation, so a delimiter was always a bet.
  List<String> get photos => textList('photos');

  List<String> get sizes => textList('sizes');

  List<double> get suggestedAmounts => moneyList('amounts');

  bool get allowCustomAmount => boolFor('allowOther');

  /// True when this product has no single price, so a payment against it has
  /// to carry the amount rather than read it off the catalogue.
  bool get hasVariableAmount =>
      suggestedAmounts.isNotEmpty || allowCustomAmount;
}

/// Product types, matching HC.Payment.ProductType and the mobile app's enums.
///
/// Type 1, a single run, is deliberately absent: a run's price lives on its
/// event and is not a catalogue entry.
const Map<int, String> productTypeLabels = <int, String>{
  4: 'Run package',
  2: 'Membership',
  3: 'Haberdashery',
  5: 'Trips & Events',
  6: 'Bar & Refreshments',
  7: 'Charity & Donation',
};

String productTypeLabel(int value) => productTypeLabels[value] ?? 'Other';

/// The catalogue's product groups, in the order the Kennel Products tabs show
/// them. Each tab is one ProductType, so adding a group here adds a tab.
///
/// Type 1 (a single run) is deliberately absent: a run's price lives on its
/// event, varies by member and non-member, and is not a catalogue entry.
const List<({int type, String label, String blurb})> productGroups =
    <({int type, String label, String blurb})>[
  (
    type: 2,
    label: 'Memberships',
    blurb: 'Annual or rolling membership of the kennel. The term itself is set '
        'in Edit Kennel, not here, so one kennel cannot have two different '
        'membership lengths.',
  ),
  (
    type: 4,
    label: 'Run Packages',
    blurb: 'Pay for several runs up front. Put the runs bought in Runs '
        'included, and anything free on top in Promotional credit.',
  ),
  (
    type: 3,
    label: 'Haberdashery',
    blurb: 'Shirts, mugs, badges and patches. Sizes and photos live on the '
        'product; the supplier details stay in the portal and never reach a '
        "hasher's phone.",
  ),
  (
    type: 5,
    label: 'Trips & Events',
    blurb: 'Weekends away, red dress runs, anniversary dos and coach trips. '
        'Anything ticketed that is not an ordinary run.',
  ),
  (
    type: 6,
    label: 'Bar & Refreshments',
    blurb: 'Beer tokens, food at the on-on, prepaid bar tabs.',
  ),
  (
    type: 7,
    label: 'Charity & Donation',
    blurb: 'Collections passed straight on. Leave Unit cost at zero unless the '
        'kennel keeps a handling share.',
  ),
];
