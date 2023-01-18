// @dart=2.11
import 'package:harrier_central/imports.dart';

part 'payments_service.g.dart';

@JsonSerializable(fieldRename: FieldRename.none)
class PaymentsModel implements BaseModel {
  PaymentsModel({
    this.paymentId,
    this.kennelId,
    this.paidBy,
    this.hemId,
    this.eventId,
    this.paidTo,
    this.creditAmount,
    this.debitAmount,
    this.paidDate,
    this.paymentType,
    this.productType,
    this.cancelledDate,
    this.cancelledBy,
    this.confirmedDate,
    this.confirmedBy,
    this.paymentReference,
    this.notes,
    this.doPayForExtras,
    this.surcharge,
    this.paymentProvider,
    this.discountAmount,
    this.discountPercent,
    this.discountDescription,
    this.specialRunPriceReason,
    this.removed,
    this.updatedAt,
  });

  factory PaymentsModel.fromJson(Map<String, dynamic> json) => _$PaymentsModelFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentsModelToJson(this);

  final String paymentId;
  final String kennelId;
  final String paidBy;
  final String hemId;
  final String eventId;
  final String paidTo;
  num creditAmount;
  final num debitAmount;
  final DateTime paidDate;
  int paymentType;
  final int productType;
  final DateTime cancelledDate;
  final String cancelledBy;
  final DateTime confirmedDate;
  final String confirmedBy;
  final String paymentReference;
  final String notes;
  final int doPayForExtras;
  final num surcharge;
  final String paymentProvider;
  final num discountAmount;
  final int discountPercent;
  final String discountDescription;
  final String specialRunPriceReason;
  final int removed;
  final DateTime updatedAt;
}

