import 'dart:async';
import 'dart:convert';

import 'package:harrier_central/data/hc3_services/sync_user_data_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;

import 'package:harrier_central/data/hc3_services/base_service.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:harrier_central/data/hc3_services/sync_event_admin_service.dart';
import 'package:harrier_central/util/enums.dart';

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
    this.removed,
    this.updatedAt,
  });

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
  final int removed;
  final DateTime updatedAt;

  @override
  List<PaymentsModel> itemsFromJson(String jsonResult) {
    final List<PaymentsModel> items = <PaymentsModel>[];

    PaymentsModel item;

    json.decode(jsonResult).forEach(
      (dynamic jsonItem) {
        item = PaymentsModel(
            paymentId: jsonItem['paymentId'],
            kennelId: jsonItem['kennelId'],
            paidBy: jsonItem['paidBy'],
            hemId: jsonItem['hemId'],
            eventId: jsonItem['eventId'],
            paidTo: jsonItem['paidTo'],
            creditAmount: jsonItem['creditAmount'],
            debitAmount: jsonItem['debitAmount'],
            paidDate: DateTime.parse(jsonItem['paidDate'].toString().substring(0, 19)),
            paymentType: jsonItem['paymentType'],
            productType: jsonItem['productType'],
            cancelledDate: DateTime.parse(jsonItem['cancelledDate'].toString().substring(0, 19)),
            cancelledBy: jsonItem['cancelledBy'],
            confirmedDate: DateTime.parse(jsonItem['confirmedDate'].toString().substring(0, 19)),
            confirmedBy: jsonItem['confirmedBy'],
            paymentReference: jsonItem['paymentReference'],
            notes: jsonItem['notes'],
            doPayForExtras: jsonItem['doPayForExtras'],
            surcharge: jsonItem['surcharge'],
            paymentProvider: jsonItem['paymentProvider'],
            updatedAt: DateTime.parse(jsonItem['updatedAt'].toString().substring(0, 19)),
            removed: jsonItem['removed']);

        items.add(item);
      },
    );

    if (items.isEmpty) {
      return null;
    }

    return items;
  }
}

class PaymentsTableHelper with BaseFields implements BaseTableHelper {
  PaymentsTableHelper();

  @override
  num forceRequeryInterval;

  @override
  num cacheDuration;

  // @override
  // String tableName = 'Payments';

  // @override
  // String getTableName(TableType type) {
  //   return tableName;
  // }

  @override
  String tableName = '';

  @override
  String getTableName(TableType tblType) {
    if (tblType == TableType.paymentsUser) {
      return userPaymentsTable;
    } else {
      return eventPaymentsTable;
    }
  }

  @override
  String remoteDbId = 'paymentId';

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
  final String colNotes = 'notes';
  final String colDoPayForExtras = 'doPayForExtras';
  final String colSurcharge = 'surcharge';
  final String colPaymentProvider = 'paymentProvider';

  @override
  Future<dynamic> createTable(Database db, int version, TableType tableType) async {
    await db.execute('''
          CREATE TABLE ${getTableName(tableType)} (
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

            $colRemoved INT,
            $colUpdatedAt TEXT,
            $colUpdatedAtValue NUM NULL
          )
          ''');

    String sql = 'CREATE INDEX idx_${getTableName(tableType)}_id ON ${getTableName(tableType)}($remoteDbId);';
    await db.execute(sql);
    sql = 'CREATE INDEX idx_${getTableName(tableType)}_update_at_value ON ${getTableName(tableType)}($colUpdatedAtValue);';
    await db.execute(sql);

    // await db.execute('CREATE INDEX idx_${tableName}_id ON $tableName($remoteDbId);');
    // await db.execute('CREATE INDEX idx_${tableName}_update_at_value ON $tableName($colUpdatedAtValue);');
  }

