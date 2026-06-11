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
    debugPrint('[BOOT] boot() start: ${DateTime.now().millisecondsSinceEpoch}ms');
    await initPrefs();
    debugPrint('[BOOT] initPrefs done: ${DateTime.now().millisecondsSinceEpoch}ms');

    // Send the previous session's error log to the server (awaited only for the
    // pref clear — the server call itself is fire-and-forget), then seed the
    // new session log and start persisting errors to the pref.
    await _sendPreviousSessionErrors();
    _startErrorPersistence();

    if (getStringPref(StringPrefsEnum.bootType) == BOOT_TYPE_RELOAD_DATA) {
      await _handleReloadData();
      return;
    }

    final String? userId = await _resolveUserId();
    final String? deviceId = getStringPref(StringPrefsEnum.deviceId);
    final String? deviceSecret = getStringPref(StringPrefsEnum.deviceSecret);
    debugPrint('[BOOT] userId resolved: ${userId != null ? "present" : "null"}, deviceId: ${deviceId != null ? "present" : "null"}');

    debugPrint('[BOOT] checkForInternetConnection start: ${DateTime.now().millisecondsSinceEpoch}ms');
    await Utilities.checkForInternetConnection();
    debugPrint('[BOOT] checkForInternetConnection done: ${DateTime.now().millisecondsSinceEpoch}ms');

    // 1.x → 2.x migration: userId exists in legacy prefs but no deviceId yet.
    if (userId != null && deviceId == null) {
      await _handleLegacyMigration(userId);
      return;
    }

    // No registered device — drop into guest discovery mode instead of forcing
    // the user through the intro slider immediately. They can browse runs and
    // choose to log in or create an account when ready.
    if (deviceId == null || deviceId.isEmpty) {
      await Get.off(
        () => const GuestDiscoveryPage(),
        routeName: RouteNames.GUEST_DISCOVERY.toString(),
      );
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

    debugPrint('[BOOT] _prepareDeviceContext start: ${DateTime.now().millisecondsSinceEpoch}ms');
    await _prepareDeviceContext();
    debugPrint('[BOOT] _prepareDeviceContext done: ${DateTime.now().millisecondsSinceEpoch}ms');

    bool reauthorizationHandled = false;
    debugPrint('[BOOT] _fetchLoginResult start: ${DateTime.now().millisecondsSinceEpoch}ms');
    final ApproveLoginModel? loginResult = await _fetchLoginResult(
      errorCallback: (DbErrorModel error) async {
        if (_isReauthorizationError(error)) {
          reauthorizationHandled = true;
          await _handleDeviceNoLongerRegistered();
          return true;
        }
        return false;
      },
    );

    debugPrint('[BOOT] _fetchLoginResult done: ${DateTime.now().millisecondsSinceEpoch}ms — result=${loginResult != null ? "present" : "null"}, reauthorizationHandled=$reauthorizationHandled');

    if (reauthorizationHandled) return;

    if (loginResult == null) {
      debugPrint('[BOOT] loginResult null — handling no connection');
      await _handleNoConnection(userId);
      return;
    }

    debugPrint('[BOOT] _storeLoginPrefs start: ${DateTime.now().millisecondsSinceEpoch}ms');
    await _storeLoginPrefs(loginResult);
    debugPrint('[BOOT] _storeLoginPrefs done: ${DateTime.now().millisecondsSinceEpoch}ms');
    debugPrint('[BOOT] _showLoginMessage start: ${DateTime.now().millisecondsSinceEpoch}ms');
    await _showLoginMessage(loginResult);
    debugPrint('[BOOT] _showLoginMessage done: ${DateTime.now().millisecondsSinceEpoch}ms');
    debugPrint('[BOOT] _routeAfterLogin start: ${DateTime.now().millisecondsSinceEpoch}ms');
    await _routeAfterLogin(userId, loginResult);
    debugPrint('[BOOT] _routeAfterLogin done: ${DateTime.now().millisecondsSinceEpoch}ms');
  }

  // ---------------------------------------------------------------------------
  // Error log persistence
  // ---------------------------------------------------------------------------

  /// Reads the previous session's error log, sends it to the server, then
  /// clears the pref so it doesn't repeat on the next boot.
  static Future<void> _sendPreviousSessionErrors() async {
    final log = getStringPref(StringPrefsEnum.lastSessionErrorLog);
    if (log == null || log.isEmpty) return;
    await setStringPref(StringPrefsEnum.lastSessionErrorLog, null);
    unawaited(ServiceCommon.recordClientErrorLog(log));
  }

  /// Wires BootLogger to start persisting errors to the pref if the debug
  /// harvest flag (set on the previous boot) is enabled. Discards the buffer
  /// if harvesting is not enabled for this device.
  static void _startErrorPersistence() {
    if (getBoolPref(BoolPrefsEnum.debugHarvestEnabled) != true) {
      BootLogger.clearErrorBuffer();
      return;
    }
    BootLogger.onErrorPersist = _persistErrorEntry;
    _persistErrorEntry('[${DateTime.now().toIso8601String()}] [STARTUP]');
    for (final entry in BootLogger.pendingErrorEntries) {
      _persistErrorEntry(entry);
    }
    BootLogger.clearErrorBuffer();
  }

  /// Appends a single error entry to the pref, capped at 20 000 chars.
  static void _persistErrorEntry(String entry) {
    final existing = getStringPref(StringPrefsEnum.lastSessionErrorLog) ?? '';
    final separator = existing.isEmpty ? '' : '\n===\n';
    var updated = '$existing$separator$entry';
    if (updated.length > 100000) {
      updated = updated.substring(updated.length - 100000);
    }
    unawaited(setStringPref(StringPrefsEnum.lastSessionErrorLog, updated));
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
    debugPrint('[BOOT] _routeAfterLogin: serverStatusCode=${loginResult.serverStatusCode}, approvalCode=${loginResult.approvalCode}');
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

    final String normalizedId = normalizeUuid(userId ?? GUID_EMPTY);
    final bool isFirstRun = normalizedId.isEmpty || normalizedId == GUID_EMPTY;

    if (isFirstRun) {
      await Navigator.of(
        navigatorKey.currentContext!,
      ).pushReplacementNamed(RouteNames.INTRO_SLIDER.toString());
      return;
    }

    debugPrint('[BOOT] _handleExistingUser start: ${DateTime.now().millisecondsSinceEpoch}ms');
    await _handleExistingUser();
    debugPrint('[BOOT] _handleExistingUser done: ${DateTime.now().millisecondsSinceEpoch}ms');
  }

  /// Normal boot for a returning user: check DB version and upgrade if needed.
  Future<void> _handleExistingUser() async {
    debugPrint('[BOOT] _handleExistingUser: checking DB version');
    final int installedDbVersion =
        getIntPref(IntPrefsEnum.databaseVersion) ?? 0;
    debugPrint('[BOOT] _handleExistingUser: installedDbVersion=$installedDbVersion, DB_VERSION=$DB_VERSION');
    final bool dbTooFarBehind =
        installedDbVersion != DB_VERSION &&
        (installedDbVersion + 9) < DB_VERSION;

    if (dbTooFarBehind) {
      await _handleDbUpgrade(installedDbVersion);
      return;
    }

    await setStringPref(StringPrefsEnum.bootType, BOOT_TYPE_NORMAL);
    debugPrint('[BOOT] Get.off(MainNavigationPage) start: ${DateTime.now().millisecondsSinceEpoch}ms');
    await Get.off(() => MainNavigationPage(), routeName: '/main');
    debugPrint('[BOOT] Get.off(MainNavigationPage) done: ${DateTime.now().millisecondsSinceEpoch}ms');

    // Navigate to songbook if a proximity song was found at login.
    final SongSessionNotifier notifier = SongSessionNotifier.ensure();
    if (notifier.navigateOnLoad) {
      notifier.clearNavigateOnLoad();
      final String? eid = notifier.pendingEventId.value;
      if (eid != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.to<void>(() => AppScaffold(
            appBar: AppBar(
              backgroundColor: themeAppBarBackground,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text('Songbook', style: ts_appBarTitle),
            ),
            body: SongsPage(eventId: eid),
          ));
        });
      }
    }
  }

  /// DB version is too far behind — migrate to secure storage, wipe local DB,
  /// and re-authorise to pull a fresh profile from the server.
  Future<void> _handleDbUpgrade(int installedDbVersion) async {
    if (installedDbVersion != 0) {
      await setStringPref(StringPrefsEnum.bootType, BOOT_TYPE_UPGRADE_DB);
    }

    // ── Step 1: Read resetCode ───────────────────────────────────────────────
    // Prefer secure storage (already migrated devices) over plain GetStorage.
    final String? secureCode = await readSecureResetCode();
    final bool readFromSecure = secureCode != null && secureCode.isNotEmpty;
    final String resetCode =
        readFromSecure ? secureCode : (getStringPref(StringPrefsEnum.resetCode) ?? '');

    if (resetCode.isEmpty) {
      await Get.off(() => MainNavigationPage(), routeName: '/main');
      return;
    }

    // ── Step 2: Wipe ALL local storage ───────────────────────────────────────
    await GetStorage().erase();
    await deleteAllSecure();

    // ── Step 3: Write resetCode to secure storage ────────────────────────────
    // Retry once. On persistent failure, warn the user and fall back to plain
    // GetStorage so the migration can still complete.
    final bool wroteToSecure = await writeSecureResetCode(resetCode);
    if (!wroteToSecure) {
      await Utilities.showAlert(
        'Secure Storage Unavailable',
        'Your device does not support encrypted storage. Your data will be stored using standard security.',
        'OK',
      );
      await setStringPref(StringPrefsEnum.resetCode, resetCode);
    }

    // ── Step 4: Record storage type ──────────────────────────────────────────
    // GetStorage was just erased — this is the first write back into it.
    await setStringPref(
      StringPrefsEnum.storageType,
      wroteToSecure ? 'encrypted' : 'legacy',
    );

    // ── Step 5: Delete local SQLite DB ───────────────────────────────────────
    await DBProvider.deleteDb(DB_NAME);
    appModel.dbStatus = EdbStatus.uninitialized;

    // ── Step 6: Re-authorise device ──────────────────────────────────────────
    // GetStorage was erased so deviceId is always null here — always call
    // authorizeDevice to get a fresh deviceSecret and user profile from server.
    final AuthorizeDeviceService srv = AuthorizeDeviceService();
    final Map<String, String> result = await srv.authorizeDevice(
      scanText: resetCode.toUpperCase(),
    );
    final bool authorized = result['result'] != 'failed';

    if (!authorized) {
      await Utilities.showAlert(
        'Profile Load Failed',
        'We were unable to re-authorise this device during the upgrade.\r\n\r\nPlease scan your QR code from your profile page to restore access.',
        'Continue',
      );
      await Get.off(() => MainNavigationPage(), routeName: '/main');
      return;
    }

    // ── Step 7: Migrate fresh resetCode to secure storage ───────────────────
    // authorizeDevice wrote a new resetCode to GetStorage. If we're using
    // secure storage, move it there and remove it from GetStorage.
    if (wroteToSecure) {
      final String? freshCode = getStringPref(StringPrefsEnum.resetCode);
      if (freshCode != null && freshCode.isNotEmpty) {
        final bool migrated = await writeSecureResetCode(freshCode);
        if (migrated) {
          await removePref(StringPrefsEnum.resetCode);
        }
      }
    }

    await setIntPref(IntPrefsEnum.databaseVersion, DB_VERSION);

    final String userName =
        getStringPref(StringPrefsEnum.displayName) ?? '<no user name>';
    final bool isEncrypted =
        getStringPref(StringPrefsEnum.storageType) == 'encrypted';

    String dialogTitle =
        isEncrypted ? 'Account Load Successful' : 'Profile Load Successful';
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
    debugPrint('[BOOT] _prepareDeviceContext: PackageInfo.fromPlatform start: ${DateTime.now().millisecondsSinceEpoch}ms');
    final PackageInfo p = await PackageInfo.fromPlatform();
    debugPrint('[BOOT] _prepareDeviceContext: PackageInfo done: ${DateTime.now().millisecondsSinceEpoch}ms — v${p.version}+${p.buildNumber}');
    await setStringPref(
      StringPrefsEnum.harrierCentralVersionAndBuild,
      'HC Ver: ${p.version}, Bld: ${p.buildNumber}',
    );
    await setStringPref(StringPrefsEnum.harrierCentralVersion, p.version);

    appModel.appStartTime = DateTime.now();
    debugPrint('[BOOT] _prepareDeviceContext: Permission.location.isGranted check: ${DateTime.now().millisecondsSinceEpoch}ms');
    appModel.hasLocationPermissions = await Permission.location.isGranted;
    debugPrint('[BOOT] _prepareDeviceContext: hasLocationPermissions=${appModel.hasLocationPermissions}: ${DateTime.now().millisecondsSinceEpoch}ms');

    if (appModel.hasLocationPermissions) {
      if (!Get.isRegistered<LocationService>()) {
        Get.put(LocationService());
      }
      if (kDebugMode) {
        debugPrint('[BOOT] _prepareDeviceContext: Geolocator.getLastKnownPosition start: ${DateTime.now().millisecondsSinceEpoch}ms');
      }
      final Position? position = await Geolocator.getLastKnownPosition();
      if (kDebugMode) {
        debugPrint('[BOOT] _prepareDeviceContext: getLastKnownPosition done: ${DateTime.now().millisecondsSinceEpoch}ms — lat=${position?.latitude}');
      }
      deviceInfo.deviceLat = position?.latitude.toDouble();
      deviceInfo.deviceLon = position?.longitude.toDouble();
    }
  }

  /// Call the login API and return the parsed model, or null if offline / error.
  Future<ApproveLoginModel?> _fetchLoginResult({
    Function? errorCallback,
  }) async {
    debugPrint('[BOOT] _fetchLoginResult: isConnected=${Utilities.isConnected()}: ${DateTime.now().millisecondsSinceEpoch}ms');
    if (!Utilities.isConnected()) return null;

    final ApproveLoginService svc = ApproveLoginService();
    debugPrint('[BOOT] _fetchLoginResult: approveLogin HTTP call start: ${DateTime.now().millisecondsSinceEpoch}ms');
    final String responseBody = await svc.approveLogin(
      errorCallback: errorCallback,
    );
    debugPrint('[BOOT] _fetchLoginResult: approveLogin HTTP call done: ${DateTime.now().millisecondsSinceEpoch}ms — responseLen=${responseBody.length}');

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
    if (responseJson[1] is! List) return null;
    final List<dynamic> loginRowset = responseJson[1] as List<dynamic>;
    if (loginRowset.isEmpty) return null;

    final Map<String, dynamic> row = loginRowset[0] as Map<String, dynamic>;

    // Check for proximity song (server found an active song within 500m).
    // Parsed outside ApproveLoginModel to avoid regenerating Freezed files.
    final String? activeSongId      = row['activeSongId']      as String?;
    final String? activeSongEventId = row['activeSongEventId'] as String?;
    if (activeSongId != null && activeSongId.isNotEmpty &&
        activeSongId != GUID_EMPTY &&
        activeSongEventId != null && activeSongEventId.isNotEmpty &&
        activeSongEventId != GUID_EMPTY) {
      SongSessionNotifier.ensure().setPendingProximitySong(
        eventId: activeSongEventId,
        songId:  activeSongId,
      );
    }

    return ApproveLoginModel.fromJson(row);
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
    final int prefs = login.hasherPreferences ?? 0;
    await setBoolPref(
      BoolPrefsEnum.debugHarvestEnabled,
      (prefs & hasherPref_debugHarvestEnabled) != 0,
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

  Future<void> _handleDeviceNoLongerRegistered() async {
    // Report immediately before clearing prefs so the stale deviceId is captured.
    // hcapp_logClientErrors accepts unregistered devices for exactly this case.
    unawaited(ServiceCommon.recordClientErrorLog(
      '[${DateTime.now().toIso8601String()}] [DEVICE_NOT_REGISTERED] '
      'deviceId=${getStringPref(StringPrefsEnum.deviceId) ?? "<null>"} '
      'userId=${getStringPref(StringPrefsEnum.userId) ?? "<null>"} '
      'hcVersion=${getStringPref(StringPrefsEnum.harrierCentralVersionAndBuild) ?? "<null>"}',
    ));

    await Get.dialog<void>(
      AlertDialog(
        title: const Text('Device No Longer Registered'),
        content: const Text(
          'This device is no longer registered with Harrier Central.\n\nTap Reload to reconnect automatically.',
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Reload'),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    final String resetCode = getStringPref(StringPrefsEnum.resetCode) ?? '';
    await _clearStaleDeviceAuthPrefs();

    if (resetCode.isEmpty) {
      await Navigator.of(
        navigatorKey.currentContext!,
      ).pushReplacementNamed(RouteNames.INTRO_SLIDER.toString());
      return;
    }

    await DBProvider.deleteDb(DB_NAME);
    appModel.dbStatus = EdbStatus.uninitialized;

    final AuthorizeDeviceService srv = AuthorizeDeviceService();
    final Map<String, String> result = await srv.authorizeDevice(
      scanText: resetCode.toUpperCase(),
    );

    if (result['result'] != 'success') {
      await Utilities.showAlert(
        'Reconnection Failed',
        'Unable to reconnect this device automatically. Please restart the app and use your QR code or reset code to log in.',
        'Continue',
      );
      await Navigator.of(
        navigatorKey.currentContext!,
      ).pushReplacementNamed(RouteNames.INTRO_SLIDER.toString());
      return;
    }

    restartKey.currentState?.restartApp();
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
