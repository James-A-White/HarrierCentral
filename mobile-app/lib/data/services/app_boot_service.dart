import 'package:geolocator/geolocator.dart';
import 'package:harrier_central/imports.dart';

/// Owns all app startup logic — previously embedded in AppEntryPageState._handleStartup.
///
/// Call [boot] once from AppEntryPage. The service handles every boot path and
/// is responsible for all startup navigation. Nothing in AppEntryPage needs to
/// know which path was taken.
class AppBootService {
  // ---------------------------------------------------------------------------
  // Credential prefs that survive a BOOT_TYPE_RELOAD_DATA wipe. Add new
  // identity/auth prefs here rather than to the individual read/write calls.
  // ---------------------------------------------------------------------------

  static const List<StringPrefsEnum> _credentialStringPrefs = [
    StringPrefsEnum.userId,
    StringPrefsEnum.publicHasherId,
    StringPrefsEnum.deviceId,
    StringPrefsEnum.resetCode,
    StringPrefsEnum.deviceSecret,
    StringPrefsEnum.displayName,
    StringPrefsEnum.profilePhotoUrl,
    StringPrefsEnum.betaFeaturesEnabled,
    StringPrefsEnum.thirdPartyAccessToken,
    StringPrefsEnum.thirdPartyAuthorizationCode,
    StringPrefsEnum.thirdPartyEmail,
    StringPrefsEnum.thirdPartyForceTokenRefresh,
    StringPrefsEnum.thirdPartyLoginEmail,
    StringPrefsEnum.thirdPartyLoginType,
    StringPrefsEnum.thirdPartyUserId,
  ];

  static const List<IntPrefsEnum> _credentialIntPrefs = [
    IntPrefsEnum.timeWindow,
  ];

  static const List<DatePrefsEnum> _credentialDatePrefs = [
    DatePrefsEnum.thirdPartyTokenLastUpdated,
    DatePrefsEnum.thirdPartyTokenExpires,
  ];

  // ---------------------------------------------------------------------------
  // Main entry point
  // ---------------------------------------------------------------------------

  Future<void> boot() async {
    await initPrefs();

    if (getStringPref(StringPrefsEnum.bootType) == BOOT_TYPE_RELOAD_DATA) {
      await _handleReloadData();
      return;
    }

    final String? userId = await _resolveUserId();
    final String? deviceId = getStringPref(StringPrefsEnum.deviceId);
    final String? deviceSecret = getStringPref(StringPrefsEnum.deviceSecret);

    await Utilities.checkForInternetConnection(false);

    // 1.x → 2.x migration: userId exists in legacy prefs but no deviceId yet.
    if (userId != null && deviceId == null) {
      await _handleLegacyMigration(userId);
      return;
    }

    // No registered device — skip approveLogin entirely and go to intro.
    // approveLogin requires a valid deviceSecret; without one, the token is
    // meaningless and the SP will reject the call.
    if (deviceId == null || deviceId.isEmpty) {
      await Navigator.of(
        navigatorKey.currentContext!,
      ).pushReplacementNamed(RouteNames.INTRO_SLIDER.toString());
      return;
    }

    // Device ID exists but the rest of the auth bundle is incomplete.
    // This commonly happens on simulators with stale persisted prefs.
    if (!_hasCompleteLocalAuthBundle(
      userId: userId,
      deviceId: deviceId,
      deviceSecret: deviceSecret,
    )) {
      await _clearStaleDeviceAuthPrefs();
      await Utilities.showAlert(
        'Re-authorization Required',
        'This device has stale or incomplete login credentials. Please re-authorise to continue.',
        'Continue',
      );
      await Navigator.of(
        navigatorKey.currentContext!,
      ).pushReplacementNamed(RouteNames.INTRO_SLIDER.toString());
      return;
    }

    await _prepareDeviceContext();

    bool reauthorizationHandled = false;
    final ApproveLoginModel? loginResult = await _fetchLoginResult(
      errorCallback: (DbErrorModel error) async {
        if (_isReauthorizationError(error)) {
          reauthorizationHandled = true;
          await _clearStaleDeviceAuthPrefs();
          await Utilities.showAlert(
            'Re-authorization Required',
            'Your device authorization has expired or become invalid.\r\n\r\nPlease scan your QR code or enter your Reset Code to restore access.',
            'Continue',
          );
          await Navigator.of(
            navigatorKey.currentContext!,
          ).pushReplacementNamed(RouteNames.INTRO_SLIDER.toString());
          return true;
        }
        return false;
      },
    );

    if (reauthorizationHandled) return;

    if (loginResult == null) {
      await _handleNoConnection(userId);
      return;
    }

    await _storeLoginPrefs(loginResult);
    await _showLoginMessage(loginResult);
    await _routeAfterLogin(userId, loginResult);
  }