class PaymentsTableHelper extends BaseTableHelper with BaseFields {
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
  String getTableName(dynamic appDomainType) {
    String tableName;
    switch (appDomainType) {
      case AppDomainType.event:
        tableName = 'Payments';
        break;
      // case AppDomainType.kennel:
      //   break;
      case AppDomainType.user:
        tableName = 'userPayments';
        break;
      default:
        assert(false);
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
  Future<dynamic> createTable(Database db, int version, dynamic appDomainType) async {
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
            $colCreditAmount NUM,
            $colDebitAmount NUM,
            $colPaidDate TEXT,
            $colPaymentType INT,
            $colProductType INT,
            $colCancelledDate TEXT,
            $colCancelledBy TEXT,
            $colConfirmedDate TEXT,
            $colConfirmedBy TEXT,
            $colPaymentReference TEXT,
            $colNotes TEXT,
            $colDoPayForExtras INT,
            $colSurcharge NUM,
            $colPaymentProvider TEXT,
            $colDiscountAmount NUM NOT NULL,
            $colDiscountPercent INT NOT NULL,
            $colDiscountDescription TEXT NOT NULL,
            $colSpecialRunPriceReason TEXT NOT NULL,
            $colRemoved INT,
            $colUpdatedAt TEXT,
            $colUpdatedAtValue INT NULL
          )
          ''');
  }

  @override
  Future<void> createIndexes(Database db, int version, dynamic appDomainType) async {
    await db.execute('CREATE INDEX idx_${getTableName(appDomainType)}_id ON ${getTableName(appDomainType)}($remoteDbId);');
    await db.execute('CREATE INDEX idx_${getTableName(appDomainType)}_update_at_value ON ${getTableName(appDomainType)}($colUpdatedAtValue);');
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
  Future<List<dynamic>> payForEvent(
    String eventId,
    String hasherId,
    String hasherEventMapId,
    int paymentType,
    num paymentAmount,
    int minimumAttendenceValue,
    EnumPayForExtras<int> doPayForExtras,
    AppDomainType appDomainType, {
    num surcharge,
    String paymentProvider,
    String paymentReference,
    num specialRunPrice,
    String specialRunPriceReason,
    bool useSpecialPriceAsDefault,
  }) async {
    List<dynamic> results = <dynamic>[];

    if (G0<AppModel>().connectionStatus == EnumConnectionStatus.not_connected) {
      return results;
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    final String userId = getStringPref(StringPrefsEnum.userId);

    if ((hasherEventMapId ?? '').isEmpty) {
      hasherEventMapId = GUID_EMPTY;
    }

    if ((hasherId ?? '').isEmpty) {
      hasherId = GUID_EMPTY;
    }

    final String tokenParameterString = '${hasherEventMapId.toUpperCase()}#$hasherId#${paymentAmount.toInt()}#${eventId.toUpperCase()}';

    final String accessToken = IveCoreUtilities.generateToken(userId, 'processPayment', paramString: tokenParameterString);

    final num hasherEventMapLastUpdated = await G0<TableModel>().baseService.getLastUpdatedTime(
          G0<Database>(),
          G0<TableModel>().hasherEventMapTableHelper,
          G0<TableModel>().hasherEventMapTableHelper.getTableName(appDomainType),
          G0<TableModel>().hasherEventMapTableHelper.colUpdatedAtValue,
        );
    final DateTime hasherEventMapUpdatedAfter = hasherEventMapLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMicrosecondsSinceEpoch(hasherEventMapLastUpdated + 1);

    final num hasherKennelMapLastUpdated = await G0<TableModel>().baseService.getLastUpdatedTime(
          G0<Database>(),
          G0<TableModel>().hasherKennelMapTableHelper,
          G0<TableModel>().hasherKennelMapTableHelper.getTableName(appDomainType),
          G0<TableModel>().hasherKennelMapTableHelper.colUpdatedAtValue,
        );
    final DateTime hasherKennelMapUpdatedAfter = hasherKennelMapLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMicrosecondsSinceEpoch(hasherKennelMapLastUpdated + 1);

    final num paymentsLastUpdated = await G0<TableModel>().baseService.getLastUpdatedTime(
          G0<Database>(),
          G0<TableModel>().paymentsTableHelper,
          G0<TableModel>().paymentsTableHelper.getTableName(appDomainType),
          G0<TableModel>().paymentsTableHelper.colUpdatedAtValue,
        );
    final DateTime paymentsUpdatedAfter = paymentsLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMicrosecondsSinceEpoch(paymentsLastUpdated + 1);

    // final num _kennelCreditsLastUpdated = await G0<TableModel>().baseService.getLastUpdatedTime(
    //       G0<Database>(),
    //       G0<TableModel>().kennelCreditsTableHelper,
    //       G0<TableModel>().kennelCreditsTableHelper.getTableName(appDomainType),
    //       G0<TableModel>().kennelCreditsTableHelper.colUpdatedAtValue,
    //     );
    // final DateTime kennelCreditsUpdatedAfter = _kennelCreditsLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMicrosecondsSinceEpoch(_kennelCreditsLastUpdated + 1);

    final String appDomainStr = appDomainType.toString();

    final Map<String, String> bodyMap = <String, String>{
      'userId': userId,
      'accessToken': accessToken,
      'userIdWhoPaid': hasherId,
      'eventId': eventId,
      'hasherEventMapId': hasherEventMapId,
      'paymentType': paymentType?.toString(),
      'productType': productTypeEvent.value.toString(),
      'paymentAmount': paymentAmount?.toString(),
      'minimumAttendenceValue': minimumAttendenceValue.toString(),
      'hasherEventMapUpdatedAfter': hasherEventMapUpdatedAfter.toString(),
      'hasherKennelMapUpdatedAfter': hasherKennelMapUpdatedAfter.toString(),
      'paymentsUpdatedAfter': paymentsUpdatedAfter.toString(),
      'kennelCreditsUpdatedAfter': 'ignore',
      'doPayForExtras': doPayForExtras.value.toString(),
      'surcharge': surcharge?.toString(),
      'paymentProvider': paymentProvider ?? '',
      'appDomainType': appDomainStr,
      'paymentReference': paymentReference,
      'transactionTimestamp': DateTime.now().toString(),
    };

    if (specialRunPrice != null) {
      bodyMap.addAll(<String, String>{
        'specialRunPrice': specialRunPrice.toString(),
        'specialRunPriceReason': specialRunPriceReason,
        'useSpecialPriceAsDefault': (useSpecialPriceAsDefault ? 1 : 0).toString(),
      });
    }

    final String body = jsonEncode(bodyMap);

    final String responseBody = await ServiceCommon.sendHttpPost('hc3_process_payment', body);

    if (!responseBody.startsWith(ERROR_PREFIX)) {
      if (appDomainType == AppDomainType.event) {
        results = await G0<TableModel>().syncEventAdminService.updateSqlTablesWithResultsFromBackendApiCall(responseBody);
      } else {
        results = await G0<TableModel>().syncUserDataService.updateSqlTablesWithResultsFromApiWithAdHocData(responseBody);
      }
    }
    return results;
  }

  Future<Map<String, String>> sendPaymentReportByEmail({
    String eventId,
    String eventName,
  }) async {
    final String userId = getStringPref(StringPrefsEnum.userId);
    final String userName = getStringPref(StringPrefsEnum.displayName);
    final String emailAddress = getStringPref(StringPrefsEnum.email);

    final String accessToken = IveCoreUtilities.generateToken(userId, 'getPaymentReport');

    if ((emailAddress ?? '').isNotEmpty) {
      final String body = jsonEncode(<String, String>{
        //'code': EMAIL_PAYMENT_API_KEY,
        'userId': userId,
        'accessToken': accessToken,
        'eventId': eventId,
        'eventName': eventName,
        'userName': userName,
        'emailAddress': emailAddress
      });

      final Response response = await post(Uri.parse(EMAIL_PAYMENT_API_URL), headers: <String, String>{'content-type': 'application/json'}, body: body
              // Send authorization headers to your backend
              //headers: {HttpHeaders.authorizationHeader: 'Basic your_api_token_here'},
              )
          .catchError(
        (dynamic error) {
          return Future<Response>.value(null);
        },
      );

      return <String, String>{'result': response.body, 'email': emailAddress};
    }
    return <String, String>{'result': 'No valid email address found', 'email': ''};
  }
}
