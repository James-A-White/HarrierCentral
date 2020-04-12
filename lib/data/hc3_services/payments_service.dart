import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;

import 'package:ive_flutter_core/database/base_service.dart';

import 'package:harrier_central/util/constants.dart';
import 'package:ive_flutter_core/util/core_utilities.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/database/tables.dart';
import 'package:ive_flutter_core/util/connection.dart';

import 'package:json_annotation/json_annotation.dart';

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
    this.removed,
    this.updatedAt,
  });

  factory PaymentsModel.fromJson(Map<String, dynamic> json) => _$PaymentsModelFromJson(json);

  @override
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
  final int removed;
  final DateTime updatedAt;
}

class PaymentsTableHelper with BaseFields implements BaseTableHelper {
  PaymentsTableHelper();

  @override
  num forceRequeryInterval;

  @override
  num cacheDuration;

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

            $colRemoved INT,
            $colUpdatedAt TEXT,
            $colUpdatedAtValue NUM NULL
          )
          ''');

    String sql = 'CREATE INDEX idx_${tableName}_id ON $tableName($remoteDbId);';
    await db.execute(sql);
    sql = 'CREATE INDEX idx_${tableName}_update_at_value ON $tableName($colUpdatedAtValue);';
    await db.execute(sql);
  }

  @override
  Map<String, dynamic> normalizeMap(Map<String, dynamic> map) {
    return PaymentsModel.fromJson(map).toJson();
  }

  @override
  PaymentsModel fromMap(Map<String, dynamic> map) {
    return PaymentsModel.fromJson(map);
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

    final String accessToken = CoreUtilities.generateToken(userId, 'processPayment', paramString: tokenParameterString);

    final num _hasherEventMapLastUpdated = await baseService.getLastUpdatedTime(
      internalSqlDb,
      hasherEventMapTableHelper,
      hasherEventMapTableHelper.getTableName(appDomainType),
      hasherEventMapTableHelper.colUpdatedAtValue,
    );
    final DateTime hasherEventMapUpdatedAfter = _hasherEventMapLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_hasherEventMapLastUpdated + 1000);

    final num _hasherKennelMapLastUpdated = await baseService.getLastUpdatedTime(
      internalSqlDb,
      hasherKennelMapTableHelper,
      hasherKennelMapTableHelper.getTableName(appDomainType),
      hasherKennelMapTableHelper.colUpdatedAtValue,
    );
    final DateTime hasherKennelMapUpdatedAfter = _hasherKennelMapLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_hasherKennelMapLastUpdated + 1000);

    final num _paymentsLastUpdated = await baseService.getLastUpdatedTime(
      internalSqlDb,
      paymentsTableHelper,
      paymentsTableHelper.getTableName(appDomainType),
      paymentsTableHelper.colUpdatedAtValue,
    );
    final DateTime paymentsUpdatedAfter = _paymentsLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_paymentsLastUpdated + 1000);

    final num _kennelCreditsLastUpdated = await baseService.getLastUpdatedTime(
      internalSqlDb,
      kennelCreditsTableHelper,
      kennelCreditsTableHelper.getTableName(appDomainType),
      kennelCreditsTableHelper.colUpdatedAtValue,
    );
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
      'appDomainType': appDomainStr
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

    if (appDomainType == AppDomainType.event) {
      results = await syncEventAdminService.updateSqlTablesWithResultsFromBackendApiCall(response.body);
    } else {
      results = await syncUserDataService.updateSqlTablesWithResultsFromBackendApiCall(response.body);
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

    final String accessToken = CoreUtilities.generateToken(userId, 'getPaymentReport');

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
