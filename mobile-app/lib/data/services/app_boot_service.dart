import 'package:geolocator/geolocator.dart';
import 'package:harrier_central/imports.dart';
import 'package:harrier_central/services/metrickit_service.dart';

/// Outcome of a silent re-authorisation attempt at boot.
///
/// [deadCode] is reserved for a positive rejection from the server — the code
/// is not found, or names a removed account. Everything else is
/// [transientFailure], because discarding a still-valid recovery key locks the
/// user out far more thoroughly than one more failed retry ever could.
enum ReauthorizeOutcome { success, deadCode, transientFailure }

/// Owns all app startup logic — previously embedded in AppEntryPageState._handleStartup.
///
/// Call [boot] once from AppEntryPage. The service handles every boot path and
/// is responsible for all startup navigation. Nothing in AppEntryPage needs to
/// know which path was taken.
class AppBootService {
  /// The app version the PREVIOUS run stamped — i.e., what the user upgraded
  /// FROM when this boot follows an app update. Captured in
  /// [_prepareDeviceContext] before the stamp overwrites it; being in-memory
  /// it survives the DB-upgrade GetStorage wipe within the same boot. Empty
  /// when the old build predates the version stamp (ancient) or on first run.
  static String previousInstalledVersion = '';

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
    // Ship any MetricKit crash / hang / OOM diagnostics captured natively on the
    // previous run (iOS only, harvest-gated). Fire-and-forget like the log send.
    unawaited(MetricKitService.drainAndUpload());
    _startErrorPersistence();

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

