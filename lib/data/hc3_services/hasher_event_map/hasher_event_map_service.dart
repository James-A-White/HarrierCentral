import 'package:harrier_central/imports.dart';

class HasherEventMapTableHelper extends BaseTableHelper with BaseFields {
  HasherEventMapTableHelper() {
    remoteDbId = 'hemId';
    humanReadableTableName = 'Event Data';
    pageSize = SyncUserDataService.pageSize_hemTable;
    tableFlag = SyncUserDataService.flagHasherEventMapTable;
  }

  @override
  String getTableName(dynamic appDomainType) {
    String tableName = '';
    switch (appDomainType) {
      case AppDomainType.event:
        tableName = 'hasherEventMapForRunAdmin';
        break;
      case AppDomainType.kennel:
        tableName = 'hasherEventMapForKennelAdmin';
        break;
      case AppDomainType.user:
        tableName = 'hasherEventMap';
        break;
      default:
        assert(false);
    }
    return tableName;
  }

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
  final String colTotalHaring = 'totalHaring';
  final String colTotalHaringThisKennel = 'totalHaringThisKennel';
  final String colTotalRuns = 'totalRuns';
  final String colTotalRunsThisKennel = 'totalRunsThisKennel';

  final String colEventCountOverride = 'eventCountOverride';
  final String colVirginVisitorType = 'virginVisitorType';
  final String colDisplayName = 'displayName';
  final String colEmail = 'email';
  final String colPhoneNumber = 'phoneNumber';

  final String colEventName = 'hemEventName';
  final String colEventNumber = 'hemEventNumber';
  final String colEventStartDatetime = 'hemEventStartDatetime';
  final String colCanEditRunAttendence = 'hemCanEditRunAttendence';
  final String colEventKennelId = 'hemEventKennelId';
  final String colEventIsCountedAndVisible = 'hemEventIsCountedAndVisible';
  final String colKennelUserPhoto = 'hemKennelUserPhoto';
  final String colKennelHashName = 'hemKennelHashName';

  @override
  Future<dynamic> createTable(
      Database db, int version, dynamic appDomainType) async {
    await db.execute('''
          CREATE TABLE ${getTableName(appDomainType)} (
            $colId INTEGER PRIMARY KEY,

            $colHemId TEXT NOT NULL,
            $colUserId TEXT NOT NULL,
            $colEventId TEXT NOT NULL,
            $colHasherOwnEventId TEXT,
            $colUserStartEvent TEXT,
            $colUserEndEvent TEXT,
            $colRsvpState INT NOT NULL,
            $colAttendenceState INT NOT NULL,
            $colIsHare INT NOT NULL,
            $colEventNotificationPreference INT,
            $colEventEmailAlertPreference INT,

            $colTotalHaring INT,
            $colTotalHaringThisKennel INT,
            $colTotalRuns INT,
            $colTotalRunsThisKennel INT,

            $colEventCountOverride NUM,
            $colVirginVisitorType NUM NOT NULL,
            $colDisplayName TEXT,
            $colEmail TEXT,
            $colPhoneNumber TEXT,

            $colEventName TEXT,
            $colEventNumber INT,
            $colEventStartDatetime TEXT NOT NULL,
            $colCanEditRunAttendence NUM,
            $colEventKennelId TEXT,
            $colEventIsCountedAndVisible INT,
            $colKennelUserPhoto TEXT,
            $colKennelHashName TEXT,
            $colRemoved INT NOT NULL,
            $colUpdatedAt TEXT NOT NULL,
            $colUpdatedAtValue INT NULL

          )
          ''');
  }

  @override
  Future<void> createIndexes(
      Database db, int version, dynamic appDomainType) async {
    await db.execute(
        'CREATE INDEX idx_${getTableName(appDomainType)}_id ON ${getTableName(appDomainType)}($remoteDbId);');
    await db.execute(
        'CREATE INDEX idx_${getTableName(appDomainType)}_update_at_value ON ${getTableName(appDomainType)}($colUpdatedAtValue);');
  }

  // @override
  // Map<String, dynamic> toMap(dynamic item) {
  //   final Map<String, dynamic> map = _$HasherEventMapModelToJson(item);

  //   return map;
  // }

  @override
  Map<String, dynamic> normalizeMap(Map<String, dynamic> inputMap) {
    return HasherEventMapModel.fromJson(inputMap).toJson();
  }

  @override
  HasherEventMapModel fromMap(Map<String, dynamic> map) {
    return HasherEventMapModel.fromJson(map);
  }
}

