import 'package:harrier_central/imports.dart';

class HasherKennelMapTableHelper extends BaseTableHelper with BaseFields {
  HasherKennelMapTableHelper() {
    remoteDbId = 'hkmId';
    humanReadableTableName = 'Kennel';
    pageSize = SyncUserDataService.pageSize_hkmTable;
    tableFlag = SyncUserDataService.flagHasherKennelMapTable;
  }

  // @override
  // String getTableName(dynamic tblType) {
  //   if (tblType == TableType.hkmEventAdmin) {
  //     return hkmEventAdminTable;
  //   } else if (tblType == TableType.hkmKennelAdmin) {
  //     return hkmKennelAdminTable;
  //   } else {
  //     return hkmUserTable;
  //   }
  // }

  @override
  String getTableName(dynamic appDomainType) {
    String tableName = '';
    switch (appDomainType) {
      case AppDomainType.event:
        tableName = 'hasherKennelMapForRunAdmin';
        break;
      case AppDomainType.kennel:
        tableName = 'hasherKennelMapForKennelAdmin';
        break;
      case AppDomainType.user:
        tableName = 'hasherKennelMap';
        break;
      default:
        assert(false);
    }
    return tableName;
  }

  final String colHkmId = 'hkmId';
  final String colUserId = 'userId';
  final String colKennelId = 'kennelId';
  final String colFollowing = 'following';
  final String colIsMember = 'isMember';
  final String colIsHomeKennel = 'isHomeKennel';
  final String colKennelNotificationPreference = 'kennelNotificationPreference';
  final String colKennelEmailAlertPreference = 'kennelEmailAlertPreference';
  final String colAuthorizedDeviceList = 'authorizedDeviceList';
  final String colAuthorizedDeviceCount = 'authorizedDeviceCount';
  final String colUserRoleFlags = 'userRoleFlags';
  final String colAppAccessFlags = 'appAccessFlags';
  final String colHcTotalRunCount = 'hcTotalRunCount';
  final String colHcHaringCount = 'hcHaringCount';
  final String colHistoricalTotalRunCount = 'historicalTotalRunCount';
  final String colHistoricalHaringCount = 'historicalHaringCount';
  final String colHistoricalCountIsEstimate = 'historicalCountIsEstimate';
  final String colKennelCredit = 'kennelCredit';
  final String colDiscountAmount = 'discountAmount';
  final String colDiscountPercent = 'discountPercent';
  final String colDiscountDescription = 'discountDescription';
  final String colDateOfLastRun = 'dateOfLastRun';
  final String colMembershipExpirationDate = 'membershipExpirationDate';
  final String colMemberSince = 'memberSince';
  final String colIsKennelFollowing = 'isKennelFollowing';
  final String colMismanagementRoles = 'mismanagementRoles';
  final String colKennelUserPhoto = 'kennelUserPhoto';
  final String colKennelHashName = 'kennelHashName';

