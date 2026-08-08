import 'package:harrier_central/imports.dart';

class PaymentsTableHelper extends BaseTableHelper<AppDomainType>
    with BaseFields {
  PaymentsTableHelper() {
    remoteDbId = 'paymentId';
    humanReadableTableName = 'Payments';
    pageSize = 250;
  }

  // @override
  // String tableName = '';

  // @override
  // String getTableName(dynamic tblType) {
  //   if (tblType == TableType.paymentsUser) {
  //     return userPaymentsTable;
  //   } else {
  //     return eventPaymentsTable;
  //   }
  // }

  @override
  String getTableName(AppDomainType appDomainType) {
    String tableName = '';
    switch (appDomainType) {
      case AppDomainType.event:
        tableName = EnumDataTables.payments.eventTableName;
        break;
      case AppDomainType.kennel:
        tableName = EnumDataTables.payments.kennelTableName;
        break;
      case AppDomainType.user:
        tableName = EnumDataTables.payments.commonTableName;
        break;
    }
    return tableName;
  }

  final String colPaymentId = 'paymentId';
  final String colKennelId = 'kennelId';
  final String colPaidBy = 'paidBy';
  final String colHemId = 'hemId';
  final String colEventId = 'eventId';
  final String colPaidTo = 'paidTo';
  final String colCreditAmount = 'creditAmount';
  final String colDebitAmount = 'debitAmount';
  final String colCreditAvailable = 'creditAvailable';
  final String colPaidDate = 'paidDate';
  final String colPaymentType = 'paymentType';
  final String colProductType = 'productType';
  final String colCancelledDate = 'cancelledDate';
  final String colCancelledBy = 'cancelledBy';
  final String colConfirmedDate = 'confirmedDate';
  final String colConfirmedBy = 'confirmedBy';
  final String colPaymentReference = 'paymentReference';
  final String colDiscountAmount = 'discountAmount';
  final String colDiscountPercent = 'discountPercent';
  final String colDiscountDescription = 'discountDescription';
  final String colSpecialRunPriceReason = 'specialRunPriceReason';
  final String colNotes = 'notes';
  final String colDoPayForExtras = 'doPayForExtras';
  final String colSurcharge = 'surcharge';
  final String colPaymentProvider = 'paymentProvider';

  @override
  Future<dynamic> createTable(
    Database db,
    int version,
    dynamic appDomainType,
  ) async {
    final String tableName = getTableName(appDomainType);
    await db.execute('''
          CREATE TABLE $tableName (
            $colId INTEGER PRIMARY KEY,

            $colPaymentId TEXT NOT NULL,
            $colKennelId TEXT NOT NULL,
            $colPaidBy TEXT NOT NULL,
            $colHemId TEXT NOT NULL,
            $colEventId TEXT NOT NULL,
            $colPaidTo TEXT NOT NULL,
            $colCreditAmount NUM NOT NULL,
            $colDebitAmount NUM NOT NULL,
            $colCreditAvailable NUM,
            $colPaidDate TEXT NOT NULL,
            $colPaymentType INT NOT NULL,
            $colProductType INT NOT NULL,
            $colCancelledDate TEXT,
            $colCancelledBy TEXT,
            $colConfirmedDate TEXT,
            $colConfirmedBy TEXT,
            $colPaymentReference TEXT,
            $colNotes TEXT,
            $colDoPayForExtras INT NOT NULL,
            $colSurcharge NUM NOT NULL,
            $colPaymentProvider TEXT,
            $colDiscountAmount NUM NOT NULL,
            $colDiscountPercent INT NOT NULL,
            $colDiscountDescription TEXT NOT NULL,
            $colSpecialRunPriceReason TEXT NOT NULL,
            $colRemoved INT NOT NULL,
            $colUpdatedAt TEXT NOT NULL,
            $colUpdatedAtValue INT NULL
          )
          ''');
  }

  @override
  Future<void> createIndexes(
    Database db,
    int version,
    dynamic appDomainType,
  ) async {
    await db.execute(
      'CREATE INDEX idx_${getTableName(appDomainType)}_id ON ${getTableName(appDomainType)}($remoteDbId);',
    );
    await db.execute(
      'CREATE INDEX idx_${getTableName(appDomainType)}_update_at_value ON ${getTableName(appDomainType)}($colUpdatedAtValue);',
    );
  }

  @override
  Map<String, dynamic> normalizeMap(Map<String, dynamic> inputMap) {
    return PaymentsModel.fromJson(inputMap).toJson();
  }

  @override
  PaymentsModel fromMap(Map<String, dynamic> map) {
    return PaymentsModel.fromJson(map);
  }
}

