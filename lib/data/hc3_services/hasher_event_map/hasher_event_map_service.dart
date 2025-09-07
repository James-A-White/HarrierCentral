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
  final String colCountryId = 'hemCountryId';
  final String colEventStartDatetime = 'hemEventStartDatetime';
  final String colCanEditRunAttendence = 'hemCanEditRunAttendence';
  final String colEventKennelId = 'hemEventKennelId';
  final String colEventIsCountedAndVisible = 'hemEventIsCountedAndVisible';
  final String colKennelUserPhoto = 'hemKennelUserPhoto';
  final String colKennelHashName = 'hemKennelHashName';

  @override
  Future<dynamic> createTable(
    Database db,
    int version,
    dynamic appDomainType,
  ) async {
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
            $colCountryId TEXT,
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
      final String accessToken1 = Utilities.generateToken(
        userId!,
        'hcapp_getRuns',
        paramString: deviceSecret!,
      );

      final String accessToken2 = Utilities.generateToken(
        userId,
        'hcapp_getMyKennelRunTotals',
        paramString: deviceSecret,
      );

      final String body = jsonEncode(<String, String>{
        'queryType': 'SendRunCountsReport',
        'deviceId': deviceId!,
        'accessToken1': accessToken1,
        'accessToken2': accessToken2,
        'kennelId': kennelId,
        'kennelName': kennelName,
        'userName': userName,
        'emailAddress': emailAddress!,
      });

      final Response response = await post(
        Uri.parse(EMAIL_RUN_REPORT_API_URL),
        headers: <String, String>{'content-type': 'application/json'},
        body: body,
      ).catchError((dynamic error) {
        return Future<Response>.value(Response('', 500));
      });

      return <String, String>{'result': response.body, 'email': emailAddress};
    }
    return <String, String>{
      'result': 'No valid email address found',
      'email': '',
    };
  }

  Future<List<dynamic>> setEmailAndNotificationPreferences(
    String eventId,
    String hasherId,
    AppDomainType appDomainType,
    NotificationState notificationPreference,
    EnumEmailAlertState emailPreference,
  ) async {
    if (appModel.connectionStatus == EnumConnectionStatus2.notConnected) {
      return <dynamic>[];
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    final String userId = getStringPref(StringPrefsEnum.userId)!;

    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret =
        getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    final String accessToken = Utilities.generateToken(
      userId,
      'hcapp_setEmailAndNotificationPrefs',
      paramString: deviceSecret,
    );

    final int hasherEventMapLastUpdated = await tableModel.baseService
        .getLastUpdatedTime(
          database,
          tableModel.hasherEventMapTableHelper,
          tableModel.hasherEventMapTableHelper.getTableName(appDomainType),
          tableModel.hasherEventMapTableHelper.colUpdatedAtValue,
        );
    final int hasherKennelMapLastUpdated = await tableModel.baseService
        .getLastUpdatedTime(
          database,
          tableModel.hasherKennelMapTableHelper,
          tableModel.hasherKennelMapTableHelper.getTableName(appDomainType),
          tableModel.hasherKennelMapTableHelper.colUpdatedAtValue,
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
        adHocData = await tableModel.syncEventAdminService
            .updateSqlTablesWithResultsFromBackendApiCall(responseBody);
      } else if (appDomainType == AppDomainType.user) {
        adHocData = await tableModel.syncUserDataService
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
    bool? autoSetNotifications,
  }) async {
    if (appModel.connectionStatus == EnumConnectionStatus2.notConnected) {
      return <dynamic>[];
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret =
        getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    final String userId = getStringPref(StringPrefsEnum.userId)!;
    final String accessToken = Utilities.generateToken(
      userId,
      'hcapp_setEventRsvp',
      paramString: deviceSecret,
    );

    final int hasherEventMapLastUpdated = await tableModel.baseService
        .getLastUpdatedTime(
          database,
          tableModel.hasherEventMapTableHelper,
          tableModel.hasherEventMapTableHelper.getTableName(appDomainType),
          tableModel.hasherEventMapTableHelper.colUpdatedAtValue,
        );
    final int hasherKennelMapLastUpdated = await tableModel.baseService
        .getLastUpdatedTime(
          database,
          tableModel.hasherKennelMapTableHelper,
          tableModel.hasherKennelMapTableHelper.getTableName(appDomainType),
          tableModel.hasherKennelMapTableHelper.colUpdatedAtValue,
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
      'autoSetNotifications':
          (autoSetNotifications ??
                  getBoolPref(BoolPrefsEnum.automaticallySetNotifiationPrefs) ??
                  true)
              ? 1
              : 0,
    };

    if (isHare != null) {
      bodyMap['isHare'] = isHare;
    }

    final String body = jsonEncode(bodyMap);

    final String responseBody = await ServiceCommon.sendHttpPostV2(body);

    List<dynamic> adHocData = <dynamic>[];

    if (!responseBody.startsWith(ERROR_PREFIX)) {
      if (appDomainType == AppDomainType.event) {
        adHocData = await tableModel.syncEventAdminService
            .updateSqlTablesWithResultsFromBackendApiCall(responseBody);
      } else if (appDomainType == AppDomainType.user) {
        adHocData = await tableModel.syncUserDataService
            .updateSqlTablesWithResultsFromApiWithAdHocData(responseBody);
      } else {
        assert(false);
      }
    }

    return adHocData;
  }

  Future<List<dynamic>> setBulkEventAttendence(
    String eventId,
    String hasherIds,
    int attendenceState,
  ) async {
    if (appModel.connectionStatus == EnumConnectionStatus2.notConnected) {
      return <dynamic>[];
    }

    final String userId = getStringPref(StringPrefsEnum.userId)!;
    String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    String deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    final String accessToken = Utilities.generateToken(
      userId,
      'hcapp_setBulkEventAttendence',
      paramString: deviceSecret,
    );

    final int hasherEventMapLastUpdated = await tableModel.baseService
        .getLastUpdatedTime(
          database,
          tableModel.hasherEventMapTableHelper,
          tableModel.hasherEventMapTableHelper.getTableName(
            AppDomainType.event,
          ),
          tableModel.hasherEventMapTableHelper.colUpdatedAtValue,
        );
    final int hasherKennelMapLastUpdated = await tableModel.baseService
        .getLastUpdatedTime(
          database,
          tableModel.hasherKennelMapTableHelper,
          tableModel.hasherKennelMapTableHelper.getTableName(
            AppDomainType.event,
          ),
          tableModel.hasherKennelMapTableHelper.colUpdatedAtValue,
        );

    final DateTime hasherEventMapUpdatedAfter =
        DateTime.fromMicrosecondsSinceEpoch(hasherEventMapLastUpdated + 1);
    final DateTime hasherKennelMapUpdatedAfter =
        DateTime.fromMicrosecondsSinceEpoch(hasherKennelMapLastUpdated + 1);

    final Map<String, Object?> bodyMap = <String, Object?>{
      'queryType': 'setBulkEventAttendence',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'eventId': eventId,
      'hasherIds': hasherIds,
      'attendenceState': attendenceState,
      'hasherEventMapUpdatedAfter': hasherEventMapUpdatedAfter.toString(),
      'hasherKennelMapUpdatedAfter': hasherKennelMapUpdatedAfter.toString(),
    };

    final String body = jsonEncode(bodyMap);

    final String responseBody = await ServiceCommon.sendHttpPostV2(body);

    List<dynamic> adHocData = <dynamic>[];

    if (!responseBody.startsWith(ERROR_PREFIX)) {
      adHocData = await tableModel.syncEventAdminService
          .updateSqlTablesWithResultsFromBackendApiCall(responseBody);
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
    if (appModel.connectionStatus == EnumConnectionStatus2.notConnected) {
      return <dynamic>[];
    }

    final String userId = getStringPref(StringPrefsEnum.userId)!;
    String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    String deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    final String accessToken = Utilities.generateToken(
      userId,
      'hcapp_setEventAttendence',
      paramString: deviceSecret,
    );

    final int hasherEventMapLastUpdated = await tableModel.baseService
        .getLastUpdatedTime(
          database,
          tableModel.hasherEventMapTableHelper,
          tableModel.hasherEventMapTableHelper.getTableName(appDomainType),
          tableModel.hasherEventMapTableHelper.colUpdatedAtValue,
        );
    final int hasherKennelMapLastUpdated = await tableModel.baseService
        .getLastUpdatedTime(
          database,
          tableModel.hasherKennelMapTableHelper,
          tableModel.hasherKennelMapTableHelper.getTableName(appDomainType),
          tableModel.hasherKennelMapTableHelper.colUpdatedAtValue,
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
        adHocData = await tableModel.syncEventAdminService
            .updateSqlTablesWithResultsFromBackendApiCall(responseBody);
      } else if (appDomainType == AppDomainType.user) {
        adHocData = await tableModel.syncUserDataService
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
    if (appModel.connectionStatus == EnumConnectionStatus2.notConnected) {
      return <dynamic>[];
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    final String userId = getStringPref(StringPrefsEnum.userId)!;
    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret =
        getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    final String accessToken = Utilities.generateToken(
      userId,
      'hcapp_joinEventAsVisitor',
      paramString: deviceSecret,
    );

    final int hasherEventMapLastUpdated = await tableModel.baseService
        .getLastUpdatedTime(
          database,
          tableModel.hasherEventMapTableHelper,
          tableModel.hasherEventMapTableHelper.getTableName(appDomainType),
          tableModel.hasherEventMapTableHelper.colUpdatedAtValue,
        );
    final int paymentsLastUpdated = await tableModel.baseService
        .getLastUpdatedTime(
          database,
          tableModel.paymentsTableHelper,
          tableModel.paymentsTableHelper.getTableName(appDomainType),
          tableModel.paymentsTableHelper.colUpdatedAtValue,
        );

    final DateTime hasherEventMapUpdatedAfter =
        DateTime.fromMicrosecondsSinceEpoch(hasherEventMapLastUpdated + 1);
    final DateTime paymentsUpdatedAfter = DateTime.fromMicrosecondsSinceEpoch(
      paymentsLastUpdated + 1,
    );

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
      'paymentsUpdatedAfter': paymentsUpdatedAfter.toString(),
    });

    final String responseBody = await ServiceCommon.sendHttpPostV2(body);

    List<dynamic> adHocData = <dynamic>[];

    if (!responseBody.startsWith(ERROR_PREFIX)) {
      adHocData = await tableModel.syncEventAdminService
          .updateSqlTablesWithResultsFromBackendApiCall(responseBody);
    }
    return adHocData;
  }

  Future<List<dynamic>> copyEventRsvps(
    String fromEventId,
    String toEventId,
  ) async {
    if (appModel.connectionStatus == EnumConnectionStatus2.notConnected) {
      return <dynamic>[];
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret =
        getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    final String userId = getStringPref(StringPrefsEnum.userId)!;
    final String accessToken = Utilities.generateToken(
      userId,
      'hcapp_copyEventRsvps',
      paramString: deviceSecret,
    );

    final int hasherEventMapLastUpdated = await tableModel.baseService
        .getLastUpdatedTime(
          database,
          tableModel.hasherEventMapTableHelper,
          tableModel.hasherEventMapTableHelper.getTableName(
            AppDomainType.event,
          ),
          tableModel.hasherEventMapTableHelper.colUpdatedAtValue,
        );

    final DateTime hasherEventMapUpdatedAfter =
        DateTime.fromMicrosecondsSinceEpoch(hasherEventMapLastUpdated + 1);

    // final DateTime hasherEventMapUpdatedAfter = DateTime.now().subtract(
    //   const Duration(days: 999),
    // );

    final Map<String, Object?> bodyMap = <String, Object?>{
      'queryType': 'copyEventRsvps',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'fromEvent': fromEventId,
      'toEvent': toEventId,
      'hasherEventMapUpdatedAfter': hasherEventMapUpdatedAfter.toString(),
    };

    final String body = jsonEncode(bodyMap);

    final String responseBody = await ServiceCommon.sendHttpPostV2(body);

    List<dynamic> adHocData = <dynamic>[];

    adHocData = await tableModel.syncEventAdminService
        .updateSqlTablesWithResultsFromBackendApiCall(responseBody);

    return adHocData;
  }
}
