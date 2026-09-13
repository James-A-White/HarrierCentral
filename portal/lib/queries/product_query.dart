import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:hcportal/imports.dart';

/// Builds the access token for a kennel-scoped portal SP.
///
/// The compound paramString is the convention every kennel-scoped portal SP
/// uses, because HC6.ValidatePortalAuth takes @publicKennelId as its caller
/// param. Getting it wrong produces an auth failure with no hint as to why.
String _kennelToken(String procName, String publicKennelId) {
  final String deviceId = box.get(HIVE_DEVICE_ID) as String;
  final String deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';
  return Utilities.generateToken(
    deviceId,
    procName,
    paramString: '$deviceSecret:$publicKennelId',
  );
}

/// One kennel's catalogue. Returns inactive products too unless [activeOnly].
///
/// Returns an empty list on any failure. sendHttpPostToHC6Api has already
/// shown the user an alert by then, so there is nothing to add here.
Future<List<ProductModel>> queryKennelProducts(
  String publicKennelId, {
  bool activeOnly = false,
}) async {
  publicKennelId = normalizeUuid(publicKennelId);
  if (publicKennelId.length != 36) return <ProductModel>[];

  final Map<String, dynamic> body = <String, dynamic>{
    'queryType': 'getKennelProducts',
    'deviceId': box.get(HIVE_DEVICE_ID) as String,
    'accessToken': _kennelToken('hcportal_getKennelProducts', publicKennelId),
    'publicKennelId': publicKennelId,
    'activeOnly': activeOnly ? 1 : 0,
  };

  final ApiResult result = await ServiceCommon.sendHttpPostToHC6Api(body);
  if (kDebugMode) {
    debugPrint(
      result is ApiError
          ? '[getKennelProducts] FAILED'
          : '[getKennelProducts] success',
    );
  }

  if (result case ApiSuccess(:final String body)) {
    final List<dynamic> rowsets = jsonDecode(body) as List<dynamic>;
    if (rowsets.isEmpty) return <ProductModel>[];
    final List<dynamic> rows = rowsets[0] as List<dynamic>;
    // The SP returns EITHER the products or the error envelope in rowset 0.
    // A row carrying 'Success' is the envelope, not a product.
    if (rows.isNotEmpty) {
      final Map<String, dynamic> first = rows.first as Map<String, dynamic>;
      if (first.containsKey('Success')) return <ProductModel>[];
    }
    return rows
        .map((dynamic r) => ProductModel.fromJson(r as Map<String, dynamic>))
        .toList(growable: false);
  }
  return <ProductModel>[];
}

/// Creates or edits one product. Returns its id, or null on failure.
///
/// There is no delete. Retiring something is [isActive] = false, which keeps
/// the row syncing so a payment made against it still resolves its product.
Future<String?> addEditProduct({
  required String publicKennelId,
  String? productId,
  required int productType,
  required String name,
  String? description,
  required double priceCharged,
  required double promotionalCredit,
  required double unitCost,
  int? runCount,
  String? productDetailsJson,
  String? photoUrls,
  String? sourceJson,
  required bool isActive,
  int sortOrder = 0,
}) async {
  publicKennelId = normalizeUuid(publicKennelId);
  if (publicKennelId.length != 36) return null;

  final Map<String, dynamic> body = <String, dynamic>{
    'queryType': 'addEditProduct',
    'deviceId': box.get(HIVE_DEVICE_ID) as String,
    'accessToken': _kennelToken('hcportal_addEditProduct', publicKennelId),
    'publicKennelId': publicKennelId,
    if (productId != null && productId.isNotEmpty) 'productId': productId,
    'productType': productType,
    'name': name,
    'description': ?description,
    'priceCharged': priceCharged,
    'promotionalCredit': promotionalCredit,
    'unitCost': unitCost,
    'runCount': ?runCount,
    'productDetailsJson': ?productDetailsJson,
    'photoUrls': ?photoUrls,
    'sourceJson': ?sourceJson,
    'isActive': isActive ? 1 : 0,
    'sortOrder': sortOrder,
  };

  final ApiResult result = await ServiceCommon.sendHttpPostToHC6Api(body);
  if (result case ApiSuccess(:final String body)) {
    final List<dynamic> rowsets = jsonDecode(body) as List<dynamic>;
    if (rowsets.isEmpty) return null;
    final List<dynamic> envelope = rowsets[0] as List<dynamic>;
    if (envelope.isEmpty) return null;
    final Map<String, dynamic> row = envelope.first as Map<String, dynamic>;
    if ((row['Success'] as num?)?.toInt() != 1) return null;
    // Rowset 1 carries the id, which matters on a create.
    if (rowsets.length > 1) {
      final List<dynamic> out = rowsets[1] as List<dynamic>;
      if (out.isNotEmpty) {
        final String? id =
            (out.first as Map<String, dynamic>)['productId'] as String?;
        if (id != null) return id.toLowerCase();
      }
    }
    return productId ?? '';
  }
  return null;
}