  @override
  Map<String, dynamic> toMap(dynamic item) {
    final Map<String, dynamic> map = <String, dynamic>{
      colPaymentId: item.paymentId,
      colKennelId: item.kennelId,
      colPaidBy: item.paidBy,
      colHemId: item.hemId,
      colEventId: item.id,
      colPaidTo: item.paidTo,
      colCreditAmount: item.creditAmount,
      colDebitAmount: item.debitAmount,
      colPaidDate: item.paidDate.toString(),
      colPaymentType: item.paymentType,
      colProductType: item.productType,
      colCancelledDate: item.cancelledDate.toString(),
      colCancelledBy: item.cancelledBy,
      colConfirmedDate: item.confirmedDate,
      colConfirmedBy: item.confirmedBy,
      colPaymentReference: item.paymentReference,
      colNotes: item.notes,
      colDoPayForExtras: item.doPayForExtras,
      colSurcharge: item.surcharge,
      colPaymentProvider: item.paymentProvider,
      colUpdatedAt: item.updatedAt.toString(),
      colUpdatedAtValue: item.updatedAt.millisecondsSinceEpoch,
      colRemoved: item.removed
    };

    return map;
  }

  @override
  Map<String, dynamic> normalizeMap(Map<String, dynamic> inputMap) {
    final Map<String, dynamic> outputMap = <String, dynamic>{
      colPaymentId: inputMap[colPaymentId],
      colKennelId: inputMap[colKennelId],
      colPaidBy: inputMap[colPaidBy],
      colHemId: inputMap[colHemId],
      colEventId: inputMap[colEventId],
      colPaidTo: inputMap[colPaidTo],
      colCreditAmount: inputMap[colCreditAmount],
      colDebitAmount: inputMap[colDebitAmount],
      colPaidDate: inputMap[colPaidDate],
      colPaymentType: inputMap[colPaymentType],
      colProductType: inputMap[colProductType],
      colCancelledDate: inputMap[colCancelledDate],
      colCancelledBy: inputMap[colCancelledBy],
      colConfirmedDate: inputMap[colConfirmedDate],
      colConfirmedBy: inputMap[colConfirmedBy],
      colPaymentReference: inputMap[colPaymentReference],
      colNotes: inputMap[colNotes],
      colDoPayForExtras: inputMap[colDoPayForExtras],
      colSurcharge: inputMap[colSurcharge],
      colPaymentProvider: inputMap[colPaymentProvider],
      colUpdatedAt: inputMap[colUpdatedAt],
      colUpdatedAtValue: DateTime.parse(inputMap[colUpdatedAt].toString().substring(0, 19)).millisecondsSinceEpoch,
      colRemoved: inputMap[colRemoved],
    };

    return outputMap;
  }

  // List<PaymentsModel> listFromMap(List<Map<String, dynamic>> mapList) {
  //   final List<PaymentsModel> paymentList = <PaymentsModel>[];
  //   for (int i = 0; i < mapList.length; i++) {
  //     paymentList.add(fromMap(mapList[i]));
  //   }
  //   return paymentList;
  // }

  @override
  PaymentsModel fromMap(Map<String, dynamic> map) {
    final PaymentsModel item = PaymentsModel(
      paymentId: map[colPaymentId],
      kennelId: map[colKennelId],
      paidBy: map[colPaidBy],
      hemId: map[colHemId],
      eventId: map[colEventId],
      paidTo: map[colPaidTo],
      creditAmount: map[colCreditAmount],
      debitAmount: map[colDebitAmount],
      paidDate: (map[colPaidDate] == null) ? null : DateTime.parse(map[colPaidDate].toString().substring(0, 19)),
      paymentType: map[colPaymentType],
      productType: map[colProductType],
      cancelledDate: (map[colCancelledDate] == null) ? null : DateTime.parse(map[colCancelledDate].toString().substring(0, 19)),
      cancelledBy: map[colCancelledBy],
      confirmedDate: (map[colConfirmedDate] == null) ? null : DateTime.parse(map[colConfirmedDate].toString().substring(0, 19)),
      confirmedBy: map[colConfirmedBy],
      paymentReference: map[colPaymentReference],
      notes: map[colNotes],
      doPayForExtras: map[colDoPayForExtras],
      surcharge: map[colSurcharge],
      paymentProvider: map[colPaymentProvider],
      updatedAt: (map[colUpdatedAt] == null) ? null : DateTime.parse(map[colUpdatedAt].toString().substring(0, 19)),
      removed: map[colRemoved],
    );

    return item;
  }
}

