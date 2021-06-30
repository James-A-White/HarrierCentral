import 'package:harrier_central/imports.dart';

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

class HashersTableHelper extends BaseTableHelper with BaseFields {
  HashersTableHelper() {
    remoteDbId = 'hasherId';
    humanReadableTableName = 'Hashers';
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
  Future<dynamic> createTable(Database db, int version, dynamic appDomainType) async {
    final String tableName = getTableName(appDomainType);
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
  }

  @override
  Future<void> createIndexes(Database db, int version, dynamic appDomainType) async {
    await db.execute('CREATE INDEX idx_${getTableName(appDomainType)}_id ON ${getTableName(appDomainType)}($remoteDbId);');
    await db.execute('CREATE INDEX idx_${getTableName(appDomainType)}_update_at_value ON ${getTableName(appDomainType)}($colUpdatedAtValue);');
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
    if (G0<AppModel>().connectionStatus == EnumConnectionStatus.not_connected) {
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

    final String accessToken = IveCoreUtilities.generateToken(userId.toUpperCase(), 'addEditUser', paramString: targetUserId.toUpperCase());

    DateTime hashersUpdatedAfter;
    DateTime hasherEventMapUpdatedAfter;
    DateTime hasherKennelMapUpdatedAfter;

    if (!newUserForThisDevice) {
      final num _hashersLastUpdated = await getLastUpdatedTime(
        G0<Database>(),
        G0<TableModel>().hashersTableHelper,
        G0<TableModel>().hashersTableHelper.getTableName(AppDomainType.user),
        G0<TableModel>().hashersTableHelper.colUpdatedAtValue,
      );
      hashersUpdatedAfter = _hashersLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_hashersLastUpdated + 1000);

      // TODO(James): Check the logic here in this call we are using AppDomainType of event but in the next one we have logic to go between event and kennel
      final num _hasherEventMapLastUpdated = await G0<TableModel>().baseService.getLastUpdatedTime(
            G0<Database>(),
            G0<TableModel>().hasherEventMapTableHelper,
            G0<TableModel>().hasherEventMapTableHelper.getTableName(AppDomainType.event),
            G0<TableModel>().hasherEventMapTableHelper.colUpdatedAtValue,
          );
      hasherEventMapUpdatedAfter = _hasherEventMapLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_hasherEventMapLastUpdated + 1000);

      // this one has event and kennel
      final num _hasherKennelMapLastUpdated = await G0<TableModel>().baseService.getLastUpdatedTime(
            G0<Database>(),
            G0<TableModel>().hasherKennelMapTableHelper,
            G0<TableModel>()
                .hasherKennelMapTableHelper
                .getTableName(((eventId != null) && (eventId.isNotEmpty) && (eventId != GUID_EMPTY)) ? AppDomainType.event : AppDomainType.kennel),
            G0<TableModel>().hasherKennelMapTableHelper.colUpdatedAtValue,
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

    final String responseBody = await ServiceCommon.sendHttpPost('hc3_add_edit_user', body, errorCallback: (DbErrorModel dbError) async {
      bool okButtonPressed = false;
      if (dbError.errorType == DB_ERROR_EMAIL_ALREADY_EXISTS) {
        okButtonPressed = await IveCoreUtilities.showAlert(navigatorKey.currentContext, dbError.errorTitle,
            'This email address already exists in our server. Would you like an invite code sent to your email that you can use to install the app?', 'Send code',
            showCancelButton: true);

        if (okButtonPressed) {
          final String userMessage = await _sendInviteCodeByEmail(email);
          await IveCoreUtilities.showAlert(navigatorKey.currentContext, 'Check your email', userMessage, 'OK');
        }
      }
      return okButtonPressed;
    });

    // final Response response = await post(BASE_API_URL + 'hc3_add_edit_user', headers: <String, String>{'content-type': 'application/json'}, body: body
    //         // Send authorization headers to your backend
    //         //headers: {HttpHeaders.authorizationHeader: 'Basic your_api_token_here'},
    //         )
    //     .catchError(
    //   (dynamic error) {
    //     return Future<Response>.value(null);
    //   },
    // );

    if ((responseBody != null) && (responseBody.isNotEmpty) && (!responseBody.startsWith(ERROR_PREFIX))) {
      if (!newUserForThisDevice) {
        if (((eventId == null) || (eventId == GUID_EMPTY)) && ((kennelId == null) || (kennelId == GUID_EMPTY))) {
          // we don't have either an eventId or a kennelId so all we need to do is update
          // the Hasher table
          await G0<TableModel>().syncUserDataService.updateSqlTablesWithResultsFromBackendApiCall(responseBody);
        } else if ((eventId != null) && (eventId != GUID_EMPTY)) {
          // if we have an eventId we are definitely editing an event irrespective of whether or not
          // there is also a kennelId
          await G0<TableModel>().syncEventAdminService.updateSqlTablesWithResultsFromBackendApiCall(responseBody);
        } else if ((kennelId != null) && (kennelId != GUID_EMPTY)) {
          // if we get here, we have a kennelId but no eventId, which means we are editing kennel members
          await G0<TableModel>().syncKennelAdminService.updateSqlTablesWithResultsFromBackendApiCall(responseBody);
        } else {
          // TODO(James): handle this error, we should never arrive at this point in the code
        }
      }
    }

    return responseBody;
  }

  Future<String> _sendInviteCodeByEmail(String email) async {
    final String body = jsonEncode(<String, String>{
      'email': email,
    });

    final Response response = await post(EMAIL_INVITE_CODE_API_URL, headers: <String, String>{'content-type': 'application/json'}, body: body
            // Send authorization headers to your backend
            //headers: {HttpHeaders.authorizationHeader: 'Basic your_api_token_here'},
            )
        .catchError(
      (dynamic error) {
        return Future<Response>.value(null);
      },
    );

    String returnValue = ERROR_UNKNOWN_HTTP_ERROR;

    if (response == null) {
      returnValue = ERROR_UNKNOWN_HTTP_ERROR;
    } else if ((response.statusCode < 200) || (response.statusCode >= 300)) {
      returnValue = ERROR_UNKNOWN_HTTP_ERROR;
    } else {
      returnValue = response.body;
    }
    return returnValue;
  }

  Future<String> changeProfilePicture({String targetUserId, String photo}) async {
    if (G0<AppModel>().connectionStatus == EnumConnectionStatus.not_connected) {
      return '';
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    final String hcVersion = getStringPref(StringPrefsEnum.harrierCentralVersion);
    String userId = getStringPref(StringPrefsEnum.userId);
    if ((userId == null) || (userId.isEmpty)) {
      userId = GUID_EMPTY;
    }

    final String accessToken = IveCoreUtilities.generateToken(userId.toUpperCase(), 'addEditUser', paramString: targetUserId.toUpperCase());

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

    final String responseBody = await ServiceCommon.sendHttpPost('hc3_add_edit_user', body);

    // final Response response = await post(BASE_API_URL + 'hc3_add_edit_user', headers: <String, String>{'content-type': 'application/json'}, body: body
    //         // Send authorization headers to your backend
    //         //headers: {HttpHeaders.authorizationHeader: 'Basic your_api_token_here'},
    //         )
    //     .catchError(
    //   (dynamic error) {
    //     return Future<Response>.value(null);
    //   },
    // );

    return responseBody;
  }

  Future<String> processFacebookLogin(
      {String firstName,
      String lastName,
      String email,
      String hashName,
      String photo,
      String facebookId,
      String facebookAccessToken,
      int includeInGlobalHashDirectory = -1}) async {
    if (G0<AppModel>().connectionStatus == EnumConnectionStatus.not_connected) {
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
        G0<Database>(),
        G0<TableModel>().hashersTableHelper,
        G0<TableModel>().hashersTableHelper.getTableName(AppDomainType.user),
        G0<TableModel>().hashersTableHelper.colUpdatedAtValue,
      );
      hashersUpdatedAfter = _hashersLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_hashersLastUpdated + 1000);
    } else {
      // do this to suppress any records being returned through the sync mechanism
      hashersUpdatedAfter = DateTime(2050, 1, 1);
    }

    final String accessToken = IveCoreUtilities.generateToken(userId.toUpperCase(), 'processFacebookLogin', paramString: userId.toUpperCase());

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

    final String responseBody = await ServiceCommon.sendHttpPost('hc3_process_facebook_login', body);

    if ((responseBody != null) && (responseBody.isNotEmpty) && (!responseBody.startsWith(ERROR_PREFIX))) {
      if (!newUserForThisDevice) {
        await G0<TableModel>().syncUserDataService.updateSqlTablesWithResultsFromBackendApiCall(responseBody);
      }
    }

    // Get long life FB token... looks like this is not required as the FB token already has a long life.

    // final String body2 = jsonEncode(<String, String>{
    //   'userId': userId,
    //   'facebookAccessToken': facebookAccessToken,
    // });

    // final Response response2 = await post(PROCESS_FACEBOOK_TOKEN_API_URL, headers: <String, String>{'content-type': 'application/json'}, body: body2
    //         // Send authorization headers to your backend
    //         //headers: {HttpHeaders.authorizationHeader: 'Basic your_api_token_here'},
    //         )
    //     .catchError(
    //   (dynamic error) {
    //     return Future<Response>.value(null);
    //   },
    // );

    if (!newUserForThisDevice) {
      await G0<TableModel>().syncUserDataService.updateSqlTablesWithResultsFromBackendApiCall(responseBody);
    }

    return responseBody;
  }
}
