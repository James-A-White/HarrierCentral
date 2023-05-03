import 'package:harrier_central/imports.dart';

class HashersTableHelper extends BaseTableHelper with BaseFields {
  HashersTableHelper() {
    remoteDbId = 'hasherId';
    humanReadableTableName = 'Hashers';
    pageSize = SyncUserDataService.pageSize_hashersTable;
    tableFlag = SyncUserDataService.flagHashersTable;
  }

  @override
  String getTableName(dynamic appDomainType) {
    String tableName;
    switch (appDomainType) {
      // case AppDomainType.event:
      //   break;
      // case AppDomainType.kennel:
      //   break;
      // case AppDomainType.user:
      //   tableName = 'hashers';
      //   break;
      default:
        tableName = 'hashers';
    }
    return tableName;
  }

  final String colHasherId = 'hasherId';
  //final String colHomeKennelId = 'homeKennelId';
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
  Future<dynamic> createTable(
      Database db, int version, dynamic appDomainType) async {
    final String tableName = getTableName(appDomainType);
    await db.execute('''
          CREATE TABLE $tableName (
            $colId INTEGER PRIMARY KEY,
            $colHasherId TEXT NOT NULL,
            $colFirstName TEXT,
            $colLastName TEXT,
            $colDispName TEXT NOT NULL,
            $colHashName TEXT,
            $colPhoto TEXT,
            $colDispPref INT NOT NULL,
            $colIncludeInGlobalHashDirectory INT NOT NULL,
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
  //   final Map<String, dynamic> map = _$HashersModelToJson(item);
  //   return map;
  // }

  @override
  Map<String, dynamic> normalizeMap(Map<String, dynamic> inputMap) {
    // do we need to block the data from the email field?
    return HashersModel.fromJson(inputMap).toJson();
  }

  @override
  HashersModel fromMap(Map<String, dynamic> map) {
    return HashersModel.fromJson(map);
  }
}

class HashersService extends BaseService {
  // ============ Functions go here =============

  Future<String> addEditUser(
      {required String targetUserId,
      String? firstName,
      String? lastName,
      String? email,
      String? hashName,
      String? photo,
      String? eventId,
      String? kennelId,
      String? historicalTotalRunCount,
      String? historicalHaringCount,
      bool? historicalCountIsEstimate,
      int? followKennelOnAddNewUser,
      int includeInGlobalHashDirectory = -1,
      int preferences = -1,
      int nameDisplayPreference = -1}) async {
    if (G0<AppModel>().connectionStatus == EnumConnectionStatus2.notConnected) {
      return '';
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    bool newUserForThisDevice = false;

    final String hcVersion =
        getStringPref(StringPrefsEnum.harrierCentralVersion) ??
            '<unknown version>';
    String? userId = getStringPref(StringPrefsEnum.userId);
    if ((userId == null) || (userId.isEmpty)) {
      userId = GUID_EMPTY;
      newUserForThisDevice = true;
    }

    final String accessToken = IveCoreUtilities.generateToken(
        userId.toUpperCase(), 'addEditUser800',
        paramString: targetUserId.toUpperCase());

    DateTime hashersUpdatedAfter;
    DateTime hasherEventMapUpdatedAfter;
    DateTime hasherKennelMapUpdatedAfter;

    if (!newUserForThisDevice) {
      final int hashersLastUpdated = await getLastUpdatedTime(
        G0<Database>(),
        G0<TableModel>().hashersTableHelper,
        G0<TableModel>().hashersTableHelper.getTableName(AppDomainType.user),
        G0<TableModel>().hashersTableHelper.colUpdatedAtValue,
      );
      hashersUpdatedAfter =
          DateTime.fromMicrosecondsSinceEpoch(hashersLastUpdated + 1);

      // TODO(James): Check the logic here in this call we are using AppDomainType of event but in the next one we have logic to go between event and kennel
      final int hasherEventMapLastUpdated =
          await G0<TableModel>().baseService.getLastUpdatedTime(
                G0<Database>(),
                G0<TableModel>().hasherEventMapTableHelper,
                G0<TableModel>()
                    .hasherEventMapTableHelper
                    .getTableName(AppDomainType.event),
                G0<TableModel>().hasherEventMapTableHelper.colUpdatedAtValue,
              );
      hasherEventMapUpdatedAfter =
          DateTime.fromMicrosecondsSinceEpoch(hasherEventMapLastUpdated + 1);

      // this one has event and kennel
      final int hasherKennelMapLastUpdated =
          await G0<TableModel>().baseService.getLastUpdatedTime(
                G0<Database>(),
                G0<TableModel>().hasherKennelMapTableHelper,
                G0<TableModel>().hasherKennelMapTableHelper.getTableName(
                    ((eventId != null) &&
                            (eventId.isNotEmpty) &&
                            (eventId != GUID_EMPTY))
                        ? AppDomainType.event
                        : AppDomainType.kennel),
                G0<TableModel>().hasherKennelMapTableHelper.colUpdatedAtValue,
              );
      hasherKennelMapUpdatedAfter =
          DateTime.fromMicrosecondsSinceEpoch(hasherKennelMapLastUpdated + 1);
    } else {
      // do this to suppress any records being returned through the sync mechanism
      hashersUpdatedAfter = DateTime(2050, 1, 1);
      hasherEventMapUpdatedAfter = DateTime(2050, 1, 1);
      hasherKennelMapUpdatedAfter = DateTime(2050, 1, 1);
    }

    final String body = jsonEncode(<String, String?>{
      'userId': userId,
      'accessToken': accessToken,
      'hcVersion': hcVersion,
      'hashersUpdatedAfter': hashersUpdatedAfter.toString(),
      'hasherEventMapUpdatedAfter':
          ((eventId != null) && (eventId.isNotEmpty) && (eventId != GUID_EMPTY))
              ? hasherEventMapUpdatedAfter.toString()
              : 'ignore',
      'hasherKennelMapUpdatedAfter': ((kennelId != null) &&
              (kennelId.isNotEmpty) &&
              (kennelId != GUID_EMPTY))
          ? hasherKennelMapUpdatedAfter.toString()
          : 'ignore',
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
      'historicalTotalRunCount': historicalTotalRunCount,
      'historicalHaringCount': historicalHaringCount,
      'historicalCountIsEstimate':
          (historicalCountIsEstimate ?? false) ? '1' : '0',
      'followKennelOnAddNewUser': followKennelOnAddNewUser?.toString(),
      'latitude': G0<DeviceInfo>().deviceLat.toString(),
      'longitude': G0<DeviceInfo>().deviceLon.toString(),
      'nameDisplayPreference': nameDisplayPreference.toString(),
    });

    bool dbErrorIsDuplicateEmail = false;

    String responseBody =
        await ServiceCommon.sendHttpPost('hc3_add_edit_user_800', body,
            errorCallback: (DbErrorModel dbError) async {
      bool okButtonPressed = false;
      if (dbError.errorType == DB_ERROR_EMAIL_ALREADY_EXISTS) {
        dbErrorIsDuplicateEmail = true;
        okButtonPressed = await Utilities.showAlert(
                dbError.errorTitle ?? 'Error',
                'This email address already exists in our server. Would you like an invite code sent to your email that you can use to install the app?',
                'Send code',
                showCancelButton: true) ??
            false;

        if (okButtonPressed) {
          final String userMessage = await sendInviteCodeByEmail(email!);
          await Utilities.showAlert('Check your email', userMessage, 'OK');
        }
      }
      return okButtonPressed;
    });

    if (dbErrorIsDuplicateEmail && (responseBody == ERROR_HANDLED)) {
      responseBody = ERROR_INVITE_CODE_SENT;
    }

    if (!responseBody.startsWith(ERROR_PREFIX)) {
      if (!newUserForThisDevice) {
        if (((eventId == null) || (eventId == GUID_EMPTY)) &&
            ((kennelId == null) || (kennelId == GUID_EMPTY))) {
          // we don't have either an eventId or a kennelId so all we need to do is update
          // the Hasher table
          await G0<TableModel>()
              .syncUserDataService
              .updateSqlTablesWithResultsFromApiWithAdHocData(responseBody);
        } else if ((eventId != null) && (eventId != GUID_EMPTY)) {
          // if we have an eventId we are definitely editing an event irrespective of whether or not
          // there is also a kennelId
          await G0<TableModel>()
              .syncEventAdminService
              .updateSqlTablesWithResultsFromBackendApiCall(responseBody);
        } else if ((kennelId != null) && (kennelId != GUID_EMPTY)) {
          // if we get here, we have a kennelId but no eventId, which means we are editing kennel members
          await G0<TableModel>()
              .syncKennelAdminService
              .updateSqlTablesWithResultsFromBackendApiCall(responseBody);
        } else {
          // TODO(James): handle this error, we should never arrive at this point in the code
        }
      }
    }

    // callers checked and they are handling the error
    return responseBody;
  }

  static Future<String> sendInviteCodeByEmail(String email) async {
    final String body = jsonEncode(<String, String>{
      'email': email,
    });

    final Response response = await post(Uri.parse(EMAIL_INVITE_CODE_API_URL),
            headers: <String, String>{'content-type': 'application/json'},
            body: body
            // Send authorization headers to your backend
            //headers: {HttpHeaders.authorizationHeader: 'Basic your_api_token_here'},
            )
        .catchError(
      (dynamic error) {
        return Future<Response>.value(Response('', 500));
      },
    );

    String returnValue = ERROR_UNKNOWN_HTTP_ERROR;

    if ((response.statusCode < 200) || (response.statusCode >= 300)) {
      returnValue = ERROR_UNKNOWN_HTTP_ERROR;
    } else {
      returnValue = response.body;
    }
    return returnValue;
  }

  Future<bool> changeProfilePicture({
    required String targetUserId,
    required String photo,
  }) async {
    if (G0<AppModel>().connectionStatus == EnumConnectionStatus2.notConnected) {
      return false;
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    final String hcVersion =
        getStringPref(StringPrefsEnum.harrierCentralVersion) ??
            '<unknown version>';
    String userId = getStringPref(StringPrefsEnum.userId)!;
    if (userId.isEmpty) {
      userId = GUID_EMPTY;
    }

    final String accessToken = IveCoreUtilities.generateToken(
        userId.toUpperCase(), 'addEditUser800',
        paramString: targetUserId.toUpperCase());

    final String body = jsonEncode(<String, String?>{
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
      'historicalTotalRunCount': '-1',
      'historicalHaringCount': '-1',
      'historicalCountIsEstimate': '-1',
      'followKennelOnAddNewUser': null
    });

    final String responseBody =
        await ServiceCommon.sendHttpPost('hc3_add_edit_user_800', body);

    // I checked and the error condition is being properly handled by the caller
    return !responseBody.startsWith(ERROR_PREFIX);
  }

  Future<dynamic> processThirdPartyLogin({
    required ThirdPartyLoginData loginData,
    required String hashName,
    required String email,
    int includeInGlobalHashDirectory = -1,
  }) async {
    if (G0<AppModel>().connectionStatus == EnumConnectionStatus2.notConnected) {
      return '';
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    bool newUserForThisDevice = false;

    final String hcVersion =
        getStringPref(StringPrefsEnum.harrierCentralVersion) ??
            '<unknown version>';
    String userId = getStringPref(StringPrefsEnum.userId)!;
    if (userId.isEmpty) {
      userId = GUID_EMPTY;
      newUserForThisDevice = true;
    }

    DateTime hashersUpdatedAfter;

    if (!newUserForThisDevice) {
      final int hashersLastUpdated = await getLastUpdatedTime(
        G0<Database>(),
        G0<TableModel>().hashersTableHelper,
        G0<TableModel>().hashersTableHelper.getTableName(AppDomainType.user),
        G0<TableModel>().hashersTableHelper.colUpdatedAtValue,
      );
      hashersUpdatedAfter =
          DateTime.fromMicrosecondsSinceEpoch(hashersLastUpdated + 1);
    } else {
      // do this to suppress any records being returned through the sync mechanism
      hashersUpdatedAfter = DateTime(2050, 1, 1);
    }

    final String accessToken = IveCoreUtilities.generateToken(
        userId.toUpperCase(), 'processThirdPartyLogin',
        paramString: userId.toUpperCase());

    final String body = jsonEncode(<String, String?>{
      'userId': userId,
      'accessToken': accessToken,
      'hashersUpdatedAfter': hashersUpdatedAfter.toString(),
      'firstName': loginData.firstName,
      'lastName': loginData.lastName,
      'hashName': hashName,
      'email': email,
      'photo': loginData.photoUrl ?? '',
      'thirdPartyLoginType': loginData.loginType,
      'thirdPartyUserId': loginData.id,
      'thirdPartyAccessToken': loginData.accessToken,
      'thirdPartyAuthorizationCode': loginData.authorizationCode ?? '',
      'thirdPartyAccessTokenExpires': loginData.accessTokenExpires?.toString(),
      'includeInGlobalHashDirectory': includeInGlobalHashDirectory.toString(),
      'hcVersion': hcVersion,
      'latitude': G0<DeviceInfo>().deviceLat.toString(),
      'longitude': G0<DeviceInfo>().deviceLon.toString(),
      'thirdPartyEmail': loginData.thirdPartyEmail,
    });

    final String responseBody =
        await ServiceCommon.sendHttpPost('hc3_process_third_party_login', body);

    if (!responseBody.startsWith(ERROR_PREFIX)) {
      if (!newUserForThisDevice) {
        await G0<TableModel>()
            .syncUserDataService
            .updateSqlTablesWithResultsFromApiWithAdHocData(responseBody);
      }
    }

    if (!newUserForThisDevice) {
      await G0<TableModel>()
          .syncUserDataService
          .updateSqlTablesWithResultsFromApiWithAdHocData(responseBody);
    }

    if (!responseBody.startsWith(ERROR_PREFIX)) {
      final dynamic result = json.decode(responseBody);
      return result;
    }

    return null;
  }
}