  @override
  Future<dynamic> createTable(
    Database db,
    int version,
    dynamic appDomainType,
  ) async {
    await db.execute('''
          CREATE TABLE ${getTableName(appDomainType)} (
            $colId INTEGER PRIMARY KEY,

            $colHkmId TEXT NOT NULL,
            $colUserId TEXT NOT NULL,
            $colKennelId TEXT NOT NULL,
            $colFollowing INT NOT NULL,
            $colIsMember INT NOT NULL,
            $colIsHomeKennel INT NOT NULL,
            $colKennelNotificationPreference INT NOT NULL,
            $colKennelEmailAlertPreference INT NOT NULL,
            $colAuthorizedDeviceList TEXT,
            $colAuthorizedDeviceCount INT,
            $colUserRoleFlags INT NOT NULL,
            $colAppAccessFlags INT NOT NULL,
            $colHcTotalRunCount INT NOT NULL,
            $colHcHaringCount INT NOT NULL,
            $colHistoricalTotalRunCount INT NOT NULL,
            $colHistoricalHaringCount INT NOT NULL,
            $colHistoricalCountIsEstimate INT NOT NULL,
            $colKennelCredit NUM NOT NULL,
            $colDiscountAmount NUM NOT NULL NOT NULL,
            $colDiscountPercent INT NOT NULL NOT NULL,
            $colDiscountDescription TEXT NOT NULL NOT NULL,
            $colDateOfLastRun TEXT,
            $colMembershipExpirationDate TEXT,
            $colMemberSince TEXT,
            $colIsKennelFollowing INT,
            $colMismanagementRoles INT NOT NULL,
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
  //   final Map<String, dynamic> map = _$HasherKennelMapModelToJson(item);

  //   return map;
  // }

  @override
  Map<String, dynamic> normalizeMap(Map<String, dynamic> inputMap) {
    return HasherKennelMapModel.fromJson(inputMap).toJson();
  }

  @override
  HasherKennelMapModel fromMap(Map<String, dynamic> map) {
    return HasherKennelMapModel.fromJson(map);
  }
}

class HasherKennelMapService {
  //=================  Domain specific functions ================

  Future<List<dynamic>> setEmailAndNotificationPreferences(
    String kennelId,
    String hasherId,
    AppDomainType appDomainType,
    NotificationState notificationPreference,
    EnumEmailAlertState emailPreference,
  ) async {
    if (Utilities.isNotConnected()) {
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

    final Map<String, Object?> bodyMap = <String, Object?>{
      'queryType': 'setEmailAndNotificationPrefs',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'hasherId': hasherId,
      'kennelId': kennelId,
      'eventId': null,
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

  Future<List<dynamic>> updateHasherKennelStatus(
    String kennelId,
    AppDomainType appDomainType, {
    int? monthsToAddToMembership,
    String? targetUserId,
    int notificationState = -1,
    int emailAlertState = -1,
    int followingState = -1,
    int isHomeKennel = -1,
    int appAccessFlags = -1,
    int mismanagementRoles = -1,
  }) async {
    List<dynamic> adHocData = <dynamic>[];

    if (Utilities.isNotConnected()) {
      return adHocData;
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    if (followingState == followTypeToggleHomeKennel.value) {
      followingState = -1;
    }

    final String userId = getStringPref(StringPrefsEnum.userId)!;
    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret =
        getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    final String accessToken = Utilities.generateToken(
      userId,
      'hcapp_joinKennel',
      paramString: deviceSecret,
    );

    final int hasherKennelMapLastUpdated = await tableModel.baseService
        .getLastUpdatedTime(
          database,
          tableModel.hasherKennelMapTableHelper,
          tableModel.hasherKennelMapTableHelper.getTableName(appDomainType),
          tableModel.hasherKennelMapTableHelper.colUpdatedAtValue,
        );
    final int kennelsLastUpdated = await tableModel.baseService
        .getLastUpdatedTime(
          database,
          tableModel.kennelsTableHelper,
          tableModel.kennelsTableHelper.getTableName(appDomainType),
          tableModel.kennelsTableHelper.colUpdatedAtValue,
        );
    final int hashersLastUpdated = await tableModel.hashersService
        .getLastUpdatedTime(
          database,
          tableModel.hashersTableHelper,
          tableModel.hashersTableHelper.getTableName(AppDomainType.user),
          tableModel.hashersTableHelper.colUpdatedAtValue,
        );

    final DateTime hasherKennelMapUpdatedAfter =
        DateTime.fromMicrosecondsSinceEpoch(hasherKennelMapLastUpdated + 1);
    final DateTime kennelsUpdatedAfter = DateTime.fromMicrosecondsSinceEpoch(
      kennelsLastUpdated + 1,
    );
    final DateTime hashersUpdatedAfter = DateTime.fromMicrosecondsSinceEpoch(
      hashersLastUpdated + 1,
    );

    monthsToAddToMembership ??= 0;

    final String body = jsonEncode(<String, Object?>{
      'queryType': 'joinKennel',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'kennelId': kennelId,
      'targetUserId': targetUserId ?? userId,
      'isFollowing': followingState,
      'isHomeKennel': isHomeKennel,
      'notificationState': notificationState,
      'emailAlertState': emailAlertState,
      'monthsToAddToMembership': monthsToAddToMembership,
      'appAccessFlags': appAccessFlags,
      'mismanagementRoles': mismanagementRoles,
      'hasherKennelMapUpdatedAfter': ('${hasherKennelMapUpdatedAfter}000000')
          .substring(0, 26),
      'kennelsUpdatedAfter': ('${kennelsUpdatedAfter}000000').substring(0, 26),
      'hashersUpdatedAfter': ('${hashersUpdatedAfter}000000').substring(0, 26),
    });

    final String responseBody = await ServiceCommon.sendHttpPostV2(body);

    if (!responseBody.startsWith(ERROR_PREFIX)) {
      if (responseBody.isNotEmpty) {
        if (appDomainType == AppDomainType.event) {
          adHocData = await tableModel.syncEventAdminService
              .updateSqlTablesWithResultsFromBackendApiCall(responseBody);
        } else if (appDomainType == AppDomainType.kennel) {
          adHocData = await tableModel.syncKennelAdminService
              .updateSqlTablesWithResultsFromBackendApiCall(responseBody);
        } else if (appDomainType == AppDomainType.user) {
          adHocData = await tableModel.syncUserDataService
              .updateSqlTablesWithResultsFromApiWithAdHocData(responseBody);
        } else {
          assert(false);
        }
      }
    }

    return adHocData;
  }
}