  // ---------------------------------------------------------------------------
  // Boot paths
  // ---------------------------------------------------------------------------

  /// Preserve credentials, wipe all other prefs and the local DB, then restart
  /// the app shell. Used when the user triggers a full data reload from settings.
  Future<void> _handleReloadData() async {
    final Map<StringPrefsEnum, String?> strings = {
      for (final k in _credentialStringPrefs) k: getStringPref(k),
    };
    final Map<IntPrefsEnum, int?> ints = {
      for (final k in _credentialIntPrefs) k: getIntPref(k),
    };
    final Map<DatePrefsEnum, DateTime?> dates = {
      for (final k in _credentialDatePrefs) k: getDatePref(k),
    };

    Get.reset();
    await clearPrefs();
    await DBProvider.deleteDb(DB_NAME);
    await Future.delayed(const Duration(milliseconds: 500));

    // Second reset clears runtime state from the GetMaterialApp we are
    // about to destroy. Credentials are restored AFTER initPrefs so
    // GetStorage is fully re-initialised from disk before we write to it —
    // restoring before this point risks the write being lost if GetStorage's
    // in-memory state is cleared by the reset.
    Get.reset();
    await initPrefs();

    for (final entry in strings.entries) {
      await setStringPref(entry.key, entry.value);
    }
    for (final entry in ints.entries) {
      await setIntPref(entry.key, entry.value);
    }
    for (final entry in dates.entries) {
      await setDatePref(entry.key, entry.value);
    }

    await initServices();
    restartKey.currentState?.restartApp();
  }

