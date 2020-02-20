import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;

import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:harrier_central/data/hc3_services/base_service.dart';
import 'package:harrier_central/data/hc3_services/sync_event_admin_service.dart';
import 'package:harrier_central/data/hc3_services/sync_kennel_admin_service.dart';
import 'package:harrier_central/data/hc3_services/sync_user_data_service.dart';
import 'package:harrier_central/util/enums.dart';

class HasherKennelMapModel implements BaseModel {
  HasherKennelMapModel(
      {this.hkmId,
      this.userId,
      this.kennelId,
      this.following,
      this.isMember,
      this.isHomeKennel,
      this.kennelNotificationPreference,
      this.kennelEmailAlertPreference,
      this.mismanagementRoleFlags,
      this.userRoleFlags,
      this.appAccessFlags,
      this.currentPackRunCount,
      this.currentHaringCount,
      this.historicalPackRunCount,
      this.historicalHaringCount,
      this.historicalCountIsEstimate,
      this.dateOfLastRun,
      this.membershipExpirationDate,
      this.memberSince,
      this.isKennelFollowing,
      this.mismanagementRoles,
      this.removed,
      this.updatedAt});

  final String hkmId;
  final String userId;
  final String kennelId;
  int following;
  final int isMember;
  final int isHomeKennel;
  int kennelNotificationPreference;
  int kennelEmailAlertPreference;
  final int mismanagementRoleFlags;
  final int userRoleFlags;
  final int appAccessFlags;
  final int currentPackRunCount;
  final int currentHaringCount;
  final int historicalPackRunCount;
  final int historicalHaringCount;
  final int historicalCountIsEstimate;
  final DateTime dateOfLastRun;
  final DateTime membershipExpirationDate;
  final DateTime memberSince;
  final int isKennelFollowing;
  final int mismanagementRoles;

  final DateTime updatedAt;
  final int removed;

  @override
  List<HasherKennelMapModel> itemsFromJson(String jsonResult) {
    final List<HasherKennelMapModel> items = <HasherKennelMapModel>[];

    HasherKennelMapModel item;

    json.decode(jsonResult).forEach(
      (dynamic jsonItem) {
        item = HasherKennelMapModel(
          hkmId: jsonItem['hkmId'],
          userId: jsonItem['userId'],
          kennelId: jsonItem['kennelId'],
          following: jsonItem['following'],
          isMember: jsonItem['isMember'],
          isHomeKennel: jsonItem['isHomeKennel'],
          kennelNotificationPreference: jsonItem['kennelNotificationPreference'],
          kennelEmailAlertPreference: jsonItem['kennelEmailAlertPreference'],
          mismanagementRoleFlags: jsonItem['mismanagementRoleFlags'] ?? 0,
          userRoleFlags: jsonItem['userRoleFlags'],
          appAccessFlags: jsonItem['appAccessFlags'],
          currentPackRunCount: jsonItem['currentPackRunCount'],
          currentHaringCount: jsonItem['currentHaringCount'],
          historicalPackRunCount: jsonItem['historicalPackRunCount'],
          historicalHaringCount: jsonItem['historicalHaringCount'],
          historicalCountIsEstimate: jsonItem['historicalCountIsEstimate'],
          dateOfLastRun: jsonItem['dateOfLastRun'] == null ? null : DateTime.parse(jsonItem['dateOfLastRun'].toString().substring(0, 19)),
          membershipExpirationDate: jsonItem['membershipExpirationDate'] == null ? null : DateTime.parse(jsonItem['membershipExpirationDate'].toString().substring(0, 19)),
          memberSince: jsonItem['memberSince'] == null ? null : DateTime.parse(jsonItem['memberSince'].toString().substring(0, 19)),
          isKennelFollowing: jsonItem['isKennelFollowing'],
          mismanagementRoles: jsonItem['mismanagementRoles'],
          updatedAt: DateTime.parse(jsonItem['updatedAt'].toString().substring(0, 19)),
          removed: jsonItem['removed'],
        );

        items.add(item);
      },
    );

    if (items.isEmpty) {
      return null;
    }

    return items;
  }
}

