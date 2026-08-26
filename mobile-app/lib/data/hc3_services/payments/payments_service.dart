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

  /// Builds a [PendingPayment] capture for the given charge. The
  /// clientPaymentId minted here is the server-side Payment row's id — the
  /// idempotency key that makes resending this exact request safe.
  static PendingPayment buildPending({
    required String eventId,
    required String? hasherId,
    required String? hasherEventMapId,
    required int paymentType,
    required double paymentAmount,
    required int minimumAttendenceValue,
    required EnumPayForExtras doPayForExtras,
    required AppDomainType appDomainType,
    required String displayLabel,
    double? surcharge,
    String? paymentProvider,
    String? paymentReference,
    double? specialRunPrice,
    String? specialRunPriceReason,
    bool? useSpecialPriceAsDefault,
    EnumProductType productType = productTypeEvent,
    String? notes,
    bool alsoPayRunFee = false,
  }) {
    return PendingPayment(
      clientPaymentId: const Uuid().v4(),
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
      eventId: eventId,
      hasherId: (hasherId ?? '').isEmpty ? GUID_EMPTY : hasherId,
      hasherEventMapId: (hasherEventMapId ?? '').isEmpty
          ? GUID_EMPTY
          : hasherEventMapId,
      paymentType: paymentType,
      paymentAmount: paymentAmount,
      minimumAttendenceValue: minimumAttendenceValue,
      doPayForExtrasValue: doPayForExtras.value,
      appDomainTypeStr: appDomainType.toString(),
      productTypeValue: productType.value,
      surcharge: surcharge,
      paymentProvider: paymentProvider,
      paymentReference: paymentReference,
      specialRunPrice: specialRunPrice,
      specialRunPriceReason: specialRunPriceReason,
      useSpecialPriceAsDefault: useSpecialPriceAsDefault,
      notes: notes,
      alsoPayRunFee: alsoPayRunFee,
      displayLabel: displayLabel,
    );
  }

  /// Sends one captured payment to the server. Called for the initial
  /// attempt AND for every outbox retry — the request body is rebuilt from
  /// the capture each time (fresh access token, fresh sync watermarks), but
  /// the clientPaymentId never changes, so the server can deduplicate.
  ///
  /// [errorCallback] follows sendHttpPost semantics: pass one to suppress
  /// the default server-error dialog (background retries do).
  Future<PaymentSendResult> sendPending(
    PendingPayment p, {
    Function? errorCallback,
  }) async {
    final String userId = currentUserId;
    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret =
        getStringPref(StringPrefsEnum.deviceSecret) ?? '';
    final AppDomainType appDomainType = p.appDomainType;

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

    final Map<String, String?> payBody = <String, String?>{
      'queryType': 'processPayment',
      'deviceId': deviceId,
      'userIdWhoPaid': p.hasherId,
      'eventId': p.eventId,
      'hasherEventMapId': p.hasherEventMapId,
      'paymentType': p.paymentType.toString(),
      'productType': p.productTypeValue.toString(),
      'paymentAmount': p.paymentAmount.toString(),
      'minimumAttendenceValue': p.minimumAttendenceValue.toString(),
      'hasherEventMapUpdatedAfter': hasherEventMapUpdatedAfter.toString(),
      'hasherKennelMapUpdatedAfter': hasherKennelMapUpdatedAfter.toString(),
      'paymentsUpdatedAfter': paymentsUpdatedAfter.toString(),
      //'kennelCreditsUpdatedAfter': 'ignore',
      'doPayForExtras': p.doPayForExtrasValue.toString(),
      'surcharge': p.surcharge?.toString(),
      'paymentProvider': p.paymentProvider ?? '',
      'appDomainType': p.appDomainTypeStr,
      'paymentReference': p.paymentReference,
      // The ORIGINAL capture instant, not "now": on a replayed send the
      // recorded PaidDate should be when the admin took the money.
      'transactionTimestamp': DateTime.fromMillisecondsSinceEpoch(
        p.createdAtMs,
      ).toString(),
      // Idempotency key — requires processPayment >= 1.5.0 server-side.
      'clientPaymentId': p.clientPaymentId,
      if (p.notes != null && p.notes!.trim().isNotEmpty)
        'notes': p.notes!.trim(),
      if (p.alsoPayRunFee) 'alsoPayRunFee': '1',
    };

    if (p.specialRunPrice != null) {
      payBody.addAll(<String, String>{
        'specialRunPrice': p.specialRunPrice.toString(),
        'specialRunPriceReason': p.specialRunPriceReason ?? '',
        'useSpecialPriceAsDefault':
            ((p.useSpecialPriceAsDefault ?? false) ? 1 : 0).toString(),
      });
    }

    // Compound token includes hasherEventMapId and paymentAmount — both come
    // from the persisted capture, so a retry hours later builds the same
    // compound param; the token itself is minted fresh per attempt.
    final String hemId = p.hasherEventMapId ?? GUID_EMPTY;
    final String responseBody = await ServiceCommon.sendHttpPost(
      () {
        payBody['accessToken'] = Utilities.generateToken(
          userId,
          'hcapp_processPayment',
          paramString: '$deviceSecret$hemId#${p.paymentAmount.toInt()}',
        );
        return jsonEncode(payBody);
      },
      noRetries: true,
      errorCallback: errorCallback,
    );

    List<dynamic> results = <dynamic>[];
    if (!responseBody.startsWith(ERROR_PREFIX)) {
      if (appDomainType == AppDomainType.event) {
        results = await tableModel.syncEventAdminService
            .updateSqlTablesWithResultsFromBackendApiCall(responseBody);
      } else {
        results = await tableModel.syncUserDataService
            .updateSqlTablesWithResultsFromApiWithAdHocData(responseBody);
      }
    }
    return PaymentSendResult(responseBody, results);
  }

  /// Direct, non-queued send — the pre-outbox behaviour. Prefer
  /// PaymentOutboxService.submit for anything that charges money: it keeps
  /// the capture on the phone until the server acknowledges it.
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
    EnumProductType productType = productTypeEvent,
    String? notes,
    bool alsoPayRunFee = false,
  }) async {
    if (Utilities.isNotConnected()) {
      return <dynamic>[];
    }
    final PaymentSendResult result = await sendPending(
      buildPending(
        eventId: eventId,
        hasherId: hasherId,
        hasherEventMapId: hasherEventMapId,
        paymentType: paymentType,
        paymentAmount: paymentAmount,
        minimumAttendenceValue: minimumAttendenceValue,
        doPayForExtras: doPayForExtras,
        appDomainType: appDomainType,
        displayLabel: 'payment',
        surcharge: surcharge,
        paymentProvider: paymentProvider,
        paymentReference: paymentReference,
        specialRunPrice: specialRunPrice,
        specialRunPriceReason: specialRunPriceReason,
        useSpecialPriceAsDefault: useSpecialPriceAsDefault,
        productType: productType,
        notes: notes,
        alsoPayRunFee: alsoPayRunFee,
      ),
    );
    return result.results;
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
              )
              .timeout(
                const Duration(seconds: 30),
                onTimeout: () => Response('timeout', 408),
              )
              .catchError((dynamic error) {
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
