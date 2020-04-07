import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/core/base_service.dart';
import 'package:harrier_central/data/hc3_services/sync_event_admin_service.dart';
import 'package:harrier_central/data/hc3_services/sync_user_data_service.dart';
import 'package:harrier_central/database/tables.dart';

import 'package:json_annotation/json_annotation.dart';

part 'hasher_event_map_service.g.dart';

@JsonSerializable(fieldRename: FieldRename.none)
class HasherEventMapModel implements BaseModel {
  HasherEventMapModel(
      {this.hemId,
      this.userId,
      this.eventId,
      this.hasherOwnEventId,
      this.userStartEvent,
      this.userEndEvent,
      this.rsvpState,
      this.attendenceState,
      this.isHare,
      this.eventNotificationPreference,
      this.eventEmailAlertPreference,
      this.eventCountOverride,
      this.virginVisitorType,
      this.displayName,
      this.email,
      this.phoneNumber,
      this.removed,
      this.updatedAt});

  factory HasherEventMapModel.fromJson(Map<String, dynamic> json) => _$HasherEventMapModelFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$HasherEventMapModelToJson(this);

  final String hemId;
  final String userId;
  final String eventId;
  final String hasherOwnEventId;
  final String userStartEvent;
  final String userEndEvent;
  int rsvpState;
  final int attendenceState;
  int isHare;
  int eventNotificationPreference;
  int eventEmailAlertPreference;
  final num eventCountOverride;
  final num virginVisitorType;
  final String displayName;
  final String email;
  final String phoneNumber;

  final int removed;
  final DateTime updatedAt;
}

class HasherEventMapTableHelper with BaseFields implements BaseTableHelper {
  HasherEventMapTableHelper();

  @override
  num forceRequeryInterval;

  @override
  num cacheDuration;

  @override
  String tableName = '';

  @override
  String getTableName(TableType tblType) {
    if (tblType == TableType.hemEventAdmin) {
      return hemAdminTable;
    }
    return hemUserTable;
  }

  @override
  String remoteDbId = 'hemId';

  final String colHemId = 'hemId';
  final String colUserId = 'userId';
  final String colEventId = 'eventId';
  final String colHasherOwnEventId = 'hasherOwnEventId';
  final String colUserStartEvent = 'userStartEvent';
  final String colUserEndEvent = 'userEndEvent';
  final String colRsvpState = 'rsvpState';
  final String colAttendenceState = 'attendenceState';
  final String colIsHare = 'isHare';
  final String colEventNotificationPreference = 'eventNotificationPreference';
  final String colEventEmailAlertPreference = 'eventEmailAlertPreference';
  final String colEventCountOverride = 'eventCountOverride';
  final String colVirginVisitorType = 'virginVisitorType';
  final String colDisplayName = 'displayName';
  final String colEmail = 'email';
  final String colPhoneNumber = 'phoneNumber';

  @override
  Future<dynamic> createTable(Database db, int version, TableType tblType) async {
    await db.execute('''
          CREATE TABLE ${getTableName(tblType)} (
            $colId INTEGER PRIMARY KEY,

            $colHemId TEXT NOT NULL,
            $colUserId TEXT NOT NULL,
            $colEventId TEXT,
            $colHasherOwnEventId TEXT,
            $colUserStartEvent TEXT,
            $colUserEndEvent TEXT,
            $colRsvpState INT,
            $colAttendenceState INT,
            $colIsHare INT,
            $colEventNotificationPreference INT,
            $colEventEmailAlertPreference INT,
            $colEventCountOverride NUM,
            $colVirginVisitorType NUM,
            $colDisplayName TEXT,
            $colEmail TEXT,
            $colPhoneNumber TEXT,

            $colRemoved NUM,
            $colUpdatedAt TEXT,
            $colUpdatedAtValue NUM NULL

          )
          ''');

    await db.execute('CREATE INDEX idx_${getTableName(tblType)}_id ON ${getTableName(tblType)}($remoteDbId);');
    await db.execute('CREATE INDEX idx_${getTableName(tblType)}_update_at_value ON ${getTableName(tblType)}($colUpdatedAtValue);');
  }

  // @override
  // Map<String, dynamic> toMap(dynamic item) {
  //   final Map<String, dynamic> map = _$HasherEventMapModelToJson(item);

