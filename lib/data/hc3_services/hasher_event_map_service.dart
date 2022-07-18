// @dart=2.11
import 'package:harrier_central/imports.dart';

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
      this.totalHaring,
      this.totalHaringThisKennel,
      this.totalRuns,
      this.totalRunsThisKennel,
      this.eventCountOverride,
      this.virginVisitorType,
      this.displayName,
      this.email,
      this.phoneNumber,
      this.removed,
      // these fields are cached from the event itself. This enables us to keep run count information without
      // having to have the actual run cached on the phone
      this.hemEventName,
      this.hemEventNumber,
      this.hemEventStartDatetime,
      this.hemEventIsCountedAndVisible,
      this.hemCanEditRunAttendence,
      this.hemEventKennelId,
      this.updatedAt});

  factory HasherEventMapModel.fromJson(Map<String, dynamic> json) => _$HasherEventMapModelFromJson(json);

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
  int totalHaring;
  int totalHaringThisKennel;
  int totalRuns;
  int totalRunsThisKennel;
  final num eventCountOverride;
  final num virginVisitorType;
  final String displayName;
  final String email;
  final String phoneNumber;

  // these fields are cached from the event itself. This enables us to keep run count information without
  // having to have the actual run cached on the phone
  final String hemEventName;
  final int hemEventNumber;
  final DateTime hemEventStartDatetime;
  final num hemCanEditRunAttendence;
  final String hemEventKennelId;
  final int hemEventIsCountedAndVisible;

  final int removed;
  final DateTime updatedAt;
}

class HasherEventMapTableHelper extends BaseTableHelper with BaseFields {
  HasherEventMapTableHelper() {
    remoteDbId = 'hemId';
    humanReadableTableName = 'Event Data';
    pageSize = SyncUserDataService.pageSize_hemTable;
    tableFlag = SyncUserDataService.flagHasherEventMapTable;
  }

