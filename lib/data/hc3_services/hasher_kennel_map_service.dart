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
}

class HasherKennelMapTableHelper extends BaseTableHelper with BaseFields {
  HasherKennelMapTableHelper() {
    remoteDbId = 'hkmId';
    humanReadableTableName = 'Kennel';
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

  Future<List<dynamic>> updateHasherKennelStatus(String kennelId, AppDomainType appDomainType,
      {int monthsToAddToMembership, String targetUserId, int notificationState = -1, int emailAlertState = -1, int followingState = -1, int isHomeKennel = -1}) async {
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

    final DateTime hasherKennelMapUpdatedAfter =
        _hasherKennelMapLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_hasherKennelMapLastUpdated + 1000);
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

    final String responseBody = await ServiceCommon.sendHttpPost('hc3_join_kennel', body);

    if (!responseBody.startsWith(ERROR_PREFIX)) {
      if ((responseBody != null) && (responseBody.isNotEmpty)) {
        if (appDomainType == AppDomainType.event) {
          adHocData = await G0<TableModel>().syncEventAdminService.updateSqlTablesWithResultsFromBackendApiCall(responseBody);
        } else if (appDomainType == AppDomainType.kennel) {
          adHocData = await G0<TableModel>().syncKennelAdminService.updateSqlTablesWithResultsFromBackendApiCall(responseBody);
        } else if (appDomainType == AppDomainType.user) {
          adHocData = await G0<TableModel>().syncUserDataService.updateSqlTablesWithResultsFromBackendApiCall(responseBody);
        } else {
          assert(false);
        }
      }
    }

    return adHocData;
  }
}