    // No registered device. If the reset code survived in the keychain, this is
    // a wiped/reset device that can re-authorise itself with no user input
    // (self-healing recovery — see resetAndReboot). Otherwise, guest discovery.
    if (deviceId == null || deviceId.isEmpty) {
      final String? recoveryCode = await getResetCode();
      if (recoveryCode != null && recoveryCode.isNotEmpty) {
        final ReauthorizeOutcome outcome = await _autoReauthorize(recoveryCode);
        if (outcome == ReauthorizeOutcome.success) {
          // A user-requested Reload Data lands here (resetAndReboot marks it);
          // silent self-healing recovery carries no marker and stays silent.
          if (getStringPref(StringPrefsEnum.bootType) == BOOT_TYPE_RELOAD_DATA) {
            await setStringPref(StringPrefsEnum.bootType, BOOT_TYPE_NORMAL);
            final String userName =
                getStringPref(StringPrefsEnum.displayName) ?? 'Hasher';
            await Utilities.showAlert(
              'Data Reload Complete',
              'Your local data has been cleared, $userName, and is being '
              'reloaded fresh from the Harrier Central servers.',
              'OK',
            );
          }
          await Get.off(() => MainNavigationPage(), routeName: '/main');
          return;
        }
        if (outcome == ReauthorizeOutcome.deadCode) {
          // The server has positively told us this code can never work again.
          // Discard it: on iOS the keychain survives an app uninstall, so a
          // dead code left in place is retried on every launch forever and
          // reinstalling cannot clear it.
          await clearStoredResetCode();

          // Deliberately neutral copy. A removed code does NOT mean the person
          // has no account — kennel admins create accounts on members' behalf,
          // so they may well have a second, live one they don't know about.
          // Send them to look themselves up rather than telling them anything
          // about the account the dead code pointed at.
          await Utilities.showAlert(
            'Let\'s find your account',
            'We couldn\'t sign you in automatically using the code saved on '
            'this device.\r\n\r\nEnter your hash name or email address and '
            'we\'ll find your account.',
            'Continue',
          );
          await OnboardingFlowController.start(
            OnboardingDestination.findMyAccount,
          );
          return;
        }

        // Transient failure (no network, timeout, 5xx, clock skew). KEEP the
        // stored code — it is very probably still valid, and it is the only
        // durable recovery key this device has.
        await Utilities.showAlert(
          'Reconnection Needed',
          'We couldn\'t reconnect this device automatically.\r\n\r\nPlease log '
          'in with your QR code or reset code to continue.',
          'Continue',
        );
        await OnboardingFlowController.start(
          OnboardingDestination.accountQuestion,
        );
        return;
      }
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
      await OnboardingFlowController.start(
        OnboardingDestination.accountQuestion,
      );
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
  ///
  /// Cleared BEFORE the send so an app death mid-send can't double-upload —
  /// but a FAILED send re-appends the log to the pref so the next boot
  /// retries. Without the requeue, one flaky POST at boot silently erased a
  /// whole session's log (the 2026-08-06 run log died this way), and the
  /// long flaky-network sessions worth diagnosing are exactly the ones most
  /// likely to boot next on a bad connection.
  static Future<void> _sendPreviousSessionErrors() async {
    final log = getStringPref(StringPrefsEnum.lastSessionErrorLog);
    if (log == null || log.isEmpty) return;
    await setStringPref(StringPrefsEnum.lastSessionErrorLog, null);
    unawaited(
      ServiceCommon.recordClientErrorLog(log).then((bool accepted) {
        if (accepted) return;
        // By now the CURRENT session has been seeding the pref (the STARTUP
        // entry lands right after this call) — merge the failed log back in
        // FRONT so entries stay chronological, with the same separator and
        // cap as _persistErrorEntry. The cap trims the oldest content first.
        final String newer =
            getStringPref(StringPrefsEnum.lastSessionErrorLog) ?? '';
        var restored = newer.isEmpty ? log : '$log\n===\n$newer';
        if (restored.length > 100000) {
          restored = restored.substring(restored.length - 100000);
        }
        unawaited(
          setStringPref(StringPrefsEnum.lastSessionErrorLog, restored),
        );
      }),
    );
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

  /// Unified reset: wipe everything (GetStorage, keychain, local DB) and reboot.
  ///
  /// [keepResetCode] true  → recovery / full reload: the reset code is preserved
  ///   in the keychain so boot can self-heal (auto re-authorise). Guarded by a
  ///   full backend connectivity check — we never wipe if we can't re-authorise
  ///   afterwards.
  /// [keepResetCode] false → log out: the reset code is wiped too, so boot lands
  ///   on guest discovery / login.
  static Future<void> resetAndReboot({required bool keepResetCode}) async {
    // A recovery reset must be able to re-authorise afterwards — verify the full
    // path through to the DB before wiping anything.
    if (keepResetCode) {
      final bool reachable = await Utilities.checkHcServer()
          .timeout(const Duration(seconds: 15), onTimeout: () => false);
      if (!reachable) {
        await Utilities.showAlert(
          'No Connection',
          'A full reload needs a connection to Harrier Central so the app can '
          'reload your data afterwards.\r\n\r\nPlease reconnect and try again.',
          'OK',
        );
        return; // aborted — nothing wiped
      }
    }

    // Hold the recovery key (if we're keeping it) before wiping.
    final String? recoveryCode = keepResetCode ? await getResetCode() : null;

    // Wipe everything.
    await clearPrefs();
    await deleteAllSecure();
    await DBProvider.deleteDb(DB_NAME);
    appModel.dbStatus = EdbStatus.uninitialized;

    // Restore only the recovery key, into the keychain, so boot can self-heal.
    if (keepResetCode && recoveryCode != null && recoveryCode.isNotEmpty) {
      await saveResetCode(recoveryCode);
    }

    // Keeping the reset code == this is a user-requested data reload (the
    // logout path passes false). Mark it so the next boot's completion dialog
    // can say WHY the data was rebuilt — the marker is written after the wipe,
    // so it survives into the reboot.
    if (keepResetCode) {
      await setStringPref(StringPrefsEnum.bootType, BOOT_TYPE_RELOAD_DATA);
    }

    await initServices();
    restartKey.currentState?.restartApp();
  }

  /// Self-healing re-authorisation. After a reset/wipe the device has no auth
  /// bundle, but the reset code survives in the keychain — use it to mint a fresh
  /// device bundle (new deviceId + device secret) and reload. Returns true on
  /// success; never throws, so callers can always fall back to a manual login and
  /// the app can't brick.
  Future<ReauthorizeOutcome> _autoReauthorize(String resetCode) async {
    try {
      final AuthorizeDeviceService srv = AuthorizeDeviceService();
      final Map<String, String> result =
          await srv.authorizeDevice(scanText: normalizeInviteCode(resetCode));

      if (result['result'] != 'success') {
        final int? errorCode = int.tryParse(result['errorCode'] ?? '');
        return isDeadInviteCode(errorCode)
            ? ReauthorizeOutcome.deadCode
            : ReauthorizeOutcome.transientFailure;
      }

      // Wipe the local DB only once we know we can repopulate it. This used to
      // run BEFORE the call, so every transient failure — a boot with no
      // signal — destroyed the user's local data and forced a full re-sync.
      await DBProvider.deleteDb(DB_NAME);
      appModel.dbStatus = EdbStatus.uninitialized;
      // The empty DB is reloaded by the normal post-login sync; mark it current
      // so _handleExistingUser does a normal boot, not another upgrade/wipe.
      await setIntPref(IntPrefsEnum.databaseVersion, DB_VERSION);
      return ReauthorizeOutcome.success;
    } catch (_) {
      return ReauthorizeOutcome.transientFailure;
    }
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
      await OnboardingFlowController.start(
        OnboardingDestination.accountQuestion,
      );
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

    // Fresh 2.x installs persist sensitive credentials to GetStorage during
    // authorizeDevice; historically only the 1.x→2.x migration promoted them to
    // the keychain, so fresh installs ran on (and were labelled) "legacy"
    // storage forever. Promote them here so every registered device ends up
    // encrypted. Idempotent — a no-op once already in secure storage.
    await ensureCredentialsEncrypted();

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
  ///
  /// Only reachable from [_handleExistingUser] (an authenticated returning
  /// user), so this rebuild is ALWAYS an app upgrade — including
  /// installedDbVersion == 0, which just means the old build predates the
  /// databaseVersion pref (added 2.2.9; a 2.1.x upgrader reads 0). Any
  /// upgrade markers must be written AFTER the Step 2 erase or they are
  /// wiped with everything else (this bit both the 3.0 welcome dialog and
  /// the version-splash check on real 2.x→3.0 upgrades).
  Future<void> _handleDbUpgrade(int installedDbVersion) async {
    // ── Step 0: Connectivity guard ───────────────────────────────────────────
    // We're about to wipe and re-authorise — without the backend we'd wipe and
    // be unable to recover. Keep the old DB and retry on the next online boot.
    final bool reachable = await Utilities.checkHcServer()
        .timeout(const Duration(seconds: 15), onTimeout: () => false);
    if (!reachable) {
      await Utilities.showAlert(
        'Update Postponed',
        'Harrier Central needs a connection to finish updating your data.\r\n\r\n'
        'We\'ll try again next time you open the app while connected.',
        'Continue',
      );
      await Get.off(
        () => const GuestDiscoveryPage(),
        routeName: RouteNames.GUEST_DISCOVERY.toString(),
      );
      return;
    }

    // ── Step 1: Read resetCode (keychain-first) ──────────────────────────────
    final String resetCode = (await getResetCode()) ?? '';
    if (resetCode.isEmpty) {
      await Get.off(() => MainNavigationPage(), routeName: '/main');
      return;
    }

    // ── Step 2: Wipe ALL local storage ───────────────────────────────────────
    await clearPrefs();
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

    // ── Step 4: Record storage type + upgrade markers ────────────────────────
    // GetStorage was just erased — these are the first writes back into it.
    // The bootType marker (drives the "Welcome to 3.0" dialog and post-boot
    // consumers) and the app-version stamp (drives MainNavigationPage's
    // version-changed splash check) both MUST be re-written here, after the
    // erase: writing them earlier gets them wiped, which is why upgrades
    // showed the generic dialog and no welcome sequence.
    await setStringPref(
      StringPrefsEnum.storageType,
      wroteToSecure ? 'encrypted' : 'legacy',
    );
    await setStringPref(StringPrefsEnum.bootType, BOOT_TYPE_UPGRADE_DB);
    final PackageInfo upgradePkg = await PackageInfo.fromPlatform();
    await setStringPref(
      StringPrefsEnum.harrierCentralVersion,
      upgradePkg.version,
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

    final String bootType = getStringPref(StringPrefsEnum.bootType) ?? '';
    if (bootType == BOOT_TYPE_UPGRADE_1_2) {
      dialogTitle = 'Upgrade to Harrier Central 2.0';
      dialogMessage =
          'Congratulations $userName. You have just received the long awaited 2.0 version upgrade of Harrier Central!\r\n\r\nWe hope you enjoy the many new features and improvements.';
    } else if (bootType == BOOT_TYPE_UPGRADE_DB) {
      final PackageInfo pkg = await PackageInfo.fromPlatform();
      final String oldMajor = previousInstalledVersion.split('.').first;
      final String newMajor = pkg.version.split('.').first;
      // The welcome dialog is for MAJOR upgrades only (2.x → 3.x). A rebuild
      // within the same major — a bug-fix release whose DB_VERSION jump forced
      // a wipe — keeps the generic 'Profile Load Successful' text; announcing
      // minor versions is the splash system's job. Empty oldMajor = the old
      // build predates the version stamp = ancient = major upgrade.
      if (oldMajor.isEmpty || oldMajor != newMajor) {
        final String majorMinor = pkg.version.split('.').take(2).join('.');
        dialogTitle = 'Welcome to Harrier Central $majorMinor';
        dialogMessage =
            'Congratulations $userName — your app has been upgraded to Harrier '
            'Central $majorMinor!\r\n\r\nYour Hash data is being refreshed for '
            'the new version. We hope you enjoy the new features and improvements.';
      }
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

  /// Get userId from prefs. (The 1.x-era SharedPreferences legacy fallback
  /// was removed 2026-08-25 — no users remain on pre-2.0 builds.)
  Future<String?> _resolveUserId() async {
    return getStringPref(StringPrefsEnum.userId);
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
    // Capture what the last run stamped BEFORE overwriting — the upgraded-FROM
    // version, used to decide whether a DB rebuild crossed a major version.
    previousInstalledVersion =
        getStringPref(StringPrefsEnum.harrierCentralVersion) ?? '';
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

    // Permissions V2: the server sends the compiled global matrix + its watermark
    // only when newer than the watermark we sent. Persist + apply when present;
    // otherwise keep the matrix we already have (loaded at boot in initServices).
    final String? permMatrixJson = row['permissionMatrixJson'] as String?;
    if (permMatrixJson != null && permMatrixJson.isNotEmpty) {
      await setStringPref(StringPrefsEnum.permissionMatrixJson, permMatrixJson);
      await setStringPref(
        StringPrefsEnum.permissionMatrixWatermark,
        (row['permissionMatrixUpdatedAt'] as String?) ?? '',
      );
      PermissionMatrix.setGlobalJson(permMatrixJson);
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

    final String resetCode = (await getResetCode()) ?? '';
    await _clearStaleDeviceAuthPrefs();

    if (resetCode.isEmpty) {
      await OnboardingFlowController.start(
        OnboardingDestination.accountQuestion,
      );
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
      await OnboardingFlowController.start(
        OnboardingDestination.accountQuestion,
      );
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
