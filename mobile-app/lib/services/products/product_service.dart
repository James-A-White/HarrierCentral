import 'package:harrier_central/imports.dart';

/// One entry in a kennel's catalogue, as the phone holds it (3.1).
class KennelProduct {
  const KennelProduct({
    required this.productId,
    required this.kennelId,
    required this.productType,
    required this.name,
    this.description,
    this.pricingJson,
    this.productDetailsJson,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory KennelProduct.fromRow(Map<String, dynamic> r) {
    final h = tableModel.productsTableHelper;
    return KennelProduct(
      productId: normalizeUuid((r[h.colProductId] as String?) ?? ''),
      kennelId: normalizeUuid((r[h.colKennelId] as String?) ?? ''),
      productType: (r[h.colProductType] as num?)?.toInt() ?? 0,
      name: (r[h.colName] as String?) ?? '',
      description: r[h.colDescription] as String?,
      pricingJson: r[h.colPricingJson] as String?,
      productDetailsJson: r[h.colProductDetailsJson] as String?,
      isActive: ((r[h.colIsActive] as num?)?.toInt() ?? 1) != 0,
      sortOrder: (r[h.colSortOrder] as num?)?.toInt() ?? 0,
    );
  }

  final String productId;
  final String kennelId;
  final int productType;
  final String name;
  final String? description;

  /// How this product is priced, as JSON. One price, a member and non-member
  /// price, a choice of amounts, a price per size, or a deposit and a balance
  /// — four numeric columns could express exactly one of those.
  ///
  ///   {"mode":"fixed","price":20,"unitCost":12}
  ///   {"mode":"choice","amounts":[5,10,20],"allowOther":true}
  final String? pricingJson;

  /// The product group's own rules, as JSON: photos always, plus sizes,
  /// colours, dates, capacity and so on depending on the group.
  final String? productDetailsJson;

  /// On sale. NOT the same as removed — a product that has been sold is never
  /// removed, or the sync would delete it from every phone and break the link
  /// from the payments made against it.
  final bool isActive;

  final int sortOrder;

  Map<String, dynamic> _decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const <String, dynamic>{};
    try {
      final Object? d = jsonDecode(raw);
      return d is Map<String, dynamic> ? d : const <String, dynamic>{};
    } catch (e, s) {
      BootLogger.logError('[ERROR][PRODUCT]', 'product details unparseable: $e', s);
      return const <String, dynamic>{};
    }
  }

  Map<String, dynamic> get pricing => _decode(pricingJson);
  Map<String, dynamic> get details => _decode(productDetailsJson);

  String get pricingMode => (pricing['mode'] as String?) ?? 'fixed';

  /// A single headline price, where the mode has one. Null for a mode that
  /// genuinely has no single price, such as a collection offering a choice —
  /// showing a number there would be an invention.
  double? get headlinePrice {
    final Object? v = switch (pricingMode) {
      'fixed' => pricing['price'],
      'memberTiered' => pricing['memberPrice'],
      'deposit' => pricing['total'],
      'perVariant' => pricing['default'],
      _ => null,
    };
    if (v is num) return v.toDouble();
    return double.tryParse('${v ?? ''}');
  }

  double get promotionalCredit {
    final Object? v = pricing['promotionalCredit'];
    return v is num ? v.toDouble() : (double.tryParse('${v ?? ''}') ?? 0);
  }

  int? get runsIncluded {
    final Object? v = pricing['runsIncluded'];
    return v is num ? v.toInt() : int.tryParse('${v ?? ''}');
  }

  List<String> get photos {
    final Object? v = details['photos'];
    if (v is! List) return const <String>[];
    return v
        .map((Object? e) => (e?.toString() ?? '').trim())
        .where((String e) => e.isNotEmpty)
        .toList(growable: false);
  }
}

/// Reading the catalogue from the phone, and writing it back to the server.
///
/// Reads are local: products sync to every phone like songs, so the editor
/// and any future shop screen work from the local table and stay right
/// offline.
class ProductService {
  const ProductService();

  /// One kennel's catalogue, best-selling order first, inactive last.
  static Future<List<KennelProduct>> forKennel(
    String kennelId, {
    bool activeOnly = false,
  }) async {
    final h = tableModel.productsTableHelper;
    final String table = EnumDataTables.products.commonTableName;
    final List<Map<String, dynamic>> rows = await database.rawQuery(
      '''
      SELECT * FROM $table
       WHERE ${h.colKennelId} = ? AND ${h.colRemoved} = 0
         ${activeOnly ? 'AND ${h.colIsActive} = 1' : ''}
       ORDER BY ${h.colIsActive} DESC, ${h.colSortOrder} ASC, ${h.colName} ASC
      ''',
      <Object?>[kennelId],
    );
    return rows.map(KennelProduct.fromRow).toList(growable: false);
  }

  /// Create or update one entry. Returns its id, or null on failure.
  ///
  /// Taking something off sale is [isActive] = false, never a delete: the row
  /// has to keep syncing so a payment made against it still resolves.
  Future<String?> save({
    required String kennelId,
    String? productId,
    required int productType,
    required String name,
    String? description,
    String? pricingJson,
    String? productDetailsJson,
    required bool isActive,
    int sortOrder = 0,
  }) async {
    final String userId = currentUserId;
    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret =
        getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    final String raw = await ServiceCommon.sendHttpPost(() {
      return jsonEncode(<String, dynamic>{
        'queryType': 'addEditProduct',
        'deviceId': deviceId,
        'kennelId': kennelId,
        if (productId != null && productId.isNotEmpty) 'productId': productId,
        'productType': productType,
        'name': name,
        'description': ?description,
        'pricingJson': ?pricingJson,
        'productDetailsJson': ?productDetailsJson,
        'isActive': isActive ? 1 : 0,
        'sortOrder': sortOrder,
        'accessToken': Utilities.generateToken(
          userId,
          'hcapp_addEditProduct',
          paramString: deviceSecret,
        ),
      });
    }, noRetries: true);

    if (raw.startsWith(ERROR_PREFIX)) return null;
    try {
      final List<dynamic> rowsets = jsonDecode(raw) as List<dynamic>;
      if (rowsets.isEmpty) return null;
      final List<dynamic> envelope = rowsets[0] as List<dynamic>;
      if (envelope.isEmpty) return null;
      final int success =
          ((envelope.first as Map<String, dynamic>)['success'] as num?)
                  ?.toInt() ??
              0;
      if (success != 1) return null;
      if (rowsets.length > 1) {
        final List<dynamic> out = rowsets[1] as List<dynamic>;
        if (out.isNotEmpty) {
          return normalizeUuid(
            ((out.first as Map<String, dynamic>)['productId'] as String?) ?? '',
          );
        }
      }
      return productId ?? '';
    } catch (e, s) {
      BootLogger.logError('[ProductService.save]', e, s);
      return null;
    }
  }
}