class HasherKennelMapTableHelper with BaseFields implements BaseTableHelper {

  @override
  num forceRequeryInterval;

  @override
  num cacheDuration;

  @override
  String tableName = '';

  @override
  String getTableName(TableType tblType) {
    if (tblType == TableType.hkmEventAdmin) {
      return hkmEventAdminTable;
    } else if (tblType == TableType.hkmKennelAdmin) {
      return hkmKennelAdminTable;
    } else {
      return hkmUserTable;
    }
  }

  @override
  String remoteDbId = 'hkmId';

  final String colHkmId = 'hkmId';
  final String colUserId = 'userId';
  final String colKennelId = 'kennelId';
  final String colFollowing = 'following';
  final String colIsMember = 'isMember';
  final String colIsHomeKennel = 'isHomeKennel';
  final String colKennelNotificationPreference = 'kennelNotificationPreference';
  final String colKennelEmailAlertPreference = 'kennelEmailAlertPreference';
  final String colMismanagementRoleFlags = 'mismanagementRoleFlags';
  final String colUserRoleFlags = 'userRoleFlags';
  final String colAppAccessFlags = 'appAccessFlags';
  final String colCurrentPackRunCount = 'currentPackRunCount';
  final String colCurrentHaringCount = 'currentHaringCount';
  final String colHistoricalPackRunCount = 'historicalPackRunCount';
  final String colHistoricalHaringCount = 'historicalHaringCount';
  final String colHistoricalCountIsEstimate = 'historicalCountIsEstimate';
  final String colDateOfLastRun = 'dateOfLastRun';
  final String colMembershipExpirationDate = 'membershipExpirationDate';
  final String colMemberSince = 'memberSince';
  final String colIsKennelFollowing = 'isKennelFollowing';
  final String colMismanagementRoles = 'mismanagementRoles';

  @override
  Future<dynamic> createTable(Database db, int version, TableType tblType) async {
    await db.execute('''
          CREATE TABLE ${getTableName(tblType)} (
            $colId INTEGER PRIMARY KEY,

            $colHkmId TEXT NOT NULL,
            $colUserId TEXT NOT NULL,
            $colKennelId TEXT NOT NULL,
            $colFollowing INT,
            $colIsMember INT,
            $colIsHomeKennel INT,
            $colKennelNotificationPreference INT,
            $colKennelEmailAlertPreference INT,
            $colMismanagementRoleFlags INT,
            $colUserRoleFlags INT,
            $colAppAccessFlags INT,
            $colCurrentPackRunCount INT,
            $colCurrentHaringCount INT,
            $colHistoricalPackRunCount INT,
            $colHistoricalHaringCount INT,
            $colHistoricalCountIsEstimate INT,
            $colDateOfLastRun TEXT,
            $colMembershipExpirationDate TEXT,
            $colMemberSince TEXT,
            $colIsKennelFollowing INT,
            $colMismanagementRoles INT,

            $colRemoved INT,
            $colUpdatedAt TEXT,
            $colUpdatedAtValue NUM NULL
          )
          ''');

    String sql = 'CREATE INDEX idx_${getTableName(tblType)}_id ON ${getTableName(tblType)}($remoteDbId);';
    await db.execute(sql);
    sql = 'CREATE INDEX idx_${getTableName(tblType)}_update_at_value ON ${getTableName(tblType)}($colUpdatedAtValue);';
    await db.execute(sql);
  }