class HasherEventMapService {
  //==============  Domain specific functions ===========

  Future<Map<String, String>> sendRunCountReportByEmail({
    required String kennelId,
    required String kennelName,
  }) async {
    final String userId = getStringPref(StringPrefsEnum.userId)!;
    final String userName = getStringPref(StringPrefsEnum.displayName)!;
    final String? emailAddress = getStringPref(StringPrefsEnum.email);

    final String accessToken1 =
        Utilities.generateToken(userId.toUpperCase(), 'getRuns');

    final String accessToken2 =
        Utilities.generateToken(userId, 'getMyKennelRunTotals');

    if ((emailAddress ?? '').isNotEmpty) {
      final String body = jsonEncode(<String, String>{
        'userId': userId,
        'accessToken1': accessToken1,
        'accessToken2': accessToken2,
        'kennelId': kennelId,
        'kennelName': kennelName,
        'userName': userName,
        'emailAddress': emailAddress!
      });

      final Response response = await post(Uri.parse(EMAIL_RUN_REPORT_API_URL),
              headers: <String, String>{'content-type': 'application/json'},
              body: body)
          .catchError(
        (dynamic error) {
          return Future<Response>.value(Response('', 500));
        },
      );

      return <String, String>{'result': response.body, 'email': emailAddress};
    }
    return <String, String>{
      'result': 'No valid email address found',
      'email': ''
    };
  }