class PaymentsService {
  Future<List<dynamic>> payForEvent(String eventId, String hasherId, String hasherEventMapId, int paymentType, num paymentAmount, int minimumAttendenceValue, EnumPayForExtras<int> doPayForExtras, AppDomainType appDomainType, {num surcharge, String paymentProvider}) async {
    List<dynamic> results;

    if (globalConnectionStatus == connectionStatus_notConnected) {
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

    final String tokenParameterString = hasherEventMapId.toUpperCase() + '#' + hasherId + '#' + paymentAmount.toInt().toString() + '#' + eventId.toUpperCase();

    final String accessToken = Utilities.generateToken(userId, 'processPayment', paramString: tokenParameterString);

    final num _hasherEventMapLastUpdated = await baseService.getLastUpdatedTime(hasherEventMapTableHelper, hasherEventMapTableHelper.colUpdatedAtValue, tableType: appDomainType == AppDomainType.event ? TableType.hemEventAdmin : TableType.hemUser);
    final DateTime hasherEventMapUpdatedAfter = _hasherEventMapLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_hasherEventMapLastUpdated + 1000);

    final num _hasherKennelMapLastUpdated = await baseService.getLastUpdatedTime(hasherKennelMapTableHelper, hasherKennelMapTableHelper.colUpdatedAtValue, tableType: appDomainType == AppDomainType.event ? TableType.hkmEventAdmin : TableType.hkmUser);
    final DateTime hasherKennelMapUpdatedAfter = _hasherKennelMapLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_hasherKennelMapLastUpdated + 1000);

    final num _paymentsLastUpdated = await baseService.getLastUpdatedTime(paymentsTableHelper, paymentsTableHelper.colUpdatedAtValue, tableType: appDomainType == AppDomainType.event ? TableType.paymentsEvent : TableType.paymentsUser);
    final DateTime paymentsUpdatedAfter = _paymentsLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_paymentsLastUpdated + 1000);

    final num _kennelCreditsLastUpdated = await baseService.getLastUpdatedTime(kennelCreditsTableHelper, kennelCreditsTableHelper.colUpdatedAtValue);
    final DateTime kennelCreditsUpdatedAfter = _kennelCreditsLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_kennelCreditsLastUpdated + 1000);

    final String appDomainStr = appDomainType.toString();

    final String body = jsonEncode(<String, String>{
      'userId': userId,
      'accessToken': accessToken,
      'userIdWhoPaid': hasherId,
      'eventId': eventId,
      'hasherEventMapId': hasherEventMapId,
      'paymentType': paymentType == null ? null : paymentType.toString(),
      'productType': productTypeEvent.value.toString(),
      'paymentAmount': paymentAmount == null ? null : paymentAmount.toString(),
      'minimumAttendenceValue': minimumAttendenceValue.toString(),
      'hasherEventMapUpdatedAfter': hasherEventMapUpdatedAfter.toString(),
      'hasherKennelMapUpdatedAfter': hasherKennelMapUpdatedAfter.toString(),
      'paymentsUpdatedAfter': paymentsUpdatedAfter.toString(),
      'kennelCreditsUpdatedAfter': kennelCreditsUpdatedAfter.toString(),
      'doPayForExtras': doPayForExtras.value.toString(),
      'surcharge': surcharge == null ? null : surcharge.toString(),
      'paymentProvider': paymentProvider ?? '',
      'appDomainType' : appDomainStr
    });

    final http.Response response = await http
        .post(BASE_API_URL + 'hc3_process_payment', headers: <String, String>{'content-type': 'application/json'}, body: body
            // Send authorization headers to your backend
            //headers: {HttpHeaders.authorizationHeader: 'Basic your_api_token_here'},
            )
        .catchError(
      (dynamic error) {
        return null;
      },
    );

    if (appDomainType == AppDomainType.event)
    {
      results = await SyncEventAdminService.updateSqlTablesWithResultsFromBackendApiCall(response.body);
    } else {
      results = await SyncUserDataService.updateSqlTablesWithResultsFromBackendApiCall(response.body);
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

    final String accessToken = Utilities.generateToken(userId, 'getPaymentReport');

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

      final http.Response response = await http
          .post(EMAIL_PAYMENT_API_URL, headers: <String, String>{'content-type': 'application/json'}, body: body
              // Send authorization headers to your backend
              //headers: {HttpHeaders.authorizationHeader: 'Basic your_api_token_here'},
              )
          .catchError(
        (dynamic error) {
          return <String, String>{'result': 'error', 'email': ''};
        },
      );

      return <String, String>{'result': response.body, 'email': emailAddress};
    }
    return <String, String>{'result': 'No valid email address found', 'email': ''};
  }
}