  @override
  String getTableName(dynamic appDomainType) {
    String tableName;
    switch (appDomainType) {
      case AppDomainType.event:
        tableName = 'hasherEventMapForRunAdmin';
        break;
      // case AppDomainType.kennel:
      //   break;
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

  @override
  Future<dynamic> createTable(Database db, int version, dynamic appDomainType) async {
    await db.execute('''
          CREATE TABLE ${getTableName(appDomainType)} (
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

            $colTotalHaring INT,
            $colTotalHaringThisKennel INT,
            $colTotalRuns INT,
            $colTotalRunsThisKennel INT,

            $colEventCountOverride NUM,
            $colVirginVisitorType NUM,
            $colDisplayName TEXT,
            $colEmail TEXT,
            $colPhoneNumber TEXT,

            $colEventName TEXT,
            $colEventNumber INT,
            $colEventStartDatetime TEXT,
            $colCanEditRunAttendence NUM,
            $colEventKennelId TEXT,
            $colEventIsCountedAndVisible INT,

            $colRemoved NUM,
            $colUpdatedAt TEXT,
            $colUpdatedAtValue NUM NULL

          )
          ''');
  }

  @override
  Future<void> createIndexes(Database db, int version, dynamic appDomainType) async {
    await db.execute('CREATE INDEX idx_${getTableName(appDomainType)}_id ON ${getTableName(appDomainType)}($remoteDbId);');
    await db.execute('CREATE INDEX idx_${getTableName(appDomainType)}_update_at_value ON ${getTableName(appDomainType)}($colUpdatedAtValue);');
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

  Future<Map<String, String>> sendRunCountReportByEmail({String kennelId, String kennelName}) async {
    final String userId = getStringPref(StringPrefsEnum.userId);
    final String userName = getStringPref(StringPrefsEnum.displayName);
    final String emailAddress = getStringPref(StringPrefsEnum.email);

    final String accessToken1 = IveCoreUtilities.generateToken(userId.toUpperCase(), 'getRuns');

    final String accessToken2 = IveCoreUtilities.generateToken(userId, 'getMyKennelRunTotals');

    if ((emailAddress ?? '').isNotEmpty) {
      final String body = jsonEncode(<String, String>{
        'userId': userId,
        'accessToken1': accessToken1,
        'accessToken2': accessToken2,
        'kennelId': kennelId,
        'kennelName': kennelName,
        'userName': userName,
        'emailAddress': emailAddress
      });

      final Response response = await post(Uri.parse(EMAIL_RUN_REPORT_API_URL), headers: <String, String>{'content-type': 'application/json'}, body: body).catchError(
        (dynamic error) {
          return Future<Response>.value(null);
        },
      );

      return <String, String>{'result': response.body, 'email': emailAddress};
    }
    return <String, String>{'result': 'No valid email address found', 'email': ''};
  }

  Future<List<dynamic>> joinEvent(
    String eventId,
    String hasherId,
    String hasherEventMapId,
    AppDomainType appDomainType, {
    int rsvpState = -1,
    int attendenceState = -1,
    int isHare = -1,
    int virginVisitorType = 0,
    int notificationState = -1,
    int emailAlertState = -1,
    String userQrCode,
  }) async {
    if (G0<AppModel>().connectionStatus == EnumConnectionStatus.not_connected) {
      return null;
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    final String userId = getStringPref(StringPrefsEnum.userId);
    final String accessToken = IveCoreUtilities.generateToken(userId.toUpperCase(), 'joinEvent');

    final num _hasherEventMapLastUpdated = await G0<TableModel>().baseService.getLastUpdatedTime(
          G0<Database>(),
          G0<TableModel>().hasherEventMapTableHelper,
          G0<TableModel>().hasherEventMapTableHelper.getTableName(appDomainType),
          G0<TableModel>().hasherEventMapTableHelper.colUpdatedAtValue,
        );
    final num _hasherKennelMapLastUpdated = await G0<TableModel>().baseService.getLastUpdatedTime(
          G0<Database>(),
          G0<TableModel>().hasherKennelMapTableHelper,
          G0<TableModel>().hasherKennelMapTableHelper.getTableName(appDomainType),
          G0<TableModel>().hasherKennelMapTableHelper.colUpdatedAtValue,
        );
    final num _paymentsLastUpdated = await G0<TableModel>().baseService.getLastUpdatedTime(
          G0<Database>(),
          G0<TableModel>().paymentsTableHelper,
          G0<TableModel>().paymentsTableHelper.getTableName(appDomainType),
          G0<TableModel>().paymentsTableHelper.colUpdatedAtValue,
        );
    final num _kennelCreditsLastUpdated = await G0<TableModel>().baseService.getLastUpdatedTime(
          G0<Database>(),
          G0<TableModel>().kennelCreditsTableHelper,
          G0<TableModel>().kennelCreditsTableHelper.getTableName(appDomainType),
          G0<TableModel>().kennelCreditsTableHelper.colUpdatedAtValue,
        );

    final DateTime hasherEventMapUpdatedAfter = _hasherEventMapLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_hasherEventMapLastUpdated + 1000);
    final DateTime hasherKennelMapUpdatedAfter = _hasherKennelMapLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_hasherKennelMapLastUpdated + 1000);
    final DateTime paymentsUpdatedAfter = _paymentsLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_paymentsLastUpdated + 1000);
    final DateTime kennelCreditsUpdatedAfter = _kennelCreditsLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_kennelCreditsLastUpdated + 1000);

    final Map<String, Object> bodyMap = <String, Object>{
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
      'kennelCreditsUpdatedAfter': kennelCreditsUpdatedAfter.toString(),
    };

    if (userQrCode != null) {
      bodyMap.addAll(<String, Object>{'userQrCode': userQrCode});
    }

    final String body = jsonEncode(bodyMap);

    final String responseBody = await ServiceCommon.sendHttpPost('hc3_join_event', body);

    List<dynamic> adHocData = <dynamic>[];

    if (!responseBody.startsWith(ERROR_PREFIX)) {
      if (appDomainType == AppDomainType.event) {
        adHocData = await G0<TableModel>().syncEventAdminService.updateSqlTablesWithResultsFromBackendApiCall(responseBody);
      } else if (appDomainType == AppDomainType.user) {
        adHocData = await G0<TableModel>().syncUserDataService.updateSqlTablesWithResultsFromApiWithAdHocData(responseBody);
      } else {
        assert(false);
      }
    }

    return adHocData;
  }

  Future<List<dynamic>> setEmailAndNotificationPreferences(
    String eventId,
    String hasherId,
    AppDomainType appDomainType,
    EnumNotificationState<int> notificationPreference,
    EnumEmailAlertState<int> emailPreference,
  ) async {
    if (G0<AppModel>().connectionStatus == EnumConnectionStatus.not_connected) {
      return null;
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    final String userId = getStringPref(StringPrefsEnum.userId);
    final String accessToken = IveCoreUtilities.generateToken(userId.toUpperCase(), 'setEmailAndNotificationPrefs');

    final num _hasherEventMapLastUpdated = await G0<TableModel>().baseService.getLastUpdatedTime(
          G0<Database>(),
          G0<TableModel>().hasherEventMapTableHelper,
          G0<TableModel>().hasherEventMapTableHelper.getTableName(appDomainType),
          G0<TableModel>().hasherEventMapTableHelper.colUpdatedAtValue,
        );
    final num _hasherKennelMapLastUpdated = await G0<TableModel>().baseService.getLastUpdatedTime(
          G0<Database>(),
          G0<TableModel>().hasherKennelMapTableHelper,
          G0<TableModel>().hasherKennelMapTableHelper.getTableName(appDomainType),
          G0<TableModel>().hasherKennelMapTableHelper.colUpdatedAtValue,
        );

    final DateTime hasherEventMapUpdatedAfter = _hasherEventMapLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_hasherEventMapLastUpdated + 1000);
    final DateTime hasherKennelMapUpdatedAfter = _hasherKennelMapLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_hasherKennelMapLastUpdated + 1000);