  Future<List<dynamic>> setEmailAndNotificationPreferences(
    String eventId,
    String hasherId,
    AppDomainType appDomainType,
    EnumNotificationState<int> notificationPreference,
    EnumEmailAlertState<int> emailPreference,
  ) async {
    if (G0<AppModel>().connectionStatus == EnumConnectionStatus2.notConnected) {
      return <dynamic>[];
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    final String userId = getStringPref(StringPrefsEnum.userId)!;

    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret =
        getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    final String accessToken = Utilities.generateToken(
      userId.toUpperCase(),
      'hcapp_setEmailAndNotificationPrefs',
      paramString: deviceSecret,
    );

    final int hasherEventMapLastUpdated =
        await G0<TableModel>().baseService.getLastUpdatedTime(
              G0<Database>(),
              G0<TableModel>().hasherEventMapTableHelper,
              G0<TableModel>()
                  .hasherEventMapTableHelper
                  .getTableName(appDomainType),
              G0<TableModel>().hasherEventMapTableHelper.colUpdatedAtValue,
            );
    final int hasherKennelMapLastUpdated =
        await G0<TableModel>().baseService.getLastUpdatedTime(
              G0<Database>(),
              G0<TableModel>().hasherKennelMapTableHelper,
              G0<TableModel>()
                  .hasherKennelMapTableHelper
                  .getTableName(appDomainType),
              G0<TableModel>().hasherKennelMapTableHelper.colUpdatedAtValue,
            );

    final DateTime hasherEventMapUpdatedAfter =
        DateTime.fromMicrosecondsSinceEpoch(hasherEventMapLastUpdated + 1);
    final DateTime hasherKennelMapUpdatedAfter =
        DateTime.fromMicrosecondsSinceEpoch(hasherKennelMapLastUpdated + 1);

    //     final DateTime hasherEventMapUpdatedAfter = hasherEventMapLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMicrosecondsSinceEpoch(hasherEventMapLastUpdated + 1);
    // final DateTime hasherKennelMapUpdatedAfter = hasherKennelMapLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMicrosecondsSinceEpoch(hasherKennelMapLastUpdated + 1);

    final Map<String, Object?> bodyMap = <String, Object?>{
      'queryType': 'setEmailAndNotificationPrefs',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'hasherId': hasherId,
      'kennelId': null,
      'eventId': eventId,
      'emailPreference': emailPreference.value,
      'notificationPreference': notificationPreference.value,
      'hasherEventMapUpdatedAfter': hasherEventMapUpdatedAfter.toString(),
      'hasherKennelMapUpdatedAfter': hasherKennelMapUpdatedAfter.toString(),
    };

    final String body = jsonEncode(bodyMap);

    final String responseBody = await ServiceCommon.sendHttpPostV2(body);

    List<dynamic> adHocData = <dynamic>[];

    if (!responseBody.startsWith(ERROR_PREFIX)) {
      if (appDomainType == AppDomainType.event) {
        adHocData = await G0<TableModel>()
            .syncEventAdminService
            .updateSqlTablesWithResultsFromBackendApiCall(responseBody);
      } else if (appDomainType == AppDomainType.user) {
        adHocData = await G0<TableModel>()
            .syncUserDataService
            .updateSqlTablesWithResultsFromApiWithAdHocData(responseBody);
      } else {
        assert(false);
      }
    }

    return adHocData;
  }

  Future<List<dynamic>> setEventRsvp(
    String eventId,
    String? hasherId,
    AppDomainType appDomainType,
    int rsvpState, {
    int? isHare,
    String? hemId,
  }) async {
    if (G0<AppModel>().connectionStatus == EnumConnectionStatus2.notConnected) {
      return <dynamic>[];
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret =
        getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    final String userId = getStringPref(StringPrefsEnum.userId)!;
    final String accessToken = Utilities.generateToken(
      userId.toUpperCase(),
      'hcapp_setEventRsvp',
      paramString: deviceSecret.toUpperCase(),
    );

    final int hasherEventMapLastUpdated =
        await G0<TableModel>().baseService.getLastUpdatedTime(
              G0<Database>(),
              G0<TableModel>().hasherEventMapTableHelper,
              G0<TableModel>()
                  .hasherEventMapTableHelper
                  .getTableName(appDomainType),
              G0<TableModel>().hasherEventMapTableHelper.colUpdatedAtValue,
            );
    final int hasherKennelMapLastUpdated =
        await G0<TableModel>().baseService.getLastUpdatedTime(
              G0<Database>(),
              G0<TableModel>().hasherKennelMapTableHelper,
              G0<TableModel>()
                  .hasherKennelMapTableHelper
                  .getTableName(appDomainType),
              G0<TableModel>().hasherKennelMapTableHelper.colUpdatedAtValue,
            );

    final DateTime hasherEventMapUpdatedAfter =
        DateTime.fromMicrosecondsSinceEpoch(hasherEventMapLastUpdated + 1);
    final DateTime hasherKennelMapUpdatedAfter =
        DateTime.fromMicrosecondsSinceEpoch(hasherKennelMapLastUpdated + 1);

    final Map<String, Object?> bodyMap = <String, Object?>{
      'queryType': 'setEventRsvp',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'eventId': eventId,
      'hasherId': hasherId,
      'rsvpState': rsvpState,
      'hasherEventMapUpdatedAfter': hasherEventMapUpdatedAfter.toString(),
      'hasherKennelMapUpdatedAfter': hasherKennelMapUpdatedAfter.toString(),
      'hemId': hemId,
    };

    if (isHare != null) {
      bodyMap['isHare'] = isHare;
    }

    final String body = jsonEncode(bodyMap);

    final String responseBody = await ServiceCommon.sendHttpPostV2(body);

    List<dynamic> adHocData = <dynamic>[];

    if (!responseBody.startsWith(ERROR_PREFIX)) {
      if (appDomainType == AppDomainType.event) {
        adHocData = await G0<TableModel>()
            .syncEventAdminService
            .updateSqlTablesWithResultsFromBackendApiCall(responseBody);
      } else if (appDomainType == AppDomainType.user) {
        adHocData = await G0<TableModel>()
            .syncUserDataService
            .updateSqlTablesWithResultsFromApiWithAdHocData(responseBody);
      } else {
        assert(false);
      }
    }

    return adHocData;
  }

  Future<List<dynamic>> setEventAttendence(
    String eventId,
    String? hasherId,
    AppDomainType appDomainType,
    int attendenceState, {
    int isHare = -1,
    String? qrScanText,
    String? hemId,
  }) async {
    if (G0<AppModel>().connectionStatus == EnumConnectionStatus2.notConnected) {
      return <dynamic>[];
    }

    final String userId = getStringPref(StringPrefsEnum.userId)!;
    String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    String deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    final String accessToken = Utilities.generateToken(
      userId.toUpperCase(),
      'hcapp_setEventAttendence',
      paramString: deviceSecret,
    );

    final int hasherEventMapLastUpdated =
        await G0<TableModel>().baseService.getLastUpdatedTime(
              G0<Database>(),
              G0<TableModel>().hasherEventMapTableHelper,
              G0<TableModel>()
                  .hasherEventMapTableHelper
                  .getTableName(appDomainType),
              G0<TableModel>().hasherEventMapTableHelper.colUpdatedAtValue,
            );
    final int hasherKennelMapLastUpdated =
        await G0<TableModel>().baseService.getLastUpdatedTime(
              G0<Database>(),
              G0<TableModel>().hasherKennelMapTableHelper,
              G0<TableModel>()
                  .hasherKennelMapTableHelper
                  .getTableName(appDomainType),
              G0<TableModel>().hasherKennelMapTableHelper.colUpdatedAtValue,
            );

    final DateTime hasherEventMapUpdatedAfter =
        DateTime.fromMicrosecondsSinceEpoch(hasherEventMapLastUpdated + 1);
    final DateTime hasherKennelMapUpdatedAfter =
        DateTime.fromMicrosecondsSinceEpoch(hasherKennelMapLastUpdated + 1);

    final Map<String, Object?> bodyMap = <String, Object?>{
      'queryType': 'setEventAttendence',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'eventId': eventId,
      'hasherId': hasherId,
      'attendenceState': attendenceState,
      'isHare': isHare,
      'hasherEventMapUpdatedAfter': hasherEventMapUpdatedAfter.toString(),
      'hasherKennelMapUpdatedAfter': hasherKennelMapUpdatedAfter.toString(),
      'returnUserRecords': appDomainType == AppDomainType.user ? 1 : 0,
      'qrScanText': qrScanText ?? '',
      'hemId': hemId,
    };

    final String body = jsonEncode(bodyMap);

    final String responseBody = await ServiceCommon.sendHttpPostV2(body);

    List<dynamic> adHocData = <dynamic>[];

    if (!responseBody.startsWith(ERROR_PREFIX)) {
      if (appDomainType == AppDomainType.event) {
        adHocData = await G0<TableModel>()
            .syncEventAdminService
            .updateSqlTablesWithResultsFromBackendApiCall(responseBody);
      } else if (appDomainType == AppDomainType.user) {
        adHocData = await G0<TableModel>()
            .syncUserDataService
            .updateSqlTablesWithResultsFromApiWithAdHocData(responseBody);
      } else {
        assert(false);
      }
    }

    return adHocData;
  }

  Future<List<dynamic>> joinEventAsVisitor(
    String eventId,
    String displayName,
    int virginVisitorType,
    int attendenceState,
    String email,
    String phoneNumber,
    AppDomainType appDomainType,
  ) async {
    if (G0<AppModel>().connectionStatus == EnumConnectionStatus2.notConnected) {
      return <dynamic>[];
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    final String userId = getStringPref(StringPrefsEnum.userId)!;
    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret =
        getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    final String accessToken = Utilities.generateToken(
      userId.toUpperCase(),
      'hcapp_joinEventAsVisitor',
      paramString: deviceSecret,
    );

    final int hasherEventMapLastUpdated =
        await G0<TableModel>().baseService.getLastUpdatedTime(
              G0<Database>(),
              G0<TableModel>().hasherEventMapTableHelper,
              G0<TableModel>()
                  .hasherEventMapTableHelper
                  .getTableName(appDomainType),
              G0<TableModel>().hasherEventMapTableHelper.colUpdatedAtValue,
            );
    final int paymentsLastUpdated =
        await G0<TableModel>().baseService.getLastUpdatedTime(
              G0<Database>(),
              G0<TableModel>().paymentsTableHelper,
              G0<TableModel>().paymentsTableHelper.getTableName(appDomainType),
              G0<TableModel>().paymentsTableHelper.colUpdatedAtValue,
            );

    final DateTime hasherEventMapUpdatedAfter =
        DateTime.fromMicrosecondsSinceEpoch(hasherEventMapLastUpdated + 1);
    final DateTime paymentsUpdatedAfter =
        DateTime.fromMicrosecondsSinceEpoch(paymentsLastUpdated + 1);

    final String body = jsonEncode(<String, Object>{
      'queryType': 'joinEventAsVisitor',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'eventId': eventId,
      'displayName': displayName,
      'virginVisitorType': virginVisitorType.toString(),
      'attendenceState': attendenceState.toString(),
      'email': email,
      'phoneNumber': phoneNumber,
      'hasherEventMapUpdatedAfter': hasherEventMapUpdatedAfter.toString(),
      'paymentsUpdatedAfter': paymentsUpdatedAfter.toString()
    });

    final String responseBody = await ServiceCommon.sendHttpPostV2(body);

    List<dynamic> adHocData = <dynamic>[];

    if (!responseBody.startsWith(ERROR_PREFIX)) {
      adHocData = await G0<TableModel>()
          .syncEventAdminService
          .updateSqlTablesWithResultsFromBackendApiCall(responseBody);
    }
    return adHocData;
  }
}
