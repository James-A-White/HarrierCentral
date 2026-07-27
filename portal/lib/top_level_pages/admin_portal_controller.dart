import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:hcportal/firebase_options.dart';
import 'package:hcportal/imports.dart';
import 'package:web/web.dart' as web;

class AdminPortalController extends GetxController {
  // Same-device login from the mobile app: the app registers an auth code and
  // opens the portal at `…/#authCode=<code>`. When present we use it directly
  // (the app has already approved it), so the poll below authenticates without
  // the user scanning a QR. Otherwise we generate a fresh code for the QR flow.
  final String authCode = _resolveAuthCode();

  // Captured at construction (before the code is stripped from the URL) so the
  // QR-vs-app-login branch still knows which path we are on.
  static bool _isAppLogin = false;

  /// True when [authCode] came from the URL (mobile-app same-device login).
  bool get isAppLogin => _isAppLogin;

  static String _resolveAuthCode() {
    final code = _codeFromUrl();
    if (code.length >= 10) {
      _isAppLogin = true;
      // Remove the code from the address bar/history immediately (defence in
      // depth — it is single-use, but this stops it lingering).
      _stripCodeFromUrl();
      return code;
    }
    return const Uuid().v4();
  }

  /// Reads the login code from the URL **fragment** (`#authCode=…`, which the
  /// browser never sends to any server, so it stays out of access logs) and
  /// falls back to the legacy query string (`?authCode=…`) for older app builds.
  static String _codeFromUrl() {
    final fromFragment =
        Uri.splitQueryString(Uri.base.fragment)['authCode']?.trim() ?? '';
    if (fromFragment.length >= 10) return fromFragment;
    return Uri.base.queryParameters['authCode']?.trim() ?? '';
  }

  /// Strips any `?query`/`#fragment` from the browser URL, leaving just the
  /// path — so the auth code is not left in history, the back button, the
  /// address bar, or a `Referer` header.
  static void _stripCodeFromUrl() {
    try {
      final path = web.window.location.pathname;
      web.window.history
          .replaceState(null, '', path.isEmpty ? '/' : path);
    } catch (_) {
      // Non-web / unsupported — nothing to strip.
    }
  }

  String firstName = '';
  String lastName = '';
  String hashName = '';
  String displayName = '';
  String photo = '';
  String publicHasherId = '';
  bool isReady = false;

  final List<HasherKennelsModel> allKennels = [];
  final List<HasherKennelsModel> filteredKennels = [];

  bool hasNavigated = false;
  bool privilegesFetched = false;

