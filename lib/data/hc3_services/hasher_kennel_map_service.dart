// @dart=2.11
import 'package:harrier_central/imports.dart';

part 'hasher_kennel_map_service.g.dart';

@JsonSerializable(fieldRename: FieldRename.none)
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
      this.authorizedDeviceList,
      this.authorizedDeviceCount,
      this.userRoleFlags,
      this.appAccessFlags,
      this.hcTotalRunCount,
      this.hcHaringCount,
      this.historicalTotalRunCount,
      this.historicalHaringCount,
      this.historicalCountIsEstimate,
      this.kennelCredit,
      this.discountAmount,
      this.discountPercent,
      this.discountDescription,
      this.dateOfLastRun,
      this.membershipExpirationDate,
      this.memberSince,
      this.isKennelFollowing,
      this.mismanagementRoles,
      this.removed,
      this.updatedAt});

  factory HasherKennelMapModel.fromJson(Map<String, dynamic> json) => _$HasherKennelMapModelFromJson(json);

  Map<String, dynamic> toJson() => _$HasherKennelMapModelToJson(this);

  final String hkmId;
  final String userId;
  final String kennelId;
  int following;
  final int isMember;
  final int isHomeKennel;
  int kennelNotificationPreference;
  int kennelEmailAlertPreference;
  final String authorizedDeviceList;
  final int authorizedDeviceCount;
  final int userRoleFlags;
  final int appAccessFlags;
  final int hcTotalRunCount;
  final int hcHaringCount;
  final int historicalTotalRunCount;
  final int historicalHaringCount;
  final int historicalCountIsEstimate;
  final num kennelCredit;
  final num discountAmount;
  final int discountPercent;
  final String discountDescription;
  final DateTime dateOfLastRun;
  final DateTime membershipExpirationDate;
  final DateTime memberSince;
  final int isKennelFollowing;
  final int mismanagementRoles;

  final DateTime updatedAt;
  final int removed;

  Mismanagement get mismanagement {
    return Mismanagement(mismanagementRoles);
  }

  AppAccess get appAccess {
    return AppAccess(appAccessFlags);
  }
}

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
    String tableName;
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

  @override
  Future<dynamic> createTable(Database db, int version, dynamic appDomainType) async {
    await db.execute('''
          CREATE TABLE ${getTableName(appDomainType)} (
            $colId INTEGER PRIMARY KEY,

            $colHkmId TEXT NOT NULL,
            $colUserId TEXT NOT NULL,
            $colKennelId TEXT NOT NULL,
            $colFollowing INT,
            $colIsMember INT,
            $colIsHomeKennel INT,
            $colKennelNotificationPreference INT,
            $colKennelEmailAlertPreference INT,
            $colAuthorizedDeviceList TEXT,
            $colAuthorizedDeviceCount INT,
            $colUserRoleFlags INT,
            $colAppAccessFlags INT,
            $colHcTotalRunCount INT,
            $colHcHaringCount INT,
            $colHistoricalTotalRunCount INT,
            $colHistoricalHaringCount INT,
            $colHistoricalCountIsEstimate INT,
            $colKennelCredit NUM,
            $colDiscountAmount NUM NOT NULL,
            $colDiscountPercent INT NOT NULL,
            $colDiscountDescription TEXT NOT NULL,
            $colDateOfLastRun TEXT,
            $colMembershipExpirationDate TEXT,
            $colMemberSince TEXT,
            $colIsKennelFollowing INT,
            $colMismanagementRoles INT,

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

    final DateTime hasherEventMapUpdatedAfter = _hasherEventMapLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMicrosecondsSinceEpoch(_hasherEventMapLastUpdated + 1);
    final DateTime hasherKennelMapUpdatedAfter = _hasherKennelMapLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMicrosecondsSinceEpoch(_hasherKennelMapLastUpdated + 1);

    final Map<String, Object> bodyMap = <String, Object>{
      'userId': userId,
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

  Future<List<dynamic>> updateHasherKennelStatus(String kennelId, AppDomainType appDomainType,
      {int monthsToAddToMembership,
      String targetUserId,
      int notificationState = -1,
      int emailAlertState = -1,
      int followingState = -1,
      int isHomeKennel = -1,
      int appAccessFlags = -1,
      int mismanagementRoles = -1}) async {
    List<dynamic> adHocData = <dynamic>[];

    if (G0<AppModel>().connectionStatus == EnumConnectionStatus.not_connected) {
      return adHocData;
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    if (followingState == followTypeToggleHomeKennel.value) {
      followingState = -1;
    }

    final String userId = getStringPref(StringPrefsEnum.userId);
    final String accessToken = IveCoreUtilities.generateToken(userId.toUpperCase(), 'joinKennel');

    final num _hasherKennelMapLastUpdated = await G0<TableModel>().baseService.getLastUpdatedTime(
          G0<Database>(),
          G0<TableModel>().hasherKennelMapTableHelper,
          G0<TableModel>().hasherKennelMapTableHelper.getTableName(appDomainType),
          G0<TableModel>().hasherKennelMapTableHelper.colUpdatedAtValue,
        );
    final num _kennelsLastUpdated = await G0<TableModel>().baseService.getLastUpdatedTime(
          G0<Database>(),
          G0<TableModel>().kennelsTableHelper,
          G0<TableModel>().kennelsTableHelper.getTableName(appDomainType),
          G0<TableModel>().kennelsTableHelper.colUpdatedAtValue,
        );
    final num _hashersLastUpdated = await G0<TableModel>().hashersService.getLastUpdatedTime(
          G0<Database>(),
          G0<TableModel>().hashersTableHelper,
          G0<TableModel>().hashersTableHelper.getTableName(AppDomainType.user),
          G0<TableModel>().hashersTableHelper.colUpdatedAtValue,
        );

    final DateTime hasherKennelMapUpdatedAfter = _hasherKennelMapLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMicrosecondsSinceEpoch(_hasherKennelMapLastUpdated + 1);
    final DateTime kennelsUpdatedAfter = _kennelsLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMicrosecondsSinceEpoch(_kennelsLastUpdated + 1);
    final DateTime hashersUpdatedAfter = _hashersLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMicrosecondsSinceEpoch(_hashersLastUpdated + 1);

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
      'appAccessFlags': appAccessFlags,
      'mismanagementRoles': mismanagementRoles,
      'hasherKennelMapUpdatedAfter': (hasherKennelMapUpdatedAfter.toString() + '000000').substring(0, 26),
      'kennelsUpdatedAfter': (kennelsUpdatedAfter.toString() + '000000').substring(0, 26),
      'hashersUpdatedAfter': (hashersUpdatedAfter.toString() + '000000').substring(0, 26)
    });

    final String responseBody = await ServiceCommon.sendHttpPost('hc3_join_kennel', body);

    if (!responseBody.startsWith(ERROR_PREFIX)) {
      if ((responseBody != null) && (responseBody.isNotEmpty)) {
        if (appDomainType == AppDomainType.event) {
          adHocData = await G0<TableModel>().syncEventAdminService.updateSqlTablesWithResultsFromBackendApiCall(responseBody);
        } else if (appDomainType == AppDomainType.kennel) {
          adHocData = await G0<TableModel>().syncKennelAdminService.updateSqlTablesWithResultsFromBackendApiCall(responseBody);
        } else if (appDomainType == AppDomainType.user) {
          adHocData = await G0<TableModel>().syncUserDataService.updateSqlTablesWithResultsFromApiWithAdHocData(responseBody);
        } else {
          assert(false);
        }
      }
    }

    return adHocData;
  }
}
