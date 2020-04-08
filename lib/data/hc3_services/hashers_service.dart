import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/data/hc3_services/sync_user_data_service.dart';
import 'package:harrier_central/data/hc3_services/sync_event_admin_service.dart';
import 'package:harrier_central/data/hc3_services/sync_kennel_admin_service.dart';
import 'package:ive_flutter_core/database/base_service.dart';
import 'package:harrier_central/database/tables.dart';

import 'package:json_annotation/json_annotation.dart';

part 'hashers_service.g.dart';

@JsonSerializable(fieldRename: FieldRename.none)
class HashersModel implements BaseModel {
  HashersModel({
    this.hasherId,
    this.homeKennelId,
    this.firstName,
    this.lastName,
    this.dispName,
    this.hashName,
    this.email,
    this.photo,
    this.dispPref,
    this.resetCode,
    this.qrCode,
    this.includeInGlobalHashDirectory,
    this.preferences,
    this.removed,
    this.updatedAt,
  });

  factory HashersModel.fromJson(Map<String, dynamic> json) => _$HashersModelFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$HashersModelToJson(this);

  final String hasherId;
  final String homeKennelId;
  String firstName;
  String lastName;
  String dispName;
  String hashName;
  String email;
  String photo;
  int dispPref;
  String resetCode;
  String qrCode;
  int includeInGlobalHashDirectory;
  int preferences;

  final int removed;
  final DateTime updatedAt;
}

class HashersTableHelper with BaseFields implements BaseTableHelper {
  HashersTableHelper();

  @override
  num forceRequeryInterval;

  @override
  num cacheDuration;

  @override
  String tableName = 'hashers';

  @override
  String getTableName(TableType type) {
    return tableName;
  }

  @override
  String remoteDbId = 'hasherId';

  final String colHasherId = 'hasherId';
  final String colHomeKennelId = 'homeKennelId';
  final String colFirstName = 'firstName';
  final String colLastName = 'lastName';
  final String colDispName = 'dispName';
  final String colHashName = 'hashName';
  final String colEmail = 'email';
  final String colPhoto = 'photo';
  final String colDispPref = 'dispPref';
  final String colResetCode = 'resetCode';
  final String colQrCode = 'qrCode';
  final String colIncludeInGlobalHashDirectory = 'includeInGlobalHashDirectory';
  final String colPreferences = 'preferences';

  @override
  Future<dynamic> createTable(Database db, int version, TableType tableType) async {
    await db.execute('''
          CREATE TABLE $tableName (
            $colId INTEGER PRIMARY KEY,

            $colHasherId TEXT NOT NULL,
            $colHomeKennelId TEXT,
            $colFirstName TEXT,
            $colLastName TEXT,
            $colDispName TEXT,
            $colHashName TEXT,
            $colEmail TEXT,
            $colPhoto TEXT,
            $colDispPref INT,
            $colResetCode TEXT,
            $colQrCode TEXT,
            $colIncludeInGlobalHashDirectory INT,
            $colPreferences INT,

            $colRemoved NUM,
            $colUpdatedAt TEXT,
            $colUpdatedAtValue NUM NULL
          )
          ''');

    await db.execute('CREATE INDEX idx_${tableName}_id ON $tableName($remoteDbId);');
    await db.execute('CREATE INDEX idx_${tableName}_update_at_value ON $tableName($colUpdatedAtValue);');
  }

  // @override
  // Map<String, dynamic> toMap(dynamic item) {
  //   final Map<String, dynamic> map = _$HashersModelToJson(item);
  //   return map;
  // }

  @override
  Map<String, dynamic> normalizeMap(Map<String, dynamic> map) {
    // do we need to block the data from the email field?
    return HashersModel.fromJson(map).toJson();
  }

  @override
  HashersModel fromMap(Map<String, dynamic> map) {
    return HashersModel.fromJson(map);
  }
}

class HashersService extends BaseService {
  // ============ Functions go here =============