    final Map<String, Object> bodyMap = <String, Object>{
      'userId': userId,
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

    final String responseBody = await ServiceCommon.sendHttpPost('hc3_set_email_notification_prefs', body);

    List<dynamic> adHocData = <dynamic>[];

    if (!responseBody.startsWith(ERROR_PREFIX)) {
      if (appDomainType == AppDomainType.event) {
        adHocData = await G0<TableModel>().syncEventAdminService.updateSqlTablesWithResultsFromBackendApiCall(responseBody);
      } else if (appDomainType == AppDomainType.user) {
        adHocData = await G0<TableModel>().syncUserDataService.updateSqlTablesWithResultsFromApiWithAdHocData(responseBody);
      } else {
        assert(false);
      }
    }

    return adHocData;
  }

  Future<List<dynamic>> setEventRsvp(
    String eventId,
    String hasherId,
    AppDomainType appDomainType,
    int rsvpState,
    int isHare,
  ) async {
    if (G0<AppModel>().connectionStatus == EnumConnectionStatus.not_connected) {
      return null;
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    final String userId = getStringPref(StringPrefsEnum.userId);
    final String accessToken = IveCoreUtilities.generateToken(userId.toUpperCase(), 'setEventRsvp');

    final num _hasherEventMapLastUpdated = await G0<TableModel>().baseService.getLastUpdatedTime(
          G0<Database>(),
          G0<TableModel>().hasherEventMapTableHelper,
          G0<TableModel>().hasherEventMapTableHelper.getTableName(appDomainType),
          G0<TableModel>().hasherEventMapTableHelper.colUpdatedAtValue,
        );
    final num _hasherKennelMapLastUpdated = await G0<TableModel>().baseService.getLastUpdatedTime(
          G0<Database>(),
          G0<TableModel>().hasherKennelMapTableHelper,
          G0<TableModel>().hasherKennelMapTableHelper.getTableName(appDomainType),
          G0<TableModel>().hasherKennelMapTableHelper.colUpdatedAtValue,
        );

    final DateTime hasherEventMapUpdatedAfter = _hasherEventMapLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_hasherEventMapLastUpdated + 1000);
    final DateTime hasherKennelMapUpdatedAfter = _hasherKennelMapLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_hasherKennelMapLastUpdated + 1000);

    final Map<String, Object> bodyMap = <String, Object>{
      'userId': userId,
      'accessToken': accessToken,
      'eventId': eventId,
      'hasherId': hasherId,
      'isHare': isHare,
      'rsvpState': rsvpState,
      'hasherEventMapUpdatedAfter': hasherEventMapUpdatedAfter.toString(),
      'hasherKennelMapUpdatedAfter': hasherKennelMapUpdatedAfter.toString(),
    };

    final String body = jsonEncode(bodyMap);

    final String responseBody = await ServiceCommon.sendHttpPost('hc3_set_event_rsvp', body);

    List<dynamic> adHocData = <dynamic>[];

    if (!responseBody.startsWith(ERROR_PREFIX)) {
      if (appDomainType == AppDomainType.event) {
        adHocData = await G0<TableModel>().syncEventAdminService.updateSqlTablesWithResultsFromBackendApiCall(responseBody);
      } else if (appDomainType == AppDomainType.user) {
        adHocData = await G0<TableModel>().syncUserDataService.updateSqlTablesWithResultsFromApiWithAdHocData(responseBody);
      } else {
        assert(false);
      }
    }