  @override
  Map<String, dynamic> toMap(dynamic item) {
    final Map<String, dynamic> map = <String, dynamic>{
      colHkmId: item.hkmId,
      colUserId: item.userId,
      colKennelId: item.kennelId,
      colFollowing: item.following,
      colIsMember: item.isMember,
      colIsHomeKennel: item.isHomeKennel,
      colKennelNotificationPreference: item.kennelNotificationPreference,
      colKennelEmailAlertPreference: item.kennelEmailAlertPreference,
      colMismanagementRoleFlags: item.mismanagementRoleFlags,
      colUserRoleFlags: item.userRoleFlags,
      colAppAccessFlags: item.appAccessFlags,
      colCurrentPackRunCount: item.currentPackRunCount,
      colCurrentHaringCount: item.currentHaringCount,
      colHistoricalPackRunCount: item.historicalPackRunCount,
      colHistoricalHaringCount: item.historicalHaringCount,
      colHistoricalCountIsEstimate: item.historicalCountIsEstimate,
      colDateOfLastRun: item.dateOfLastRun,
      colMembershipExpirationDate: item.membershipExpirationDate,
      colMemberSince: item.memberSince,
      colIsKennelFollowing: item.isKennelFollowing,
      colMismanagementRoles: item.mismanagementRoles,
      colUpdatedAt: item.updatedAt,
      colRemoved: item.removed,
    };

    return map;
  }

  @override
  Map<String, dynamic> normalizeMap(Map<String, dynamic> inputMap) {
    final Map<String, dynamic> outputMap = <String, dynamic>{
      colHkmId: inputMap[colHkmId],
      colUserId: inputMap[colUserId],
      colKennelId: inputMap[colKennelId],
      colFollowing: inputMap[colFollowing],
      colIsMember: inputMap[colIsMember],
      colIsHomeKennel: inputMap[colIsHomeKennel],
      colKennelNotificationPreference: inputMap[colKennelNotificationPreference],
      colKennelEmailAlertPreference: inputMap[colKennelEmailAlertPreference],
      colMismanagementRoleFlags: inputMap[colMismanagementRoleFlags],
      colUserRoleFlags: inputMap[colUserRoleFlags],
      colAppAccessFlags: inputMap[colAppAccessFlags],
      colCurrentPackRunCount: inputMap[colCurrentPackRunCount],
      colCurrentHaringCount: inputMap[colCurrentHaringCount],
      colHistoricalPackRunCount: inputMap[colHistoricalPackRunCount],
      colHistoricalHaringCount: inputMap[colHistoricalHaringCount],
      colHistoricalCountIsEstimate: inputMap[colHistoricalCountIsEstimate],
      colDateOfLastRun: inputMap[colDateOfLastRun],
      colMembershipExpirationDate: inputMap[colMembershipExpirationDate],
      colMemberSince: inputMap[colMemberSince],
      colIsKennelFollowing: inputMap[colIsKennelFollowing],
      colMismanagementRoles: inputMap[colMismanagementRoles],
      colUpdatedAt: inputMap[colUpdatedAt],
      colUpdatedAtValue: DateTime.parse(inputMap[colUpdatedAt].toString().substring(0, 19)).millisecondsSinceEpoch,
      colRemoved: inputMap[colRemoved],
    };

    return outputMap;
  }

  @override
  HasherKennelMapModel fromMap(Map<String, dynamic> map) {
    final HasherKennelMapModel item = HasherKennelMapModel(
      hkmId: map[colHkmId],
      userId: map[colUserId],
      kennelId: map[colKennelId],
      following: map[colFollowing],
      isMember: map[colIsMember],
      isHomeKennel: map[colIsHomeKennel],
      kennelNotificationPreference: map[colKennelNotificationPreference],
      kennelEmailAlertPreference: map[colKennelEmailAlertPreference],
      mismanagementRoleFlags: map[colMismanagementRoleFlags],
      userRoleFlags: map[colUserRoleFlags],
      appAccessFlags: map[colAppAccessFlags],
      currentPackRunCount: map[colCurrentPackRunCount],
      currentHaringCount: map[colCurrentHaringCount],
      historicalPackRunCount: map[colHistoricalPackRunCount],
      historicalHaringCount: map[colHistoricalHaringCount],
      historicalCountIsEstimate: map[colHistoricalCountIsEstimate],
      dateOfLastRun: (map[colDateOfLastRun] == null) ? null : DateTime.parse(map[colDateOfLastRun].toString().substring(0, 19)),
      membershipExpirationDate: (map[colMembershipExpirationDate] == null) ? null : DateTime.parse(map[colMembershipExpirationDate].toString().substring(0, 19)),
      memberSince: (map[colMemberSince] == null) ? null : DateTime.parse(map[colMemberSince].toString().substring(0, 19)),
      isKennelFollowing: map[colIsKennelFollowing],
      mismanagementRoles: map[colMismanagementRoles],
      updatedAt: DateTime.parse(map[colUpdatedAt].toString().substring(0, 19)),
      removed: map[colRemoved],
    );

    return item;
  }
}

