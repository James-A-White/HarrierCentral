import 'package:harrier_central/imports.dart';

/// One entry in a kennel's catalogue, as the phone holds it (3.1).
class KennelProduct {
  const KennelProduct({
    required this.productId,
    required this.kennelId,
    required this.productType,
    required this.name,
    this.description,
    this.priceCharged = 0,
    this.promotionalCredit = 0,
    this.unitCost = 0,
    this.runCount,
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
      priceCharged: (r[h.colPriceCharged] as num?)?.toDouble() ?? 0,
      promotionalCredit: (r[h.colPromotionalCredit] as num?)?.toDouble() ?? 0,
      unitCost: (r[h.colUnitCost] as num?)?.toDouble() ?? 0,
      runCount: (r[h.colRunCount] as num?)?.toInt(),
      isActive: ((r[h.colIsActive] as num?)?.toInt() ?? 1) != 0,
      sortOrder: (r[h.colSortOrder] as num?)?.toInt() ?? 0,
    );
  }

  final String productId;
  final String kennelId;
  final int productType;
  final String name;
  final String? description;

  /// What the hasher pays.
  final double priceCharged;

  /// Credit granted on top of the cash — a package is "pay 70, get 7".
  final double promotionalCredit;

  /// What it costs the kennel to supply. Price minus this is the margin.
  final double unitCost;

  /// How many runs a package is worth. Null for anything not counted in runs.
  final int? runCount;

  /// On sale. NOT the same as removed — a product that has been sold is never
  /// removed, or the sync would delete it from every phone and break the link
  /// from the payments made against it.
  final bool isActive;

  final int sortOrder;

  /// What the kennel actually gives away on this line.
  double get totalValue => priceCharged + promotionalCredit;
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
    required double priceCharged,
    required double promotionalCredit,
    required double unitCost,
    int? runCount,
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
        ?'description': description,
        'priceCharged': priceCharged,
        'promotionalCredit': promotionalCredit,
        'unitCost': unitCost,
        ?'runCount': runCount,
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