    return adHocData;
  }

  Future<List<dynamic>> setEventAttendence(
    String eventId,
    String hasherId,
    AppDomainType appDomainType,
    int attendenceState,
  ) async {
    if (G0<AppModel>().connectionStatus == EnumConnectionStatus.not_connected) {
      return null;
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    final String userId = getStringPref(StringPrefsEnum.userId);
    final String accessToken = IveCoreUtilities.generateToken(userId.toUpperCase(), 'setEventAttendence');

    final num _hasherEventMapLastUpdated = await G0<TableModel>().baseService.getLastUpdatedTime(
          G0<Database>(),
          G0<TableModel>().hasherEventMapTableHelper,
          G0<TableModel>().hasherEventMapTableHelper.getTableName(appDomainType),
          G0<TableModel>().hasherEventMapTableHelper.colUpdatedAtValue,
        );
    final num _hasherKennelMapLastUpdated = await G0<TableModel>().baseService.getLastUpdatedTime(
          G0<Database>(),
          G0<TableModel>().hasherKennelMapTableHelper,
          G0<TableModel>().hasherKennelMapTableHelper.getTableName(appDomainType),
          G0<TableModel>().hasherKennelMapTableHelper.colUpdatedAtValue,
        );

    final DateTime hasherEventMapUpdatedAfter = _hasherEventMapLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_hasherEventMapLastUpdated + 1000);
    final DateTime hasherKennelMapUpdatedAfter = _hasherKennelMapLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_hasherKennelMapLastUpdated + 1000);

    final Map<String, Object> bodyMap = <String, Object>{
      'userId': userId,
      'accessToken': accessToken,
      'eventId': eventId,
      'hasherId': hasherId,
      'attendenceState': attendenceState,
      'hasherEventMapUpdatedAfter': hasherEventMapUpdatedAfter.toString(),
      'hasherKennelMapUpdatedAfter': hasherKennelMapUpdatedAfter.toString(),
    };

    final String body = jsonEncode(bodyMap);

    final String responseBody = await ServiceCommon.sendHttpPost('hc3_set_event_attendence', body);

    List<dynamic> adHocData = <dynamic>[];

    if (!responseBody.startsWith(ERROR_PREFIX)) {
      if (appDomainType == AppDomainType.event) {
        adHocData = await G0<TableModel>().syncEventAdminService.updateSqlTablesWithResultsFromBackendApiCall(responseBody);
      } else if (appDomainType == AppDomainType.user) {
        adHocData = await G0<TableModel>().syncUserDataService.updateSqlTablesWithResultsFromApiWithAdHocData(responseBody);
      } else {
        assert(false);
      }
    }

    return adHocData;
  }

  Future<List<dynamic>> joinEventAsVisitor(String eventId, String displayName, int virginVisitorType, int attendenceState, String email, String phoneNumber, AppDomainType appDomainType) async {
    if (G0<AppModel>().connectionStatus == EnumConnectionStatus.not_connected) {
      return null;
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    final String userId = getStringPref(StringPrefsEnum.userId);
    final String accessToken = IveCoreUtilities.generateToken(userId.toUpperCase(), 'joinEventAsVisitor');

    final num _hasherEventMapLastUpdated = await G0<TableModel>().baseService.getLastUpdatedTime(
          G0<Database>(),
          G0<TableModel>().hasherEventMapTableHelper,
          G0<TableModel>().hasherEventMapTableHelper.getTableName(appDomainType),
          G0<TableModel>().hasherEventMapTableHelper.colUpdatedAtValue,
        );
    final num _paymentsLastUpdated = await G0<TableModel>().baseService.getLastUpdatedTime(
          G0<Database>(),
          G0<TableModel>().paymentsTableHelper,
          G0<TableModel>().paymentsTableHelper.getTableName(appDomainType),
          G0<TableModel>().paymentsTableHelper.colUpdatedAtValue,
        );
    // final num _kennelCreditsLastUpdated = await G0<TableModel>().baseService.getLastUpdatedTime(
    //       G0<Database>(),
    //       G0<TableModel>().kennelCreditsTableHelper,
    //       G0<TableModel>().kennelCreditsTableHelper.getTableName(appDomainType),
    //       G0<TableModel>().kennelCreditsTableHelper.colUpdatedAtValue,
    //     );

    final DateTime hasherEventMapUpdatedAfter = _hasherEventMapLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_hasherEventMapLastUpdated + 1000);
    final DateTime paymentsUpdatedAfter = _paymentsLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_paymentsLastUpdated + 1000);

    final String body = jsonEncode(<String, Object>{
      'userId': userId,
      'accessToken': accessToken,
      'eventId': eventId,
      'displayName': displayName ?? '<no name>',
      'virginVisitorType': virginVisitorType?.toString(),
      'attendenceState': attendenceState?.toString(),
      'email': email,
      'phoneNumber': phoneNumber,
      'hasherEventMapUpdatedAfter': hasherEventMapUpdatedAfter.toString(),
      'paymentsUpdatedAfter': paymentsUpdatedAfter.toString()
    });

    final String responseBody = await ServiceCommon.sendHttpPost('hc3_join_event_as_visitor', body);

    List<dynamic> adHocData = <dynamic>[];

    if (!responseBody.startsWith(ERROR_PREFIX)) {
      adHocData = await G0<TableModel>().syncEventAdminService.updateSqlTablesWithResultsFromBackendApiCall(responseBody);
    }
    return adHocData;
  }
}