  Future<String> addEditUser(
      {String targetUserId,
      String firstName,
      String lastName,
      String email,
      String hashName,
      String photo,
      String eventId,
      String kennelId,
      String historicalPackRunCount,
      String historicalHaringCount,
      bool historicalCountIsEstimate,
      int followKennelOnAddNewUser,
      int includeInGlobalHashDirectory = -1,
      int preferences = -1}) async {
    if (globalConnectionStatus == connectionStatus_notConnected) {
      return '';
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    bool newUserForThisDevice = false;

    final String hcVersion = getStringPref(StringPrefsEnum.harrierCentralVersion);
    String userId = getStringPref(StringPrefsEnum.userId);
    if ((userId == null) || (userId.isEmpty)) {
      userId = GUID_EMPTY;
      newUserForThisDevice = true;
    }

    final String accessToken = Utilities.generateToken(userId.toUpperCase(), 'addEditUser', paramString: targetUserId.toUpperCase());

    DateTime hashersUpdatedAfter;
    DateTime hasherEventMapUpdatedAfter;
    DateTime hasherKennelMapUpdatedAfter;

    if (!newUserForThisDevice) {
      final num _hashersLastUpdated = await getLastUpdatedTime(
        internalSqlDb,
        hashersTableHelper,
        Tables.getTableName(hashersTableHelper),
        hashersTableHelper.colUpdatedAtValue,
      );
      hashersUpdatedAfter = _hashersLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_hashersLastUpdated + 1000);

      final num _hasherEventMapLastUpdated = await baseService.getLastUpdatedTime(
        internalSqlDb,
        hasherEventMapTableHelper,
        Tables.getTableName(hasherEventMapTableHelper, tableType: TableType.hemEventAdmin),
        hasherEventMapTableHelper.colUpdatedAtValue,
      );
      hasherEventMapUpdatedAfter = _hasherEventMapLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_hasherEventMapLastUpdated + 1000);

      final num _hasherKennelMapLastUpdated = await baseService.getLastUpdatedTime(
        internalSqlDb,
        hasherKennelMapTableHelper,
        Tables.getTableName(hasherKennelMapTableHelper, tableType: ((eventId != null) && (eventId.isNotEmpty) && (eventId != GUID_EMPTY)) ? TableType.hkmEventAdmin : TableType.hkmKennelAdmin),
        hasherKennelMapTableHelper.colUpdatedAtValue,
      );
      hasherKennelMapUpdatedAfter = _hasherKennelMapLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_hasherKennelMapLastUpdated + 1000);
    } else {
      // do this to suppress any records being returned through the sync mechanism
      hashersUpdatedAfter = DateTime(2050, 1, 1);
      hasherEventMapUpdatedAfter = DateTime(2050, 1, 1);
    }

    final String body = jsonEncode(<String, String>{
      'userId': userId,
      'accessToken': accessToken,
      'hcVersion': hcVersion,
      'hashersUpdatedAfter': hashersUpdatedAfter.toString(),
      'hasherEventMapUpdatedAfter': ((eventId != null) && (eventId.isNotEmpty) && (eventId != GUID_EMPTY)) ? hasherEventMapUpdatedAfter.toString() : 'ignore',
      'hasherKennelMapUpdatedAfter': ((kennelId != null) && (kennelId.isNotEmpty) && (kennelId != GUID_EMPTY)) ? hasherKennelMapUpdatedAfter.toString() : 'ignore',
      'targetUserId': targetUserId,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'hashName': hashName,
      'photo': photo,
      'includeInGlobalHashDirectory': includeInGlobalHashDirectory.toString(),
      'preferences': preferences.toString(),
      'eventId': eventId,
      'kennelId': kennelId,
      'historicalPackRunCount': historicalPackRunCount,
      'historicalHaringCount': historicalHaringCount,
      'historicalCountIsEstimate': (historicalCountIsEstimate ?? false) ? '1' : '0',
      'followKennelOnAddNewUser': followKennelOnAddNewUser == null ? null : followKennelOnAddNewUser.toString()
    });

    final http.Response response = await http
        .post(BASE_API_URL + 'hc3_add_edit_user', headers: <String, String>{'content-type': 'application/json'}, body: body
            // Send authorization headers to your backend
            //headers: {HttpHeaders.authorizationHeader: 'Basic your_api_token_here'},
            )
        .catchError(
      (dynamic error) {
        return false;
      },
    );

    if (!newUserForThisDevice) {
      if (((eventId == null) || (eventId == GUID_EMPTY)) && ((kennelId == null) || (kennelId == GUID_EMPTY))) {
        // we don't have either an eventId or a kennelId so all we need to do is update
        // the Hasher table
        await SyncUserDataService.updateSqlTablesWithResultsFromBackendApiCall(response.body);
      } else if ((eventId != null) && (eventId != GUID_EMPTY)) {
        // if we have an eventId we are definitely editing an event irrespective of whether or not
        // there is also a kennelId
        await SyncEventAdminService.updateSqlTablesWithResultsFromBackendApiCall(response.body);
      } else if ((kennelId != null) && (kennelId != GUID_EMPTY)) {
        // if we get here, we have a kennelId but no eventId, which means we are editing kennel members
        await SyncKennelAdminService.updateSqlTablesWithResultsFromBackendApiCall(response.body);
      } else {
        // TODO(James): handle this error, we should never arrive at this point in the code
      }
    }

    return response.body;
  }

  Future<String> changeProfilePicture({String targetUserId, String photo}) async {
    if (globalConnectionStatus == connectionStatus_notConnected) {
      return '';
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    final String hcVersion = getStringPref(StringPrefsEnum.harrierCentralVersion);
    String userId = getStringPref(StringPrefsEnum.userId);
    if ((userId == null) || (userId.isEmpty)) {
      userId = GUID_EMPTY;
    }

    final String accessToken = Utilities.generateToken(userId.toUpperCase(), 'addEditUser', paramString: targetUserId.toUpperCase());

    final String body = jsonEncode(<String, String>{
      'userId': userId,
      'accessToken': accessToken,
      'hcVersion': hcVersion,
      'hashersUpdatedAfter': 'ignore',
      'hasherEventMapUpdatedAfter': 'ignore',
      'hasherKennelMapUpdatedAfter': 'ignore',
      'targetUserId': targetUserId,
      'email': '',
      'firstName': '',
      'lastName': '',
      'hashName': '',
      'photo': photo,
      'includeInGlobalHashDirectory': '-1',
      'eventId': GUID_EMPTY,
      'kennelId': GUID_EMPTY,
      'historicalPackRunCount': '-1',
      'historicalHaringCount': '-1',
      'historicalCountIsEstimate': '-1',
      'followKennelOnAddNewUser': null
    });

    final http.Response response = await http
        .post(BASE_API_URL + 'hc3_add_edit_user', headers: <String, String>{'content-type': 'application/json'}, body: body
            // Send authorization headers to your backend
            //headers: {HttpHeaders.authorizationHeader: 'Basic your_api_token_here'},
            )
        .catchError(
      (dynamic error) {
        return false;
      },
    );

    return response.body;
  }

  Future<String> processFacebookLogin({String firstName, String lastName, String email, String hashName, String photo, String facebookId, String facebookAccessToken, int includeInGlobalHashDirectory = -1}) async {
    if (globalConnectionStatus == connectionStatus_notConnected) {
      return '';
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    bool newUserForThisDevice = false;

    final String hcVersion = getStringPref(StringPrefsEnum.harrierCentralVersion);
    String userId = getStringPref(StringPrefsEnum.userId);
    if ((userId == null) || (userId.isEmpty)) {
      userId = GUID_EMPTY;
      newUserForThisDevice = true;
    }

    DateTime hashersUpdatedAfter;

    if (!newUserForThisDevice) {
      final num _hashersLastUpdated = await getLastUpdatedTime(
        internalSqlDb,
        hashersTableHelper,
        Tables.getTableName(hashersTableHelper),
        hashersTableHelper.colUpdatedAtValue,
      );
      hashersUpdatedAfter = _hashersLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_hashersLastUpdated + 1000);
    } else {
      // do this to suppress any records being returned through the sync mechanism
      hashersUpdatedAfter = DateTime(2050, 1, 1);
    }

    final String accessToken = Utilities.generateToken(userId.toUpperCase(), 'processFacebookLogin', paramString: userId.toUpperCase());

    final String body = jsonEncode(<String, String>{
      'userId': userId,
      'accessToken': accessToken,
      'hashersUpdatedAfter': hashersUpdatedAfter.toString(),
      'firstName': firstName,
      'lastName': lastName,
      'hashName': hashName,
      'email': email,
      'photo': photo,
      'facebookId': facebookId,
      'facebookAccessToken': facebookAccessToken,
      'includeInGlobalHashDirectory': includeInGlobalHashDirectory.toString(),
      'hcVersion': hcVersion,
    });

    final http.Response response = await http
        .post(BASE_API_URL + 'hc3_process_facebook_login', headers: <String, String>{'content-type': 'application/json'}, body: body
            // Send authorization headers to your backend
            //headers: {HttpHeaders.authorizationHeader: 'Basic your_api_token_here'},
            )
        .catchError(
      (dynamic error) {
        return false;
      },
    );

    if (!newUserForThisDevice) {
      await SyncUserDataService.updateSqlTablesWithResultsFromBackendApiCall(response.body);
    }

    return response.body;
  }
}