  final FocusNode searchFocusNode = FocusNode();
  final TextEditingController searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    unawaited(_init());
  }

  @override
  void onClose() {
    searchFocusNode.dispose();
    searchController.dispose();
    super.onClose();
  }

  void filterKennels(String text) {
    filteredKennels
      ..clear()
      ..addAll(
        allKennels
            .where(
              (element) =>
                  element.kennelName.toLowerCase().contains(text.toLowerCase()),
            )
            .toList(),
      );
    update();
  }

  Future<void> _initHive() async {
    Hive.init('ignored');
    box = await Hive.openBox<dynamic>(HIVE_NAME);
    isReady = true;
    update();
  }

  Future<void> _init() async {
    await _initHive();

    packageInfo.value = await PackageInfo.fromPlatform();

    try {
      var previousBuildNumber = 0;

      if (box.containsKey(HIVE_APP_BUILD)) {
        previousBuildNumber = await box.get(HIVE_APP_BUILD) as int;
      }

      previousBuildNumber =
          int.tryParse(packageInfo.value?.buildNumber ?? '0') ?? 0;

      // Sometimes we change the types of parameters being saved in Hive.
      // When we do this, clear all parameters and force a re-login to
      // reset everything to a stable and known state.
      if (previousBuildNumber <= 554) {
        await box.clear();
      }

      // If the previousBuildNumber and currentBuildNumber differ, the
      // software has been updated since the last run.
      final currentBuildNumber =
          int.tryParse(packageInfo.value?.buildNumber ?? '0') ?? 0;

      if (previousBuildNumber != currentBuildNumber) {
        await box.put(HIVE_APP_BUILD, previousBuildNumber);
        await box.put(HIVE_APP_VERSION, packageInfo.value?.buildNumber ?? '0');
      }

      // uncomment the line below to force login on every run
      //await box.put(HIVE_IS_LOGGED_IN, false);
      if (!box.containsKey(HIVE_IS_LOGGED_IN)) {
        await box.put(HIVE_IS_LOGGED_IN, false);
      }

      if (box.get(HIVE_IS_LOGGED_IN) as bool) {
        firstName = box.get(HIVE_FIRST_NAME) as String;
        lastName = box.get(HIVE_LAST_NAME) as String;
        hashName = box.get(HIVE_HASH_NAME) as String;
        displayName = box.get(HIVE_DISPLAY_NAME) as String? ??
            box.get(HIVE_HASH_NAME) as String;
        photo = box.get(HIVE_HASHER_PHOTO) as String? ?? '';
        publicHasherId = box.get(HIVE_HASHER_ID) as String;

        await _getHasherKennels();
        await _fetchPlatformAdminPrivileges();
      } else {
        final deviceId = const Uuid().v4();

        final deviceInfoPlugin = DeviceInfoPlugin();
        final webInfo = await deviceInfoPlugin.webBrowserInfo;

        final deviceData = {
          'browserName': webInfo.browserName.toString(),
          'appCodeName': webInfo.appCodeName,
          'appName': webInfo.appName,
          'appVersion': webInfo.appVersion,
          'deviceMemory': webInfo.deviceMemory,
          'language': webInfo.language,
          'languages': webInfo.languages,
          'platform': webInfo.platform,
          'product': webInfo.product,
          'productSub': webInfo.productSub,
          'userAgent': webInfo.userAgent,
          'vendor': webInfo.vendor,
          'vendorSub': webInfo.vendorSub,
          'hardwareConcurrency': webInfo.hardwareConcurrency,
          'maxTouchPoints': webInfo.maxTouchPoints,
        };

        final allInfo = jsonEncode(deviceData);
        await Future<void>.delayed(
          const Duration(seconds: AUTH_POLL_INTERVAL_SECONDS),
        );

        if (kDebugMode) debugPrint(
          '[Auth poll] Starting — authCode: ${authCode.substring(0, 8)}… '
          'max $AUTH_POLL_MAX_ATTEMPTS attempts @ ${AUTH_POLL_INTERVAL_SECONDS}s',
        );

        for (var i = 0; i < AUTH_POLL_MAX_ATTEMPTS; i++) {
          if (kDebugMode) debugPrint(
            '[Auth poll] Attempt ${i + 1}/$AUTH_POLL_MAX_ATTEMPTS',
          );

          // NOTE: This is a randomly generated user ID that matches the one
          // in the database used to generate the access token.
          // DO NOT CHANGE THIS or it will result in an invalid access token error.
          const serviceAccountId = HC_ADMIN_PORTAL_INTERNAL_USER_ID;

          final accessToken = Utilities.generateToken(
            serviceAccountId,
            'hcportal_confirmAuthentication',
            paramString: authCode,
          );

          final body = <String, String?>{
            'queryType': 'confirmAuthentication',
            'deviceId': serviceAccountId,
            'newDeviceId': deviceId,
            'accessToken': accessToken,
            'qrCodeData': authCode,
            'deviceInfo': allInfo,
            // QR flow (code shown on screen) gets the 5-minute TTL; same-device
            // app-login (code from the URL) gets the tighter 90s window.
            'isQrFlow': isAppLogin ? '0' : '1',
          };

          final authResult =
              await ServiceCommon.sendHttpPostToHC6Api(body);
          if (kDebugMode) debugPrint(authResult is ApiError
              ? '[Auth poll] Attempt ${i + 1} — SP FAILED'
              : '[Auth poll] Attempt ${i + 1} — SP success');

          if (authResult case ApiSuccess(:final body)) {
            final rows = (json.decode(body) as List<dynamic>)[0] as List<dynamic>;
            if (rows.isEmpty) {
              if (kDebugMode) debugPrint(
                '[Auth poll] Attempt ${i + 1} — no scan yet, waiting…',
              );
              await Future<void>.delayed(
                const Duration(seconds: AUTH_POLL_INTERVAL_SECONDS),
              );
              continue;
            }
            if (kDebugMode) debugPrint(
              '[Auth poll] Attempt ${i + 1} — scan received! Parsing credentials…',
            );
            final items = rows[0] as Map<String, dynamic>;

            publicHasherId = items['publicHasherId'] as String;
            if (publicHasherId.isNotEmpty) {
              firstName = items['firstName'] as String;
              lastName = items['lastName'] as String;
              hashName = items['hashName'] as String;
              displayName = items['displayName'] as String;
              photo = items['photo'] as String;
              await box.put(HIVE_FIRST_NAME, firstName);
              await box.put(HIVE_LAST_NAME, lastName);
              await box.put(HIVE_HASH_NAME, hashName);
              await box.put(HIVE_DISPLAY_NAME, displayName);
              await box.put(HIVE_HASHER_PHOTO, photo);
              await box.put(HIVE_HASHER_ID, publicHasherId);
              await box.put(HIVE_DEVICE_ID, deviceId);
              await box.put(
                HIVE_DEVICE_SECRET,
                (items['iconDataBase64'] as String?) ?? '',
              );
              await box.put(HIVE_IS_LOGGED_IN, true);

              update();

              await _getHasherKennels();
              await _fetchPlatformAdminPrivileges();

              if (kDebugMode) debugPrint(
                '[Auth poll] Login complete on attempt ${i + 1} — '
                'hasher: $publicHasherId',
              );
              break;
            }
          }
          await Future<void>.delayed(
            const Duration(seconds: AUTH_POLL_INTERVAL_SECONDS),
          );
        }
        if (kDebugMode) debugPrint('[Auth poll] Loop ended.');
      }
      unawaited(_initializeNotifications());
    } on Exception catch (e) {
      if (kDebugMode) debugPrint('App init error: $e');
    }
  }

  Future<String?> _fetchAndStoreFcmToken(FirebaseMessaging messaging) async {
    final cachedFcmToken = (box.get(HIVE_FCM_TOKEN) as String?) ?? '';
    final newToken = await messaging.getToken(vapidKey: FIREBASE_VAPID_KEY);
    if (newToken != null && newToken != cachedFcmToken) {
      await box.put(HIVE_FCM_TOKEN, newToken);
      await box.put(HIVE_FCM_TOKEN_CHANGED, true);
      await box.put(HIVE_FCM_TOKEN_DATE, DateTime.now());
    } else {
      await box.put(HIVE_FCM_TOKEN_CHANGED, false);
    }
    return newToken;
  }

  Future<void> _syncFcmTokenToServer(String? fcmToken) async {
    final deviceId = (box.get(HIVE_DEVICE_ID) as String?) ?? '';
    final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';
    // Compound token: binds the auth to the specific FCM token being registered.
    // Use deviceSecret-only paramString when fcmToken is null (no token to bind).
    final accessToken = Utilities.generateToken(
      deviceId,
      'hcportal_updateFcmToken',
      paramString: fcmToken != null ? '$deviceSecret:$fcmToken' : deviceSecret,
    );
    final body = <String, String?>{
      'queryType': 'updateFcmToken',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'fcmToken': fcmToken,
      'buildNumber': packageInfo.value?.buildNumber ?? '0',
      'version': packageInfo.value?.version ?? 'unknown',
    };
    final fcmResult = await ServiceCommon.sendHttpPostToHC6Api(body);
    if (kDebugMode) debugPrint(fcmResult is ApiError
        ? 'SP 19 [updateFcmToken] called — FAILED'
        : 'SP 19 [updateFcmToken] called — success');
  }

  Future<void> _initializeNotifications() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Sync refreshed tokens to the DB mid-session (Firebase can rotate tokens
    // at any time without an app restart).
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      await box.put(HIVE_FCM_TOKEN, token);
      await _syncFcmTokenToServer(token);
    });

    String? newFcmToken;

    final messaging = FirebaseMessaging.instance;
    final ns = await messaging.getNotificationSettings();
    if (ns.authorizationStatus == AuthorizationStatus.authorized) {
      newFcmToken = await _fetchAndStoreFcmToken(messaging);
    } else if ((ns.authorizationStatus == AuthorizationStatus.notDetermined) ||
        (ns.authorizationStatus == AuthorizationStatus.provisional)) {
      await CoreUtilities.showAlert(
        'Harrier Central Notifications',
        'Harrier Central will soon contain a trail chat function (expected in the next few weeks) where a chat group is automatically created for each run.\r\n\r\nFor this to work properly, you must enable notifications. You will not receive any pop-up notifications by enabling notifications for Harrier Central.',
        'OK',
        dialogImage: 'images/other/chat_dialog.png',
        width: 700,
        height: 380,
      );

      final settings = await messaging.requestPermission();

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        newFcmToken = await _fetchAndStoreFcmToken(messaging);
      } else {
        await box.delete(HIVE_FCM_TOKEN);
        await box.delete(HIVE_FCM_TOKEN_CHANGED);
        await box.delete(HIVE_FCM_TOKEN_DATE);
      }
    } else if (ns.authorizationStatus == AuthorizationStatus.denied) {
      var fcmTokenDeniedCount =
          (box.get(HIVE_FCM_TOKEN_DENIED_COUNT) ?? 0) as int;

      if (fcmTokenDeniedCount % FCM_DENIED_REMINDER_INTERVAL == 0) {
        final userResponse = await CoreUtilities.showAlert(
              'Harrier Central Notifications',
              'Harrier Central will soon contain a trail chat function (expected in the next few weeks) where a chat group is automatically created for each run.\r\n\r\nFor this to work properly, you must enable notifications. You will not receive any pop-up notifications by enabling notifications for Harrier Central.',
              'Allow notifications',
              cancelButtonText: 'Do not allow',
              showCancelButton: true,
              dialogImage: 'images/other/chat_dialog.png',
              width: 700,
              height: 380,
            ) ??
            true;

        if (userResponse) {
          await CoreUtilities.showAlert(
            'Harrier Central Notifications',
            "It looks like you have previously blocked notifications for Harrier Central. Our web app cannot force the browser to ask you again for permission to show notifications.\r\n\r\nYou will have to enable notifications for Harrier Central in your browser's settings.",
            'OK',
            width: 400,
            height: 150,
          );
        }
      }

      fcmTokenDeniedCount++;
      await box.put(HIVE_FCM_TOKEN_DENIED_COUNT, fcmTokenDeniedCount);
    }

    await _syncFcmTokenToServer(newFcmToken);
  }

  Future<void> _getHasherKennels() async {
    final deviceId = box.get(HIVE_DEVICE_ID) as String;
    final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';
    final fcmToken = box.get(HIVE_FCM_TOKEN) as String?;

    final accessToken = Utilities.generateToken(
      deviceId,
      'hcportal_getLandingPageData',
      paramString: deviceSecret,
    );

    final body = <String, String?>{
      'queryType': 'getLandingPageData',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'fcmToken': fcmToken,
    };

    final landingResult = await ServiceCommon.sendHttpPostToHC6Api(body);
    if (kDebugMode) debugPrint(landingResult is ApiError
        ? 'SP 13 [getLandingPageData] called — FAILED'
        : 'SP 13 [getLandingPageData] called — success');

    // Stale device credentials (e.g. device record deleted server-side) cause
    // auth to fail even though HIVE_IS_LOGGED_IN is still true.  Without
    // clearing Hive the user is stuck — every reload fails the same way.
    // A private/incognito window fixes it because it starts with empty Hive.
    // Reproduce that fix automatically: clear Hive and reload to force a fresh
    // QR-code login whenever the startup SP call returns an auth error.
    if (landingResult is ApiError) {
      await box.clear();
      web.window.location.reload();
      return;
    }

    if (landingResult case ApiSuccess(:final body)) {
      final items = ((json.decode(body) as List<dynamic>)[0]
          as List<dynamic>)[0] as Map<String, dynamic>;

      if (publicHasherId.isNotEmpty) {
        firstName = items['firstName'] as String;
        lastName = items['lastName'] as String;
        hashName = items['hashName'] as String;
        await box.put(HIVE_FIRST_NAME, firstName);
        await box.put(HIVE_LAST_NAME, lastName);
        await box.put(HIVE_HASH_NAME, hashName);

        final itemList =
            (json.decode(body) as List<dynamic>)[1] as List<dynamic>;

        for (var i = 0; i < itemList.length; i++) {
          final hkModel = HasherKennelsModel.fromJson(
            itemList[i] as Map<String, dynamic>,
          );
          allKennels.add(hkModel);
        }
      }
    }

    allKennels.sort((HasherKennelsModel a, HasherKennelsModel b) {
      final cmp = (b.appAccessFlags & 0x00000001)
          .compareTo(a.appAccessFlags & 0x00000001);
      if (cmp != 0) {
        return cmp;
      }
      return a.kennelName.compareTo(b.kennelName);
    });

    filteredKennels.addAll(allKennels);
    update();
  }

  Future<void> _fetchPlatformAdminPrivileges() async {
    try {
      final deviceId = (box.get(HIVE_DEVICE_ID) as String?) ?? '';
      final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';

      final accessToken = Utilities.generateToken(
        deviceId,
        'hcportal_getHcAdminPrivileges',
        paramString: deviceSecret,
      );

      final body = <String, String?>{
        'queryType': 'getHcAdminPrivileges',
        'deviceId': deviceId,
        'accessToken': accessToken,
      };

      final result = await ServiceCommon.sendHttpPostToHC6Api(body);
      if (kDebugMode) debugPrint(result is ApiError
          ? 'SP [getHcAdminPrivileges] called — FAILED'
          : 'SP [getHcAdminPrivileges] called — success');

      if (result case ApiSuccess(:final body)) {
        final row = ((json.decode(body) as List<dynamic>)[0]
            as List<dynamic>)[0] as Map<String, dynamic>;

        await box.put(HIVE_PLATFORM_ADMIN_CAN_VIEW_MONITOR,
            (row['CanViewMonitor'] as int? ?? 0) != 0);
        await box.put(HIVE_PLATFORM_ADMIN_CAN_MANAGE_NEWSFLASH,
            (row['CanManageNewsflash'] as int? ?? 0) != 0);
        await box.put(HIVE_PLATFORM_ADMIN_CAN_EDIT_KENNEL,
            (row['CanEditKennel'] as int? ?? 0) != 0);
        await box.put(HIVE_PLATFORM_ADMIN_CAN_MANAGE_PERMISSIONS,
            (row['CanManagePermissions'] as int? ?? 0) != 0);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[getHcAdminPrivileges] exception: $e');
    } finally {
      // Signal that privilege fetch is complete (success or failure) so the
      // navigation gate in AdminPortalApp can open. Flags default to false
      // if the call failed — the button simply won't show.
      privilegesFetched = true;
      update();
    }
  }
}