  //   return map;
  // }

  @override
  Map<String, dynamic> normalizeMap(Map<String, dynamic> map) {
    return HasherEventMapModel.fromJson(map).toJson();
  }

  @override
  HasherEventMapModel fromMap(Map<String, dynamic> map) {
    return HasherEventMapModel.fromJson(map);
  }
}

class HasherEventMapService {
  //==============  Domain specific functions ===========

  Future<Map<String, String>> sendRunCountReportByEmail({String kennelId, String kennelName}) async {
    final String userId = getStringPref(StringPrefsEnum.userId);
    final String userName = getStringPref(StringPrefsEnum.displayName);
    final String emailAddress = getStringPref(StringPrefsEnum.email);

    final String accessToken1 = Utilities.generateToken(userId.toUpperCase(), 'getRuns');

    final String accessToken2 = Utilities.generateToken(userId, 'getMyKennelRunTotals');

    if ((emailAddress ?? '').isNotEmpty) {
      final String body = jsonEncode(<String, String>{'userId': userId, 'accessToken1': accessToken1, 'accessToken2': accessToken2, 'kennelId': kennelId, 'kennelName': kennelName, 'userName': userName, 'emailAddress': emailAddress});

      final http.Response response = await http.post(EMAIL_RUN_REPORT_API_URL, headers: <String, String>{'content-type': 'application/json'}, body: body).catchError(
        (dynamic error) {
          return <String, String>{'result': 'error', 'email': ''};
        },
      );

      return <String, String>{'result': response.body, 'email': emailAddress};
    }
    return <String, String>{'result': 'No valid email address found', 'email': ''};
  }