  /// 1.x → 2.x migration: register this device and reboot into the entry page
  /// so that the normal boot flow runs with a complete credential set.
  Future<void> _handleLegacyMigration(String userId) async {
    await setStringPref(StringPrefsEnum.bootType, BOOT_TYPE_UPGRADE_1_2);
    final AuthorizeDeviceService srv = AuthorizeDeviceService();
    await srv.authorizeDevice(userId: userId);
    await DBProvider.deleteDb(DB_NAME);
    await Get.deleteAll(force: true);
    await Navigator.of(navigatorKey.currentContext!).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AppEntryPage()),
      (route) => false,
    );
  }

  /// No API response — show a network error for first-time users (who have no
  /// cached data), or silently continue in offline mode for returning users.
  Future<void> _handleNoConnection(String? userId) async {
    final bool hasAccount = (userId ?? '').isNotEmpty && userId != GUID_EMPTY;

    if (!hasAccount) {
      await Utilities.showAlert(
        'Network Error',
        'The first time you run Harrier Central, you must be connected to the network.\r\n\r\nPlease check your connection and re-run Harrier Central when online.',
        'Quit',
      );
      exit(0);
    }

    await Get.off(() => MainNavigationPage(), routeName: '/main');
  }

  /// Route based on server status, approval code, and local state.
  Future<void> _routeAfterLogin(
    String? userId,
    ApproveLoginModel loginResult,
  ) async {
    if (loginResult.serverStatusCode == serverStatusDownForMaintenance.value) {
      await Utilities.showAlert(
        'Down for Maintenance',
        'Harrier Central is temporarily offline for maintenance.\r\n\r\nYou can continue using the app in Offline Mode with cached data.',
        'Continue Offline',
      );
      await Get.off(() => MainNavigationPage(), routeName: '/main');
      return;
    }

    if (loginResult.serverStatusCode == serverStatusDegraded.value) {
      // Degraded but still up — warn the user and fall through to normal routing.
      await Utilities.showAlert(
        'Service Degraded',
        'Harrier Central is experiencing some issues. Some features may be unavailable.',
        'Continue',
      );
    }

    if (loginResult.approvalCode != loginApprovalApproved.value) {
      await _handleDisapprovedLogin(loginResult.approvalCode);
      return;
    }

    // SQL Server returns UNIQUEIDENTIFIER as uppercase; toLowerCase() normalises
    // before comparison. Replace with normalizeUuid() once uuid_utils.dart exists.
    final String normalizedId = (userId ?? GUID_EMPTY).toLowerCase();
    final bool isFirstRun = normalizedId.isEmpty || normalizedId == GUID_EMPTY;

    if (isFirstRun) {
      await Navigator.of(
        navigatorKey.currentContext!,
      ).pushReplacementNamed(RouteNames.INTRO_SLIDER.toString());
      return;
    }

    await _handleExistingUser();
  }

  /// Normal boot for a returning user: check DB version and upgrade if needed.
  Future<void> _handleExistingUser() async {
    final int installedDbVersion =
        getIntPref(IntPrefsEnum.databaseVersion) ?? 0;
    final bool dbTooFarBehind =
        installedDbVersion != DB_VERSION &&
        (installedDbVersion + 9) < DB_VERSION;

    if (dbTooFarBehind) {
      await _handleDbUpgrade(installedDbVersion);
      return;
    }

    await setStringPref(StringPrefsEnum.bootType, BOOT_TYPE_NORMAL);
    await Get.off(() => MainNavigationPage(), routeName: '/main');
  }

  /// DB version is too far behind — delete local DB and re-authorise to pull a
  /// fresh profile. Falls back to offline mode if the reset code is missing or
  /// device re-auth fails.
  Future<void> _handleDbUpgrade(int installedDbVersion) async {
    // Only set the upgrade boot type if this is a real upgrade, not a first
    // run where installedDbVersion == 0 (DB was never initialised).
    if (installedDbVersion != 0) {
      await setStringPref(StringPrefsEnum.bootType, BOOT_TYPE_UPGRADE_DB);
    }

    final String resetCode = getStringPref(StringPrefsEnum.resetCode) ?? '';
    if (resetCode.isEmpty) {
      // No reset code — can't re-authorise. Boot offline so the user can
      // recover via their profile page.
      await Get.off(() => MainNavigationPage(), routeName: '/main');
      return;
    }

    await DBProvider.deleteDb(DB_NAME);
    appModel.dbStatus = EdbStatus.uninitialized;

    // authorizeDevice may already have been called during the 1.x→2.x migration
    // path earlier in this same boot. Only call it again if deviceId is missing.
    bool authorized = true;
    if (getStringPref(StringPrefsEnum.deviceId) == null) {
      final AuthorizeDeviceService srv = AuthorizeDeviceService();
      final Map<String, String> result = await srv.authorizeDevice(
        scanText: resetCode.toUpperCase(),
      );
      authorized = result['result'] != 'failed';
    }

    if (!authorized) {
      await Utilities.showAlert(
        'Profile Load Failed',
        'We were unable to re-authorise this device during the upgrade.\r\n\r\nPlease scan your QR code from your profile page to restore access.',
        'Continue',
      );
      await Get.off(() => MainNavigationPage(), routeName: '/main');
      return;
    }

    await setIntPref(IntPrefsEnum.databaseVersion, DB_VERSION);

    final String userName =
        getStringPref(StringPrefsEnum.displayName) ?? '<no user name>';

    String dialogTitle = 'Profile Load Successful';
    String dialogMessage =
        'The app has been successfully updated for $userName.';

    if (getStringPref(StringPrefsEnum.bootType) == BOOT_TYPE_UPGRADE_1_2) {
      dialogTitle = 'Upgrade to Harrier Central 2.0';
      dialogMessage =
          'Congratulations $userName. You have just received the long awaited 2.0 version upgrade of Harrier Central!\r\n\r\nWe hope you enjoy the many new features and improvements.';
    }

    await Utilities.showAlert(dialogTitle, dialogMessage, 'OK');
    await Get.off(() => MainNavigationPage(), routeName: '/main');
  }

  /// Login was rejected by the server — tell the user why and fall through to
  /// offline mode so they aren't completely locked out.
  Future<void> _handleDisapprovedLogin(int? approvalCode) async {
    if (approvalCode == loginApprovalUnauthorizedDevice.value) {
      await Utilities.showAlert(
        'Device Not Authorised',
        'This device is not authorised to access Harrier Central. Please scan your QR code to re-authorise.',
        'Continue',
      );
    } else if (approvalCode == loginApprovalUserAccountDoesNotExist.value) {
      await Utilities.showAlert(
        'Account Not Found',
        'Your Harrier Central account could not be found. Please contact your Kennel administrator.',
        'Continue',
      );
    } else if (approvalCode == loginApprovalNotAuthorized.value) {
      await Utilities.showAlert(
        'Not Authorised',
        'You are not authorised to access Harrier Central. Please contact your Kennel administrator.',
        'Continue',
      );
    } else {
      await Utilities.showAlert(
        'Login Failed',
        'Harrier Central was unable to verify your account. Please check your connection and try again.',
        'Continue',
      );
    }

    await Get.off(() => MainNavigationPage(), routeName: '/main');
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Get userId from GetStorage; fall back to legacy SharedPreferences for
  /// apps migrating from 1.x where GetStorage wasn't yet in use.
  Future<String?> _resolveUserId() async {
    final String? userId = getStringPref(StringPrefsEnum.userId);
    final String? deviceId = getStringPref(StringPrefsEnum.deviceId);

    if (userId == null && deviceId == null) {
      return getStringPrefLegacy(StringPrefsEnum.userId);
    }
    return userId;
  }

  /// Store app version in prefs and collect location — everything ApproveLoginService
  /// needs that isn't already populated by initServices().
  Future<void> _prepareDeviceContext() async {
    final PackageInfo p = await PackageInfo.fromPlatform();
    await setStringPref(
      StringPrefsEnum.harrierCentralVersionAndBuild,
      'HC Ver: ${p.version}, Bld: ${p.buildNumber}',
    );
    await setStringPref(StringPrefsEnum.harrierCentralVersion, p.version);

    appModel.appStartTime = DateTime.now();
    appModel.hasLocationPermissions = await Permission.location.isGranted;

    if (appModel.hasLocationPermissions) {
      Get.put(LocationService());
      final Position? position = await Geolocator.getLastKnownPosition();
      deviceInfo.deviceLat = position?.latitude.toDouble();
      deviceInfo.deviceLon = position?.longitude.toDouble();
    }
  }

  /// Call the login API and return the parsed model, or null if offline / error.
  Future<ApproveLoginModel?> _fetchLoginResult({
    Function? errorCallback,
  }) async {
    if (!Utilities.isConnected()) return null;

    final ApproveLoginService svc = ApproveLoginService();
    final String responseBody = await svc.approveLogin(
      errorCallback: errorCallback,
    );

    // approveLogin shows an error dialog and returns ERROR_KEY_OK_BTN_PRESSED
    // when the server returns a hard error the user acknowledged.
    // Do not force-quit here; let boot choose a safe fallback route.
    if (responseBody == ERROR_KEY_OK_BTN_PRESSED) {
      return null;
    }

    if (responseBody.startsWith(ERROR_PREFIX) || responseBody.isEmpty) {
      return null;
    }

    final List<dynamic> responseJson =
        jsonDecode(responseBody) as List<dynamic>;

    // HC6: rowset 0 is the write SP success envelope; login data is at rowset 1.
    if (responseJson.length < 2) return null;
    final List<dynamic> loginRowset = responseJson[1] as List<dynamic>;
    if (loginRowset.isEmpty) return null;

    return ApproveLoginModel.fromJson(loginRowset[0] as Map<String, dynamic>);
  }

  /// Persist the fields from the login result that need to survive restarts.
  Future<void> _storeLoginPrefs(ApproveLoginModel login) async {
    await setStringPref(
      StringPrefsEnum.splashSequenceRootName,
      login.splashSequenceRootName,
    );
    await setIntPref(IntPrefsEnum.splashSequenceType, login.splashSequenceType);
    await removePref(DatePrefsEnum.splashSequenceViewedAt);
    await setStringPref(StringPrefsEnum.iosDownloadLink, login.iosDownloadLink);
    await setStringPref(
      StringPrefsEnum.androidDownloadLink,
      login.androidDownloadLink,
    );
    await setStringPref(StringPrefsEnum.imageRootUrl, login.imageRootUrl);
    await setStringPref(
      StringPrefsEnum.betaFeaturesEnabled,
      login.betaFeaturesEnabled,
    );
    await setStringPref(StringPrefsEnum.email, login.email);
    await setStringPref(
      StringPrefsEnum.homeKennelId,
      login.homeKennelId?.toLowerCase() ?? '',
    );
  }

  /// Show the server login message if one is present.
  Future<void> _showLoginMessage(ApproveLoginModel login) async {
    if (login.messageDisplayType == loginMessageTypeAlert.value) {
      await Utilities.showAlert(
        login.loginMessageTitle ?? 'Harrier Central Status',
        login.loginMessage ?? 'Harrier Central status is normal',
        'OK, Got it!',
      );
    }
  }

  bool _hasCompleteLocalAuthBundle({
    required String? userId,
    required String? deviceId,
    required String? deviceSecret,
  }) {
    final String normalizedUserId = (userId ?? '').trim();
    final String normalizedDeviceId = (deviceId ?? '').trim();
    final String normalizedDeviceSecret = (deviceSecret ?? '').trim();

    return normalizedUserId.isNotEmpty &&
        normalizedUserId != GUID_EMPTY &&
        normalizedDeviceId.isNotEmpty &&
        normalizedDeviceSecret.isNotEmpty;
  }

  bool _isReauthorizationError(DbErrorModel error) {
    if (error.errorType == 11) {
      return true;
    }

    final String title = (error.errorTitle ?? '').toLowerCase();
    final String message = (error.errorUserMessage ?? '').toLowerCase();
    final String debug = (error.debugMessage ?? '').toLowerCase();

    final bool tokenMentioned =
        title.contains('access token') ||
        message.contains('access token') ||
        debug.contains('access token');
    final bool invalidOrExpired =
        title.contains('invalid') ||
        message.contains('invalid') ||
        debug.contains('invalid') ||
        title.contains('expired') ||
        message.contains('expired') ||
        debug.contains('expired');

    return tokenMentioned && invalidOrExpired;
  }

  Future<void> _clearStaleDeviceAuthPrefs() async {
    await removePref(StringPrefsEnum.deviceId);
    await removePref(StringPrefsEnum.deviceSecret);
    await removePref(IntPrefsEnum.timeWindow);
    await removePref(StringPrefsEnum.thirdPartyAccessToken);
    await removePref(StringPrefsEnum.thirdPartyAuthorizationCode);
    await removePref(StringPrefsEnum.thirdPartyForceTokenRefresh);
    await removePref(DatePrefsEnum.thirdPartyTokenLastUpdated);
    await removePref(DatePrefsEnum.thirdPartyTokenExpires);
  }
}