class PaymentsService {
  Future<List<dynamic>> bulkPayForEvent(
    String eventId,
    String? hasherIds,
    int paymentType,
  ) async {
    List<dynamic> results = <dynamic>[];

    if (Utilities.isNotConnected()) {
      return results;
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    final String userId = currentUserId;
    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret =
        getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    final int hasherEventMapLastUpdated = await tableModel.baseService
        .getLastUpdatedTime(
          database,
          tableModel.hasherEventMapTableHelper,
          EnumDataTables.hasherEventMap.eventTableName,
          tableModel.hasherEventMapTableHelper.colUpdatedAtValue,
        );
    final DateTime hasherEventMapUpdatedAfter =
        DateTime.fromMicrosecondsSinceEpoch(hasherEventMapLastUpdated + 1);

    final int hasherKennelMapLastUpdated = await tableModel.baseService
        .getLastUpdatedTime(
          database,
          tableModel.hasherKennelMapTableHelper,
          EnumDataTables.hasherKennelMap.eventTableName,
          tableModel.hasherKennelMapTableHelper.colUpdatedAtValue,
        );
    final DateTime hasherKennelMapUpdatedAfter =
        DateTime.fromMicrosecondsSinceEpoch(hasherKennelMapLastUpdated + 1);

    final int paymentsLastUpdated = await tableModel.baseService
        .getLastUpdatedTime(
          database,
          tableModel.paymentsTableHelper,
          EnumDataTables.payments.eventTableName,
          tableModel.paymentsTableHelper.colUpdatedAtValue,
        );
    final DateTime paymentsUpdatedAfter = DateTime.fromMicrosecondsSinceEpoch(
      paymentsLastUpdated + 1,
    );

    final Map<String, String?> bulkPayBody = <String, String?>{
      'queryType': 'processBulkPayment',
      'deviceId': deviceId,
      'userIdsWhoPaid': hasherIds,
      'eventId': eventId,
      'paymentType': paymentType.toString(),
      'productType': productTypeEvent.value.toString(),
      'hasherEventMapUpdatedAfter': hasherEventMapUpdatedAfter.toString(),
      'hasherKennelMapUpdatedAfter': hasherKennelMapUpdatedAfter.toString(),
      'paymentsUpdatedAfter': paymentsUpdatedAfter.toString(),
      'transactionTimestamp': DateTime.now().toString(),
    };

    final String responseBody = await ServiceCommon.sendHttpPost(() {
      bulkPayBody['accessToken'] = Utilities.generateToken(
        userId,
        'hcapp_processBulkPayment',
        paramString: deviceSecret,
      );
      return jsonEncode(bulkPayBody);
    }, noRetries: true);

    if (!responseBody.startsWith(ERROR_PREFIX)) {
      results = await tableModel.syncEventAdminService
          .updateSqlTablesWithResultsFromBackendApiCall(responseBody);
    }
    return results;
  }

  Future<List<dynamic>> payForEvent(
    String eventId,
    String? hasherId,
    String? hasherEventMapId,
    int paymentType,
    double paymentAmount,
    int minimumAttendenceValue,
    EnumPayForExtras doPayForExtras,
    AppDomainType appDomainType, {
    double? surcharge,
    String? paymentProvider,
    String? paymentReference,
    double? specialRunPrice,
    String? specialRunPriceReason,
    bool? useSpecialPriceAsDefault,
    // productTypeMembership charges the kennel's membership fee (or
    // specialRunPrice as an override) and advances the member's expiry —
    // see docs/membership_payments_plan.md. productTypeHaberdashery sells
    // an item for @paymentAmount with [notes] as the description. Default
    // keeps every existing caller an event payment.
    EnumProductType productType = productTypeEvent,
    String? notes,
  }) async {
    List<dynamic> results = <dynamic>[];

    if (Utilities.isNotConnected()) {
      return results;
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    final String userId = currentUserId;
    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret =
        getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    if ((hasherEventMapId ?? '').isEmpty) {
      hasherEventMapId = GUID_EMPTY;
    }

    if ((hasherId ?? '').isEmpty) {
      hasherId = GUID_EMPTY;
    }

    final int hasherEventMapLastUpdated = await tableModel.baseService
        .getLastUpdatedTime(
          database,
          tableModel.hasherEventMapTableHelper,
          tableModel.hasherEventMapTableHelper.getTableName(appDomainType),
          tableModel.hasherEventMapTableHelper.colUpdatedAtValue,
        );
    final DateTime hasherEventMapUpdatedAfter =
        DateTime.fromMicrosecondsSinceEpoch(hasherEventMapLastUpdated + 1);

    final int hasherKennelMapLastUpdated = await tableModel.baseService
        .getLastUpdatedTime(
          database,
          tableModel.hasherKennelMapTableHelper,
          tableModel.hasherKennelMapTableHelper.getTableName(appDomainType),
          tableModel.hasherKennelMapTableHelper.colUpdatedAtValue,
        );
    final DateTime hasherKennelMapUpdatedAfter =
        DateTime.fromMicrosecondsSinceEpoch(hasherKennelMapLastUpdated + 1);

    final int paymentsLastUpdated = await tableModel.baseService
        .getLastUpdatedTime(
          database,
          tableModel.paymentsTableHelper,
          tableModel.paymentsTableHelper.getTableName(appDomainType),
          tableModel.paymentsTableHelper.colUpdatedAtValue,
        );
    final DateTime paymentsUpdatedAfter = DateTime.fromMicrosecondsSinceEpoch(
      paymentsLastUpdated + 1,
    );

    final String appDomainStr = appDomainType.toString();

    final Map<String, String?> payBody = <String, String?>{
      'queryType': 'processPayment',
      'deviceId': deviceId,
      'userIdWhoPaid': hasherId,
      'eventId': eventId,
      'hasherEventMapId': hasherEventMapId,
      'paymentType': paymentType.toString(),
      'productType': productType.value.toString(),
      'paymentAmount': paymentAmount.toString(),
      'minimumAttendenceValue': minimumAttendenceValue.toString(),
      'hasherEventMapUpdatedAfter': hasherEventMapUpdatedAfter.toString(),
      'hasherKennelMapUpdatedAfter': hasherKennelMapUpdatedAfter.toString(),
      'paymentsUpdatedAfter': paymentsUpdatedAfter.toString(),
      //'kennelCreditsUpdatedAfter': 'ignore',
      'doPayForExtras': doPayForExtras.value.toString(),
      'surcharge': surcharge?.toString(),
      'paymentProvider': paymentProvider ?? '',
      'appDomainType': appDomainStr,
      'paymentReference': paymentReference,
      'transactionTimestamp': DateTime.now().toString(),
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    };

    if (specialRunPrice != null) {
      payBody.addAll(<String, String>{
        'specialRunPrice': specialRunPrice.toString(),
        'specialRunPriceReason': specialRunPriceReason ?? '',
        'useSpecialPriceAsDefault':
            ((useSpecialPriceAsDefault ?? false) ? 1 : 0).toString(),
      });
    }

    // Compound token includes hasherEventMapId and paymentAmount — both captured
    // by the closure so they stay consistent with the body across retries.
    final String hemId = hasherEventMapId ?? GUID_EMPTY;
    final String responseBody = await ServiceCommon.sendHttpPost(() {
      payBody['accessToken'] = Utilities.generateToken(
        userId,
        'hcapp_processPayment',
        paramString: '$deviceSecret$hemId#${paymentAmount.toInt()}',
      );
      return jsonEncode(payBody);
    }, noRetries: true);

    if (!responseBody.startsWith(ERROR_PREFIX)) {
      if (appDomainType == AppDomainType.event) {
        results = await tableModel.syncEventAdminService
            .updateSqlTablesWithResultsFromBackendApiCall(responseBody);
      } else {
        results = await tableModel.syncUserDataService
            .updateSqlTablesWithResultsFromApiWithAdHocData(responseBody);
      }
    }
    return results;
  }

  Future<Map<String, String?>> sendPaymentReportByEmail({
    required String eventId,
    required String eventName,
  }) async {
    final String? emailAddress = getStringPref(StringPrefsEnum.email);
    final String userName =
        getStringPref(StringPrefsEnum.displayName) ?? '<no name>';
    final String? deviceId = getStringPref(StringPrefsEnum.deviceId);
    final String? deviceSecret = getStringPref(StringPrefsEnum.deviceSecret);

    final String? userId = getStringPref(StringPrefsEnum.userId);

    if (((userId ?? '').isNotEmpty) &&
        ((emailAddress ?? '').isNotEmpty) &&
        ((deviceId ?? '').isNotEmpty) &&
        ((deviceSecret ?? '').isNotEmpty)) {
      final String accessToken = Utilities.generateToken(
        userId!,
        'hcapp_getPaymentReport',
        paramString: deviceSecret!,
      );

      final String body = jsonEncode(<String, String?>{
        'queryType': 'getPaymentReport',
        'deviceId': deviceId,
        'accessToken': accessToken,
        'eventId': eventId,
        'eventName': eventName,
        'userName': userName,
        'emailAddress': emailAddress,
      });

      final Response response =
          await post(
            Uri.parse(EMAIL_PAYMENT_API_URL),
            headers: <String, String>{'content-type': 'application/json'},
            body: body,
          ).timeout(
            const Duration(seconds: 30),
            onTimeout: () => Response('timeout', 408),
          ).catchError((dynamic error) {
            return Future<Response>.value(Response('', 500));
          });

      return <String, String?>{'result': response.body, 'email': emailAddress};
    }
    return <String, String>{
      'result': 'No valid email address found',
      'email': '',
    };
  }
}