  Future<List<dynamic>> joinEvent(String eventId, TableType tblType, String hasherId, String hasherEventMapId, AppDomainType appDomainType, {int rsvpState = -1, int attendenceState = -1, int isHare = -1, int virginVisitorType = 0, int notificationState = -1, int emailAlertState = -1}) async {
    if (globalConnectionStatus == connectionStatus_notConnected) {
      return null;
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    final String userId = getStringPref(StringPrefsEnum.userId);
    final String accessToken = Utilities.generateToken(userId.toUpperCase(), 'joinEvent');

    final num _hasherEventMapLastUpdated = await baseService.getLastUpdatedTime(
      internalSqlDb,
      hasherEventMapTableHelper,
      Tables.getTableName(hasherEventMapTableHelper,tableType:appDomainType == AppDomainType.event ? TableType.hemEventAdmin : TableType.hemUser),
      hasherEventMapTableHelper.colUpdatedAtValue,
    );
    final num _hasherKennelMapLastUpdated = await baseService.getLastUpdatedTime(
      internalSqlDb,
      hasherKennelMapTableHelper,
      Tables.getTableName(hasherKennelMapTableHelper,tableType:appDomainType == AppDomainType.event ? TableType.hkmEventAdmin : TableType.hkmUser),
      hasherKennelMapTableHelper.colUpdatedAtValue,
    );
    final num _paymentsLastUpdated = await baseService.getLastUpdatedTime(
      internalSqlDb,
      paymentsTableHelper,
      Tables.getTableName(paymentsTableHelper,tableType:appDomainType == AppDomainType.event ? TableType.paymentsEvent : TableType.paymentsUser),
      paymentsTableHelper.colUpdatedAtValue,
    );
    final num _kennelCreditsLastUpdated = await baseService.getLastUpdatedTime(
      internalSqlDb,
      kennelCreditsTableHelper,
      Tables.getTableName(kennelCreditsTableHelper),
      kennelCreditsTableHelper.colUpdatedAtValue,
    );

    final DateTime hasherEventMapUpdatedAfter = _hasherEventMapLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_hasherEventMapLastUpdated + 1000);
    final DateTime hasherKennelMapUpdatedAfter = _hasherKennelMapLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_hasherKennelMapLastUpdated + 1000);
    final DateTime paymentsUpdatedAfter = _paymentsLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_paymentsLastUpdated + 1000);
    final DateTime kennelCreditsUpdatedAfter = _kennelCreditsLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_kennelCreditsLastUpdated + 1000);

    final String body = jsonEncode(<String, Object>{
      'userId': userId,
      'accessToken': accessToken,
      'eventId': eventId,
      'hasherId': hasherId,
      'hasherEventMapId': hasherEventMapId,
      'isHare': isHare,
      'rsvpState': rsvpState,
      'attendenceState': attendenceState,
      'virginVisitorType': virginVisitorType,
      'notificationState': notificationState,
      'emailAlertState': emailAlertState,
      'hasherEventMapUpdatedAfter': hasherEventMapUpdatedAfter.toString(),
      'hasherKennelMapUpdatedAfter': hasherKennelMapUpdatedAfter.toString(),
      'paymentsUpdatedAfter': paymentsUpdatedAfter.toString(),
      'kennelCreditsUpdatedAfter': kennelCreditsUpdatedAfter.toString()
    });

    final http.Response response = await http.post(BASE_API_URL + 'hc3_join_event', headers: <String, String>{'content-type': 'application/json'}, body: body).catchError(
      (dynamic error) {
        return false;
      },
    );

    List<dynamic> adHocData;

    if (tblType == TableType.hemEventAdmin) {
      adHocData = await SyncEventAdminService.updateSqlTablesWithResultsFromBackendApiCall(response.body);
    } else {
      adHocData = await SyncUserDataService.updateSqlTablesWithResultsFromBackendApiCall(response.body);
    }

    return adHocData;
  }

  Future<List<dynamic>> joinEventAsVisitor(String eventId, TableType tblType, String displayName, int virginVisitorType, int attendenceState, String email, String phoneNumber, AppDomainType appDomainType) async {
    if (globalConnectionStatus == connectionStatus_notConnected) {
      return null;
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    final String userId = getStringPref(StringPrefsEnum.userId);
    final String accessToken = Utilities.generateToken(userId.toUpperCase(), 'joinEventAsVisitor');

    final num _hasherEventMapLastUpdated = await baseService.getLastUpdatedTime(
      internalSqlDb,
      hasherEventMapTableHelper,
      Tables.getTableName(hasherEventMapTableHelper,tableType:appDomainType == AppDomainType.event ? TableType.hemEventAdmin : TableType.hemUser ),
      hasherEventMapTableHelper.colUpdatedAtValue,
    );
    final num _paymentsLastUpdated = await baseService.getLastUpdatedTime(
      internalSqlDb,
      paymentsTableHelper,
      Tables.getTableName(paymentsTableHelper,tableType:appDomainType == AppDomainType.event ? TableType.paymentsEvent : TableType.paymentsUser ),
      paymentsTableHelper.colUpdatedAtValue,
    );
    final num _kennelCreditsLastUpdated = await baseService.getLastUpdatedTime(
      internalSqlDb,
      kennelCreditsTableHelper,
      Tables.getTableName(kennelCreditsTableHelper),
      kennelCreditsTableHelper.colUpdatedAtValue,
    );

    final DateTime hasherEventMapUpdatedAfter = _hasherEventMapLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_hasherEventMapLastUpdated + 1000);
    final DateTime paymentsUpdatedAfter = _paymentsLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_paymentsLastUpdated + 1000);
    final DateTime kennelCreditsUpdatedAfter = _kennelCreditsLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_kennelCreditsLastUpdated + 1000);

    final String body = jsonEncode(<String, Object>{
      'userId': userId,
      'accessToken': accessToken,
      'eventId': eventId,
      'displayName': displayName ?? '<no name>',
      'virginVisitorType': virginVisitorType == null ? null : virginVisitorType.toString(),
      'attendenceState': attendenceState == null ? null : attendenceState.toString(),
      'email': email,
      'phoneNumber': phoneNumber,
      'hasherEventMapUpdatedAfter': hasherEventMapUpdatedAfter.toString(),
      'paymentsUpdatedAfter': paymentsUpdatedAfter.toString(),
      'kennelCreditsUpdatedAfter': kennelCreditsUpdatedAfter.toString()
    });

    final http.Response response = await http.post(BASE_API_URL + 'hc3_join_event_as_visitor', headers: <String, String>{'content-type': 'application/json'}, body: body).catchError(
      (dynamic error) {
        return false;
      },
    );

    final List<dynamic> adHocData = await SyncEventAdminService.updateSqlTablesWithResultsFromBackendApiCall(response.body);

    return adHocData;
  }
}
