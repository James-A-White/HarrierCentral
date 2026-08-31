import 'package:harrier_central/imports.dart';

class HashersTableHelper extends BaseTableHelper<AppDomainType>
    with BaseFields {
  HashersTableHelper() {
    remoteDbId = 'hasherId';
    humanReadableTableName = 'Hashers';
    pageSize = SyncUserDataService.pageSize_hashersTable;
    tableFlag = EnumDataTables.hashers.flag;
  }

  @override
  String getTableName(AppDomainType appDomainType) {
    String tableName;
    switch (appDomainType) {
      case AppDomainType.user:
        tableName = EnumDataTables.hashers.commonTableName;
        break;
      default:
        throw Exception(
          'EnumDataTables.${EnumDataTables.hashers.name} does not have a table associated with it.',
        );
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
  final String colHomeKennelId = 'homeKennelId';
  final String colIncludeInGlobalHashDirectory = 'includeInGlobalHashDirectory';
  final String colPreferences = 'preferences';

  @override
  Future<dynamic> createTable(
    Database db,
    int version,
    dynamic appDomainType,
  ) async {
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
            $colHomeKennelId TEXT,
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

  Future<String> addEditUser({
    required String targetUserId,
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
    int nameDisplayPreference = -1,
  }) async {
    if (Utilities.isNotConnected()) {
      return '';
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    bool newUserForThisDevice = false;

    final String hcVersion =
        getStringPref(StringPrefsEnum.harrierCentralVersionAndBuild) ??
        '<unknown version>';
    String? userId = getStringPref(StringPrefsEnum.userId);
    if ((userId == null) || (userId.isEmpty)) {
      userId = GUID_EMPTY;
      newUserForThisDevice = true;
    }

    String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    String deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';
    final String paramString = deviceSecret + targetUserId;

    DateTime hashersUpdatedAfter;
    DateTime hasherEventMapUpdatedAfter;
    DateTime hasherKennelMapUpdatedAfter;

    if (!newUserForThisDevice) {
      final int hashersLastUpdated = await getLastUpdatedTime(
        database,
        tableModel.hashersTableHelper,
        EnumDataTables.hashers.commonTableName,
        tableModel.hashersTableHelper.colUpdatedAtValue,
      );
      hashersUpdatedAfter = DateTime.fromMicrosecondsSinceEpoch(
        hashersLastUpdated + 1,
      );

      // TODO(James): Check the logic here in this call we are using AppDomainType of event but in the next one we have logic to go between event and kennel
      final int hasherEventMapLastUpdated = await tableModel.baseService
          .getLastUpdatedTime(
            database,
            tableModel.hasherEventMapTableHelper,
            EnumDataTables.hasherEventMap.eventTableName,
            tableModel.hasherEventMapTableHelper.colUpdatedAtValue,
          );
      hasherEventMapUpdatedAfter = DateTime.fromMicrosecondsSinceEpoch(
        hasherEventMapLastUpdated + 1,
      );

      // this one has event and kennel
      final int hasherKennelMapLastUpdated = await tableModel.baseService
          .getLastUpdatedTime(
            database,
            tableModel.hasherKennelMapTableHelper,
            tableModel.hasherKennelMapTableHelper.getTableName(
              ((eventId != null) &&
                      (eventId.isNotEmpty) &&
                      (eventId != GUID_EMPTY))
                  ? AppDomainType.event
                  : AppDomainType.kennel,
            ),
            tableModel.hasherKennelMapTableHelper.colUpdatedAtValue,
          );
      hasherKennelMapUpdatedAfter = DateTime.fromMicrosecondsSinceEpoch(
        hasherKennelMapLastUpdated + 1,
      );
    } else {
      // do this to suppress any records being returned through the sync mechanism
      hashersUpdatedAfter = DateTime(2050, 1, 1);
      hasherEventMapUpdatedAfter = DateTime(2050, 1, 1);
      hasherKennelMapUpdatedAfter = DateTime(2050, 1, 1);
    }

    final Map<String, String?> addEditBody = <String, String?>{
      'queryType': 'addEditUser',
      'deviceId': deviceId,
      'hcVersion': hcVersion,
      'hashersUpdatedAfter': hashersUpdatedAfter.toString(),
      'hasherEventMapUpdatedAfter':
          ((eventId != null) && (eventId.isNotEmpty) && (eventId != GUID_EMPTY))
          ? hasherEventMapUpdatedAfter.toString()
          : 'ignore',
      'hasherKennelMapUpdatedAfter':
          ((kennelId != null) &&
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
      'historicalCountIsEstimate': (historicalCountIsEstimate ?? false)
          ? '1'
          : '0',
      'followKennelOnAddNewUser': followKennelOnAddNewUser?.toString(),
      'latitude': deviceInfo.deviceLat.toString(),
      'longitude': deviceInfo.deviceLon.toString(),
      'nameDisplayPreference': nameDisplayPreference.toString(),
    };

    bool dbErrorIsDuplicateEmail = false;

    String responseBody = await ServiceCommon.sendHttpPost(
      () {
        addEditBody['accessToken'] = Utilities.generateToken(
          userId ?? GUID_EMPTY,
          'hcapp_addEditUser',
          paramString: paramString,
        );
        return jsonEncode(addEditBody);
      },
      noRetries: true,
      errorCallback: (DbErrorModel dbError) async {
        if (dbError.errorType != DB_ERROR_EMAIL_ALREADY_EXISTS) {
          return false;
        }

        final String? existingEmail = email;
        if ((existingEmail == null) || existingEmail.isEmpty) {
          return false;
        }

        // The address is already registered, so this is an existing hasher
        // setting up a device rather than a genuinely new account. Send a
        // fresh invite code straight away rather than asking first: typing
        // the address into the signup form is consent enough, and the extra
        // confirmation step was one more place for people to get stuck.
        final String response = await sendInviteCodeByEmail(existingEmail);
        final bool codeWasSent = _looksLikeInviteCode(response);

        if (codeWasSent) {
          // Only set this when a code actually went out - it is what routes
          // the caller on to UseInviteCodePage.
          dbErrorIsDuplicateEmail = true;
          await Utilities.showAlert(
            'Check your email',
            'That email address is already registered to a Harrier Central '
                'account, so we have emailed a new invite code to '
                '$existingEmail.\n\nEnter the code on the next screen to '
                'finish setting up this device.',
            'OK',
          );
        } else {
          await Utilities.showAlert(
            'We could not send your code',
            response.startsWith(ERROR_PREFIX)
                ? 'That email address is already registered, but we could not '
                      'send your invite code just now. Please check your '
                      'connection and try again.'
                : response,
            'OK',
          );
        }

        // Report handled either way: the user has just been shown a specific
        // message, so the generic failure dialog would only be a confusing
        // second one on top of it.
        return true;
      },
    );

    if (dbErrorIsDuplicateEmail && (responseBody == ERROR_HANDLED)) {
      responseBody = ERROR_INVITE_CODE_SENT;
    }

    if (!responseBody.startsWith(ERROR_PREFIX)) {
      if (!newUserForThisDevice) {
        if (((eventId == null) || (eventId == GUID_EMPTY)) &&
            ((kennelId == null) || (kennelId == GUID_EMPTY))) {
          // we don't have either an eventId or a kennelId so all we need to do is update
          // the Hasher table
          await tableModel.syncUserDataService
              .updateSqlTablesWithResultsFromApiWithAdHocData(responseBody);
        } else if ((eventId != null) && (eventId != GUID_EMPTY)) {
          // if we have an eventId we are definitely editing an event irrespective of whether or not
          // there is also a kennelId
          await tableModel.syncEventAdminService
              .updateSqlTablesWithResultsFromBackendApiCall(responseBody);
          await _syncHashersIntoCommon();
        } else if ((kennelId != null) && (kennelId != GUID_EMPTY)) {
          // if we get here, we have a kennelId but no eventId, which means we are editing kennel members
          await tableModel.syncKennelAdminService
              .updateSqlTablesWithResultsFromBackendApiCall(responseBody);
          await _syncHashersIntoCommon();
        } else {
          // TODO(James): handle this error, we should never arrive at this point in the code
        }
      }
    }

    // callers checked and they are handling the error
    return responseBody;
  }

  /// The event/kennel admin syncs deliberately skip the hashers table (it is a
  /// common-domain table), so a hasher added or edited through those flows never
  /// reaches `common_hashers` until a full resync — which leaves a newly added
  /// member invisible in member/user lists (they read `common_hashers`). Pull
  /// hashers into `common_hashers` now, scoped by the watermark so it's cheap.
  Future<void> _syncHashersIntoCommon() async {
    await tableModel.syncUserDataService.updateFromBackend(
      EnumDataTables.hashers.flag,
      true,
      debugText: 'addEditUser: sync new/edited hasher into common_hashers',
    );
  }

  /// The EmailInviteCode function returns the bare six-letter code on
  /// success, or a human-readable sentence when the address could not be
  /// matched to a live account. There is no status field to test, so the
  /// shape of the response is the only signal available.
  static bool _looksLikeInviteCode(String response) =>
      RegExp(r'^[A-Za-z]{6}$').hasMatch(response.trim());

  static Future<String> sendInviteCodeByEmail(String email) async {
    final String body = jsonEncode(<String, String>{'email': email});

    final Response response =
        await post(
          Uri.parse(EMAIL_INVITE_CODE_API_URL),
          headers: <String, String>{'content-type': 'application/json'},
          body: body,
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () => Response('timeout', 408),
        ).catchError((dynamic error) {
          return Future<Response>.value(Response('', 500));
        });

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
    if (Utilities.isNotConnected()) {
      return false;
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    final String hcVersion =
        getStringPref(StringPrefsEnum.harrierCentralVersionAndBuild) ??
        '<unknown version>';
    String userId = currentUserId;
    if (userId.isEmpty) {
      userId = GUID_EMPTY;
    }

    String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    String deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    final String picParamString = deviceSecret + targetUserId;

    final String responseBody = await ServiceCommon.sendHttpPost(
      () => jsonEncode(<String, String?>{
        'queryType': 'addEditUser',
        'deviceId': deviceId,
        'accessToken': Utilities.generateToken(
          userId,
          'hcapp_addEditUser',
          paramString: picParamString,
        ),
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
        'followKennelOnAddNewUser': null,
      }),
      noRetries: true,
    );

    // I checked and the error condition is being properly handled by the caller
    return !responseBody.startsWith(ERROR_PREFIX);
  }

  Future<dynamic> processThirdPartyLogin({
    required ThirdPartyLoginData loginData,
    required String hashName,
    required String email,
    int includeInGlobalHashDirectory = -1,
  }) async {
    if (Utilities.isNotConnected()) {
      return '';
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    bool newUserForThisDevice = false;

    final String hcVersion =
        getStringPref(StringPrefsEnum.harrierCentralVersionAndBuild) ??
        '<unknown version>';
    String userId = currentUserId;

    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret =
        getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    if (userId.isEmpty) {
      userId = GUID_EMPTY;
      newUserForThisDevice = true;
    }

    DateTime hashersUpdatedAfter;

    if (!newUserForThisDevice) {
      final int hashersLastUpdated = await getLastUpdatedTime(
        database,
        tableModel.hashersTableHelper,
        EnumDataTables.hashers.commonTableName,
        tableModel.hashersTableHelper.colUpdatedAtValue,
      );
      hashersUpdatedAfter = DateTime.fromMicrosecondsSinceEpoch(
        hashersLastUpdated + 1,
      );
    } else {
      // do this to suppress any records being returned through the sync mechanism
      hashersUpdatedAfter = DateTime(2050, 1, 1);
    }

    final String responseBody = await ServiceCommon.sendHttpPost(
      () => jsonEncode(<String, String?>{
        'queryType': 'processThirdPartyLogin',
        'deviceId': deviceId,
        'accessToken': Utilities.generateToken(
          userId,
          'hcapp_processThirdPartyLogin',
          paramString: deviceSecret + userId,
        ),
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
        'thirdPartyAccessTokenExpires': loginData.accessTokenExpires
            ?.toString(),
        'includeInGlobalHashDirectory': includeInGlobalHashDirectory.toString(),
        'hcVersion': hcVersion,
        'latitude': deviceInfo.deviceLat.toString(),
        'longitude': deviceInfo.deviceLon.toString(),
        'thirdPartyEmail': loginData.thirdPartyEmail,
      }),
    );

    if (!responseBody.startsWith(ERROR_PREFIX)) {
      if (!newUserForThisDevice) {
        await tableModel.syncUserDataService
            .updateSqlTablesWithResultsFromApiWithAdHocData(responseBody);
      }
    }

    if (!responseBody.startsWith(ERROR_PREFIX)) {
      final dynamic result = json.decode(responseBody);
      return result;
    }

    return null;
  }
}