class HasherKennelMapService {

  //=================  Domain specific functions ================

  Future<List<dynamic>> updateHasherKennelStatus(String kennelId, TableType tblType, {int monthsToAddToMembership, String targetUserId, int notificationState = -1, int emailAlertState = -1, int followingState = -1, int isHomeKennel = -1}) async {
    List<dynamic> adHocData;

    if (globalConnectionStatus == connectionStatus_notConnected) {
      return adHocData;
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    if (followingState == followTypeToggleHomeKennel.value) {
      followingState = -1;
    }

    final String userId = getStringPref(StringPrefsEnum.userId);
    final String accessToken = Utilities.generateToken(userId.toUpperCase(), 'joinKennel');

    final num _hasherKennelMapLastUpdated = await baseService.getLastUpdatedTime(hasherKennelMapTableHelper,hasherKennelMapTableHelper.colUpdatedAtValue, tableType: TableType.hkmEventAdmin);
    final num _kennelsLastUpdated = await baseService.getLastUpdatedTime(kennelsTableHelper, kennelsTableHelper.colUpdatedAtValue);
    final num _hashersLastUpdated = await hashersService.getLastUpdatedTime(hashersTableHelper, hashersTableHelper.colUpdatedAtValue);

    final DateTime hasherKennelMapUpdatedAfter = _hasherKennelMapLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_hasherKennelMapLastUpdated + 1000);
    final DateTime kennelsUpdatedAfter = _kennelsLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_kennelsLastUpdated + 1000);
    final DateTime hashersUpdatedAfter = _hashersLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_hashersLastUpdated + 1000);

    monthsToAddToMembership ??= 0;

    final String body = jsonEncode(<String, Object>{
      'userId': userId,
      'accessToken': accessToken,
      'kennelId': kennelId,
      'targetUserId': targetUserId ?? userId,
      'isFollowing': followingState,
      'isHomeKennel': isHomeKennel,
      'notificationState': notificationState,
      'emailAlertState': emailAlertState,
      'monthsToAddToMembership': monthsToAddToMembership,
      'hasherKennelMapUpdatedAfter': hasherKennelMapUpdatedAfter.toString().substring(0, 19),
      'kennelsUpdatedAfter': kennelsUpdatedAfter.toString().substring(0, 19),
      'hashersUpdatedAfter': hashersUpdatedAfter.toString().substring(0, 19)
    });

    final http.Response response = await http.post(BASE_API_URL + 'hc3_join_kennel', headers: <String, String>{'content-type': 'application/json'}, body: body).catchError(
      (dynamic error) {
        return false;
      },
    );

    if (tblType == TableType.hkmEventAdmin) {
      adHocData = await SyncEventAdminService.updateSqlTablesWithResultsFromBackendApiCall(response.body);
    } else if (tblType == TableType.hkmKennelAdmin) {
      adHocData = await SyncKennelAdminService.updateSqlTablesWithResultsFromBackendApiCall(response.body);
    } else {
      adHocData = await SyncUserDataService.updateSqlTablesWithResultsFromBackendApiCall(response.body);
    }

    return adHocData;
  }
}
